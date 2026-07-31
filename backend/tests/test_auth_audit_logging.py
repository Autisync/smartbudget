"""Regression cover for L-2: audit_logs only ever got a row from transaction
create/delete — every authentication event (login, failed login, logout,
signup, password reset, email verification) went completely unlogged,
despite that being exactly the kind of sensitive-action trail this table
exists for. Uses the real endpoint functions against real Postgres so the
full login -> failed login -> logout flow is exercised end to end.
"""

import uuid

from sqlalchemy import select

from app.api.v1.endpoints import auth as auth_endpoints
from app.core.security import decode_token
from app.models.finance import AuditLog
from app.schemas.auth import (
    ForgotPasswordRequest,
    LoginRequest,
    LogoutRequest,
    ResetPasswordRequest,
    SignupRequest,
    VerifyEmailRequest,
)


class _FakeClient:
    def __init__(self, host):
        self.host = host


class _FakeRequest:
    def __init__(self, ip="203.0.113.42"):
        self.client = _FakeClient(ip)


def _audit_actions_for(db, user_id) -> list[str]:
    rows = db.scalars(
        select(AuditLog).where(AuditLog.actor_user_id == user_id).order_by(AuditLog.created_at)
    ).all()
    return [r.action for r in rows]


def test_full_auth_flow_produces_a_complete_audit_trail(real_db, monkeypatch):
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_a, **_k: None)
    email = f"audit-{uuid.uuid4().hex}@example.com"
    request = _FakeRequest(ip="198.51.100.9")

    # 1. Signup
    signup_result = auth_endpoints.signup(
        SignupRequest(email=email, password="StrongPass123", first_name="A", last_name="B"),
        request, db=real_db,
    )
    user_id = decode_token(signup_result.access_token)["sub"]

    # 2. Failed login (wrong password)
    try:
        auth_endpoints.login(
            LoginRequest(email=email, password="WrongPassword1"), request,
            db=real_db, rate_limiter=_NoopLimiter(),
        )
    except Exception:
        pass

    # 3. Successful login
    login_result = auth_endpoints.login(
        LoginRequest(email=email, password="StrongPass123"), request,
        db=real_db, rate_limiter=_NoopLimiter(),
    )

    # 4. Logout
    auth_endpoints.logout(LogoutRequest(refresh_token=login_result.refresh_token), request, db=real_db)

    actions = _audit_actions_for(real_db, uuid.UUID(user_id))
    assert actions == [
        "auth.signup",
        "auth.login_failed",
        "auth.login_success",
        "auth.logout",
    ]


class _NoopLimiter:
    def check_login_attempts(self, *_a, **_k):
        return True

    def check_login_attempts_per_account(self, *_a, **_k):
        return True


def test_login_against_nonexistent_account_is_still_audited(real_db):
    email = f"ghost-{uuid.uuid4().hex}@example.com"
    request = _FakeRequest()
    try:
        auth_endpoints.login(
            LoginRequest(email=email, password="whatever1"), request,
            db=real_db, rate_limiter=_NoopLimiter(),
        )
    except Exception:
        pass
    row = real_db.scalar(
        select(AuditLog).where(
            AuditLog.action == "auth.login_failed",
            AuditLog.metadata_json["email"].astext == email.lower(),
        )
    )
    assert row is not None
    assert row.actor_user_id is None  # no account exists to attribute it to
    assert row.ip_address == request.client.host


def test_password_reset_flow_is_fully_audited(real_db, monkeypatch):
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_a, **_k: None)
    email = f"reset-{uuid.uuid4().hex}@example.com"
    request = _FakeRequest()

    signup_result = auth_endpoints.signup(
        SignupRequest(email=email, password="StrongPass123", first_name="A", last_name="B"),
        request, db=real_db,
    )
    user_id = decode_token(signup_result.access_token)["sub"]

    auth_endpoints.forgot_password(
        ForgotPasswordRequest(email=email), request, db=real_db, rate_limiter=_NoopLimiter2(),
    )

    from app.core.security import create_short_lived_token
    reset_token = create_short_lived_token(subject=user_id, token_type="reset_password", ttl_seconds=1800)
    auth_endpoints.reset_password(
        ResetPasswordRequest(token=reset_token, new_password="NewStrongPass123"), request, db=real_db,
    )

    verify_token = create_short_lived_token(subject=user_id, token_type="verify_email", ttl_seconds=86400)
    auth_endpoints.verify_email(VerifyEmailRequest(token=verify_token), request, db=real_db)

    actions = _audit_actions_for(real_db, uuid.UUID(user_id))
    assert "auth.password_reset_requested" in actions
    assert "auth.password_reset_completed" in actions
    assert "auth.email_verified" in actions


class _NoopLimiter2:
    def check_once(self, *_a, **_k):
        return True


def test_duplicate_signup_attempt_is_audited_against_the_existing_account(real_db, monkeypatch):
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_a, **_k: None)
    email = f"dupe-{uuid.uuid4().hex}@example.com"
    request = _FakeRequest()

    signup_result = auth_endpoints.signup(
        SignupRequest(email=email, password="StrongPass123", first_name="A", last_name="B"),
        request, db=real_db,
    )
    user_id = decode_token(signup_result.access_token)["sub"]

    try:
        auth_endpoints.signup(
            SignupRequest(email=email, password="AnotherPass123", first_name="C", last_name="D"),
            request, db=real_db,
        )
    except Exception:
        pass

    actions = _audit_actions_for(real_db, uuid.UUID(user_id))
    assert "auth.signup_duplicate_attempt" in actions


def test_ip_address_is_recorded_on_audit_entries(real_db, monkeypatch):
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_a, **_k: None)
    email = f"ip-{uuid.uuid4().hex}@example.com"
    request = _FakeRequest(ip="192.0.2.55")

    signup_result = auth_endpoints.signup(
        SignupRequest(email=email, password="StrongPass123", first_name="A", last_name="B"),
        request, db=real_db,
    )
    user_id = decode_token(signup_result.access_token)["sub"]

    row = real_db.scalar(
        select(AuditLog).where(
            AuditLog.actor_user_id == uuid.UUID(user_id), AuditLog.action == "auth.signup",
        )
    )
    assert row.ip_address == "192.0.2.55"
