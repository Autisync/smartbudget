from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class AuthUserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    first_name: str
    last_name: str
    is_active: bool
    is_verified: bool


class UpdateProfileRequest(BaseModel):
    first_name: str | None = Field(default=None, min_length=1, max_length=120)
    last_name: str | None = Field(default=None, min_length=1, max_length=120)


class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    first_name: str = Field(min_length=1, max_length=120)
    last_name: str = Field(min_length=1, max_length=120)
    device_name: str | None = Field(default=None, max_length=120)
    platform: str | None = Field(default=None, max_length=40)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    device_name: str | None = Field(default=None, max_length=120)
    platform: str | None = Field(default=None, max_length=40)


class SocialLoginRequest(BaseModel):
    provider: Literal["google", "apple"]
    id_token: str = Field(min_length=20)
    email: EmailStr | None = None
    first_name: str | None = Field(default=None, max_length=120)
    last_name: str | None = Field(default=None, max_length=120)
    device_name: str | None = Field(default=None, max_length=120)
    platform: str | None = Field(default=None, max_length=40)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class LogoutRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str = Field(min_length=20)
    new_password: str = Field(min_length=8, max_length=128)


class VerifyEmailRequest(BaseModel):
    token: str = Field(min_length=20)


class AuthResponse(BaseModel):
    user: AuthUserOut
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    access_token_expires_in: int


class MessageResponse(BaseModel):
    message: str
