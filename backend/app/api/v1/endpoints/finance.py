import json
from datetime import date
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from redis import Redis
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import current_user, db_session
from app.core import errors
from app.core.redis import get_redis
from app.models.finance import (
    AuditLog,
    Budget,
    MoneyDirection,
    SavingsGoal,
    Subscription,
    Transaction,
)
from app.schemas.finance import (
    AnalyticsSummary,
    BudgetCreate,
    BudgetOut,
    PageMeta,
    SavingsGoalCreate,
    SavingsGoalOut,
    SubscriptionCreate,
    SubscriptionOut,
    TransactionCreate,
    TransactionOut,
    TransactionPage,
)
from app.tasks.finance import analyze_recurring_transactions

router = APIRouter()


def require_user(user=Depends(current_user)):
    if user is None:
        raise errors.unauthorized("Not authenticated")
    return user


def _analytics_cache_key(user_id: UUID) -> str:
    return f"analytics:summary:{user_id}"


def _invalidate_finance_cache(redis_client: Redis, user_id: UUID) -> None:
    redis_client.delete(_analytics_cache_key(user_id))


def _publish_balance_event(redis_client: Redis, user_id: UUID, event_type: str) -> None:
    redis_client.publish(
        f"balance:{user_id}",
        json.dumps({"type": event_type, "user_id": str(user_id)}),
    )


@router.get("/transactions", response_model=TransactionPage)
def list_transactions(
    db: Session = Depends(db_session),
    user=Depends(require_user),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    category: str | None = None,
    direction: MoneyDirection | None = None,
    start_date: date | None = None,
    end_date: date | None = None,
):
    filters = [Transaction.user_id == user.id]
    if category:
        filters.append(Transaction.category == category)
    if direction:
        filters.append(Transaction.direction == direction)
    if start_date:
        filters.append(Transaction.occurred_on >= start_date)
    if end_date:
        filters.append(Transaction.occurred_on <= end_date)

    total = db.scalar(select(func.count()).select_from(Transaction).where(*filters)) or 0
    rows = db.scalars(
        select(Transaction)
        .where(*filters)
        .order_by(Transaction.occurred_on.desc(), Transaction.created_at.desc())
        .limit(limit)
        .offset(offset)
    ).all()
    return TransactionPage(data=rows, meta=PageMeta(limit=limit, offset=offset, total=total))


@router.post("/transactions", response_model=TransactionOut, status_code=201)
def create_transaction(
    payload: TransactionCreate,
    db: Session = Depends(db_session),
    redis_client: Redis = Depends(get_redis),
    user=Depends(require_user),
):
    transaction = Transaction(user_id=user.id, **payload.model_dump())
    db.add(transaction)
    db.flush()
    db.add(
        AuditLog(
            actor_user_id=user.id,
            action="transaction.create",
            resource_type="transaction",
            resource_id=str(transaction.id),
        )
    )
    db.commit()
    db.refresh(transaction)
    _invalidate_finance_cache(redis_client, user.id)
    _publish_balance_event(redis_client, user.id, "transaction.created")
    analyze_recurring_transactions.delay(str(user.id))
    return transaction


@router.delete("/transactions/{transaction_id}", status_code=204)
def delete_transaction(
    transaction_id: UUID,
    db: Session = Depends(db_session),
    redis_client: Redis = Depends(get_redis),
    user=Depends(require_user),
):
    transaction = db.get(Transaction, transaction_id)
    if transaction is None or transaction.user_id != user.id:
        raise errors.not_found("Transaction not found")
    db.add(
        AuditLog(
            actor_user_id=user.id,
            action="transaction.delete",
            resource_type="transaction",
            resource_id=str(transaction_id),
        )
    )
    db.delete(transaction)
    db.commit()
    _invalidate_finance_cache(redis_client, user.id)
    _publish_balance_event(redis_client, user.id, "transaction.deleted")
    return None


@router.get("/budgets", response_model=list[BudgetOut])
def list_budgets(db: Session = Depends(db_session), user=Depends(require_user)):
    return db.scalars(select(Budget).where(Budget.user_id == user.id).order_by(Budget.category)).all()


@router.post("/budgets", response_model=BudgetOut, status_code=201)
def create_budget(payload: BudgetCreate, db: Session = Depends(db_session), user=Depends(require_user)):
    budget = Budget(user_id=user.id, **payload.model_dump())
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget


@router.get("/savings-goals", response_model=list[SavingsGoalOut])
def list_savings_goals(db: Session = Depends(db_session), user=Depends(require_user)):
    return db.scalars(select(SavingsGoal).where(SavingsGoal.user_id == user.id).order_by(SavingsGoal.created_at.desc())).all()


@router.post("/savings-goals", response_model=SavingsGoalOut, status_code=201)
def create_savings_goal(payload: SavingsGoalCreate, db: Session = Depends(db_session), user=Depends(require_user)):
    goal = SavingsGoal(user_id=user.id, **payload.model_dump())
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal


@router.get("/subscriptions", response_model=list[SubscriptionOut])
def list_subscriptions(db: Session = Depends(db_session), user=Depends(require_user)):
    return db.scalars(select(Subscription).where(Subscription.user_id == user.id).order_by(Subscription.next_due_on)).all()


@router.post("/subscriptions", response_model=SubscriptionOut, status_code=201)
def create_subscription(payload: SubscriptionCreate, db: Session = Depends(db_session), user=Depends(require_user)):
    subscription = Subscription(user_id=user.id, **payload.model_dump())
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription


@router.get("/analytics/summary", response_model=AnalyticsSummary)
def analytics_summary(
    db: Session = Depends(db_session),
    redis_client: Redis = Depends(get_redis),
    user=Depends(require_user),
):
    cache_key = _analytics_cache_key(user.id)
    cached = redis_client.get(cache_key)
    if cached:
        return AnalyticsSummary.model_validate_json(cached)

    rows = db.execute(
        select(Transaction.direction, func.coalesce(func.sum(Transaction.amount), 0), func.count())
        .where(Transaction.user_id == user.id)
        .group_by(Transaction.direction)
    ).all()
    income = Decimal("0")
    expenses = Decimal("0")
    transaction_count = 0
    for direction, total, count in rows:
        transaction_count += count
        if direction == MoneyDirection.income:
            income = total
        else:
            expenses = total

    top_categories = db.execute(
        select(Transaction.category, func.coalesce(func.sum(Transaction.amount), 0).label("total"))
        .where(Transaction.user_id == user.id, Transaction.direction == MoneyDirection.expense)
        .group_by(Transaction.category)
        .order_by(func.coalesce(func.sum(Transaction.amount), 0).desc())
        .limit(5)
    ).all()

    summary = AnalyticsSummary(
        income=income,
        expenses=expenses,
        net_flow=income - expenses,
        transaction_count=transaction_count,
        top_categories=[{"category": category, "amount": total} for category, total in top_categories],
    )
    redis_client.setex(cache_key, 300, summary.model_dump_json())
    return summary
