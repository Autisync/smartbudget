from datetime import UTC, datetime

from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from app.models.auth_session import AuthSession


class SessionRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_session(
        self,
        *,
        user_id: str,
        token_hash: str,
        device_name: str | None,
        platform: str | None,
        expires_at: datetime,
    ) -> AuthSession:
        auth_session = AuthSession(
            user_id=user_id,
            token_hash=token_hash,
            device_name=device_name,
            platform=platform,
            expires_at=expires_at,
            revoked_at=None,
        )
        self.db.add(auth_session)
        self.db.commit()
        self.db.refresh(auth_session)
        return auth_session

    def get_active_by_token_hash(self, token_hash: str) -> AuthSession | None:
        return self.db.scalar(
            select(AuthSession).where(
                and_(
                    AuthSession.token_hash == token_hash,
                    AuthSession.revoked_at.is_(None),
                    AuthSession.expires_at > datetime.now(UTC),
                )
            )
        )

    def revoke_by_token_hash(self, token_hash: str) -> None:
        auth_session = self.db.scalar(select(AuthSession).where(AuthSession.token_hash == token_hash))
        if auth_session is None:
            return
        auth_session.revoked_at = datetime.now(UTC)
        self.db.add(auth_session)
        self.db.commit()
