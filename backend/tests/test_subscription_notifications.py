"""Regression cover: check_subscriptions runs hourly via Celery beat. Without
an idempotency guard, a subscription whose next_due_on isn't advanced (the
common case — the user hasn't marked it renewed) re-triggered a brand new
Notification row on every single run, forever — flooding the notifications
table and spamming the user with the same "due" alert every hour.
"""

import uuid
from datetime import date, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import select

from app.core.security import hash_password
from app.models.finance import Notification, Subscription
from app.models.user import User
from app.tasks.finance import check_subscriptions


@pytest.fixture
def user(real_db) -> User:
    u = User(
        id=uuid.uuid4(), email=f"sub-{uuid.uuid4().hex}@example.com",
        password_hash=hash_password("StrongPass123"),
        first_name="Sub", last_name="Scriber", is_active=True, is_verified=True,
    )
    real_db.add(u)
    real_db.commit()
    real_db.refresh(u)
    return u


def _due_subscription(db, user_id, due_on: date) -> Subscription:
    sub = Subscription(
        user_id=user_id, merchant_name=f"Merchant-{uuid.uuid4().hex[:6]}",
        amount=Decimal("9.99"), currency="USD", next_due_on=due_on,
    )
    db.add(sub)
    db.commit()
    db.refresh(sub)
    return sub


def _notifications_for(db, subscription: Subscription) -> list[Notification]:
    return list(db.scalars(
        select(Notification).where(
            Notification.user_id == subscription.user_id,
            Notification.event_type == "subscription_due",
            Notification.title == f"{subscription.merchant_name} is due",
        )
    ))


def test_first_run_creates_exactly_one_notification(real_db, user):
    sub = _due_subscription(real_db, user.id, date.today())
    check_subscriptions()
    assert len(_notifications_for(real_db, sub)) == 1


def test_running_the_task_three_times_still_creates_only_one_notification(real_db, user):
    """Simulates three consecutive hourly Celery beats without the user
    having renewed the subscription in between — the exact scenario that
    used to flood the table."""
    sub = _due_subscription(real_db, user.id, date.today())

    check_subscriptions()
    check_subscriptions()
    check_subscriptions()

    notifications = _notifications_for(real_db, sub)
    assert len(notifications) == 1

    real_db.refresh(sub)
    assert sub.last_notified_for == sub.next_due_on


def test_advancing_next_due_on_after_renewal_allows_a_fresh_notification(real_db, user):
    """A real renewal (next_due_on advances to a genuinely different date)
    must still notify again — this is not a permanent one-notification-ever
    cap, just once-per-due-date. Uses yesterday -> today (two distinct dates)
    rather than mocking date.today(), since the task calls it internally."""
    sub = _due_subscription(real_db, user.id, date.today() - timedelta(days=1))
    check_subscriptions()
    assert len(_notifications_for(real_db, sub)) == 1
    real_db.refresh(sub)
    assert sub.last_notified_for == date.today() - timedelta(days=1)

    # Running the task again with the same (still overdue) due date must NOT
    # create a second notification — the bug this fix closes.
    check_subscriptions()
    assert len(_notifications_for(real_db, sub)) == 1

    # User renews; due date genuinely advances to a new date (today).
    sub.next_due_on = date.today()
    real_db.add(sub)
    real_db.commit()
    check_subscriptions()
    assert len(_notifications_for(real_db, sub)) == 2


def test_two_different_subscriptions_each_get_their_own_notification(real_db, user):
    sub_a = _due_subscription(real_db, user.id, date.today())
    sub_b = _due_subscription(real_db, user.id, date.today())

    check_subscriptions()

    assert len(_notifications_for(real_db, sub_a)) == 1
    assert len(_notifications_for(real_db, sub_b)) == 1


def test_not_yet_due_subscription_is_not_notified(real_db, user):
    sub = _due_subscription(real_db, user.id, date.today() + timedelta(days=5))
    check_subscriptions()
    assert len(_notifications_for(real_db, sub)) == 0
