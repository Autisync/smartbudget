"""Regression cover for H-1: Apple Sign-In email-spoofing account takeover.

`_verify_apple_token` used to fall back to the client-supplied `email` field
(fully attacker-controlled, straight from the request body) whenever Apple's
signed identity token omitted the `email` claim — routine on a returning
user's later logins. `social_login` would then look up an existing account
by that email and log the caller in with no password check at all: an
attacker only needed their own valid Apple identity token plus a victim's
email in the request body.

The fix resolves returning users via the token's cryptographically verified
`sub` claim (stored as `User.apple_sub`) instead, and rejects the login
outright — rather than trusting client-supplied data — when there's no email
claim and no prior `apple_sub` mapping.
"""

from types import SimpleNamespace
from uuid import uuid4

import pytest
from fastapi import HTTPException

from app.services.auth_service import AuthService

# Reuse the same lightweight in-memory fakes/pattern as test_auth_service_flow.py.


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
        self._by_id: dict[str, SimpleNamespace] = {}

    def get_by_email(self, email: str):
        return self._by_email.get(email.lower().strip())

    def get_by_id(self, user_id: str):
        return self._by_id.get(str(user_id))

    def get_by_apple_sub(self, apple_sub: str):
        for user in self._by_email.values():
            if getattr(user, "apple_sub", None) == apple_sub:
                return user
        return None

    def create(self, *, email: str, password_hash: str, first_name: str, last_name: str, apple_sub=None):
        user = SimpleNamespace(
            id=uuid4(),
            email=email.lower().strip(),
            password_hash=password_hash,
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            is_active=True,
            is_verified=False,
            apple_sub=apple_sub,
        )
        self._by_email[user.email] = user
        self._by_id[str(user.id)] = user
        return user

    def link_apple_sub(self, user, apple_sub: str):
        user.apple_sub = apple_sub
        return user

    def update_profile(self, user, *, first_name=None, last_name=None):
        return user


class _InMemorySessionRepository:
    def __init__(self):
        self._by_hash: dict[str, SimpleNamespace] = {}

    def create_session(self, *, user_id, token_hash, device_name, platform, expires_at):
        self._by_hash[token_hash] = SimpleNamespace(
            user_id=str(user_id), device_name=device_name, platform=platform,
            revoked_at=None, expires_at=expires_at,
        )

    def get_active_by_token_hash(self, token_hash):
        s = self._by_hash.get(token_hash)
        return s if s and s.revoked_at is None else None

    def revoke_by_token_hash(self, token_hash):
        s = self._by_hash.get(token_hash)
        if s:
            from datetime import UTC, datetime
            s.revoked_at = datetime.now(UTC)

    def revoke_all_for_user(self, user_id: str):
        from datetime import UTC, datetime
        now = datetime.now(UTC)
        for s in self._by_hash.values():
            if s.user_id == str(user_id) and s.revoked_at is None:
                s.revoked_at = now


@pytest.fixture
def service(monkeypatch):
    svc = AuthService(_DummyDb())
    svc.users = _InMemoryUserRepository()
    svc.sessions = _InMemorySessionRepository()
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_a, **_k: None)
    return svc


def _mock_apple_token(monkeypatch, payload: dict):
    """Bypasses the real Apple JWKS fetch + signature verification and makes
    `_verify_apple_token` see exactly `payload`, as if it were a validly
    signed token for that content."""
    monkeypatch.setattr(
        type(AuthService._apple_jwk_client),
        "get_signing_key_from_jwt",
        lambda self, token: SimpleNamespace(key="fake-key"),
    )
    monkeypatch.setattr(
        "app.services.auth_service.jwt.decode",
        lambda *args, **kwargs: payload,
    )


VICTIM_EMAIL = "victim@example.com"
ATTACKER_APPLE_SUB = "001999.attackersub.0001"
VICTIM_APPLE_SUB = "001999.victimsub.0002"


