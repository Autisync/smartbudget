from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_email(self, email: str) -> User | None:
        return self.db.scalar(select(User).where(User.email == email.lower().strip()))

    def get_by_id(self, user_id: str) -> User | None:
        return self.db.get(User, user_id)

    def get_by_apple_sub(self, apple_sub: str) -> User | None:
        return self.db.scalar(select(User).where(User.apple_sub == apple_sub))

    def create(
        self,
        *,
        email: str,
        password_hash: str,
        first_name: str,
        last_name: str,
        apple_sub: str | None = None,
    ) -> User:
        user = User(
            email=email.lower().strip(),
            password_hash=password_hash,
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            is_active=True,
            is_verified=False,
            apple_sub=apple_sub,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def link_apple_sub(self, user: User, apple_sub: str) -> User:
        """Records Apple's stable per-user identifier on an existing account —
        e.g. an existing password/Google account signing in with Apple for the
        first time. Safe to call repeatedly with the same value (idempotent)."""
        if user.apple_sub != apple_sub:
            user.apple_sub = apple_sub
            self.db.add(user)
            self.db.commit()
            self.db.refresh(user)
        return user

    def update_profile(
        self,
        user: User,
        *,
        first_name: str | None = None,
        last_name: str | None = None,
    ) -> User:
        if first_name is not None:
            user.first_name = first_name.strip()
        if last_name is not None:
            user.last_name = last_name.strip()
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
