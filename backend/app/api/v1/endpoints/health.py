import logging
from typing import Any
from urllib.parse import urlparse

from fastapi import APIRouter

from app.core.celery_app import celery_app
from app.core.config import settings

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/health")
def health_check() -> dict[str, str]:
    """Liveness probe — returns 200 whenever the process is up. The container
    healthcheck depends on this staying dependency-free, so do NOT add broker /
    database checks here; use /health/ready for those."""
    return {"status": "ok"}


def _check_broker() -> dict[str, Any]:
    """Best-effort Celery broker reachability check.

    Surfaces the transport scheme so a misconfigured broker (e.g. an empty
    CELERY_BROKER_URL that makes Celery fall back to amqp://localhost) is
    obvious at a glance, without exposing the full URL/credentials.
    """
    scheme = urlparse(settings.celery_broker_url or "").scheme or "amqp (default fallback)"
    info: dict[str, Any] = {"scheme": scheme, "reachable": False, "error": None}
    try:
        with celery_app.connection() as conn:
            conn.ensure_connection(max_retries=1, timeout=3)
        info["reachable"] = True
    except Exception as exc:  # broker down or wrong transport
        info["error"] = type(exc).__name__
        logger.warning("Readiness: Celery broker unreachable (%s)", type(exc).__name__)
    return info


def _check_workers() -> dict[str, Any]:
    """Ping live Celery workers. Broker reachability alone does NOT mean email
    will send — a task enqueued with no worker consuming it sits forever. This
    surfaces whether at least one worker is actually online."""
    info: dict[str, Any] = {"online": 0, "responding": False, "error": None}
    try:
        replies = celery_app.control.ping(timeout=2)
        info["online"] = len(replies or [])
        info["responding"] = bool(replies)
    except Exception as exc:
        info["error"] = type(exc).__name__
        logger.warning("Readiness: Celery worker ping failed (%s)", type(exc).__name__)
    return info


@router.get("/health/ready")
def readiness() -> dict[str, Any]:
    """Deep readiness for ops/monitoring: reports the prerequisites for
    transactional email delivery (Celery broker + SMTP config) so you can
    confirm "will verification emails actually send?" from one endpoint.

    Always returns HTTP 200 (with status 'ok' or 'degraded') so it can't trip
    the liveness healthcheck. Exposes only non-sensitive booleans/scheme —
    never credentials.
    """
    broker = _check_broker()
    workers = _check_workers()
    smtp_issues = settings.smtp_validation_issues()
    smtp = {
        "enabled": settings.smtp_enabled,
        "host_configured": bool(settings.smtp_host),
        "from_email": settings.smtp_from_email,
        "issues": smtp_issues,
    }
    email_ready = (
        broker["reachable"]
        and workers["responding"]
        and settings.smtp_enabled
        and bool(settings.smtp_host)
        and not smtp_issues
    )
    return {
        "status": "ok" if email_ready else "degraded",
        "email_ready": email_ready,
        "celery_broker": broker,
        "celery_workers": workers,
        "smtp": smtp,
    }