def test_social_login_with_email_claim_works_normally(service, monkeypatch):
    _mock_apple_token(monkeypatch, {
        "sub": VICTIM_APPLE_SUB,
        "email": VICTIM_EMAIL,
        "email_verified": "true",
    })

    result = service.social_login(
        provider="apple", id_token="whatever", email=None,
        first_name="Real", last_name="User", device_name="iPhone", platform="ios",
    )
    assert result.refresh_token

    user = service.users.get_by_email(VICTIM_EMAIL)
    assert user is not None
    assert user.apple_sub == VICTIM_APPLE_SUB


def test_missing_email_claim_cannot_take_over_existing_account_via_body_email(service, monkeypatch):
    # The victim already has an account (e.g. signed up with email/password
    # or Google previously) — never linked to any Apple identity.
    service.users.create(
        email=VICTIM_EMAIL, password_hash="hash", first_name="Victim", last_name="Real",
    )

    # Attacker presents THEIR OWN validly-signed Apple token (a real token
    # they legitimately obtained for their own Apple ID), which has no email
    # claim, and claims the victim's email in the request body.
    _mock_apple_token(monkeypatch, {
        "sub": ATTACKER_APPLE_SUB,
        # no "email" claim — exactly the case that was exploitable
    })

    with pytest.raises(HTTPException) as exc_info:
        service.social_login(
            provider="apple", id_token="attacker-token", email=VICTIM_EMAIL,
            first_name="Attacker", last_name="Attacker", device_name="iPhone", platform="ios",
        )
    assert exc_info.value.status_code == 400

    # Confirm the victim's account was never touched/linked to the attacker.
    victim = service.users.get_by_email(VICTIM_EMAIL)
    assert victim.apple_sub is None


def test_returning_user_without_email_claim_resolves_via_apple_sub(service, monkeypatch):
    # First login: real email claim present, links apple_sub to the account.
    _mock_apple_token(monkeypatch, {
        "sub": VICTIM_APPLE_SUB, "email": VICTIM_EMAIL, "email_verified": "true",
    })
    service.social_login(
        provider="apple", id_token="first-login", email=None,
        first_name="Real", last_name="User", device_name="iPhone", platform="ios",
    )
    first_user_id = service.users.get_by_email(VICTIM_EMAIL).id

    # Second login: Apple omits the email claim this time (routine), and the
    # request body has NO email at all (native client just replays the
    # stored apple_sub-linked session) — must still resolve to the same user.
    _mock_apple_token(monkeypatch, {"sub": VICTIM_APPLE_SUB})
    result = service.social_login(
        provider="apple", id_token="second-login", email=None,
        first_name=None, last_name=None, device_name="iPhone", platform="ios",
    )
    assert result.refresh_token

    # No duplicate account was created.
    assert service.users.get_by_email(VICTIM_EMAIL).id == first_user_id


def test_first_login_without_email_claim_and_no_prior_mapping_is_rejected(service, monkeypatch):
    _mock_apple_token(monkeypatch, {"sub": "brand-new-sub"})

    with pytest.raises(HTTPException) as exc_info:
        service.social_login(
            provider="apple", id_token="brand-new", email=None,
            first_name="New", last_name="User", device_name="iPhone", platform="ios",
        )
    assert exc_info.value.status_code == 400


def test_google_social_login_unaffected(service, monkeypatch):
    """Full regression check: the Apple-specific fix must not touch Google's
    social-login path at all."""
    monkeypatch.setattr("app.services.auth_service.settings.google_oauth_client_ids", "test-client-id")
    monkeypatch.setattr(
        "app.services.auth_service.google_id_token.verify_oauth2_token",
        lambda *args, **kwargs: {
            "email": "googleuser@example.com",
            "email_verified": True,
            "given_name": "Google",
            "family_name": "User",
        },
    )
    result = service.social_login(
        provider="google", id_token="whatever", email=None,
        first_name=None, last_name=None, device_name="Pixel", platform="android",
    )
    assert result.refresh_token
    user = service.users.get_by_email("googleuser@example.com")
    assert user is not None
    assert user.apple_sub is None
