from __future__ import annotations

from app.core.config import settings


def build_db_url(*, driver: str) -> str:
    _, rest = settings.database_url.split("://", 1)
    return f"{driver}://{rest}"