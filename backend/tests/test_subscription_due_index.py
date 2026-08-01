"""Regression cover for a re-audit finding: check_subscriptions
(app/tasks/finance.py) runs hourly and filters `next_due_on <= today` with
no user_id predicate, but the only existing index on the subscriptions
table is a composite on (user_id, next_due_on) — unusable as a
leading-column filter for this query, forcing a sequential scan of the
whole table every run.
"""

import subprocess
from pathlib import Path

from sqlalchemy import text

BACKEND_ROOT = Path(__file__).resolve().parent.parent


def _run_alembic(*args: str) -> str:
    result = subprocess.run(
        ["alembic", *args], cwd=BACKEND_ROOT, capture_output=True, text=True, timeout=30,
    )
    assert result.returncode == 0, f"alembic {' '.join(args)} failed:\n{result.stderr}"
    return result.stdout


# ---- Migration test: apply/rollback cleanly --------------------------------


def test_subscriptions_next_due_index_migration_applies_and_rolls_back_cleanly(real_db):
    _run_alembic("upgrade", "head")
    index_present = real_db.execute(
        text("SELECT 1 FROM pg_indexes WHERE indexname = 'ix_subscriptions_next_due_on'")
    ).first()
    assert index_present is not None

    try:
        _run_alembic("downgrade", "0005_subscription_last_notified")
        real_db.commit()  # release the prior session's view of the catalog
        index_after_downgrade = real_db.execute(
            text("SELECT 1 FROM pg_indexes WHERE indexname = 'ix_subscriptions_next_due_on'")
        ).first()
        assert index_after_downgrade is None
    finally:
        # Always leave the DB at head for every other test in this session.
        _run_alembic("upgrade", "head")


# ---- Query-plan smoke test: the due-check scan uses an index --------------


def test_due_subscriptions_scan_uses_an_index_not_a_seq_scan(real_db):
    """Forces enable_seqscan off — on the near-empty test DB, Postgres's own
    cost estimate correctly prefers a sequential scan regardless of whether a
    usable index exists (a handful of rows makes an index scan *more*
    expensive), so without this the assertion would be testing table size,
    not whether the index is usable at all. The real before/after cost
    comparison on a realistically-sized dataset belongs in
    PERFORMANCE_NOTES.md, not re-derived here."""
    # SET LOCAL scopes this to the current transaction only, so it can't leak
    # into other tests that reuse this connection from the pool afterward.
    real_db.execute(text("SET LOCAL enable_seqscan = off"))
    plan = real_db.execute(
        text("EXPLAIN SELECT * FROM subscriptions WHERE next_due_on <= CURRENT_DATE")
    ).scalars().all()
    plan_text = "\n".join(plan)
    assert "ix_subscriptions_next_due_on" in plan_text, (
        f"expected the new index to be usable for this query, got:\n{plan_text}"
    )
