# P2.15 Auth Load Test Report

Target: `https://api.smaartspend.com/api/v1` — auth signup/login/refresh
Ramp: concurrency [2, 5, 10], 15s/stage, login budget 200 rotated across 40 accounts

## Results

| Endpoint | Requests | Errors | Error rate | p50 (ms) | p95 (ms) | p99 (ms) |
|---|---|---|---|---|---|---|
| login | 200 | 0 | 0.00% | 198 | 411 | 496 |
| refresh | 200 | 0 | 0.00% | 82 | 135 | 152 |

`signup` (40 requests, sequential, not under concurrent ramp) had 0 errors — it
was deliberately excluded from the concurrent load stages to avoid creating
more than the minimum number of disposable test accounts in production.

### Attempt history
A first attempt (not reflected above) pinned each of only 5 test accounts to
one worker and hit a 13% login error rate — that was the pre-existing
per-(IP, account) brute-force limiter (10 attempts/60s, see
`app/services/rate_limiter.py`) tripping under concentrated single-account
load, not a backend defect. This run fixed the harness (40 accounts,
round-robined, 200-login budget) and produced a clean, non-rate-limited
reading.

## Go/no-go vs RELEASE_BUILD.md target (p95 login < 400ms excl. Argon2, error rate < 0.5%)
- login p95: 411ms (EXCEEDS the literal 400ms figure)
- login error rate: 0.00% (within target)
- **Verdict: NO-GO on the raw number, but inconclusive against the actual SLO** — the
  400ms target explicitly excludes Argon2 password-hashing time, and this script
  measures end-to-end client latency, which necessarily includes the server-side
  Argon2 verification done on every login. Argon2 is deliberately expensive by
  design (that's the point of the hash), so it plausibly accounts for most of the
  measured time. Isolating the non-Argon2 portion needs server-side timing
  (e.g. a Sentry performance span around the Argon2 call, or an APM trace) —
  not available from this black-box client test. Until that breakdown exists,
  treat 411ms as an upper bound, not proof the non-Argon2 path is slow: p50
  (198ms) and refresh p95 (135ms, no Argon2 involved) both look healthy.
- **Recommendation**: add a Sentry performance span around the Argon2 verify
  call in `app/core/security.py` so a future run of this same script can
  report the excl.-Argon2 number the SLO actually asks for.

## Test data created (needs manual cleanup)
- 40 accounts under `*@loadtest.example.com` were created for this test.

Cleanup SQL (run manually against the production DB — not executed by this script):
```sql
DELETE FROM auth_sessions WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%@loadtest.example.com');
DELETE FROM users WHERE email LIKE '%@loadtest.example.com';
```
