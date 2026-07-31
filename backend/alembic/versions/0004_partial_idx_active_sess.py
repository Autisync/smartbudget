"""partial index on active auth_sessions

Revision ID: 0004_partial_idx_active_sess
Revises: 0003_add_apple_sub_to_users
Create Date: 2026-07-31 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op


revision: str = "0004_partial_idx_active_sess"
down_revision: Union[str, None] = "0003_add_apple_sub_to_users"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # P2.7: RELEASE_BUILD.md's own performance checklist calls for this —
    # a partial index scoped to active (non-revoked) sessions, since that's
    # the only subset ever queried per-request (refresh/logout look up an
    # active session by token_hash, which already has its own unique index;
    # this partial index instead accelerates any future "list a user's
    # active sessions" lookup and keeps the index small as revoked/expired
    # rows accumulate, since Postgres excludes them from it entirely).
    op.execute(
        "CREATE INDEX ix_auth_sessions_active_by_user "
        "ON auth_sessions (user_id) WHERE revoked_at IS NULL"
    )


def downgrade() -> None:
    op.execute("DROP INDEX ix_auth_sessions_active_by_user")
