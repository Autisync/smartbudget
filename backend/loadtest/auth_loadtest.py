"""P2.15: conservative real load test of auth endpoints against production.

Run manually (never in CI, never unattended): python backend/loadtest/auth_loadtest.py

Targets https://api.smaartspend.com per the user's explicit, one-time approval
recorded in docs/REMEDIATION_PLAN.md section 2.15. Ramps a small number of
concurrent workers through login/refresh cycles, round-robining a pool of
dedicated, clearly-tagged test accounts (created once up front) so no single
account approaches the production per-(IP, account) login rate limit
(10 attempts/60s — see app/core/config.py's login_rate_limit_per_account_*
and app/services/rate_limiter.py's check_login_attempts). A first pass at 5
accounts with workers pinned to one account each tripped that limiter almost
immediately — a test-harness artifact, not a backend defect (successful
requests before the trip were well within target latency). This version
fixes that by rotating every login across a larger account pool and capping
total login volume by budget rather than by wall-clock duration alone, so the
per-account attempt count is bounded by design regardless of observed latency.

Output: backend/LOAD_TEST_REPORT.md with p50/p95/p99 latency, error rate, and
a go/no-go read against RELEASE_BUILD.md's target (p95 login < 400ms excl.
Argon2, error rate < 0.5%).
"""

import asyncio
import time
import uuid
from dataclasses import dataclass, field
from itertools import count

import httpx

BASE_URL = "https://api.smaartspend.com/api/v1"
TEST_ACCOUNT_COUNT = 40
TEST_EMAIL_DOMAIN = "loadtest.example.com"  # RFC 2606 reserved documentation domain — passes email validation, unambiguously not a real user
STAGE_CONCURRENCY = [2, 5, 10]
STAGE_DURATION_SECONDS = 15
# 200 total logins / 40 accounts = 5 attempts/account on average — comfortably
# under the 10-attempts/60s per-account limit even with uneven scheduling.
MAX_LOGIN_REQUESTS_TOTAL = 200
ABORT_ERROR_RATE_THRESHOLD = 0.10  # stop immediately if >10% of a sample of >=20 requests fail
ABORT_CONSECUTIVE_FAILURES = 5


@dataclass
class EndpointStats:
    latencies_ms: list = field(default_factory=list)
    errors: int = 0
    total: int = 0

    def record(self, elapsed_ms: float, ok: bool) -> None:
        self.total += 1
        if ok:
            self.latencies_ms.append(elapsed_ms)
        else:
            self.errors += 1

    def percentile(self, p: float) -> float:
        if not self.latencies_ms:
            return float("nan")
        data = sorted(self.latencies_ms)
        k = int(round((p / 100) * (len(data) - 1)))
        return data[k]

    def error_rate(self) -> float:
        return self.errors / self.total if self.total else 0.0


async def preflight_check(client: httpx.AsyncClient) -> bool:
    resp = await client.get(f"{BASE_URL}/health/ready")
    print(f"[preflight] /health/ready -> {resp.status_code}: {resp.text[:300]}")
    if resp.status_code != 200:
        return False
    body = resp.json()
    return body.get("status") in ("ok", "degraded")


async def create_test_accounts(client: httpx.AsyncClient, n: int) -> list[dict]:
    accounts = []
    for _ in range(n):
        email = f"loadtest-{uuid.uuid4().hex[:12]}@{TEST_EMAIL_DOMAIN}"
        password = "LoadTest123x"
        resp = await client.post(
            f"{BASE_URL}/auth/signup",
            json={
                "email": email, "password": password,
                "first_name": "Load", "last_name": "Test",
                "device_name": "loadtest-p2.15", "platform": "loadtest",
            },
        )
        if resp.status_code != 200:
            raise RuntimeError(f"Signup failed during account setup: {resp.status_code} {resp.text}")
        body = resp.json()
        accounts.append({
            "email": email, "password": password,
            "refresh_token": body["refresh_token"],
        })
    print(f"[setup] created {len(accounts)} test accounts under @{TEST_EMAIL_DOMAIN}")
    return accounts


class Aborted(Exception):
    pass


class Budget:
    """Global login-request budget shared across all workers/stages. asyncio
    is single-threaded and nothing awaits between the check and increment
    below, so this is race-free without a lock."""

    def __init__(self, total: int) -> None:
        self._counter = count()
        self._total = total
        self._issued = 0

    def take(self) -> bool:
        if self._issued >= self._total:
            return False
        self._issued += 1
        next(self._counter)
        return True


