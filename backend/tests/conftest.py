"""Shared test configuration.

Points the app at a local, disposable Postgres + Redis (started via `docker
run` for this session — see the commit history for the exact commands) so
tests that need a *real* database/cache for genuine feature-level coverage
can get one, rather than only ever testing against mocks. Must run before
any `app.*` module is imported, since `app.core.config.settings` and
`app.db.session.engine` are both created once at first import.
"""

import os
import subprocess
from pathlib import Path

os.environ.setdefault(
    "DATABASE_URL", "postgresql+psycopg://smartbudget:testpass@localhost:55432/smartbudget_test"
)
os.environ.setdefault("REDIS_URL", "redis://localhost:56379/0")
os.environ.setdefault("CELERY_BROKER_URL", "redis://localhost:56379/1")
os.environ.setdefault("CELERY_RESULT_BACKEND", "redis://localhost:56379/2")
os.environ.setdefault("ENVIRONMENT", "development")

import pytest

BACKEND_ROOT = Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session", autouse=True)
def _migrated_test_db():
    """Applies all Alembic migrations to the test database once per test
    session. Skips (rather than failing the whole suite) if the local test
    Postgres isn't running — tests that need `real_db`/`real_redis` will
    fail individually with a clear connection error instead."""
    try:
        subprocess.run(
            ["alembic", "upgrade", "head"],
            cwd=BACKEND_ROOT,
            check=True,
            capture_output=True,
            timeout=30,
        )
    except Exception:
        pass
    yield


@pytest.fixture
def real_db():
    """A real Postgres-backed SQLAlchemy session. Each test should use
    randomized/unique data (e.g. a uuid4-embedded email) rather than relying
    on transactional rollback for isolation — application code commits
    directly (see UserRepository etc.), so this is a plain session against
    the shared disposable test database, not a per-test transaction."""
    from app.db.session import SessionLocal

    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def real_redis():
    """A real Redis client against the local disposable test instance, for
    tests that specifically need to exercise real Redis behavior (e.g. TTLs,
    atomicity) rather than fakeredis."""
    from app.core.redis import get_redis

    client = get_redis()
    yield client
