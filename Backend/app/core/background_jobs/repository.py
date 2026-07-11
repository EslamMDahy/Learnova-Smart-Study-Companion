from __future__ import annotations

import uuid

from sqlalchemy import text, bindparam
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session


class DuplicateActiveJobError(Exception):
    pass


def create_job(
    *,
    db: Session,
    job_type: str,
    payload: dict,
    requested_by: int | None,
) -> uuid.UUID:
    job_id = uuid.uuid4()

    try:
        db.execute(
            text(
                """
                INSERT INTO background_jobs (id, job_type, status, payload, requested_by, created_at)
                VALUES (:id, :job_type, 'pending', :payload, :requested_by, now())
                """
            ).bindparams(bindparam("payload", type_=JSONB)),
            {
                "id": job_id,
                "job_type": job_type,
                "payload": payload,
                "requested_by": requested_by,
            },
        )
        db.commit()

    except IntegrityError as e:
        db.rollback()
        raise DuplicateActiveJobError() from e

    return job_id


def get_job_by_id(
    *,
    db: Session,
    job_id: uuid.UUID,
) -> dict | None:
    row = db.execute(
        text(
            """
            SELECT id, job_type, status, payload, result, error_message,
                   requested_by, created_at, started_at, completed_at
            FROM background_jobs
            WHERE id = :job_id
            """
        ),
        {"job_id": job_id},
    ).mappings().one_or_none()

    return dict(row) if row else None


def claim_pending_batch(
    *,
    db: Session,
    limit: int,
) -> list[dict]:
    rows = db.execute(
        text(
            """
            UPDATE background_jobs
            SET status = 'processing', started_at = now()
            WHERE id IN (
                SELECT id
                FROM background_jobs
                WHERE status = 'pending'
                ORDER BY created_at
                LIMIT :limit
                FOR UPDATE SKIP LOCKED
            )
            RETURNING id, job_type, status, payload, requested_by, created_at, started_at
            """
        ),
        {"limit": limit},
    ).mappings().all()

    db.commit()
    return [dict(r) for r in rows]


def mark_completed(
    *,
    db: Session,
    job_id: uuid.UUID,
    result: dict,
) -> None:
    db.execute(
        text(
            """
            UPDATE background_jobs
            SET status = 'completed', result = :result, completed_at = now()
            WHERE id = :job_id
            """
        ).bindparams(bindparam("result", type_=JSONB)),
        {"job_id": job_id, "result": result},
    )
    db.commit()


def mark_failed(
    *,
    db: Session,
    job_id: uuid.UUID,
    error_message: str,
) -> None:
    db.execute(
        text(
            """
            UPDATE background_jobs
            SET status = 'failed', error_message = :error_message, completed_at = now()
            WHERE id = :job_id
            """
        ),
        {"job_id": job_id, "error_message": error_message},
    )
    db.commit()