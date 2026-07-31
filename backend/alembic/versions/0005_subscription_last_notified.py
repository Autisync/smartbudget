"""add last_notified_for to subscriptions

Revision ID: 0005_subscription_last_notified
Revises: 0004_partial_idx_active_sess
Create Date: 2026-07-31 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0005_subscription_last_notified"
down_revision: Union[str, None] = "0004_partial_idx_active_sess"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("subscriptions", sa.Column("last_notified_for", sa.Date(), nullable=True))


def downgrade() -> None:
    op.drop_column("subscriptions", "last_notified_for")
