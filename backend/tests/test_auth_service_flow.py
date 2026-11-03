from datetime import UTC, datetime
from types import SimpleNamespace
from uuid import uuid4

import pytest
from fastapi import HTTPException

from app.core.security import (
    create_short_lived_token,
    decode_refresh_token,
    decode_token,
    hash_token,
    verify_password,
)
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
        self._by_id: dict[str, SimpleNamespace] = {}

    def get_by_email(self, email: str):
        return self._by_email.get(email.lower().strip())

    def get_by_id(self, user_id: str):
        return self._by_id.get(str(user_id))

    def create(self, *, email: str, password_hash: str, first_name: str, last_name: str):
        user = SimpleNamespace(
            id=uuid4(),
            email=email.lower().strip(),
            password_hash=password_hash,
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            is_active=True,
            is_verified=False,
        )
        self._by_email[user.email] = user
        self._by_id[str(user.id)] = user
        return user

    def delete(self, user) -> None:
        self._by_email.pop(user.email, None)
        self._by_id.pop(str(user.id), None)

    def update_profile(self, user, *, first_name=None, last_name=None):
        if first_name is not None:
            user.first_name = first_name.strip()
        if last_name is not None:
            user.last_name = last_name.strip()
        return user


class _InMemorySessionRepository:
    def __init__(self):
        self._by_hash: dict[str, SimpleNamespace] = {}

    def create_session(
        self,
        *,
        user_id: str,
        token_hash: str,
        device_name: str | None,
        platform: str | None,
        expires_at: datetime,
    ):
        session = SimpleNamespace(
            user_id=str(user_id),
            token_hash=token_hash,
            device_name=device_name,
            platform=platform,
            expires_at=expires_at,
            revoked_at=None,
        )
        self._by_hash[token_hash] = session
        return session

    def get_active_by_token_hash(self, token_hash: str):
        session = self._by_hash.get(token_hash)
        if session is None:
            return None
        if session.revoked_at is not None:
            return None
        if session.expires_at <= datetime.now(UTC):
            return None
        return session

    def revoke_by_token_hash(self, token_hash: str) -> None:
        session = self._by_hash.get(token_hash)
        if session is not None and session.revoked_at is None:
            session.revoked_at = datetime.now(UTC)

    def revoke_all_for_user(self, user_id: str) -> None:
        now = datetime.now(UTC)
        for session in self._by_hash.values():
            if session.user_id == str(user_id) and session.revoked_at is None:
                session.revoked_at = now


@pytest.fixture
def auth_service(monkeypatch) -> tuple[AuthService, _InMemoryUserRepository, _InMemorySessionRepository]:
    service = AuthService(_DummyDb())
    users = _InMemoryUserRepository()
    sessions = _InMemorySessionRepository()

    service.users = users
    service.sessions = sessions

    # Keep tests deterministic and independent of broker availability.
    monkeypatch.setattr("app.services.auth_service._safe_delay", lambda *_args, **_kwargs: None)

    return service, users, sessions


def test_signup_login_refresh_logout_token_lifecycle(auth_service):
    service, _users, sessions = auth_service

    signup = service.signup(
        email="person@example.com",
        password="StrongPass123",
        first_name="Person",
        last_name="One",
        device_name="Pixel",
        platform="android",
    )

    first_refresh = signup.refresh_token
    assert decode_refresh_token(first_refresh)["type"] == "refresh"

    refreshed = service.refresh(refresh_token=first_refresh)
    second_refresh = refreshed.refresh_token

    assert second_refresh != first_refresh
    assert sessions._by_hash[hash_token(first_refresh)].revoked_at is not None
    assert sessions.get_active_by_token_hash(hash_token(second_refresh)) is not None

    service.logout(refresh_token=second_refresh)
    assert sessions._by_hash[hash_token(second_refresh)].revoked_at is not None


def test_login_rejects_invalid_password(auth_service):
    service, _users, _sessions = auth_service

    service.signup(
        email="person@example.com",
        password="StrongPass123",
        first_name="Person",
        last_name="One",
        device_name="Pixel",
        platform="android",
    )

    with pytest.raises(HTTPException) as exc:
        service.login(
            email="person@example.com",
            password="WrongPass123",
            device_name="Pixel",
            platform="android",
            request_ip="127.0.0.1",
        )

    assert exc.value.status_code == 401


def test_reset_password_updates_hash_and_revokes_sessions(auth_service):
    service, users, sessions = auth_service

    signup = service.signup(
        email="person@example.com",
        password="StrongPass123",
        first_name="Person",
        last_name="One",
        device_name="Pixel",
        platform="android",
    )

    user = users.get_by_email("person@example.com")
    old_hash = user.password_hash

    reset_token = create_short_lived_token(
        subject=str(user.id), token_type="reset_password", ttl_seconds=300
    )
    token_payload = decode_token(reset_token)

    service.reset_password(token_payload=token_payload, new_password="NewStrong123")

    assert user.password_hash != old_hash
    assert verify_password("NewStrong123", user.password_hash)
    assert sessions._by_hash[hash_token(signup.refresh_token)].revoked_at is not None


def test_verify_email_marks_user_verified(auth_service):
    service, users, _sessions = auth_service

    service.signup(
        email="person@example.com",
        password="StrongPass123",
        first_name="Person",
        last_name="One",
        device_name="Pixel",
        platform="android",
    )

    user = users.get_by_email("person@example.com")
    assert user.is_verified is False

    verify_token = create_short_lived_token(
        subject=str(user.id), token_type="verify_email", ttl_seconds=300
    )
    service.verify_email(token_payload=decode_token(verify_token))

    assert user.is_verified is True


def test_delete_account_removes_the_user_revokes_sessions_and_confirms(auth_service, monkeypatch):
    service, users, sessions = auth_service
    sent = []
    monkeypatch.setattr(
        "app.services.auth_service._safe_delay",
        lambda task, **kwargs: sent.append((task.name, kwargs)),
    )

    signup = service.signup(
        email="leaving@example.com",
        password="StrongPass123",
        first_name="Lee",
        last_name="Ving",
        device_name="Pixel",
        platform="android",
    )
    user = users.get_by_email("leaving@example.com")
    assert user is not None
    sent.clear()

    service.delete_account(user=user)

    assert users.get_by_email("leaving@example.com") is None
    assert users.get_by_id(str(user.id)) is None
    assert sessions.get_active_by_token_hash(hash_token(signup.refresh_token)) is None
    assert len(sent) == 1
    name, kwargs = sent[0]
    assert name == "app.tasks.email.send_notification_email"
    assert kwargs["email"] == "leaving@example.com"
    assert "deleted" in kwargs["notification_title"].lower()


def test_delete_account_request_needs_the_word_delete():
    from pydantic import ValidationError

    from app.schemas.auth import DeleteAccountRequest

    assert DeleteAccountRequest(confirm="DELETE").confirm == "DELETE"
    for bad in ({}, {"confirm": "delete"}, {"confirm": "yes"}):
        with pytest.raises(ValidationError):
            DeleteAccountRequest(**bad)
