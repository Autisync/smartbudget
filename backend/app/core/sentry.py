import sentry_sdk
from sentry_sdk.integrations.celery import CeleryIntegration
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.starlette import StarletteIntegration

from app.core.config import settings


def configure_sentry() -> None:
    """Safe no-op without a DSN — mirrors the Flutter app's own ErrorMonitor
    pattern (P2.9). Previously there was zero error-monitoring integration
    anywhere in the backend — neither the API nor Celery tasks (e.g. a
    failure in check_subscriptions or an email-sending task) reported
    anywhere; an unhandled exception just produced a bare stdout line.
    Called from both create_application() (API process) and
    celery_app.py (worker/beat processes) — the Starlette/FastAPI
    integrations are simply inert in a process with no Starlette app."""
    if not settings.sentry_dsn:
        return
    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.environment,
        traces_sample_rate=settings.sentry_traces_sample_rate,
        integrations=[StarletteIntegration(), FastApiIntegration(), CeleryIntegration()],
        # Request/task payloads can contain passwords (signup/login) — never send them.
        send_default_pii=False,
        max_request_body_size="never",
    )
