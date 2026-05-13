from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "smartbudget-auth"
    environment: str = "development"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    cors_origins: str = "*"

    database_url: str = Field(default="postgresql+psycopg://postgres:postgres@postgres:5432/smartbudget")
    redis_url: str = Field(default="redis://redis:6379/0")
    celery_broker_url: str = Field(default="redis://redis:6379/1")
    celery_result_backend: str = Field(default="redis://redis:6379/2")

    jwt_secret_key: str = "change-me"
    jwt_algorithm: str = "HS256"
    access_token_ttl_seconds: int = 900
    refresh_token_ttl_seconds: int = 2592000
    password_reset_ttl_seconds: int = 1800
    verify_email_ttl_seconds: int = 86400

    login_rate_limit_window_seconds: int = 60
    login_rate_limit_max_attempts: int = 10

    reset_password_deep_link_base: str = "smartbudget://reset-password"
    verify_email_deep_link_base: str = "smartbudget://verify-email"
    google_oauth_client_ids: str = ""
    apple_oauth_audiences: str = ""

    smtp_enabled: bool = False
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_use_tls: bool = True
    smtp_use_ssl: bool = False
    smtp_from_email: str = "noreply@smartbudget.local"
    smtp_from_name: str = "SmartBudget"

    def smtp_validation_issues(self) -> list[str]:
        issues: list[str] = []
        if not self.smtp_enabled:
            return issues

        if not self.smtp_host:
            issues.append("SMTP_HOST is required when SMTP_ENABLED=true")
        if self.smtp_port <= 0:
            issues.append("SMTP_PORT must be greater than 0")
        if self.smtp_use_ssl and self.smtp_use_tls:
            issues.append("Set only one of SMTP_USE_SSL or SMTP_USE_TLS to true")
        if self.smtp_username and not self.smtp_password:
            issues.append("SMTP_PASSWORD is required when SMTP_USERNAME is set")
        if not self.smtp_from_email:
            issues.append("SMTP_FROM_EMAIL is required when SMTP_ENABLED=true")

        return issues

    def google_oauth_client_id_list(self) -> list[str]:
        return [value.strip() for value in self.google_oauth_client_ids.split(",") if value.strip()]

    def apple_oauth_audience_list(self) -> list[str]:
        return [value.strip() for value in self.apple_oauth_audiences.split(",") if value.strip()]


settings = Settings()
