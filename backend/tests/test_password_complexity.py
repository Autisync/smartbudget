"""Regression cover for L-4: password complexity (uppercase, lowercase,
digit) was enforced only in the reset-password page's client-side JS (see
main.py's isStrongPassword) — the API itself only checked length (8-128
chars), so a direct API call could set "aaaaaaaa" as a password.
"""

import uuid

import pytest
from pydantic import ValidationError

from app.api.v1.endpoints import auth as auth_endpoints
from app.schemas.auth import ResetPasswordRequest, SignupRequest


class _FakeClient:
    host = "203.0.113.1"


class _FakeRequest:
    client = _FakeClient()


class _NoopLimiter:
    def check_login_attempts(self, *_a, **_k):
        return True

    def check_login_attempts_per_account(self, *_a, **_k):
        return True


# ---- Unit tests: schema validation -----------------------------------------


@pytest.mark.parametrize("password", [
    "aaaaaaaa",       # all lowercase
    "AAAAAAAA",       # all uppercase
    "12345678",       # all digits
    "alllowercase",   # no digit, no uppercase
    "ALLUPPERCASE1",  # no lowercase (has digit though — still missing lowercase)
])
def test_weak_passwords_are_rejected(password):
    with pytest.raises(ValidationError):
        SignupRequest(email="a@b.com", password=password, first_name="A", last_name="B")


@pytest.mark.parametrize("password", [
    "StrongPass123",
    "Another1Good",
    "MixedCase9x",
])
def test_compliant_passwords_are_accepted(password):
    req = SignupRequest(email="a@b.com", password=password, first_name="A", last_name="B")
    assert req.password == password


def test_reset_password_new_password_has_the_same_rule():
    with pytest.raises(ValidationError):
        ResetPasswordRequest(token="a" * 25, new_password="weakweakweak")
    req = ResetPasswordRequest(token="a" * 25, new_password="StrongPass123")
    assert req.new_password == "StrongPass123"


def test_login_password_is_not_subject_to_the_complexity_rule():
    """Existing accounts may predate this rule — login must still accept
    whatever password is actually stored, not re-validate complexity."""
    from app.schemas.auth import LoginRequest
    req = LoginRequest(email="a@b.com", password="oldweakpass")
    assert req.password == "oldweakpass"


# ---- Feature tests: through the real endpoint ------------------------------


def test_signup_endpoint_rejects_a_weak_password_with_a_clear_error(real_db):
    with pytest.raises(ValidationError) as exc_info:
        SignupRequest(
            email=f"weak-{uuid.uuid4().hex}@example.com", password="weakweak",
            first_name="A", last_name="B",
        )
    message = str(exc_info.value)
    assert "uppercase" in message or "lowercase" in message or "number" in message


def test_signup_endpoint_accepts_a_compliant_password(real_db, monkeypatch):
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_a, **_k: None)
    email = f"strong-{uuid.uuid4().hex}@example.com"
    result = auth_endpoints.signup(
        SignupRequest(email=email, password="StrongPass123", first_name="A", last_name="B"),
        _FakeRequest(), db=real_db,
    )
    assert result.refresh_token
