import asyncio
import logging

from app.db.session import SessionLocal
from app.core.event_bus.publish import publish_sync
from app.core.background_jobs.repository import claim_pending_batch, mark_completed, mark_failed
from app.core.background_jobs.registry import get_handler

logger = logging.getLogger(__name__)

POLL_INTERVAL_SECONDS = 2
BATCH_SIZE = 5


async def job_worker_loop() -> None:
    # Runs forever as an asyncio background task, started once at app startup
    # (via asyncio.create_task, next to init_event_bus() in main.py).
    # This loop is the only place tying the generic job-queue infrastructure
    # to actual execution - it knows nothing about what any handler does,
    # it only knows how to claim a job, run its handler, and record the outcome.
    while True:
        try:
            await _run_one_cycle()
        except Exception:
            # A failure in the polling cycle itself (not a single job) must not
            # kill the loop - log it and keep the worker alive for the next tick.
            logger.exception("background_jobs worker cycle failed")

        await asyncio.sleep(POLL_INTERVAL_SECONDS)


async def _run_one_cycle() -> None:
    # Short-lived session just for claiming a batch - closed immediately,
    # not held open during the (potentially slow) job execution below.
    claim_db = SessionLocal()
    try:
        jobs = claim_pending_batch(db=claim_db, limit=BATCH_SIZE)
    finally:
        claim_db.close()

    if not jobs:
        return

    # Process the claimed batch concurrently - each job gets its own thread
    # (via asyncio.to_thread) and its own DB session, since sync handlers and
    # SQLAlchemy Sessions are not safe to share across concurrent execution.
    await asyncio.gather(*(_run_job(job) for job in jobs))


async def _run_job(job: dict) -> None:
    job_id = job["id"]
    job_type = job["job_type"]

    try:
        handler = get_handler(job_type)

        if handler is None:
            db = SessionLocal()
            try:
                mark_failed(
                    db=db,
                    job_id=job_id,
                    error_message=f"No handler registered for job_type: {job_type}",
                )
            finally:
                db.close()
            return

        db = SessionLocal()
        try:
            result = await asyncio.to_thread(handler, db=db, payload=job["payload"])
            mark_completed(db=db, job_id=job_id, result=result)
        except Exception as exc:
            mark_failed(db=db, job_id=job_id, error_message=str(exc))
        finally:
            db.close()

    except Exception:
        # Absolute last resort: something failed even in our own error-handling
        # path above (e.g. DB connectivity itself). Log it, but never let this
        # escape and cancel sibling jobs in the same asyncio.gather batch.
        logger.exception("Unhandled failure while processing job %s", job_id)
        return

    finally:
        publish_sync(channel=f"job_{job_id}", payload="ready")