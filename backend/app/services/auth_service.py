import logging
from datetime import datetime, timezone
from uuid import uuid4

import jwt
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
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
    verify_password_constant_time,
)
from app.models.finance import AuditLog
from app.repositories.session_repository import SessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import AuthResponse
from app.tasks.email import (
    send_duplicate_signup_alert_email_task,
    send_login_alert_email_task,
    send_password_reset_email_task,
    send_verification_email_task,
    send_welcome_email_task,
)

logger = logging.getLogger(__name__)


def _safe_delay(task, **kwargs) -> None:
    """Enqueue a Celery email task without letting a broker/transport outage
    break the calling auth flow. Transactional email is best-effort by design —
    a down broker must never turn signup/login/resend into a 500."""
    try:
        task.delay(**kwargs)
    except Exception:
        logger.exception(
            "Failed to enqueue %s; continuing without sending email", task.name
        )


class AuthService:
    _apple_jwk_client = jwt.PyJWKClient("https://appleid.apple.com/auth/keys")

    def __init__(self, db: Session):
        self.db = db
        self.users = UserRepository(db)
        self.sessions = SessionRepository(db)

    def _audit(
        self,
        *,
        action: str,
        actor_user_id=None,
        resource_id: str | None = None,
        ip_address: str | None = None,
        metadata: dict | None = None,
    ) -> None:
        """L-2 fix: audit_logs previously only ever got a row from
        transaction create/delete — every authentication event (login,
        failed login, logout, signup, password reset, email verification)
        went completely unlogged, despite that being exactly the kind of
        sensitive-action trail this table exists for. Joins the caller's
        existing transaction rather than committing separately, so a crash
        between the audit write and the real commit can't leave one without
        the other."""
        self.db.add(
            AuditLog(
                actor_user_id=actor_user_id,
                action=action,
                resource_type="auth",
                resource_id=resource_id,
                ip_address=ip_address,
                metadata_json=metadata or {},
            )
        )

    def signup(
        self,
        *,
        email: str,
        password: str,
        first_name: str,
        last_name: str,
        device_name: str | None,
        platform: str | None,
        request_ip: str | None = None,
    ):
        existing = self.users.get_by_email(email)
        if existing:
            # Account-enumeration fix: never reveal whether the email is
            # registered. The response to the caller is identical to the
            # success path up to the point where we'd return tokens — but we
            # return an error with a *generic* message so the caller cannot
            # distinguish "email already in use" from "invalid request".
            #
            # H-2: also pay the same Argon2 cost the "new account" branch
            # below pays via hash_password() — otherwise this branch returns
            # measurably faster, and response *timing* re-reveals exactly
            # what the identical response *body* was designed to hide.
            hash_password(password)
            #
            # We do notify the legitimate owner out-of-band (async, no latency)
            # so they know the attempt happened and can act if it wasn't them.
            attempt_time = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
            _safe_delay(send_duplicate_signup_alert_email_task,
                email=existing.email,
                user_name=existing.first_name,
                attempt_time=attempt_time,
            )
            self._audit(
                action="auth.signup_duplicate_attempt",
                actor_user_id=existing.id,
                ip_address=request_ip,
                metadata={"email": email.lower().strip()},
            )
            self.db.commit()
            raise errors.bad_request("Unable to create account with the provided details")

        user = self.users.create(
            email=email,
            password_hash=hash_password(password),
            first_name=first_name,
            last_name=last_name,
        )
        self._audit(
            action="auth.signup", actor_user_id=user.id, ip_address=request_ip,
        )
        self.db.commit()

        verification_token = create_short_lived_token(
            subject=str(user.id),
            token_type="verify_email",
            ttl_seconds=settings.verify_email_ttl_seconds,
        )
        # Fire-and-forget via Celery — never blocks the signup response.
        _safe_delay(send_verification_email_task,
            email=user.email, token=verification_token, user_name=user.first_name
        )
        return self._issue_tokens(user_id=str(user.id), device_name=device_name, platform=platform, user=user)

    def login(
        self,
        *,
        email: str,
        password: str,
        device_name: str | None,
        platform: str | None,
        request_ip: str | None = None,
    ):
        user = self.users.get_by_email(email)
        # H-2: always pay the same Argon2 verify cost, whether or not the
        # account exists — `user and verify_password(...)` would short-circuit
        # and skip the (deliberately expensive) hash check entirely for a
        # nonexistent account, making that case measurably faster and leaking
        # account existence via timing despite the identical error message.
        password_hash = user.password_hash if user else None
        if not verify_password_constant_time(password, password_hash):
            self._audit(
                action="auth.login_failed",
                actor_user_id=user.id if user else None,
                ip_address=request_ip,
                metadata={"email": email.lower().strip()},
            )
            self.db.commit()
            raise errors.unauthorized("Invalid email or password")
        if not user.is_active:
            self._audit(
                action="auth.login_failed", actor_user_id=user.id, ip_address=request_ip,
                metadata={"reason": "inactive_user"},
            )
            self.db.commit()
            raise errors.forbidden("User is inactive")

        self._audit(action="auth.login_success", actor_user_id=user.id, ip_address=request_ip)
        self.db.commit()

        auth_response = self._issue_tokens(
            user_id=str(user.id),
            device_name=device_name,
            platform=platform,
            user=user,
        )

        login_device = device_name or platform or "Unknown device"
        login_location = request_ip or "Unknown location"
        login_time = datetime.now(timezone.utc).isoformat()
        # M-1 FIX: Use HTTPS App Link instead of custom scheme (not hijackable).
        _safe_delay(send_login_alert_email_task,
            email=user.email,
            user_name=user.first_name,
            action_url="https://smaartspend.com/app/security",
            device=login_device,
            location=login_location,
            login_time=login_time,
        )

        return auth_response

    def social_login(
        self,
        *,
        provider: str,
        id_token: str,
        email: str | None,
        first_name: str | None,
        last_name: str | None,
        device_name: str | None,
        platform: str | None,
        request_ip: str | None = None,
    ):
        profile = self._verify_social_token(
            provider=provider,
            id_token=id_token,
            fallback_email=email,
            fallback_first_name=first_name,
            fallback_last_name=last_name,
        )
        resolved_email = profile["email"]
        apple_sub = profile.get("apple_sub")

        # Apple's `sub` claim is cryptographically verified by the token
        # signature — resolve by it first so a returning user is recognized
        # correctly even on a later login where Apple omits the `email` claim.
        user = self.users.get_by_apple_sub(apple_sub) if apple_sub else None
        if user is None:
            user = self.users.get_by_email(resolved_email)
        if user is None:
            generated_password = f"{uuid4().hex}A1a!"
            user = self.users.create(
                email=resolved_email,
                password_hash=hash_password(generated_password),
                first_name=profile["first_name"],
                last_name=profile["last_name"],
                apple_sub=apple_sub,
            )
        elif apple_sub:
            # Existing account (password or Google) signing in with Apple for
            # the first time — link it so future Apple logins without an
            # email claim resolve back to this same account.
            user = self.users.link_apple_sub(user, apple_sub)

        if not user.is_active:
            self._audit(
                action="auth.login_failed", actor_user_id=user.id, ip_address=request_ip,
                metadata={"reason": "inactive_user", "provider": provider},
            )
            self.db.commit()
            raise errors.forbidden("User is inactive")

        if profile["email_verified"] and not user.is_verified:
            user.is_verified = True
            self.db.add(user)
            self.db.commit()
            self.db.refresh(user)

        self._audit(
            action="auth.login_success", actor_user_id=user.id, ip_address=request_ip,
            metadata={"provider": provider},
        )
        self.db.commit()

        auth_response = self._issue_tokens(
            user_id=str(user.id),
            device_name=device_name,
            platform=platform,
            user=user,
        )

        login_device = device_name or platform or "Unknown device"
        login_location = request_ip or "Unknown location"
        login_time = datetime.now(timezone.utc).isoformat()
        _safe_delay(send_login_alert_email_task,
            email=user.email,
            user_name=user.first_name,
            action_url="https://smaartspend.com/app/security",
            device=login_device,
            location=login_location,
            login_time=login_time,
        )

        return auth_response

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

    def logout(self, *, refresh_token: str, request_ip: str | None = None):
        token_hash = hash_token(refresh_token)
        revoked_session = self.sessions.revoke_by_token_hash(token_hash)
        if revoked_session is not None:
            self._audit(
                action="auth.logout",
                actor_user_id=revoked_session.user_id,
                ip_address=request_ip,
            )
            self.db.commit()

    def resend_verification(self, *, user) -> None:
        """Re-issues an email-verification link to the given user. Idempotent and
        leak-free: already-verified users are a no-op."""
        if user is None or user.is_verified:
            return
        verification_token = create_short_lived_token(
            subject=str(user.id),
            token_type="verify_email",
            ttl_seconds=settings.verify_email_ttl_seconds,
        )
        _safe_delay(send_verification_email_task,
            email=user.email,
            token=verification_token,
            user_name=user.first_name,
        )

    def update_profile(self, *, user, first_name: str | None, last_name: str | None):
        return self.users.update_profile(
            user, first_name=first_name, last_name=last_name
        )

    def forgot_password(self, *, email: str, request_ip: str | None = None) -> None:
        user = self.users.get_by_email(email)
        if user is None:
            return
        token = create_short_lived_token(
            subject=str(user.id), token_type="reset_password", ttl_seconds=settings.password_reset_ttl_seconds
        )
        _safe_delay(send_password_reset_email_task,
            email=user.email, token=token, user_name=user.first_name
        )
        self._audit(action="auth.password_reset_requested", actor_user_id=user.id, ip_address=request_ip)
        self.db.commit()

    def reset_password(self, *, token_payload: dict, new_password: str, request_ip: str | None = None) -> None:
        user = self.users.get_by_id(token_payload["sub"])
        if user is None:
            raise errors.bad_request("Invalid reset token")

        user.password_hash = hash_password(new_password)
        self.db.add(user)
        self.sessions.revoke_all_for_user(str(user.id))
        self._audit(
            action="auth.password_reset_completed", actor_user_id=user.id, ip_address=request_ip,
            metadata={"sessions_revoked": True},
        )
        self.db.commit()

    def verify_email(self, *, token_payload: dict, request_ip: str | None = None) -> None:
        user = self.users.get_by_id(token_payload["sub"])
        if user is None:
            raise errors.bad_request("Invalid verification token")
        user.is_verified = True
        self.db.add(user)
        self._audit(action="auth.email_verified", actor_user_id=user.id, ip_address=request_ip)
        self.db.commit()

        _safe_delay(send_welcome_email_task,
            email=user.email,
            user_name=user.first_name,
            action_url="https://smaartspend.com/app/dashboard",
        )

    def _verify_social_token(
        self,
        *,
        provider: str,
        id_token: str,
        fallback_email: str | None,
        fallback_first_name: str | None,
        fallback_last_name: str | None,
    ) -> dict:
        if provider == "google":
            return self._verify_google_token(
                id_token=id_token,
                fallback_first_name=fallback_first_name,
                fallback_last_name=fallback_last_name,
            )

        if provider == "apple":
            return self._verify_apple_token(
                id_token=id_token,
                fallback_email=fallback_email,
                fallback_first_name=fallback_first_name,
                fallback_last_name=fallback_last_name,
            )

        raise errors.bad_request("Unsupported social provider")

    def _verify_google_token(
        self,
        *,
        id_token: str,
        fallback_first_name: str | None,
        fallback_last_name: str | None,
    ) -> dict:
        audiences = settings.google_oauth_client_id_list()
        if not audiences:
            raise errors.bad_request("Google sign-in is not configured")

        payload: dict | None = None
        request_adapter = google_requests.Request()
        for audience in audiences:
            try:
                payload = google_id_token.verify_oauth2_token(
                    id_token,
                    request_adapter,
                    audience=audience,
                )
                break
            except Exception:
                continue

        if payload is None:
            raise errors.unauthorized("Invalid Google identity token")

        email = payload.get("email")
        if not isinstance(email, str) or not email:
            raise errors.bad_request("Google account does not expose an email")

        email_verified = bool(payload.get("email_verified", False))
        first_name = payload.get("given_name") or fallback_first_name or "Smart"
        last_name = payload.get("family_name") or fallback_last_name or "User"

        return {
            "email": email.lower().strip(),
            "email_verified": email_verified,
            "first_name": first_name.strip()[:120],
            "last_name": last_name.strip()[:120],
            "apple_sub": None,
        }

    def _verify_apple_token(
        self,
        *,
        id_token: str,
        fallback_email: str | None,
        fallback_first_name: str | None,
        fallback_last_name: str | None,
    ) -> dict:
        audiences = settings.apple_oauth_audience_list()
        if not audiences:
            raise errors.bad_request("Apple sign-in is not configured")

        try:
            signing_key = self._apple_jwk_client.get_signing_key_from_jwt(id_token)
            payload = jwt.decode(
                id_token,
                signing_key.key,
                algorithms=["RS256"],
                audience=audiences,
                issuer="https://appleid.apple.com",
            )
        except Exception:
            raise errors.unauthorized("Invalid Apple identity token")

        apple_sub = payload.get("sub")
        if not isinstance(apple_sub, str) or not apple_sub:
            raise errors.unauthorized("Apple identity token is missing its subject claim")

        # H-1 fix: never trust a client-supplied email as an identity
        # fallback. `fallback_email` comes straight from the request body and
        # is fully attacker-controlled — using it here to resolve an existing
        # account by email previously allowed logging into *any* account
        # whose email an attacker guessed, with no password check, using
        # nothing but the attacker's own valid Apple identity token. When
        # Apple omits the `email` claim (routine on a returning user's later
        # logins), resolve the user via the token's cryptographically
        # verified `sub` claim instead — never via client-supplied data.
        claim_email = payload.get("email")
        if isinstance(claim_email, str) and claim_email:
            email = claim_email
        else:
            existing = self.users.get_by_apple_sub(apple_sub)
            if existing is None:
                raise errors.bad_request(
                    "Apple did not share an email for this sign-in and no account "
                    "is linked yet. Please try Apple sign-in again with email "
                    "sharing enabled, or sign in with email and password."
                )
            email = existing.email

        email_verified_value = payload.get("email_verified", False)
        if isinstance(email_verified_value, str):
            email_verified = email_verified_value.lower() == "true"
        else:
            email_verified = bool(email_verified_value)

        first_name = fallback_first_name or "Smart"
        last_name = fallback_last_name or "User"

        return {
            "email": email.lower().strip(),
            "email_verified": email_verified,
            "first_name": first_name.strip()[:120],
            "last_name": last_name.strip()[:120],
            "apple_sub": apple_sub,
        }

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
