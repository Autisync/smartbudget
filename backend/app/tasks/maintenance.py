from datetime import UTC, datetime, timedelta

from sqlalchemy import delete, or_

from app.core.celery_app import celery_app
from app.db.session import SessionLocal
from app.models.auth_session import AuthSession

# L-5 fix: auth_sessions rows were never cleaned up — expired and revoked
# sessions (created on every login/refresh, per RELEASE_BUILD.md's own
# checklist) accumulate indefinitely. Revoked sessions are kept for a
# retention window rather than deleted immediately, so they remain
# correlatable with the L-2 audit trail (auth.logout / auth.login_success
# entries) for a little while after the fact.
REVOKED_SESSION_RETENTION_DAYS = 30


@celery_app.task(name="app.tasks.maintenance.cleanup_expired_sessions")
def cleanup_expired_sessions() -> dict[str, int]:
    now = datetime.now(UTC)
    revoked_cutoff = now - timedelta(days=REVOKED_SESSION_RETENTION_DAYS)
    with SessionLocal() as db:
        result = db.execute(
            delete(AuthSession).where(
                or_(
                    AuthSession.expires_at < now,
                    AuthSession.revoked_at < revoked_cutoff,
                )
            )
        )
        db.commit()
        return {"deleted": result.rowcount}
