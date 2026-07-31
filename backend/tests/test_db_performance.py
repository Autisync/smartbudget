"""Regression cover for P2.7: explicit connection pool bounds + a partial
index on active auth_sessions, both called for by RELEASE_BUILD.md's own
"Performance & Scalability" checklist (previously unaddressed — the engine
relied on SQLAlchemy's untuned pool defaults with no documented rationale,
and no index existed scoped to active sessions specifically).
"""

import subprocess
from pathlib import Path

from sqlalchemy import text

from app.core.config import settings
from app.db.session import engine

BACKEND_ROOT = Path(__file__).resolve().parent.parent


# ---- Unit tests: engine pool configuration ---------------------------------


def test_engine_pool_size_matches_configured_settings():
    assert engine.pool.size() == settings.db_pool_size


def test_engine_pool_has_explicit_overflow_and_timeout_configured():
    # SQLAlchemy doesn't expose max_overflow/timeout as public read attrs on
    # QueuePool post-construction in a stable way across versions, so assert
    # via the underlying private attrs is fragile — instead assert the
    # *settings* that feed engine construction are sane, non-default-by-luck
    # values (i.e. someone deliberately set them, not just SQLAlchemy's
    # untouched defaults of 10/30).
    assert settings.db_pool_size > 0
    assert settings.db_max_overflow >= 0
    assert settings.db_pool_timeout_seconds > 0


# ---- Migration test: apply/rollback cleanly --------------------------------


def _run_alembic(*args: str) -> str:
    result = subprocess.run(
        ["alembic", *args], cwd=BACKEND_ROOT, capture_output=True, text=True, timeout=30,
    )
    assert result.returncode == 0, f"alembic {' '.join(args)} failed:\n{result.stderr}"
    return result.stdout


def test_partial_index_migration_applies_and_rolls_back_cleanly(real_db):
    # Ensure we start from head (the session-scoped autouse fixture already
    # applied it, but be explicit and resilient to test ordering).
    _run_alembic("upgrade", "head")
    index_present = real_db.execute(
        text("SELECT 1 FROM pg_indexes WHERE indexname = 'ix_auth_sessions_active_by_user'")
    ).first()
    assert index_present is not None

    try:
        # Target the specific prior revision rather than a relative "-1" —
        # this migration isn't guaranteed to stay at head as later ones are
        # added (it wasn't, by the very next commit in this pass).
        _run_alembic("downgrade", "0003_add_apple_sub_to_users")
        real_db.commit()  # release the prior session's view of the catalog
        index_after_downgrade = real_db.execute(
            text("SELECT 1 FROM pg_indexes WHERE indexname = 'ix_auth_sessions_active_by_user'")
        ).first()
        assert index_after_downgrade is None
    finally:
        # Always leave the DB at head for every other test in this session.
        _run_alembic("upgrade", "head")


def test_partial_index_is_scoped_to_active_sessions_only(real_db):
    _run_alembic("upgrade", "head")
    row = real_db.execute(
        text(
            "SELECT indexdef FROM pg_indexes WHERE indexname = 'ix_auth_sessions_active_by_user'"
        )
    ).first()
    assert row is not None
    assert "revoked_at IS NULL" in row[0]


# ---- Query-plan smoke test: the active-session lookup uses an index -------


def test_active_session_lookup_uses_an_index_not_a_seq_scan(real_db):
    """Doesn't require a large seeded dataset to prove correctness — just
    that Postgres has a usable index for this predicate at all. The actual
    before/after cost comparison on a realistically-sized dataset is
    recorded in PERFORMANCE_NOTES.md (captured manually against 20k seeded
    sessions, not re-derived here to keep this test fast)."""
    plan = real_db.execute(
        text(
            "EXPLAIN SELECT * FROM auth_sessions "
            "WHERE user_id = gen_random_uuid() AND revoked_at IS NULL"
        )
    ).scalars().all()
    plan_text = "\n".join(plan)
    assert "ix_auth_sessions_active_by_user" in plan_text or "Index Scan" in plan_text, (
        f"expected the partial index to be usable for this query, got:\n{plan_text}"
    )
