"""Regression cover for a re-audit finding: /reset-password and /verify-email
had no rate limiting, unlike every other auth endpoint that accepts
untrusted input (/login, /forgot-password, /social-login). Tokens are
signed JWTs (infeasible to brute-force), so this is about bounding
endpoint-abuse/probing traffic, not token guessing specifically.
"""

import fakeredis
import pytest
from fastapi import HTTPException

from app.services.rate_limiter import RateLimiterService

# ---- Unit test: RateLimiterService.check_once, the mechanism reused here --


@pytest.fixture
def svc():
    return RateLimiterService(fakeredis.FakeRedis(decode_responses=True))


def test_reset_password_bucket_allows_up_to_the_configured_max(svc):
    for _ in range(10):
        assert svc.check_once("reset-password", "203.0.113.5", max_attempts=10, window_seconds=900) is True


def test_reset_password_bucket_blocks_once_exceeded(svc):
    for _ in range(10):
        svc.check_once("reset-password", "203.0.113.5", max_attempts=10, window_seconds=900)
    assert svc.check_once("reset-password", "203.0.113.5", max_attempts=10, window_seconds=900) is False


def test_verify_email_bucket_is_independent_of_reset_password_bucket(svc):
    for _ in range(10):
        svc.check_once("reset-password", "203.0.113.5", max_attempts=10, window_seconds=900)
    assert svc.check_once("reset-password", "203.0.113.5", max_attempts=10, window_seconds=900) is False
    # A different action name against the same IP is an entirely separate
    # bucket — hammering reset-password doesn't also lock out verify-email.
    assert svc.check_once("verify-email", "203.0.113.5", max_attempts=10, window_seconds=900) is True


# ---- Feature test: through the real endpoint functions, real Redis --------


class _FakeClient:
    def __init__(self, host: str):
        self.host = host


class _FakeRequest:
    def __init__(self, ip: str):
        self.client = _FakeClient(ip)


def test_reset_password_endpoint_is_rate_limited_per_ip(real_db, real_redis):
    from app.api.v1.endpoints import auth as auth_endpoints
    from app.schemas.auth import ResetPasswordRequest

    real_redis.flushdb()
    rate_limiter = RateLimiterService(real_redis)
    request = _FakeRequest(ip="198.51.100.20")

    blocked_count = 0
    invalid_token_count = 0
    for _ in range(20):
        payload = ResetPasswordRequest(token="not-a-real-token-xxxxxxxxxx", new_password="CorrectHorse123")
        try:
            auth_endpoints.reset_password(payload, request, db=real_db, rate_limiter=rate_limiter)
        except HTTPException as exc:
            assert exc.status_code == 400
            if "Too many requests" in str(exc.detail):
                blocked_count += 1
            else:
                invalid_token_count += 1

    assert invalid_token_count == 10, "expected exactly the configured max_attempts through before blocking"
    assert blocked_count == 10, "expected the limiter to block every attempt past max_attempts"


def test_verify_email_endpoint_is_rate_limited_per_ip(real_db, real_redis):
    from app.api.v1.endpoints import auth as auth_endpoints
    from app.schemas.auth import VerifyEmailRequest

    real_redis.flushdb()
    rate_limiter = RateLimiterService(real_redis)
    request = _FakeRequest(ip="198.51.100.21")

    blocked_count = 0
    invalid_token_count = 0
    for _ in range(20):
        payload = VerifyEmailRequest(token="not-a-real-token-xxxxxxxxxx")
        try:
            auth_endpoints.verify_email(payload, request, db=real_db, rate_limiter=rate_limiter)
        except HTTPException as exc:
            assert exc.status_code == 400
            if "Too many requests" in str(exc.detail):
                blocked_count += 1
            else:
                invalid_token_count += 1

    assert invalid_token_count == 10
    assert blocked_count == 10


def test_legitimate_single_reset_attempt_is_unaffected(real_db, real_redis):
    from app.api.v1.endpoints import auth as auth_endpoints
    from app.schemas.auth import ResetPasswordRequest

    real_redis.flushdb()
    rate_limiter = RateLimiterService(real_redis)
    request = _FakeRequest(ip="198.51.100.22")

    payload = ResetPasswordRequest(token="not-a-real-token-xxxxxxxxxx", new_password="CorrectHorse123")
    with pytest.raises(HTTPException) as exc_info:
        auth_endpoints.reset_password(payload, request, db=real_db, rate_limiter=rate_limiter)
    # A single legitimate-shaped attempt hits "Invalid token" (expected —
    # this isn't a real token), never the rate limiter.
    assert "Invalid token" in str(exc_info.value.detail)
