"""Regression cover for M-2: an empty CORS_ORIGINS silently resolved to
wildcard-with-credentials in production, bypassing the startup guard, which
only rejected the literal string "*" — not an empty/unparseable value (e.g. a
forgotten .env entry; docker-compose.yml sets no default for CORS_ORIGINS,
so an unset variable becomes "").
"""

import pytest

from app.core.config import settings
from app.main import create_application


@pytest.fixture(autouse=True)
def _restore_settings():
    """Settings is a module-level singleton read by create_application() —
    snapshot and restore the fields these tests mutate."""
    original = (settings.environment, settings.cors_origins, settings.jwt_secret_key, settings.database_url)
    yield
    settings.environment, settings.cors_origins, settings.jwt_secret_key, settings.database_url = original


def _use_safe_non_cors_secrets():
    """Sets JWT_SECRET_KEY/DATABASE_URL to non-default values so tests that
    exercise the "app starts fine" path aren't tripped by the *other*,
    unrelated production_secret_issues() checks — isolates the assertions to
    CORS behavior specifically."""
    settings.jwt_secret_key = "a-real-random-looking-secret-value-not-the-default"
    settings.database_url = "postgresql+psycopg://smartspend_app:S3cur3P@ss@db.internal:5432/smartspend"


# ---- Unit tests: the startup guard -----------------------------------------


def test_wildcard_cors_is_flagged_in_production():
    settings.environment = "production"
    settings.cors_origins = "*"
    assert any("CORS_ORIGINS" in issue for issue in settings.production_secret_issues())


def test_empty_cors_is_flagged_in_production():
    settings.environment = "production"
    settings.cors_origins = ""
    assert any("CORS_ORIGINS" in issue for issue in settings.production_secret_issues())


def test_whitespace_only_cors_is_flagged_in_production():
    settings.environment = "production"
    settings.cors_origins = "   "
    assert any("CORS_ORIGINS" in issue for issue in settings.production_secret_issues())


def test_valid_cors_is_not_flagged_in_production():
    settings.environment = "production"
    settings.cors_origins = "https://smaartspend.com"
    assert not any("CORS_ORIGINS" in issue for issue in settings.production_secret_issues())


def test_anything_is_allowed_in_development():
    settings.environment = "development"
    settings.cors_origins = "*"
    assert settings.production_secret_issues() == []


# ---- Feature test: actual app startup --------------------------------------


def test_app_fails_to_start_with_empty_cors_in_production():
    settings.environment = "production"
    settings.cors_origins = ""
    # production_secret_issues() is checked first in create_application() and
    # already covers this — asserting the whole app refuses to boot end-to-end,
    # not just that the guard method itself flags it.
    with pytest.raises(SystemExit):
        create_application()


def test_app_fails_to_start_with_wildcard_cors_in_production():
    settings.environment = "production"
    settings.cors_origins = "*"
    with pytest.raises(SystemExit):
        create_application()


def test_app_starts_normally_with_valid_cors_in_production():
    settings.environment = "production"
    settings.cors_origins = "https://smaartspend.com"
    _use_safe_non_cors_secrets()
    # Must not raise, and must actually apply the configured origin — not
    # silently fall back to wildcard.
    app = create_application()
    cors_middleware = next(
        m for m in app.user_middleware if m.cls.__name__ == "CORSMiddleware"
    )
    assert cors_middleware.kwargs["allow_origins"] == ["https://smaartspend.com"]


def test_app_starts_with_empty_cors_in_development_and_defaults_to_wildcard():
    settings.environment = "development"
    settings.cors_origins = ""
    app = create_application()
    cors_middleware = next(
        m for m in app.user_middleware if m.cls.__name__ == "CORSMiddleware"
    )
    assert cors_middleware.kwargs["allow_origins"] == ["*"]
