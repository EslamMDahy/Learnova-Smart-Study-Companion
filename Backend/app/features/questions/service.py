# app/features/questions/service.py

from datetime import datetime, timezone
import json
from typing import Dict, Any, List

from fastapi import HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session


def create_material_questions_batch(*, course_id: int, module_id: int, material_id: int, 
                                    payload, db: Session, current_user: Dict[str, Any],):
    """
    Create a batch of manual MCQ questions for a specific material.

    Authorization:
      - Only the course owner (courses.created_by) can create questions (for now).

    Validations:
      - course exists and owned by current user
      - module belongs to course
      - material belongs to module

    Inserts:
      - one row per question into questions table
      - options stored as JSONB
      - expected_answer stored as choice id string (e.g. "B")
    """

    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    # -------------------------
    # 1) Validate course ownership
    # -------------------------
    course_owner = db.execute(
        text("""
            SELECT created_by
            FROM courses
            WHERE id = :cid
        """),
        {"cid": course_id},
    ).scalar()

    if course_owner is None:
        raise HTTPException(status_code=404, detail="Course not found")

    if int(course_owner) != int(user_id):
        raise HTTPException(status_code=403, detail="Not allowed to add questions to this course")

    # -------------------------
    # 2) Validate module belongs to course
    # -------------------------
    mod_exists = db.execute(
        text("""
            SELECT 1
            FROM modules
            WHERE id = :mid AND course_id = :cid
        """),
        {"mid": module_id, "cid": course_id},
    ).first()

    if not mod_exists:
        raise HTTPException(status_code=404, detail="Module not found for this course")

    # -------------------------
    # 3) Validate material belongs to module
    # -------------------------
    mat_exists = db.execute(
        text("""
            SELECT 1
            FROM materials
            WHERE id = :mat_id AND module_id = :mid
        """),
        {"mat_id": material_id, "mid": module_id},
    ).first()

    if not mat_exists:
        raise HTTPException(status_code=404, detail="Material not found for this module")

    # -------------------------
    # 4) Prepare batch insert
    # -------------------------
    questions = getattr(payload, "questions", None)
    if not questions:
        raise HTTPException(status_code=400, detail="questions list is required")

    # Defaults (as per your enums)
    default_type = "multiple_choice"
    default_source = "manual"
    default_approval = "approved"
    default_difficulty = "medium"
    default_max_score = 1
    default_auto_gradable = True

    created_items: List[Dict[str, Any]] = []

    try:
        # We do everything in one transaction
        for q in questions:
            question_text = (getattr(q, "question_text", None) or "").strip()
            if not question_text:
                raise HTTPException(status_code=400, detail="Each question must have question_text")

            options_obj = getattr(q, "options", None)
            if options_obj is None:
                raise HTTPException(status_code=400, detail="Each question must have options")

            expected_answer = (getattr(q, "expected_answer", None) or "").strip()
            if not expected_answer:
                raise HTTPException(status_code=400, detail="Each question must have expected_answer (choice id)")

            explanation = getattr(q, "explanation", None)

            # optional overrides
            difficulty = getattr(q, "difficulty", None) or default_difficulty
            max_score = getattr(q, "max_score", None) or default_max_score

            # Convert Pydantic models to dict for JSONB insert
            # (options_obj is MCQOptions schema)
            if hasattr(options_obj, "model_dump"):
                options_json = options_obj.model_dump()
            elif hasattr(options_obj, "dict"):
                options_json = options_obj.dict()
            else:
                options_json = options_obj  # assume it's already dict

            # Minimal validation of choices
            choices = options_json.get("choices") if isinstance(options_json, dict) else None
            if not isinstance(choices, list) or len(choices) < 2:
                raise HTTPException(status_code=400, detail="options.choices must be a list with at least 2 items")

            # Ensure expected_answer is one of choice ids
            choice_ids = []
            for c in choices:
                if isinstance(c, dict):
                    cid = (c.get("id") or "").strip()
                else:
                    cid = (getattr(c, "id", None) or "").strip()
                if cid:
                    choice_ids.append(cid)

            if expected_answer not in choice_ids:
                raise HTTPException(
                    status_code=400,
                    detail=f"expected_answer must match one of option ids: {choice_ids}",
                )

            row = db.execute(
                text("""
                    INSERT INTO questions (
                        course_id,
                        module_id,
                        material_id,
                        topic_id,
                        video_timestamp_id,
                        question_text,
                        explanation,
                        options,
                        type,
                        difficulty,
                        source,
                        approval_status,
                        reviewed_by,
                        reviewed_at,
                        review_notes,
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
                        :module_id,
                        :material_id,
                        NULL,
                        NULL,
                        :question_text,
                        :explanation,
                        CAST(:options AS jsonb),
                        CAST(:type AS question_type_enum),
                        CAST(:difficulty AS question_difficulty_enum),
                        CAST(:source AS question_source_enum),
                        CAST(:approval_status AS question_approval_status_enum),
                        NULL,
                        NULL,
                        NULL,
                        :expected_answer,
                        NULL,
                        :max_score,
                        :auto_gradable,
                        0,
                        NULL,
                        NULL,
                        NULL,
                        :created_by,
                        NOW(),
                        NOW()
                    )
                    RETURNING id, question_text, created_at
                """),
                {
                    "course_id": course_id,
                    "module_id": module_id,
                    "material_id": material_id,
                    "question_text": question_text,
                    "explanation": explanation,
                    "options": json.dumps(options_json),  # JSONB
                    "type": default_type,
                    "difficulty": difficulty,
                    "source": default_source,
                    "approval_status": default_approval,
                    "expected_answer": expected_answer,
                    "max_score": int(max_score),
                    "auto_gradable": bool(default_auto_gradable),
                    "created_by": user_id,
                },
            ).first()

            if not row:
                raise HTTPException(status_code=500, detail="Failed to insert question")
            
            created_items.append(
                {
                    "id": row[0],
                    "question_text": row[1],
                    "created_at": row[2].isoformat() if row[2] else datetime.now(timezone.utc).isoformat(),
                }
            )

        db.commit()

    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        # keep it not too verbose for client, but useful
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    return {
        "course_id": course_id,
        "module_id": module_id,
        "material_id": material_id,
        "created_count": len(created_items),
        "questions": created_items,
    }