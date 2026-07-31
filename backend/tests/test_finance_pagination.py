"""Regression cover: budgets/savings-goals/subscriptions previously returned
every row for a user with no limit/offset — an unbounded result set that
would grow without end as a power user accumulates years of goals/
subscriptions/budgets (RELEASE_BUILD.md's own pagination-audit checklist item,
confirmed still open by this session's audit). These now mirror the
existing /transactions pagination pattern (limit default 50 / max 200,
offset, total in the response).

Not currently consumed by the Flutter app (which is local-first for these
entities — confirmed via a repo-wide search finding no remote-datasource
calls to these paths), so this is a safe, non-breaking API shape change.
"""

import uuid
from datetime import date, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import select

from app.api.v1.endpoints import finance as finance_endpoints
from app.core.security import hash_password
from app.models.finance import Budget, SavingsGoal, Subscription
from app.models.user import User


@pytest.fixture
def two_users(real_db):
    """Two real users, each with a distinct random email, for IDOR checks."""
    def _make(tag: str) -> User:
        user = User(
            id=uuid.uuid4(),
            email=f"{tag}-{uuid.uuid4().hex}@example.com",
            password_hash=hash_password("StrongPass123"),
            first_name=tag, last_name="User", is_active=True, is_verified=True,
        )
        real_db.add(user)
        real_db.commit()
        real_db.refresh(user)
        return user

    return _make("owner"), _make("other")


def _seed_budgets(db, user_id, count: int):
    for i in range(count):
        db.add(Budget(
            user_id=user_id, category=f"cat-{i:04d}",
            monthly_limit=Decimal("100.00"), currency="USD",
        ))
    db.commit()


def _seed_goals(db, user_id, count: int):
    for i in range(count):
        db.add(SavingsGoal(
            user_id=user_id, name=f"goal-{i:04d}",
            target_amount=Decimal("1000.00"), currency="USD",
        ))
    db.commit()


def _seed_subscriptions(db, user_id, count: int):
    for i in range(count):
        db.add(Subscription(
            user_id=user_id, merchant_name=f"merchant-{i:04d}",
            amount=Decimal("9.99"), currency="USD",
            next_due_on=date.today() + timedelta(days=i),
        ))
    db.commit()


# ---- Budgets ----------------------------------------------------------------


def test_budgets_default_limit_and_total(real_db, two_users):
    owner, _other = two_users
    _seed_budgets(real_db, owner.id, 220)

    page = finance_endpoints.list_budgets(db=real_db, user=owner, limit=50, offset=0)
    assert len(page.data) == 50  # default limit
    assert page.meta.total == 220
    assert page.meta.limit == 50
    assert page.meta.offset == 0


def test_budgets_respects_max_limit_and_offset(real_db, two_users):
    owner, _other = two_users
    _seed_budgets(real_db, owner.id, 220)

    page = finance_endpoints.list_budgets(db=real_db, user=owner, limit=200, offset=200)
    assert len(page.data) == 20  # 220 total, offset 200 -> 20 remain
    assert page.meta.total == 220


def test_budgets_pages_do_not_overlap(real_db, two_users):
    owner, _other = two_users
    _seed_budgets(real_db, owner.id, 30)

    first_page = finance_endpoints.list_budgets(db=real_db, user=owner, limit=10, offset=0)
    second_page = finance_endpoints.list_budgets(db=real_db, user=owner, limit=10, offset=10)
    first_ids = {b.id for b in first_page.data}
    second_ids = {b.id for b in second_page.data}
    assert first_ids.isdisjoint(second_ids)


def test_budgets_never_leak_another_users_data(real_db, two_users):
    owner, other = two_users
    _seed_budgets(real_db, owner.id, 5)
    _seed_budgets(real_db, other.id, 5)

    page = finance_endpoints.list_budgets(db=real_db, user=owner, limit=200, offset=0)
    assert page.meta.total == 5
    assert all(b.category.startswith("cat-") for b in page.data)
    owner_budget_ids = {b.id for b in real_db.scalars(select(Budget).where(Budget.user_id == owner.id))}
    assert {b.id for b in page.data} == owner_budget_ids


# ---- Savings goals ------------------------------------------------------------


def test_savings_goals_default_limit_and_total(real_db, two_users):
    owner, _other = two_users
    _seed_goals(real_db, owner.id, 75)

    page = finance_endpoints.list_savings_goals(db=real_db, user=owner, limit=50, offset=0)
    assert len(page.data) == 50
    assert page.meta.total == 75


def test_savings_goals_never_leak_another_users_data(real_db, two_users):
    owner, other = two_users
    _seed_goals(real_db, owner.id, 3)
    _seed_goals(real_db, other.id, 40)

    page = finance_endpoints.list_savings_goals(db=real_db, user=owner, limit=200, offset=0)
    assert page.meta.total == 3
    assert len(page.data) == 3


# ---- Subscriptions --------------------------------------------------------


def test_subscriptions_default_limit_and_total(real_db, two_users):
    owner, _other = two_users
    _seed_subscriptions(real_db, owner.id, 210)

    page = finance_endpoints.list_subscriptions(db=real_db, user=owner, limit=50, offset=0)
    assert len(page.data) == 50
    assert page.meta.total == 210


def test_subscriptions_respects_max_limit(real_db, two_users):
    owner, _other = two_users
    _seed_subscriptions(real_db, owner.id, 210)

    page = finance_endpoints.list_subscriptions(db=real_db, user=owner, limit=200, offset=0)
    assert len(page.data) == 200
    assert page.meta.total == 210


def test_subscriptions_never_leak_another_users_data(real_db, two_users):
    owner, other = two_users
    _seed_subscriptions(real_db, owner.id, 2)
    _seed_subscriptions(real_db, other.id, 60)

    page = finance_endpoints.list_subscriptions(db=real_db, user=owner, limit=200, offset=0)
    assert page.meta.total == 2
    assert len(page.data) == 2
