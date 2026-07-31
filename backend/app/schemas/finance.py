from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.models.finance import MoneyDirection, Recurrence


class PageMeta(BaseModel):
    limit: int
    offset: int
    total: int


class TransactionCreate(BaseModel):
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    currency: str = Field(default="USD", min_length=3, max_length=3)
    direction: MoneyDirection
    category: str = Field(min_length=1, max_length=80)
    merchant_name: str | None = Field(default=None, max_length=160)
    note: str | None = None
    recurrence: Recurrence = Recurrence.none
    occurred_on: date


class TransactionOut(TransactionCreate):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


class TransactionPage(BaseModel):
    data: list[TransactionOut]
    meta: PageMeta


class BudgetCreate(BaseModel):
    category: str = Field(min_length=1, max_length=80)
    monthly_limit: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    currency: str = Field(default="USD", min_length=3, max_length=3)
    warning_threshold: Decimal = Field(default=Decimal("0.80"), ge=Decimal("0.50"), le=Decimal("1.00"))


class BudgetOut(BudgetCreate):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


class BudgetPage(BaseModel):
    data: list[BudgetOut]
    meta: PageMeta


class SavingsGoalCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    target_amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    current_amount: Decimal = Field(default=Decimal("0"), ge=0, max_digits=14, decimal_places=2)
    currency: str = Field(default="USD", min_length=3, max_length=3)
    target_date: date | None = None


class SavingsGoalOut(SavingsGoalCreate):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


class SavingsGoalPage(BaseModel):
    data: list[SavingsGoalOut]
    meta: PageMeta


class SubscriptionCreate(BaseModel):
    merchant_name: str = Field(min_length=1, max_length=160)
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    currency: str = Field(default="USD", min_length=3, max_length=3)
    cadence: Recurrence = Recurrence.monthly
    category: str = Field(default="Subscriptions", min_length=1, max_length=80)
    next_due_on: date


class SubscriptionOut(SubscriptionCreate):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


class SubscriptionPage(BaseModel):
    data: list[SubscriptionOut]
    meta: PageMeta


class AnalyticsSummary(BaseModel):
    income: Decimal
    expenses: Decimal
    net_flow: Decimal
    transaction_count: int
    top_categories: list[dict[str, Decimal | str]]
