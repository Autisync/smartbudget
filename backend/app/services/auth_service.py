from sqlalchemy.orm import Session

from app.core import errors
from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    create_short_lived_token,
    decode_refresh_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.repositories.session_repository import SessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import AuthResponse
from app.services.email_service import EmailService


class AuthService:
    def __init__(self, db: Session):
        self.db = db
        self.users = UserRepository(db)
        self.sessions = SessionRepository(db)
        self.email = EmailService()

    def signup(self, *, email: str, password: str, first_name: str, last_name: str, device_name: str | None, platform: str | None):
        if self.users.get_by_email(email):
            raise errors.bad_request("Account already exists")

        user = self.users.create(
            email=email,
            password_hash=hash_password(password),
            first_name=first_name,
            last_name=last_name,
        )

        verification_token = create_short_lived_token(
            subject=str(user.id),
            token_type="verify_email",
            ttl_seconds=settings.verify_email_ttl_seconds,
        )
        self.email.send_verification_email(email=user.email, token=verification_token)
        return self._issue_tokens(user_id=str(user.id), device_name=device_name, platform=platform, user=user)

    def login(self, *, email: str, password: str, device_name: str | None, platform: str | None):
        user = self.users.get_by_email(email)
        if not user or not verify_password(password, user.password_hash):
            raise errors.unauthorized("Invalid email or password")
        if not user.is_active:
            raise errors.forbidden("User is inactive")

        return self._issue_tokens(user_id=str(user.id), device_name=device_name, platform=platform, user=user)

    def refresh(self, *, refresh_token: str):
        payload = decode_refresh_token(refresh_token)
        token_hash = hash_token(refresh_token)
        current_session = self.sessions.get_active_by_token_hash(token_hash)
        if current_session is None:
            raise errors.unauthorized("Session expired")

        user = self.users.get_by_id(payload["sub"])
        if user is None or not user.is_active:
            raise errors.unauthorized("Invalid session")

        # Rotation: revoke old refresh token and issue a new one.
        self.sessions.revoke_by_token_hash(token_hash)
        return self._issue_tokens(
            user_id=str(user.id),
            device_name=current_session.device_name,
            platform=current_session.platform,
            user=user,
        )

    def logout(self, *, refresh_token: str):
        token_hash = hash_token(refresh_token)
        self.sessions.revoke_by_token_hash(token_hash)

    def forgot_password(self, *, email: str) -> None:
        user = self.users.get_by_email(email)
        if user is None:
            return
        token = create_short_lived_token(
            subject=str(user.id), token_type="reset_password", ttl_seconds=settings.password_reset_ttl_seconds
        )
        self.email.send_password_reset_email(email=user.email, token=token)

    def reset_password(self, *, token_payload: dict, new_password: str) -> None:
        user = self.users.get_by_id(token_payload["sub"])
        if user is None:
            raise errors.bad_request("Invalid reset token")

        user.password_hash = hash_password(new_password)
        self.db.add(user)
        self.db.commit()

    def verify_email(self, *, token_payload: dict) -> None:
        user = self.users.get_by_id(token_payload["sub"])
        if user is None:
            raise errors.bad_request("Invalid verification token")
        user.is_verified = True
        self.db.add(user)
        self.db.commit()

    def _issue_tokens(self, *, user_id: str, device_name: str | None, platform: str | None, user):
        access_token, access_expires_in = create_access_token(user_id)
        refresh_token, refresh_expires_at = create_refresh_token(user_id)
        self.sessions.create_session(
            user_id=user_id,
            token_hash=hash_token(refresh_token),
            device_name=device_name,
            platform=platform,
            expires_at=refresh_expires_at,
        )

        return AuthResponse(
            user=user,
            access_token=access_token,
            refresh_token=refresh_token,
            access_token_expires_in=access_expires_in,
        )
