from datetime import date

from sqlalchemy import func, or_, select

from app.core.celery_app import celery_app
from app.db.session import SessionLocal
from app.models.finance import Notification, Subscription, Transaction


@celery_app.task(name="app.tasks.finance.analyze_recurring_transactions")
def analyze_recurring_transactions(user_id: str) -> dict[str, int | str]:
    with SessionLocal() as db:
        count = db.scalar(
            select(func.count()).select_from(Transaction).where(Transaction.user_id == user_id)
        )
        return {"user_id": user_id, "transaction_count": int(count or 0)}


@celery_app.task(name="app.tasks.finance.generate_report")
def generate_report(user_id: str, report_type: str = "monthly") -> dict[str, str]:
    return {"user_id": user_id, "report_type": report_type, "status": "queued"}


@celery_app.task(name="app.tasks.finance.check_subscriptions")
def check_subscriptions() -> dict[str, int]:
    # P2.8 fix: this task runs hourly. Without the last_notified_for guard,
    # a subscription whose next_due_on isn't advanced (the common case — the
    # user hasn't marked it renewed yet) would re-trigger a brand new
    # Notification row on every single run, forever, flooding the table and
    # spamming the user. Only notify once per due date per subscription: a
    # subscription is eligible only if it's never been notified, or was last
    # notified for a *different* (i.e. earlier) due date than its current one.
    today = date.today()
    with SessionLocal() as db:
        due_subscriptions = db.scalars(
            select(Subscription).where(
                Subscription.next_due_on <= today,
                or_(
                    Subscription.last_notified_for.is_(None),
                    Subscription.last_notified_for != Subscription.next_due_on,
                ),
            )
        ).all()
        for subscription in due_subscriptions:
            db.add(
                Notification(
                    user_id=subscription.user_id,
                    title=f"{subscription.merchant_name} is due",
                    body="Review this subscription before the next payment posts.",
                    event_type="subscription_due",
                )
            )
            subscription.last_notified_for = subscription.next_due_on
            db.add(subscription)
        db.commit()
        return {"notifications_created": len(due_subscriptions)}


@celery_app.task(name="app.tasks.finance.generate_monthly_summaries")
def generate_monthly_summaries() -> dict[str, str]:
    return {"status": "queued"}


@celery_app.task(name="app.tasks.finance.generate_ai_insights")
def generate_ai_insights(user_id: str) -> dict[str, str]:
    return {"user_id": user_id, "status": "queued"}