async def worker_cycle(
    client: httpx.AsyncClient, account: dict, stats: dict, consecutive_failures: list,
) -> None:
    t0 = time.perf_counter()
    resp = await client.post(
        f"{BASE_URL}/auth/login",
        json={"email": account["email"], "password": account["password"], "platform": "loadtest"},
    )
    elapsed_ms = (time.perf_counter() - t0) * 1000
    ok = resp.status_code == 200
    stats["login"].record(elapsed_ms, ok)
    consecutive_failures[0] = 0 if ok else consecutive_failures[0] + 1
    if consecutive_failures[0] >= ABORT_CONSECUTIVE_FAILURES:
        raise Aborted(f"{ABORT_CONSECUTIVE_FAILURES} consecutive login failures")
    for key in ("login",):
        if stats[key].total >= 20 and stats[key].error_rate() > ABORT_ERROR_RATE_THRESHOLD:
            raise Aborted(f"{key} error rate {stats[key].error_rate():.1%} exceeded threshold")
    if not ok:
        return
    refresh_token = resp.json()["refresh_token"]

    t0 = time.perf_counter()
    resp = await client.post(f"{BASE_URL}/auth/refresh", json={"refresh_token": refresh_token})
    elapsed_ms = (time.perf_counter() - t0) * 1000
    ok = resp.status_code == 200
    stats["refresh"].record(elapsed_ms, ok)
    consecutive_failures[0] = 0 if ok else consecutive_failures[0] + 1
    if consecutive_failures[0] >= ABORT_CONSECUTIVE_FAILURES:
        raise Aborted(f"{ABORT_CONSECUTIVE_FAILURES} consecutive refresh failures")
    if stats["refresh"].total >= 20 and stats["refresh"].error_rate() > ABORT_ERROR_RATE_THRESHOLD:
        raise Aborted(f"refresh error rate {stats['refresh'].error_rate():.1%} exceeded threshold")


async def run_stage(
    client: httpx.AsyncClient, accounts: list[dict], concurrency: int, duration_s: int,
    stats: dict, budget: Budget, next_account_idx: list,
) -> None:
    print(f"[stage] concurrency={concurrency} duration={duration_s}s budget_remaining={budget._total - budget._issued}")
    end_at = time.monotonic() + duration_s

    async def worker() -> None:
        while time.monotonic() < end_at and budget.take():
            idx = next_account_idx[0] % len(accounts)
            next_account_idx[0] += 1
            await worker_cycle(client, accounts[idx], stats, [0])

    await asyncio.gather(*(worker() for _ in range(concurrency)))


async def main() -> None:
    stats = {"signup": EndpointStats(), "login": EndpointStats(), "refresh": EndpointStats()}
    aborted_reason = None

    async with httpx.AsyncClient(timeout=10.0) as client:
        if not await preflight_check(client):
            print("[abort] preflight /health/ready check failed — not starting load test")
            write_report(stats, aborted_reason="preflight /health/ready check failed", accounts=[])
            return

        accounts = await create_test_accounts(client, TEST_ACCOUNT_COUNT)
        budget = Budget(MAX_LOGIN_REQUESTS_TOTAL)
        next_account_idx = [0]
        for stage_concurrency in STAGE_CONCURRENCY:
            try:
                await run_stage(
                    client, accounts, stage_concurrency, STAGE_DURATION_SECONDS,
                    stats, budget, next_account_idx,
                )
            except Aborted as exc:
                aborted_reason = str(exc)
                print(f"[abort] {aborted_reason}")
                break
            if budget._issued >= budget._total:
                print("[done] login request budget exhausted")
                break

    write_report(stats, aborted_reason, accounts)


def write_report(stats: dict, aborted_reason: str | None, accounts: list[dict]) -> None:
    login = stats["login"]
    lines = [
        "# P2.15 Auth Load Test Report",
        "",
        f"Target: `{BASE_URL}` — auth signup/login/refresh",
        f"Ramp: concurrency {STAGE_CONCURRENCY}, {STAGE_DURATION_SECONDS}s/stage, "
        f"login budget {MAX_LOGIN_REQUESTS_TOTAL} rotated across {TEST_ACCOUNT_COUNT} accounts",
        "",
    ]
    if aborted_reason:
        lines += [f"**ABORTED**: {aborted_reason}", ""]

    lines.append("## Results")
    lines.append("")
    lines.append("| Endpoint | Requests | Errors | Error rate | p50 (ms) | p95 (ms) | p99 (ms) |")
    lines.append("|---|---|---|---|---|---|---|")
    for name, s in stats.items():
        lines.append(
            f"| {name} | {s.total} | {s.errors} | {s.error_rate():.2%} | "
            f"{s.percentile(50):.0f} | {s.percentile(95):.0f} | {s.percentile(99):.0f} |"
        )

    lines.append("")
    lines.append("## Go/no-go vs RELEASE_BUILD.md target (p95 login < 400ms excl. Argon2, error rate < 0.5%)")
    if login.total == 0:
        lines.append("- No login samples collected — cannot evaluate.")
    else:
        p95_ok = login.percentile(95) < 400
        err_ok = login.error_rate() < 0.005
        verdict = "GO" if (p95_ok and err_ok and not aborted_reason) else "NO-GO"
        lines.append(f"- login p95: {login.percentile(95):.0f}ms ({'within' if p95_ok else 'EXCEEDS'} target)")
        lines.append(f"- login error rate: {login.error_rate():.2%} ({'within' if err_ok else 'EXCEEDS'} target)")
        lines.append(f"- **Verdict: {verdict}**")

    lines.append("")
    lines.append("## Test data created (needs manual cleanup)")
    lines.append(f"- {len(accounts)} accounts under `*@{TEST_EMAIL_DOMAIN}` were created for this test.")
    lines.append("")
    lines.append("Cleanup SQL (run manually against the production DB — not executed by this script):")
    lines.append("```sql")
    lines.append(f"DELETE FROM auth_sessions WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%@{TEST_EMAIL_DOMAIN}');")
    lines.append(f"DELETE FROM users WHERE email LIKE '%@{TEST_EMAIL_DOMAIN}';")
    lines.append("```")

    report = "\n".join(lines) + "\n"
    with open("LOAD_TEST_REPORT.md", "w") as f:
        f.write(report)
    print("\n" + report)


if __name__ == "__main__":
    asyncio.run(main())
