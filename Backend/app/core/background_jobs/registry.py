from typing import Callable

# A job handler takes whatever kwargs it needs (db session, payload, etc.)
# and returns a dict that gets stored as the job's `result`.
JobHandler = Callable[..., dict]

# Maps job_type -> handler function.
# This module knows nothing about which domains register handlers here -
# domains import register_handler() and call it themselves at import time.
_HANDLER_REGISTRY: dict[str, JobHandler] = {}


def register_handler(job_type: str, handler: JobHandler) -> None:
    # Fail loudly on duplicate registration instead of silently overwriting -
    # a duplicate job_type usually means a naming collision or accidental
    # double-import, and silently swallowing it would hide a real bug.
    if job_type in _HANDLER_REGISTRY:
        raise ValueError(f"Handler already registered for job_type: {job_type}")

    _HANDLER_REGISTRY[job_type] = handler


def get_handler(job_type: str) -> JobHandler | None:
    # Returns None (not an exception) when nothing is registered -
    # the caller (worker.py) decides how to treat an unknown job_type
    # (e.g. mark the job as failed) rather than this module deciding for it.
    return _HANDLER_REGISTRY.get(job_type)