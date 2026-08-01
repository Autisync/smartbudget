from collections.abc import Generator

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.repositories.user_repository import UserRepository

bearer_scheme = HTTPBearer(auto_error=False)


def db_session() -> Generator[Session, None, None]:
    yield from get_db()


def current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(db_session),
):
    if credentials is None:
        return None

    try:
        payload = decode_access_token(credentials.credentials)
    except jwt.PyJWTError:
        return None

    user_id = payload.get("sub")
    if not user_id:
        return None

    user = UserRepository(db).get_by_id(user_id)
    # Re-audit fix: a deactivated account (e.g. banned for fraud, or a user
    # who deleted their account) previously kept full API access on any
    # access token issued before deactivation, until that token's normal TTL
    # expiry — login/social_login/refresh already reject inactive users
    # (auth_service.py), so the same check belongs here too, not just at the
    # token-issuance boundary.
    if user is not None and not user.is_active:
        return None

    return user
