"""Regression cover for a re-audit finding: current_user() (app/api/deps.py)
never checked user.is_active, unlike login/social_login/refresh in
auth_service.py — a deactivated account (e.g. banned for fraud, or a user
who deleted their account) kept full API access on any access token already
issued, until that token's normal TTL expiry, rather than losing access
immediately.
"""

import uuid

from fastapi.security import HTTPAuthorizationCredentials
from fastapi.testclient import TestClient
from sqlalchemy import update

from app.api.deps import current_user
from app.core.security import create_access_token
from app.main import create_application
from app.models.user import User
from app.repositories.user_repository import UserRepository

# ---- Unit test: current_user() in isolation --------------------------------


def test_current_user_returns_none_for_a_deactivated_account(real_db):
    user = UserRepository(real_db).create(
        email=f"deactivated-{uuid.uuid4().hex}@example.com",
        password_hash="not-a-real-hash",
        first_name="A",
        last_name="B",
    )
    token, _ = create_access_token(str(user.id))
    credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

    # Active: resolves normally.
    assert current_user(credentials=credentials, db=real_db) is not None

    real_db.execute(update(User).where(User.id == user.id).values(is_active=False))
    real_db.commit()

    # Deactivated: the same still-unexpired token now resolves to no user.
    assert current_user(credentials=credentials, db=real_db) is None


# ---- Feature test: a deactivated account is locked out mid-session --------


def test_deactivated_account_loses_api_access_immediately(real_db):
    user = UserRepository(real_db).create(
        email=f"deactivated-feature-{uuid.uuid4().hex}@example.com",
        password_hash="not-a-real-hash",
        first_name="A",
        last_name="B",
    )
    token, _ = create_access_token(str(user.id))
    headers = {"Authorization": f"Bearer {token}"}
    client = TestClient(create_application())

    # Active: /auth/me works normally with this token.
    resp = client.get("/api/v1/auth/me", headers=headers)
    assert resp.status_code == 200

    # Deactivate mid-session — no new login, the exact same token is reused.
    real_db.execute(update(User).where(User.id == user.id).values(is_active=False))
    real_db.commit()

    resp = client.get("/api/v1/auth/me", headers=headers)
    assert resp.status_code == 401

    # The finance API (a separate router, same require_user dependency) is
    # locked out too, not just the auth router.
    resp = client.get("/api/v1/finance/budgets", headers=headers)
    assert resp.status_code == 401
