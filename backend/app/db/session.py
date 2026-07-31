from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

# P2.7 fix: explicit, documented pool bounds instead of relying on
# SQLAlchemy's untuned defaults (pool_size=5, max_overflow=10) with no
# rationale for whether that's enough headroom relative to Postgres's
# max_connections and the other processes (celery-worker, celery-beat,
# multiple uvicorn workers) that each open their own pool against the same
# database. See db_pool_size/db_max_overflow/db_pool_timeout_seconds in
# app/core/config.py and backend/PERFORMANCE_NOTES.md.
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_size=settings.db_pool_size,
    max_overflow=settings.db_max_overflow,
    pool_timeout=settings.db_pool_timeout_seconds,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
