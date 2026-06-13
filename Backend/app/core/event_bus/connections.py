import asyncpg
from app.core.config import settings

# =========================
# 1) Module-level connection pool
# =========================
_pool: asyncpg.Pool | None = None


# =========================
# 2) Pool lifecycle
# =========================
async def init_event_bus() -> None:
    global _pool
    _pool = await asyncpg.create_pool(
        dsn=settings.database_url,
        min_size=1,
        max_size=5,
    )


async def close_event_bus() -> None:
    global _pool
    if _pool:
        await _pool.close()
        _pool = None


# =========================
# 3) Pool accessor
# =========================
def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("Event bus pool is not initialized. Call init_event_bus() on startup.")
    return _pool