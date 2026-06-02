import os
import sys

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import NullPool
from .config import settings


def _is_celery_process() -> bool:
    """
    Celery workers fork, so a shared connection pool would hand the same TCP
    socket to multiple processes — hence NullPool there. The web (uvicorn)
    process is long-lived and MUST pool, otherwise every request opens and
    tears down a fresh Postgres connection and exhausts Neon's limit.

    Detection: explicit DB_POOL_MODE override, else the launching argv
    (worker/beat both run via the `celery` entrypoint).
    """
    override = os.getenv("DB_POOL_MODE")
    if override:
        return override.lower() == "nullpool"
    argv0 = os.path.basename(sys.argv[0]) if sys.argv else ""
    return "celery" in argv0 or "celery" in sys.argv


if _is_celery_process():
    # Forked Celery workers: no shared pool.
    engine = create_async_engine(
        settings.database_url,
        echo=False,
        poolclass=NullPool,
    )
else:
    # Long-lived web process: real pool with liveness checks suited to Neon,
    # which closes idle server connections.
    engine = create_async_engine(
        settings.database_url,
        echo=settings.environment == "development",
        pool_size=10,
        max_overflow=10,
        pool_pre_ping=True,   # discard connections Neon dropped while idle
        pool_recycle=1800,    # proactively recycle before the idle timeout
    )

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
