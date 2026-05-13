from datetime import date

from sqlalchemy import func, select

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
    today = date.today()
    with SessionLocal() as db:
        due_subscriptions = db.scalars(
            select(Subscription).where(Subscription.next_due_on <= today)
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
        db.commit()
        return {"notifications_created": len(due_subscriptions)}


@celery_app.task(name="app.tasks.finance.generate_monthly_summaries")
def generate_monthly_summaries() -> dict[str, str]:
    return {"status": "queued"}


@celery_app.task(name="app.tasks.finance.generate_ai_insights")
def generate_ai_insights(user_id: str) -> dict[str, str]:
    return {"user_id": user_id, "status": "queued"}
