"""index on subscriptions.next_due_on for the hourly due-check scan

Revision ID: 0006_subs_next_due_index
Revises: 0005_subscription_last_notified
Create Date: 2026-08-01 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op


revision: str = "0006_subs_next_due_index"
down_revision: Union[str, None] = "0005_subscription_last_notified"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Re-audit fix: check_subscriptions (app/tasks/finance.py) runs hourly
    # and filters `next_due_on <= today` with no user_id predicate — the
    # existing ix_subscriptions_user_next_due index is a composite on
    # (user_id, next_due_on) and is unusable as a leading-column filter for
    # this query, forcing a sequential scan of the whole table every run.
    # CONCURRENTLY avoids taking a table lock during the build — subscriptions
    # is a table the API also writes to (create/update), unlike the earlier
    # 0004 partial index which used a plain CREATE INDEX on the much less
    # frequently written auth_sessions table.
    with op.get_context().autocommit_block():
        op.execute(
            "CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_subscriptions_next_due_on "
            "ON subscriptions (next_due_on)"
        )


def downgrade() -> None:
    with op.get_context().autocommit_block():
        op.execute("DROP INDEX CONCURRENTLY IF EXISTS ix_subscriptions_next_due_on")
