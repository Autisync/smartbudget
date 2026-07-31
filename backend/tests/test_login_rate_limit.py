"""Regression cover for M-1: login rate limiting was bucketed per (IP, email),
so an attacker rotating source IPs (proxy pool, botnet) got a fresh
10-attempts/60s allowance from every new IP against the same target account —
there was no global per-account cap independent of source IP.
"""

import uuid

import fakeredis
import pytest
from fastapi import HTTPException

from app.core.config import settings
from app.services.rate_limiter import RateLimiterService

# ---- Unit tests: RateLimiterService.check_login_attempts_per_account ------


@pytest.fixture
def svc():
    return RateLimiterService(fakeredis.FakeRedis(decode_responses=True))


def test_allows_up_to_the_configured_max(svc):
    for _ in range(settings.login_rate_limit_per_account_max_attempts):
        assert svc.check_login_attempts_per_account("person@example.com") is True


def test_blocks_once_the_max_is_exceeded(svc):
    for _ in range(settings.login_rate_limit_per_account_max_attempts):
        svc.check_login_attempts_per_account("person@example.com")
    assert svc.check_login_attempts_per_account("person@example.com") is False


def test_bucket_is_independent_per_account(svc):
    for _ in range(settings.login_rate_limit_per_account_max_attempts):
        svc.check_login_attempts_per_account("victim@example.com")
    assert svc.check_login_attempts_per_account("victim@example.com") is False
    # A different account's attempts are entirely unaffected.
    assert svc.check_login_attempts_per_account("someone-else@example.com") is True


def test_bucket_key_is_case_and_whitespace_insensitive(svc):
    for _ in range(settings.login_rate_limit_per_account_max_attempts):
        svc.check_login_attempts_per_account("  Person@Example.com ")
    # Same account, different casing/whitespace — must hit the same bucket,
    # not bypass the cap by varying how the email is formatted.
    assert svc.check_login_attempts_per_account("person@example.com") is False


def test_expiry_is_set_on_the_bucket(svc):
    svc.check_login_attempts_per_account("person@example.com")
    ttl = svc.redis.ttl("rate-limit:login-account:person@example.com")
    assert 0 < ttl <= settings.login_rate_limit_per_account_window_seconds


# ---- Feature test: real distributed-brute-force scenario through the -----
# ---- actual endpoint function, real Postgres, real Redis -----------------


class _FakeClient:
    def __init__(self, host: str):
        self.host = host


class _FakeRequest:
    """Duck-types just what the login() endpoint reads: request.client.host."""

    def __init__(self, ip: str):
        self.client = _FakeClient(ip)


def test_distributed_brute_force_is_still_capped_per_account(real_db, real_redis):
    from app.api.v1.endpoints import auth as auth_endpoints
    from app.schemas.auth import LoginRequest, SignupRequest

    real_redis.flushdb()
    rate_limiter = RateLimiterService(real_redis)
    email = f"target-{uuid.uuid4().hex}@example.com"

    auth_endpoints.signup(
        SignupRequest(
            email=email, password="CorrectHorse123", first_name="Target", last_name="User",
        ),
        _FakeRequest(ip="198.51.100.1"),
        db=real_db,
    )

    max_attempts = settings.login_rate_limit_per_account_max_attempts
    blocked_count = 0
    for i in range(max_attempts + 10):
        # A distinct source IP on every single attempt — the per-(IP, email)
        # bucket (max 10/60s) never fires since each IP is used exactly once.
        fake_request = _FakeRequest(ip=f"203.0.113.{i % 250}")
        payload = LoginRequest(email=email, password="WrongPassword1")
        try:
            auth_endpoints.login(payload, fake_request, db=real_db, rate_limiter=rate_limiter)
        except HTTPException as exc:
            if exc.status_code == 400:
                blocked_count += 1
            elif exc.status_code == 401:
                pass  # expected: wrong password, not yet rate-limited
            else:
                raise

    assert blocked_count >= 10, (
        "expected the per-account limiter to start blocking once the "
        f"account-wide cap ({max_attempts}) was exceeded, even though every "
        "attempt came from a different source IP"
    )


def test_legitimate_single_ip_login_within_normal_use_is_unaffected(real_db, real_redis):
    from app.api.v1.endpoints import auth as auth_endpoints
    from app.schemas.auth import LoginRequest, SignupRequest

    real_redis.flushdb()
    rate_limiter = RateLimiterService(real_redis)
    email = f"normal-{uuid.uuid4().hex}@example.com"

    auth_endpoints.signup(
        SignupRequest(
            email=email, password="CorrectHorse123", first_name="Normal", last_name="User",
        ),
        _FakeRequest(ip="198.51.100.7"),
        db=real_db,
    )

    fake_request = _FakeRequest(ip="198.51.100.7")
    # A couple of typo'd attempts (well under both the per-IP and per-account
    # caps), then the correct password — must succeed normally.
    for _ in range(2):
        with pytest.raises(HTTPException) as exc_info:
            auth_endpoints.login(
                LoginRequest(email=email, password="wrongpass"), fake_request,
                db=real_db, rate_limiter=rate_limiter,
            )
        assert exc_info.value.status_code == 401

    result = auth_endpoints.login(
        LoginRequest(email=email, password="CorrectHorse123"), fake_request,
        db=real_db, rate_limiter=rate_limiter,
    )
    assert result.refresh_token
