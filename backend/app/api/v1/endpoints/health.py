import hmac
import logging
from typing import Any
from urllib.parse import urlparse

from fastapi import APIRouter, Request
from sqlalchemy import text

from app.core import errors
from app.core.celery_app import celery_app
from app.core.config import settings
from app.core.redis import get_redis
from app.db.session import SessionLocal

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


def _check_database() -> dict[str, Any]:
    """L-3 fix: the readiness check previously never verified Postgres or
    Redis at all — only the Celery broker (a separate Redis DB). If Postgres
    went down, every real request would start failing while this endpoint
    still reported 'ok' as long as email prerequisites happened to be met."""
    info: dict[str, Any] = {"reachable": False, "error": None}
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
        info["reachable"] = True
    except Exception as exc:
        info["error"] = type(exc).__name__
        logger.warning("Readiness: database unreachable (%s)", type(exc).__name__)
    return info


def _check_redis() -> dict[str, Any]:
    """Checks the main app Redis (db 0 — caching/rate-limiting/pubsub), not
    the Celery broker/backend DBs already covered by _check_broker()."""
    info: dict[str, Any] = {"reachable": False, "error": None}
    try:
        get_redis().ping()
        info["reachable"] = True
    except Exception as exc:
        info["error"] = type(exc).__name__
        logger.warning("Readiness: Redis unreachable (%s)", type(exc).__name__)
    return info


@router.get("/health/ready")
def readiness(request: Request) -> Any:
    """Deep readiness for ops/monitoring: database, Redis, Celery broker/
    workers, and SMTP config, so you can confirm the deployment is actually
    functional (not just "the process is running") from one endpoint.

    Always returns HTTP 200 (with status 'ok' or 'degraded') so it can't trip
    the liveness healthcheck. Exposes only non-sensitive booleans/scheme —
    never credentials. Gated by HEALTH_CHECK_TOKEN if configured (L-3) —
    unrestricted by default for local/dev convenience.
    """
    if settings.health_check_token:
        provided = request.headers.get("x-health-check-token", "")
        if not hmac.compare_digest(provided, settings.health_check_token):
            # 404 rather than 401/403 — don't even confirm this endpoint
            # exists to an unauthenticated caller.
            raise errors.not_found("Not found")

    database = _check_database()
    redis_check = _check_redis()
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
    core_infra_ready = database["reachable"] and redis_check["reachable"]
    return {
        "status": "ok" if (core_infra_ready and email_ready) else "degraded",
        "database": database,
        "redis": redis_check,
        "email_ready": email_ready,
        "celery_broker": broker,
        "celery_workers": workers,
        "smtp": smtp,
    }
