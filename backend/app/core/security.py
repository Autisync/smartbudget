import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

from app.core.config import settings

password_hasher = PasswordHasher()

# H-2 fix: a precomputed hash used to pay Argon2's real, deliberately-expensive
# cost even when there's no real password hash to check against (e.g. the
# account doesn't exist). Without this, "no such account" and "wrong password"
# take measurably different response times, defeating the account-enumeration
# protection elsewhere in this codebase — identical response *bodies* aren't
# enough on their own if the *timing* still leaks which case occurred.
_DUMMY_PASSWORD_HASH = password_hasher.hash(secrets.token_urlsafe(32))


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return password_hasher.verify(password_hash, password)
    except VerifyMismatchError:
        return False


def verify_password_constant_time(password: str, password_hash: str | None) -> bool:
    """Same as verify_password, but always costs one real Argon2 verify even
    when `password_hash` is None — pass None for "no such account" instead of
    short-circuiting before calling this at all."""
    matched = verify_password(password, password_hash if password_hash is not None else _DUMMY_PASSWORD_HASH)
    return matched if password_hash is not None else False


def create_access_token(user_id: str) -> tuple[str, int]:
    expires_in = settings.access_token_ttl_seconds
    expires_at = datetime.now(UTC) + timedelta(seconds=expires_in)
    payload = {
        "sub": user_id,
        "jti": str(uuid4()),
        "exp": expires_at,
        "iat": datetime.now(UTC),
        "type": "access",
    }
    token = jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)
    return token, expires_in


def create_refresh_token(user_id: str) -> tuple[str, datetime]:
    expires_at = datetime.now(UTC) + timedelta(seconds=settings.refresh_token_ttl_seconds)
    payload = {
        "sub": user_id,
        "jti": str(uuid4()),
        "exp": expires_at,
        "iat": datetime.now(UTC),
        "type": "refresh",
    }
    token = jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)
    return token, expires_at


def create_short_lived_token(subject: str, token_type: str, ttl_seconds: int) -> str:
    payload = {
        "sub": subject,
        "jti": str(uuid4()),
        "exp": datetime.now(UTC) + timedelta(seconds=ttl_seconds),
        "iat": datetime.now(UTC),
        "type": token_type,
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])


def decode_access_token(token: str) -> dict:
    payload = decode_token(token)
    if payload.get("type") != "access":
        raise jwt.InvalidTokenError("Token type is not access")
    return payload


def decode_refresh_token(token: str) -> dict:
    payload = decode_token(token)
    if payload.get("type") != "refresh":
        raise jwt.InvalidTokenError("Token type is not refresh")
    return payload


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def generate_random_token() -> str:
    return secrets.token_urlsafe(48)
