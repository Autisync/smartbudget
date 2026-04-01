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

    def create(self, *, email: str, password_hash: str, first_name: str, last_name: str) -> User:
        user = User(
            email=email.lower().strip(),
            password_hash=password_hash,
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            is_active=True,
            is_verified=False,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
