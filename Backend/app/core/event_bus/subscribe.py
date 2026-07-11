import asyncio
import asyncpg

from contextlib import asynccontextmanager

from app.core.event_bus.connections import get_pool


# =========================
# 1) Subscribe to channel and yield payloads
# =========================
async def subscribe(
    *,
    channel: str,
    timeout: float = 30.0,
):
    pool: asyncpg.Pool = get_pool()
    connection: asyncpg.pool.PoolConnectionProxy = await pool.acquire()

    queue: asyncio.Queue[str] = asyncio.Queue()

    # =========================
    # 2) Register listener
    # =========================
    def listener(*args) -> None:
        queue.put_nowait(args[3])

    await connection.add_listener(channel, listener)

    try:
        # =========================
        # 3) Yield payload until timeout
        # =========================
        payload = await asyncio.wait_for(queue.get(), timeout=timeout)
        yield payload

    except asyncio.TimeoutError:
        yield ""

    finally:
        # =========================
        # 4) Always clean up listener and release connection
        # =========================
        try:
            await connection.remove_listener(channel, listener)
        finally:
            await pool.release(connection)


@asynccontextmanager
async def register_listener(*, channel: str):
    pool: asyncpg.Pool = get_pool()
    connection: asyncpg.pool.PoolConnectionProxy = await pool.acquire()

    queue: asyncio.Queue[str] = asyncio.Queue()

    def listener(*args) -> None:
        queue.put_nowait(args[3])

    await connection.add_listener(channel, listener)

    try:
        yield queue 

    finally:
        try:
            await connection.remove_listener(channel, listener)
        finally:
            await pool.release(connection)


async def wait_for_payload(queue: asyncio.Queue, *, timeout: float = 30.0) -> str:
    try:
        return await asyncio.wait_for(queue.get(), timeout=timeout)
    except asyncio.TimeoutError:
        return ""