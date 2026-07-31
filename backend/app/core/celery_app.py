from celery import Celery

from app.core.config import settings
from app.core.sentry import configure_sentry

# P2.9: report Celery task failures too (check_subscriptions, email tasks,
# etc.) — previously this process had no error-monitoring integration at
# all, same gap as the API. Safe no-op without SENTRY_DSN configured.
configure_sentry()

celery_app = Celery(
    "smartbudget",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=["app.tasks.finance", "app.tasks.email", "app.tasks.maintenance"],
)

celery_app.conf.update(
    task_acks_late=True,
    task_track_started=True,
    worker_prefetch_multiplier=1,
    broker_connection_retry_on_startup=True,
    timezone="UTC",
    beat_schedule={
        "subscription-checks-hourly": {
            "task": "app.tasks.finance.check_subscriptions",
            "schedule": 3600.0,
        },
        "monthly-summary-daily": {
            "task": "app.tasks.finance.generate_monthly_summaries",
            "schedule": 86400.0,
        },
        # L-5: low-priority daily cleanup of expired/long-revoked auth_sessions.
        "auth-session-cleanup-daily": {
            "task": "app.tasks.maintenance.cleanup_expired_sessions",
            "schedule": 86400.0,
        },
    },
)
