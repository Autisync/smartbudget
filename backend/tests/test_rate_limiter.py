"""Tests for the verification-email resend limiter.

Uses fakeredis (with lupa) so the actual Lua script in check_resend runs exactly
as it would against a real Redis — verifying the atomic two-tier policy.
"""

import fakeredis
import pytest

from app.services.rate_limiter import RateLimiterService

GAP_KEY = "rate-limit:resend_verification_gap:user1"
HOUR_KEY = "rate-limit:resend_verification:user1"


@pytest.fixture
def svc():
    return RateLimiterService(fakeredis.FakeRedis(decode_responses=True))


def _elapse_gap(svc):
    """Simulate the per-send minute gap elapsing."""
    svc.redis.delete(GAP_KEY)


def test_first_send_is_allowed(svc):
    assert svc.check_resend("user1") == ("ok", 0)


def test_second_send_within_gap_is_blocked_by_minute(svc):
    assert svc.check_resend("user1")[0] == "ok"
    status, secs = svc.check_resend("user1")
    assert status == "minute"
    assert 0 < secs <= 60


def test_three_per_hour_then_hour_lock(svc):
    # 1st, 2nd, 3rd allowed (gap elapsed between each), 4th hits the hourly cap.
    assert svc.check_resend("user1")[0] == "ok"
    _elapse_gap(svc)
    assert svc.check_resend("user1")[0] == "ok"
    _elapse_gap(svc)
    assert svc.check_resend("user1")[0] == "ok"
    _elapse_gap(svc)
    status, secs = svc.check_resend("user1")
    assert status == "hour"
    assert secs > 0


def test_minute_blocks_do_not_consume_the_hourly_quota(svc):
    # One allowed send, then several gap-blocked attempts must not advance the
    # hourly counter — so after the gap, two more sends still succeed (3 total).
    assert svc.check_resend("user1")[0] == "ok"
    for _ in range(5):
        assert svc.check_resend("user1")[0] == "minute"
    assert int(svc.redis.get(HOUR_KEY)) == 1
    _elapse_gap(svc)
    assert svc.check_resend("user1")[0] == "ok"
    _elapse_gap(svc)
    assert svc.check_resend("user1")[0] == "ok"


def test_separate_users_have_independent_buckets(svc):
    assert svc.check_resend("user1")[0] == "ok"
    # A different user is unaffected by user1's gap/cap.
    assert svc.check_resend("user2")[0] == "ok"


def test_hour_key_has_expiry_set(svc):
    svc.check_resend("user1")
    assert svc.redis.ttl(HOUR_KEY) > 0
