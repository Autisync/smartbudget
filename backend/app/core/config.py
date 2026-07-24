from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "SmartSpend"
    environment: str = "development"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    cors_origins: str = "*"

    database_url: str = Field(default="postgresql+psycopg://postgres:postgres@postgres:5432/smartbudget")
    redis_url: str = Field(default="redis://redis:6379/0")
    celery_broker_url: str = Field(default="redis://redis:6379/1")
    celery_result_backend: str = Field(default="redis://redis:6379/2")

    jwt_secret_key: str = "change-me"  # MUST be overridden via JWT_SECRET_KEY env var in production
    jwt_algorithm: str = "HS256"
    access_token_ttl_seconds: int = 900
    refresh_token_ttl_seconds: int = 2592000
    password_reset_ttl_seconds: int = 1800
    verify_email_ttl_seconds: int = 86400

    login_rate_limit_window_seconds: int = 60
    login_rate_limit_max_attempts: int = 10

    # Domain-bound App Links / Universal Links (cryptographically verified via
    # assetlinks.json + apple-app-site-association) instead of a hijackable
    # custom URL scheme. Must match the /app path prefix registered in the
    # native deep-link intent-filters.
    reset_password_deep_link_base: str = "https://api.smaartspend.com/r/reset-password"
    verify_email_deep_link_base: str = "https://api.smaartspend.com/r/verify-email"
    google_oauth_client_ids: str = ""
    # For native Sign in with Apple the identity token's `aud` claim is the
    # app's bundle identifier. Override per-environment (comma-separated) if a
    # Services ID or additional bundle IDs are also used.
    # Native Apple sign-in: the identity token's `aud` is the app bundle id.
    # Release/Profile builds use autisync.smartspend, Debug uses
    # autisync.smartbudget — accept both. Add a Services ID here too if/when
    # Android/web Apple sign-in is enabled.
    apple_oauth_audiences: str = "autisync.smartspend,autisync.smartbudget"

    smtp_enabled: bool = False
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_use_tls: bool = True
    smtp_use_ssl: bool = False
    smtp_from_email: str = "noreply@smartspend.local"
    smtp_from_name: str = "SmartSpend"

    def production_secret_issues(self) -> list[str]:
        """Returns a list of critical misconfiguration issues that must block startup
        in any non-development environment. Raises SystemExit when called from main.py."""
        if self.environment == "development":
            return []
        issues: list[str] = []
        if self.jwt_secret_key == "change-me":
            issues.append(
                "JWT_SECRET_KEY is still the default 'change-me' — "
                "set a cryptographically random value in the environment"
            )
        if "postgres:postgres@" in self.database_url or self.database_url.endswith(":5432/smartbudget") and "postgres:postgres" in self.database_url:
            issues.append(
                "DATABASE_URL contains default postgres:postgres credentials — "
                "use a dedicated DB user with a strong password"
            )
        if self.cors_origins == "*":
            issues.append(
                "CORS_ORIGINS is '*' — restrict to your production domain(s)"
            )
        return issues

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
