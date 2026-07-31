"""Regression cover for L-5: auth_sessions rows were never cleaned up —
every login/refresh creates one, and expired/revoked rows accumulated
indefinitely with no retention policy.
"""

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.core.security import hash_password, hash_token
from app.models.auth_session import AuthSession
from app.models.user import User
from app.tasks.maintenance import REVOKED_SESSION_RETENTION_DAYS, cleanup_expired_sessions


def _make_user(db) -> User:
    u = User(
        id=uuid.uuid4(), email=f"cleanup-{uuid.uuid4().hex}@example.com",
        password_hash=hash_password("StrongPass123"),
        first_name="Cleanup", last_name="User", is_active=True, is_verified=True,
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


def _make_session(db, user_id, *, expires_at, revoked_at=None) -> AuthSession:
    s = AuthSession(
        id=uuid.uuid4(), user_id=user_id, token_hash=hash_token(uuid.uuid4().hex),
        device_name="dev", platform="ios", expires_at=expires_at, revoked_at=revoked_at,
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def _still_exists(db, session_id) -> bool:
    """A fresh, uncached lookup — cleanup_expired_sessions() runs in its own
    SessionLocal(), a different session/connection than the test's `real_db`.
    `db.get(...)` can raise ObjectDeletedError trying to refresh a
    identity-mapped instance whose row another session already deleted; a
    plain SELECT avoids that entirely and just reflects what's really there."""
    db.expire_all()
    return db.execute(select(AuthSession).where(AuthSession.id == session_id)).first() is not None


def test_expired_session_is_deleted(real_db):
    user = _make_user(real_db)
    expired = _make_session(real_db, user.id, expires_at=datetime.now(UTC) - timedelta(days=1))

    cleanup_expired_sessions()

    assert not _still_exists(real_db, expired.id)


def test_active_session_survives_cleanup(real_db):
    user = _make_user(real_db)
    active = _make_session(real_db, user.id, expires_at=datetime.now(UTC) + timedelta(days=30))

    cleanup_expired_sessions()

    assert _still_exists(real_db, active.id)


def test_recently_revoked_session_survives_within_retention_window(real_db):
    user = _make_user(real_db)
    recently_revoked = _make_session(
        real_db, user.id,
        expires_at=datetime.now(UTC) + timedelta(days=30),  # not expired
        revoked_at=datetime.now(UTC) - timedelta(days=1),  # revoked yesterday
    )

    cleanup_expired_sessions()

    assert _still_exists(real_db, recently_revoked.id)


def test_long_revoked_session_beyond_retention_window_is_deleted(real_db):
    user = _make_user(real_db)
    old_revoked = _make_session(
        real_db, user.id,
        expires_at=datetime.now(UTC) + timedelta(days=30),  # not expired
        revoked_at=datetime.now(UTC) - timedelta(days=REVOKED_SESSION_RETENTION_DAYS + 5),
    )

    cleanup_expired_sessions()

    assert not _still_exists(real_db, old_revoked.id)


def test_mixed_seed_only_deletes_the_correct_rows(real_db):
    """The core scenario: expired, active, and revoked sessions coexist for
    the same user — cleanup must only remove the ones that should go.

    Captures each row's id as a plain UUID value immediately — each
    subsequent _make_session() call's commit() re-expires every previously
    loaded ORM object's attributes (SQLAlchemy's expire_on_commit default),
    and re-reading .id on an already-deleted row later raises
    ObjectDeletedError. Plain UUID values sidestep that entirely."""
    user = _make_user(real_db)
    expired_id = _make_session(real_db, user.id, expires_at=datetime.now(UTC) - timedelta(hours=1)).id
    active_id = _make_session(real_db, user.id, expires_at=datetime.now(UTC) + timedelta(days=10)).id
    old_revoked_id = _make_session(
        real_db, user.id, expires_at=datetime.now(UTC) + timedelta(days=10),
        revoked_at=datetime.now(UTC) - timedelta(days=90),
    ).id

    result = cleanup_expired_sessions()

    assert not _still_exists(real_db, expired_id)
    assert _still_exists(real_db, active_id)
    assert not _still_exists(real_db, old_revoked_id)
    assert result["deleted"] >= 2


def test_active_session_still_authenticates_immediately_after_cleanup(real_db):
    """The feature-level guarantee: cleanup running must never break a real,
    currently-valid session — refresh/logout must keep working on it."""
    from app.repositories.session_repository import SessionRepository

    user = _make_user(real_db)
    raw_token = uuid.uuid4().hex
    sessions_repo = SessionRepository(real_db)
    sessions_repo.create_session(
        user_id=str(user.id), token_hash=hash_token(raw_token),
        device_name="dev", platform="ios", expires_at=datetime.now(UTC) + timedelta(days=30),
    )

    # Seed some noise that SHOULD be cleaned up alongside the real session.
    _make_session(real_db, user.id, expires_at=datetime.now(UTC) - timedelta(days=1))

    cleanup_expired_sessions()

    active = sessions_repo.get_active_by_token_hash(hash_token(raw_token))
    assert active is not None
    assert active.user_id == user.id
