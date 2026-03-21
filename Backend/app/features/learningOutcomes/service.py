from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from .schemas import LearningOutcomeCreateRequest


def create_learning_outcome(*, course_id: int, payload: LearningOutcomeCreateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create learning outcomes")

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

    if int(course_row["created_by"]) != int(instructor_id):
        raise HTTPException(
            status_code=403,
            detail="You can only create learning outcomes for your own course"
        )

    # =========================
    # 3) Prepare fields
    # =========================
    title = (payload.title or "").strip()
    if not title:
        raise HTTPException(status_code=422, detail="title is required")

    description = payload.description
    if isinstance(description, str):
        description = description.strip() or None

    level = (payload.level or "").strip()
    if not level:
        raise HTTPException(status_code=422, detail="level is required")

    topic_ids = payload.topic_ids or []

    # remove duplicates while preserving order
    seen = set()
    normalized_topic_ids = []
    for topic_id in topic_ids:
        if not isinstance(topic_id, int) or topic_id <= 0:
            raise HTTPException(status_code=422, detail="topic_ids must contain valid positive integers")
        if topic_id not in seen:
            seen.add(topic_id)
            normalized_topic_ids.append(topic_id)

    # =========================
    # 4) Validate topics belong to same course
    # =========================
    if normalized_topic_ids:
        topic_rows = db.execute(
            text("""
                SELECT
                    t.id,
                    m.module_id,
                    mo.course_id
                FROM topics t
                JOIN materials m
                  ON m.id = t.material_id
                JOIN modules mo
                  ON mo.id = m.module_id
                WHERE t.id = ANY(:topic_ids)
            """),
            {"topic_ids": normalized_topic_ids},
        ).mappings().all()

        if len(topic_rows) != len(normalized_topic_ids):
            raise HTTPException(status_code=404, detail="One or more topics were not found")

        for row in topic_rows:
            if int(row["course_id"]) != int(course_id):
                raise HTTPException(
                    status_code=400,
                    detail="All topics must belong to the same course"
                )

    # =========================
    # 5) Insert learning outcome
    # =========================
    try:
        learning_outcome_row = db.execute(
            text("""
                INSERT INTO learning_outcomes (
                    course_id,
                    title,
                    description,
                    level,
                    is_ai_generated,
                    is_reviewed,
                    created_at,
                    updated_at
                )
                VALUES (
                    :course_id,
                    :title,
                    :description,
                    :level,
                    :is_ai_generated,
                    :is_reviewed,
                    NOW(),
                    NOW()
                )
                RETURNING
                    id,
                    course_id,
                    title,
                    description,
                    level,
                    is_ai_generated,
                    is_reviewed,
                    created_at,
                    updated_at
            """),
            {
                "course_id": course_id,
                "title": title,
                "description": description,
                "level": level,
                "is_ai_generated": False,
                "is_reviewed": True,
            },
        ).mappings().first()

        if not learning_outcome_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to create learning outcome")

        learning_outcome_id = int(learning_outcome_row["id"])

        # =========================
        # 6) Insert topic relations (optional)
        # =========================
        if normalized_topic_ids:
            for topic_id in normalized_topic_ids:
                db.execute(
                    text("""
                        INSERT INTO topic_learning_outcomes (
                            topic_id,
                            learning_outcome_id,
                            created_at
                        )
                        VALUES (
                            :topic_id,
                            :learning_outcome_id,
                            NOW()
                        )
                    """),
                    {
                        "topic_id": topic_id,
                        "learning_outcome_id": learning_outcome_id,
                    },
                )

        db.commit()
        return dict(learning_outcome_row)

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while creating learning outcome") from e

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e
    

