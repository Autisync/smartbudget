import jwt
from fastapi import APIRouter, Depends, Request
from redis import Redis
from sqlalchemy.orm import Session

from app.api.deps import current_user, db_session
from app.core import errors
from app.core.config import settings
from app.core.security import decode_token
from app.schemas.auth import (
    AuthResponse,
    AuthUserOut,
    ForgotPasswordRequest,
    LoginRequest,
    LogoutRequest,
    MessageResponse,
    RefreshRequest,
    ResetPasswordRequest,
    SocialLoginRequest,
    SignupRequest,
    UpdateProfileRequest,
    VerifyEmailRequest,
)
from app.services.auth_service import AuthService
from app.services.rate_limiter import RateLimiterService

router = APIRouter()


def limiter() -> RateLimiterService:
    redis_client = Redis.from_url(settings.redis_url, decode_responses=True)
    return RateLimiterService(redis_client)


@router.post("/signup", response_model=AuthResponse)
def signup(payload: SignupRequest, db: Session = Depends(db_session)):
    service = AuthService(db)
    return service.signup(
        email=payload.email,
        password=payload.password,
        first_name=payload.first_name,
        last_name=payload.last_name,
        device_name=payload.device_name,
        platform=payload.platform,
    )


@router.post("/login", response_model=AuthResponse)
def login(
    payload: LoginRequest,
    request: Request,
    db: Session = Depends(db_session),
    rate_limiter: RateLimiterService = Depends(limiter),
):
    ip_key = request.client.host if request.client else "unknown"
    if not rate_limiter.check_login_attempts(f"{ip_key}:{payload.email.lower()}"):
        raise errors.bad_request("Too many login attempts. Try again later.")

    service = AuthService(db)
    return service.login(
        email=payload.email,
        password=payload.password,
        device_name=payload.device_name,
        platform=payload.platform,
        request_ip=ip_key,
    )


@router.post("/social-login", response_model=AuthResponse)
def social_login(
    payload: SocialLoginRequest,
    request: Request,
    db: Session = Depends(db_session),
):
    ip_key = request.client.host if request.client else "unknown"
    service = AuthService(db)
    return service.social_login(
        provider=payload.provider,
        id_token=payload.id_token,
        email=payload.email,
        first_name=payload.first_name,
        last_name=payload.last_name,
        device_name=payload.device_name,
        platform=payload.platform,
        request_ip=ip_key,
    )


@router.post("/refresh", response_model=AuthResponse)
def refresh(payload: RefreshRequest, db: Session = Depends(db_session)):
    return AuthService(db).refresh(refresh_token=payload.refresh_token)


@router.post("/logout", response_model=MessageResponse)
def logout(payload: LogoutRequest, db: Session = Depends(db_session)):
    AuthService(db).logout(refresh_token=payload.refresh_token)
    return MessageResponse(message="Logged out")


@router.post("/forgot-password", response_model=MessageResponse)
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(db_session)):
    AuthService(db).forgot_password(email=payload.email)
    return MessageResponse(message="If account exists, reset instructions were sent")


@router.post("/reset-password", response_model=MessageResponse)
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(db_session)):
    try:
        token_payload = decode_token(payload.token)
        if token_payload.get("type") != "reset_password":
            raise errors.bad_request("Invalid token")
    except jwt.PyJWTError:
        raise errors.bad_request("Invalid token")

    AuthService(db).reset_password(token_payload=token_payload, new_password=payload.new_password)
    return MessageResponse(message="Password updated")


@router.post("/verify-email", response_model=MessageResponse)
def verify_email(payload: VerifyEmailRequest, db: Session = Depends(db_session)):
    try:
        token_payload = decode_token(payload.token)
        if token_payload.get("type") != "verify_email":
            raise errors.bad_request("Invalid token")
    except jwt.PyJWTError:
        raise errors.bad_request("Invalid token")

    AuthService(db).verify_email(token_payload=token_payload)
    return MessageResponse(message="Email verified")


@router.post("/resend-verification", response_model=MessageResponse)
def resend_verification(
    user=Depends(current_user),
    db: Session = Depends(db_session),
    rate_limiter: RateLimiterService = Depends(limiter),
):
    if user is None:
        raise errors.unauthorized("Not authenticated")
    # Throttle to prevent verification-email bombing (3 per hour per user).
    if not rate_limiter.check_action(
        "resend_verification", str(user.id), max_attempts=3, window_seconds=3600
    ):
        raise errors.bad_request(
            "Too many requests. Please wait a while before requesting another email."
        )
    AuthService(db).resend_verification(user=user)
    # Generic response — never reveals verification state to the caller.
    return MessageResponse(
        message="If your email is unverified, a new verification link has been sent."
    )


@router.get("/me", response_model=AuthUserOut)
def me(user=Depends(current_user)):
    if user is None:
        raise errors.unauthorized("Not authenticated")
    return user


@router.patch("/me", response_model=AuthUserOut)
def update_me(
    payload: UpdateProfileRequest,
    user=Depends(current_user),
    db: Session = Depends(db_session),
):
    if user is None:
        raise errors.unauthorized("Not authenticated")
    service = AuthService(db)
    return service.update_profile(
        user=user,
        first_name=payload.first_name,
        last_name=payload.last_name,
    )
