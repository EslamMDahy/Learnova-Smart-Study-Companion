import asyncpg
from app.core.event_bus.connections import get_pool


# =========================
# 1) Publish event to channel
# =========================
async def publish(*, channel: str, payload: str = "") -> None:
    pool: asyncpg.Pool = get_pool()
    async with pool.acquire() as connection:
        await connection.execute("SELECT pg_notify($1, $2)", channel, payload)