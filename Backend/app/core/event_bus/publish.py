import asyncpg
import psycopg
from app.core.config import settings
from app.core.event_bus.connections import get_pool


# =========================
# 1) Publish event to channel
# =========================
async def publish(*, channel: str, payload: str = "") -> None:
    pool: asyncpg.Pool = get_pool()
    async with pool.acquire() as connection:
        await connection.execute("SELECT pg_notify($1, $2)", channel, payload)


# =========================
# 2) Sync publish event to channel
# =========================
def publish_sync(*, channel: str, payload: str = "") -> None:
    with psycopg.connect(settings.database_url) as conn:
        conn.execute("SELECT pg_notify(%s, %s)", (channel, payload))
        conn.commit()