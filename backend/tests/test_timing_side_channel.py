"""Regression cover for H-2: Argon2 timing side-channel on signup/login.

Both endpoints returned identical response *bodies* regardless of whether an
account existed — a deliberate anti-enumeration design — but the "account
doesn't exist" branch skipped the (deliberately expensive) Argon2 hash/verify
entirely, while the "account exists" branch paid the full cost. Identical
bodies with measurably different latency still leaks account existence.
"""

import time
from types import SimpleNamespace
from uuid import uuid4

import pytest
from fastapi import HTTPException

from app.core.security import hash_password, verify_password_constant_time
from app.services.auth_service import AuthService


class _DummyDb:
    def add(self, _obj) -> None:
        return

    def commit(self) -> None:
        return

    def refresh(self, _obj) -> None:
        return


class _InMemoryUserRepository:
    def __init__(self):
        self._by_email: dict[str, SimpleNamespace] = {}

    def get_by_email(self, email: str):
        return self._by_email.get(email.lower().strip())

    def get_by_apple_sub(self, _apple_sub: str):
        return None

    def create(self, *, email, password_hash, first_name, last_name, apple_sub=None):
        user = SimpleNamespace(
            id=uuid4(), email=email.lower().strip(), password_hash=password_hash,
            first_name=first_name.strip(), last_name=last_name.strip(),
            is_active=True, is_verified=False, apple_sub=apple_sub,
        )
        self._by_email[user.email] = user
        return user


class _InMemorySessionRepository:
    def create_session(self, **_kwargs) -> None:
        return


# ---- Unit tests: verify_password_constant_time itself ----------------------


def test_constant_time_verify_rejects_when_no_hash_exists():
    assert verify_password_constant_time("anything", None) is False


def test_constant_time_verify_accepts_correct_password():
    h = hash_password("CorrectHorseBattery1")
    assert verify_password_constant_time("CorrectHorseBattery1", h) is True


def test_constant_time_verify_rejects_wrong_password():
    h = hash_password("CorrectHorseBattery1")
    assert verify_password_constant_time("WrongPassword1", h) is False


def test_constant_time_verify_calls_real_argon2_check_even_with_no_hash(monkeypatch):
    """The whole point of the fix: a real Argon2 verify must run on the
    "no such account" path too, not be skipped. Assert via call count
    (deterministic) rather than wall-clock (flaky in CI)."""
    calls = []
    import app.core.security as security_module

    real_verify = type(security_module.password_hasher).verify

    def counting_verify(self, *args, **kwargs):
        calls.append(1)
        return real_verify(self, *args, **kwargs)

    monkeypatch.setattr(type(security_module.password_hasher), "verify", counting_verify)

    verify_password_constant_time("whatever", None)
    assert len(calls) == 1, "no-such-account path must still invoke a real Argon2 verify"


# ---- Feature tests: signup/login through AuthService -----------------------


@pytest.fixture
def service(monkeypatch):
    svc = AuthService(_DummyDb())
    svc.users = _InMemoryUserRepository()
    svc.sessions = _InMemorySessionRepository()
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_a, **_k: None)
    return svc


def test_login_nonexistent_account_still_invokes_argon2(service, monkeypatch):
    calls = []
    import app.core.security as security_module
    real_verify = type(security_module.password_hasher).verify

    def counting_verify(self, *args, **kwargs):
        calls.append(1)
        return real_verify(self, *args, **kwargs)

    monkeypatch.setattr(type(security_module.password_hasher), "verify", counting_verify)

    with pytest.raises(HTTPException):
        service.login(
            email="nobody@example.com", password="whatever123",
            device_name="dev", platform="ios",
        )
    assert len(calls) == 1


def test_signup_duplicate_email_still_invokes_argon2_hash(service, monkeypatch):
    service.signup(
        email="taken@example.com", password="StrongPass123",
        first_name="A", last_name="B", device_name="dev", platform="ios",
    )

    calls = []
    import app.core.security as security_module
    real_hash = type(security_module.password_hasher).hash

    def counting_hash(self, *args, **kwargs):
        calls.append(1)
        return real_hash(self, *args, **kwargs)

    monkeypatch.setattr(type(security_module.password_hasher), "hash", counting_hash)

    with pytest.raises(HTTPException):
        service.signup(
            email="taken@example.com", password="AnotherPass123",
            first_name="C", last_name="D", device_name="dev", platform="ios",
        )
    assert len(calls) == 1, "duplicate-email branch must still pay a real Argon2 hash cost"


def test_login_timing_existing_vs_nonexistent_account_is_close(service):
    """Statistical, not exact — real wall-clock measurements on a shared dev
    machine are noisy (background processes, GC pauses, disk I/O), so this
    uses the *median* over many samples (robust to occasional slow outliers)
    and a *relative* tolerance rather than an absolute millisecond budget.
    The bug this guards against is not subtle: skipping Argon2 entirely on
    one path makes it orders of magnitude faster (a ~100ms hash vs a
    microsecond dict lookup), not merely 2-3x — so a generous ratio window
    still meaningfully catches a regression without being flaky."""
    import statistics

    service.signup(
        email="realuser@example.com", password="StrongPass123",
        first_name="A", last_name="B", device_name="dev", platform="ios",
    )

    def timed_login(email: str, password: str) -> float:
        start = time.perf_counter()
        try:
            service.login(email=email, password=password, device_name="dev", platform="ios")
        except HTTPException:
            pass
        return time.perf_counter() - start

    existing_wrong_pw = [timed_login("realuser@example.com", "WrongPassword1") for _ in range(15)]
    nonexistent = [timed_login("nobody@example.com", "WrongPassword1") for _ in range(15)]

    median_existing = statistics.median(existing_wrong_pw)
    median_nonexistent = statistics.median(nonexistent)
    ratio = max(median_existing, median_nonexistent) / max(min(median_existing, median_nonexistent), 1e-6)

    assert ratio < 4, (
        f"timing ratio too large: existing={median_existing:.4f}s "
        f"nonexistent={median_nonexistent:.4f}s (ratio {ratio:.1f}x) — "
        "Argon2 may be skipped on one path"
    )
