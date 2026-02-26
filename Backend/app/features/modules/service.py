from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from datetime import datetime, timezone

from .schemas import ModuleCreateRequest


def create_module(*, course_id: int, payload: ModuleCreateRequest, db: Session, current_user: dict):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create modules")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    # =========================
    # 2) Validate course exists + ownership
    # =========================
    course_row = db.execute(
        text("""
            SELECT id, created_by
            FROM courses
            WHERE id = :course_id
            LIMIT 1
        """),
        {"course_id": course_id},
    ).mappings().first()

    if not course_row:
        raise HTTPException(status_code=404, detail="Course not found")

    if course_row["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only manage modules for your own course")

    # =========================
    # 3) Prepare fields
    # =========================
    title = (payload.title or "").strip()
    if not title:
        raise HTTPException(status_code=422, detail="title is required")

    description = payload.description
    if isinstance(description, str):
        description = description.strip() or None

    # if omitted => default False (MVP-friendly)
    is_published = bool(payload.is_published) if payload.is_published is not None else False

    # published_at only when published
    published_at = datetime.now(timezone.utc) if is_published else None

    # =========================
    # 4) Compute order_index (append)
    #    COALESCE(MAX, -1) + 1 => 0 when empty
    # =========================
    next_order_index = db.execute(
        text("""
            SELECT COALESCE(MAX(order_index), -1) + 1 AS next_idx
            FROM modules
            WHERE course_id = :course_id
        """),
        {"course_id": course_id},
    ).scalar()

    if next_order_index is None:
        next_order_index = 0

    # =========================
    # 5) Insert module
    # =========================
    try:
        row = db.execute(
            text("""
                INSERT INTO modules (
                    course_id,
                    title,
                    description,
                    order_index,
                    is_published,
                    published_at,
                    created_at,
                    updated_at
                )
                VALUES (
                    :course_id,
                    :title,
                    :description,
                    :order_index,
                    :is_published,
                    :published_at,
                    NOW(),
                    NOW()
                )
                RETURNING
                    id,
                    course_id,
                    title,
                    description,
                    order_index,
                    is_published,
                    created_at,
                    updated_at
            """),
            {
                "course_id": course_id,
                "title": title,
                "description": description,
                "order_index": int(next_order_index),
                "is_published": is_published,
                "published_at": published_at,
            },
        ).mappings().first()

        if not row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to create module")

        db.commit()
        return dict(row)

    except IntegrityError as e:
        db.rollback()
        # مثال: unique constraint على (course_id, order_index) لو حصل concurrency
        raise HTTPException(status_code=409, detail="Conflict while creating module") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e