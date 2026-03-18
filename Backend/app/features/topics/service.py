from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from .schemas import TopicCreateRequest


def create_topic(*, course_id: int, module_id: int, material_id: int, payload: TopicCreateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create topics")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not module_id or module_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid module_id")

    if not material_id or material_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid material_id")

    # =========================
    # 2) Validate material -> module -> course + ownership
    # =========================
    material_row = db.execute(
        text("""
            SELECT
                m.id AS material_id,
                m.module_id,
                mo.course_id,
                c.created_by
            FROM materials m
            JOIN modules mo
              ON mo.id = m.module_id
            JOIN courses c
              ON c.id = mo.course_id
            WHERE m.id = :material_id
            LIMIT 1
        """),
        {"material_id": material_id},
    ).mappings().first()

    if not material_row:
        raise HTTPException(status_code=404, detail="Material not found")

    if int(material_row["module_id"]) != int(module_id):
        raise HTTPException(status_code=400, detail="Material does not belong to this module")

    if int(material_row["course_id"]) != int(course_id):
        raise HTTPException(status_code=400, detail="Material does not belong to this course")

    if int(material_row["created_by"]) != int(instructor_id):
        raise HTTPException(status_code=403, detail="You can only manage topics for your own course")

    # =========================
    # 3) Prepare fields
    # =========================
    title = (payload.title or "").strip()
    if not title:
        raise HTTPException(status_code=422, detail="title is required")

    description = payload.description
    if isinstance(description, str):
        description = description.strip() or None

    parent_topic_id = payload.parent_topic_id
    learning_outcome_ids = payload.learning_outcome_ids or []

    # remove duplicates while preserving order
    seen = set()
    normalized_learning_outcome_ids = []
    for lo_id in learning_outcome_ids:
        if not isinstance(lo_id, int) or lo_id <= 0:
            raise HTTPException(status_code=422, detail="learning_outcome_ids must contain valid positive integers")
        if lo_id not in seen:
            seen.add(lo_id)
            normalized_learning_outcome_ids.append(lo_id)

    # =========================
    # 4) Validate parent_topic_id (if provided)
    # =========================
    if parent_topic_id is not None:
        parent_row = db.execute(
            text("""
                SELECT id, material_id
                FROM topics
                WHERE id = :parent_topic_id
                LIMIT 1
            """),
            {"parent_topic_id": parent_topic_id},
        ).mappings().first()

        if not parent_row:
            raise HTTPException(status_code=404, detail="Parent topic not found")

        if int(parent_row["material_id"]) != int(material_id):
            raise HTTPException(status_code=400, detail="Parent topic must belong to the same material")

    # =========================
    # 5) Validate learning outcomes belong to same course
    # =========================
    if normalized_learning_outcome_ids:
        lo_rows = db.execute(
            text("""
                SELECT id, course_id
                FROM learning_outcomes
                WHERE id = ANY(:learning_outcome_ids)
            """),
            {"learning_outcome_ids": normalized_learning_outcome_ids},
        ).mappings().all()

        if len(lo_rows) != len(normalized_learning_outcome_ids):
            raise HTTPException(status_code=404, detail="One or more learning outcomes were not found")

        for row in lo_rows:
            if int(row["course_id"]) != int(course_id):
                raise HTTPException(
                    status_code=400,
                    detail="All learning outcomes must belong to the same course"
                )

    # =========================
    # 6) Compute order_index inside same material
    # =========================
    next_order_index = db.execute(
        text("""
            SELECT COALESCE(MAX(order_index), -1) + 1 AS next_idx
            FROM topics
            WHERE material_id = :material_id
        """),
        {"material_id": material_id},
    ).scalar()

    if next_order_index is None:
        next_order_index = 0

    # =========================
    # 7) Insert topic
    # =========================
    try:
        topic_row = db.execute(
            text("""
                INSERT INTO topics (
                    material_id,
                    title,
                    description,
                    order_index,
                    parent_topic_id,
                    is_ai_generated,
                    is_reviewed,
                    created_at,
                    updated_at
                )
                VALUES (
                    :material_id,
                    :title,
                    :description,
                    :order_index,
                    :parent_topic_id,
                    :is_ai_generated,
                    :is_reviewed,
                    NOW(),
                    NOW()
                )
                RETURNING
                    id,
                    material_id,
                    title,
                    description,
                    order_index,
                    parent_topic_id,
                    is_ai_generated,
                    is_reviewed,
                    created_at,
                    updated_at
            """),
            {
                "material_id": material_id,
                "title": title,
                "description": description,
                "order_index": int(next_order_index),
                "parent_topic_id": parent_topic_id,
                "is_ai_generated": False,
                "is_reviewed": True,
            },
        ).mappings().first()

        if not topic_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to create topic")

        topic_id = int(topic_row["id"])

        # =========================
        # 8) Insert topic-learning_outcome relations (optional)
        # =========================
        if normalized_learning_outcome_ids:
            for lo_id in normalized_learning_outcome_ids:
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
                        "learning_outcome_id": lo_id,
                    },
                )

        db.commit()
        return dict(topic_row)

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while creating topic") from e

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e
    


def list_material_topics(*, course_id: int, module_id: int, material_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authentication
    # =========================
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not module_id or module_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid module_id")

    if not material_id or material_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid material_id")

    role = (current_user.get("system_role") or "").strip().lower()

    try:
        # =========================
        # 2) Validate material -> module -> course
        # =========================
        material_row = db.execute(
            text("""
                SELECT
                    m.id AS material_id,
                    m.module_id,
                    mo.course_id,
                    c.created_by
                FROM materials m
                JOIN modules mo
                  ON mo.id = m.module_id
                JOIN courses c
                  ON c.id = mo.course_id
                WHERE m.id = :material_id
                LIMIT 1
            """),
            {"material_id": material_id},
        ).mappings().first()

        if not material_row:
            raise HTTPException(status_code=404, detail="Material not found")

        if int(material_row["module_id"]) != int(module_id):
            raise HTTPException(status_code=400, detail="Material does not belong to this module")

        if int(material_row["course_id"]) != int(course_id):
            raise HTTPException(status_code=400, detail="Material does not belong to this course")

        # =========================
        # 3) Authorization
        # =========================
        if role == "instructor":
            if int(material_row["created_by"]) != int(user_id):
                raise HTTPException(
                    status_code=403,
                    detail="You can only view topics for your own course"
                )

        elif role == "student":
            enrollment_row = db.execute(
                text("""
                    SELECT 1
                    FROM course_enrollments
                    WHERE course_id = :course_id
                      AND student_id = :student_id
                      AND status IN ('active', 'completed')
                    LIMIT 1
                """),
                {
                    "course_id": course_id,
                    "student_id": user_id,
                },
            ).first()

            if not enrollment_row:
                raise HTTPException(
                    status_code=403,
                    detail="You are not allowed to access topics for this course"
                )

        else:
            raise HTTPException(status_code=403, detail="Access denied")

        # =========================
        # 4) Fetch all topics for this material
        # =========================
        topic_rows = db.execute(
            text("""
                SELECT
                    id,
                    material_id,
                    title,
                    description,
                    order_index,
                    parent_topic_id,
                    is_ai_generated,
                    is_reviewed,
                    created_at,
                    updated_at
                FROM topics
                WHERE material_id = :material_id
                ORDER BY order_index ASC, id ASC
            """),
            {"material_id": material_id},
        ).mappings().all()

        return {
            "course_id": course_id,
            "module_id": module_id,
            "material_id": material_id,
            "topics": [dict(row) for row in topic_rows],
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e