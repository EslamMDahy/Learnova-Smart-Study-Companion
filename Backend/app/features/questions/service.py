from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
import json

from .schemas import QuestionCreateRequest
from .helpers import validate_and_normalize_question_payload


def create_question(*, course_id: int, payload: QuestionCreateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create questions")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    topic_id = payload.topic_id
    if not topic_id or topic_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid topic_id")

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
            detail="You can only create questions for your own course"
        )

    # =========================
    # 3) Validate topic belongs to same course
    # =========================
    topic_row = db.execute(
        text("""
            SELECT
                t.id,
                mo.course_id
            FROM topics t
            JOIN materials m
              ON m.id = t.material_id
            JOIN modules mo
              ON mo.id = m.module_id
            WHERE t.id = :topic_id
            LIMIT 1
        """),
        {"topic_id": topic_id},
    ).mappings().first()

    if not topic_row:
        raise HTTPException(status_code=404, detail="Topic not found")

    if int(topic_row["course_id"]) != int(course_id):
        raise HTTPException(status_code=400, detail="Topic does not belong to this course")

    # =========================
    # 4) Type-specific validation + normalization
    # =========================
    validation_result = validate_and_normalize_question_payload(payload)
    if not validation_result["ok"]:
        raise HTTPException(
            status_code=validation_result["status_code"],
            detail=validation_result["detail"]
        )

    normalized_data = validation_result["data"]

    # =========================
    # 5) Insert question
    # =========================
    try:
        question_row = db.execute(
            text("""
                INSERT INTO questions (
                    course_id,
                    topic_id,
                    question_text,
                    explanation,
                    options,
                    type,
                    difficulty,
                    source,
                    approval_status,
                    expected_answer,
                    grading_rubric,
                    max_score,
                    auto_gradable,
                    usage_count,
                    success_rate,
                    average_time_seconds,
                    tags,
                    created_by,
                    created_at,
                    updated_at
                )
                VALUES (
                    :course_id,
                    :topic_id,
                    :question_text,
                    :explanation,
                    CAST(:options AS JSONB),
                    :type,
                    :difficulty,
                    :source,
                    :approval_status,
                    CAST(:expected_answer AS JSONB),
                    CAST(:grading_rubric AS JSONB),
                    :max_score,
                    :auto_gradable,
                    :usage_count,
                    :success_rate,
                    :average_time_seconds,
                    CAST(:tags AS JSONB),
                    :created_by,
                    NOW(),
                    NOW()
                )
                RETURNING
                    id,
                    course_id,
                    topic_id,
                    question_text,
                    explanation,
                    options,
                    type,
                    difficulty,
                    source,
                    approval_status,
                    expected_answer,
                    grading_rubric,
                    max_score,
                    auto_gradable,
                    usage_count,
                    success_rate,
                    average_time_seconds,
                    tags,
                    created_by,
                    created_at,
                    updated_at
            """),
            {
                "course_id": course_id,
                "topic_id": topic_id,
                "question_text": normalized_data["question_text"],
                "explanation": normalized_data["explanation"],
                "options": json.dumps(normalized_data["options"]),
                "type": normalized_data["type"],
                "difficulty": normalized_data["difficulty"],
                "source": normalized_data["source"],
                "approval_status": normalized_data["approval_status"],
                "expected_answer": json.dumps(normalized_data["expected_answer"]),
                "grading_rubric": (
                    json.dumps(normalized_data["grading_rubric"])
                    if normalized_data["grading_rubric"] is not None else None
                ),
                "max_score": normalized_data["max_score"],
                "auto_gradable": normalized_data["auto_gradable"],
                "usage_count": normalized_data["usage_count"],
                "success_rate": normalized_data["success_rate"],
                "average_time_seconds": normalized_data["average_time_seconds"],
                "tags": (
                    json.dumps(normalized_data["tags"])
                    if normalized_data["tags"] is not None else None
                ),
                "created_by": instructor_id,
            },
        ).mappings().first()

        if not question_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to create question")

        db.commit()
        return dict(question_row)

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while creating question") from e

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e