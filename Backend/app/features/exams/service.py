from __future__ import annotations

from fastapi import HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from io import BytesIO

from .schemas import (ExamCreateRequest,
                      ExamUpdateRequest,
                      ExamAddQuestionsRequest)

from .helpers import (build_exam_export_context,
                      render_exam_pdf_html,
                      convert_html_to_pdf,)


ALLOWED_EXAM_TYPES = {"quiz", "midterm", "final", "practice"}


def create_exam(*, course_id: int, payload: ExamCreateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=422, detail="Exam title is required")

    exam_type = payload.exam_type.strip().lower()
    if exam_type not in ALLOWED_EXAM_TYPES:
        raise HTTPException(status_code=422, detail="Invalid exam_type")

    if payload.available_from and payload.available_to:
        if payload.available_to <= payload.available_from:
            raise HTTPException(
                status_code=400,
                detail="available_to must be after available_from",
            )

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
            detail="You can only create exams for your own course",
        )

    # =========================
    # 3) Insert exam metadata only
    # =========================
    try:
        exam_row = db.execute(
            text("""
                INSERT INTO exams (
                    course_id,
                    title,
                    description,
                    instructions,
                    exam_type,
                    duration_minutes,
                    max_attempts,
                    passing_score,
                    total_questions,
                    total_score,
                    is_published,
                    is_auto_generated,
                    shuffle_questions,
                    shuffle_options,
                    available_from,
                    available_to,
                    enable_proctoring,
                    prevent_copy_paste,
                    prevent_tab_switch,
                    require_webcam,
                    require_microphone,
                    access_code,
                    ip_restrictions,
                    created_by,
                    created_at,
                    updated_at
                )
                VALUES (
                    :course_id,
                    :title,
                    :description,
                    :instructions,
                    :exam_type,
                    :duration_minutes,
                    :max_attempts,
                    :passing_score,
                    :total_questions,
                    :total_score,
                    :is_published,
                    :is_auto_generated,
                    :shuffle_questions,
                    :shuffle_options,
                    :available_from,
                    :available_to,
                    :enable_proctoring,
                    :prevent_copy_paste,
                    :prevent_tab_switch,
                    :require_webcam,
                    :require_microphone,
                    :access_code,
                    CAST(:ip_restrictions AS JSON),
                    :created_by,
                    NOW(),
                    NOW()
                )
                RETURNING
                    id,
                    course_id,
                    title,
                    description,
                    instructions,
                    exam_type,
                    duration_minutes,
                    max_attempts,
                    passing_score,
                    total_questions,
                    total_score,
                    is_published,
                    is_auto_generated,
                    shuffle_questions,
                    shuffle_options,
                    available_from,
                    available_to,
                    enable_proctoring,
                    prevent_copy_paste,
                    prevent_tab_switch,
                    require_webcam,
                    require_microphone,
                    access_code,
                    ip_restrictions,
                    created_by,
                    created_at,
                    updated_at
            """),
            {
                "course_id": course_id,
                "title": title,
                "description": payload.description.strip() if payload.description else None,
                "instructions": payload.instructions.strip() if payload.instructions else None,
                "exam_type": exam_type,
                "duration_minutes": payload.duration_minutes,
                "max_attempts": payload.max_attempts,
                "passing_score": payload.passing_score,
                "total_questions": 0,
                "total_score": 0,
                "is_published": False,
                "is_auto_generated": False,
                "shuffle_questions": payload.shuffle_questions,
                "shuffle_options": payload.shuffle_options,
                "available_from": payload.available_from,
                "available_to": payload.available_to,
                "enable_proctoring": False,
                "prevent_copy_paste": False,
                "prevent_tab_switch": False,
                "require_webcam": False,
                "require_microphone": False,
                "access_code": payload.access_code.strip() if payload.access_code else None,
                "ip_restrictions": None,
                "created_by": instructor_id,
            },
        ).mappings().first()

        if not exam_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to create exam")

        db.commit()
        return dict(exam_row)

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while creating exam") from e

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def update_exam(*, course_id: int, exam_id: int, payload: ExamUpdateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can update exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    try:
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
                detail="You can only update exams for your own course",
            )

        # =========================
        # 3) Validate exam belongs to course
        # =========================
        exam_row = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    created_by,
                    is_published,
                    available_from,
                    available_to
                FROM exams
                WHERE id = :exam_id
                  AND course_id = :course_id
                LIMIT 1
                FOR UPDATE
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().first()

        if not exam_row:
            raise HTTPException(status_code=404, detail="Exam not found")

        if int(exam_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only update your own exam",
            )

        if bool(exam_row["is_published"]):
            raise HTTPException(status_code=403, detail="Cannot update a published exam")

        # =========================
        # 4) Build dynamic update fields
        # =========================
        update_fields = {}

        if payload.title is not None:
            title = payload.title.strip()
            if not title:
                raise HTTPException(status_code=422, detail="Invalid exam_title")
            update_fields["title"] = title

        if payload.description is not None:
            update_fields["description"] = payload.description.strip()

        if payload.instructions is not None:
            update_fields["instructions"] = payload.instructions.strip()

        if payload.exam_type is not None and payload.exam_type.strip() != "":
            exam_type = payload.exam_type.strip().lower()
            if exam_type not in ALLOWED_EXAM_TYPES:
                raise HTTPException(status_code=422, detail="Invalid exam_type")
            update_fields["exam_type"] = exam_type

        if payload.duration_minutes is not None:
            if payload.duration_minutes <= 0:
                raise HTTPException(status_code=422, detail="Invalid duration_minutes")
            update_fields["duration_minutes"] = payload.duration_minutes

        if payload.max_attempts is not None:
            if payload.max_attempts <= 0:
                raise HTTPException(status_code=422, detail="Invalid max_attempts")
            update_fields["max_attempts"] = payload.max_attempts

        if payload.passing_score is not None:
            if payload.passing_score < 0:
                raise HTTPException(status_code=422, detail="Invalid passing_score")
            update_fields["passing_score"] = payload.passing_score

        if payload.shuffle_questions is not None:
            update_fields["shuffle_questions"] = payload.shuffle_questions

        if payload.shuffle_options is not None:
            update_fields["shuffle_options"] = payload.shuffle_options

        if payload.available_from is not None:
            update_fields["available_from"] = payload.available_from

        if payload.available_to is not None:
            update_fields["available_to"] = payload.available_to

        if payload.access_code is not None:
            update_fields["access_code"] = payload.access_code.strip()

        if not update_fields:
            raise HTTPException(status_code=400, detail="No updatable fields provided")

        # =========================
        # 5) Validate availability window
        # =========================
        final_available_from = update_fields.get("available_from", exam_row["available_from"])
        final_available_to = update_fields.get("available_to", exam_row["available_to"])

        if final_available_from and final_available_to:
            if final_available_to <= final_available_from:
                raise HTTPException(
                    status_code=400,
                    detail="available_to must be after available_from",
                )

        # =========================
        # 6) Update exam
        # =========================
        set_clauses = []
        params = {
            "exam_id": exam_id,
            "course_id": course_id,
        }

        for col in [
            "title",
            "description",
            "instructions",
            "exam_type",
            "duration_minutes",
            "max_attempts",
            "passing_score",
            "shuffle_questions",
            "shuffle_options",
            "available_from",
            "available_to",
            "access_code",
        ]:
            if col in update_fields:
                set_clauses.append(f"{col} = :{col}")
                params[col] = update_fields[col]

        set_clauses.append("updated_at = NOW()")

        updated_row = db.execute(
            text(f"""
                UPDATE exams
                SET {", ".join(set_clauses)}
                WHERE id = :exam_id
                  AND course_id = :course_id
                  AND is_published = FALSE
                RETURNING
                    id,
                    course_id,
                    title,
                    description,
                    instructions,
                    exam_type,
                    duration_minutes,
                    max_attempts,
                    passing_score,
                    total_questions,
                    total_score,
                    is_published,
                    is_auto_generated,
                    shuffle_questions,
                    shuffle_options,
                    available_from,
                    available_to,
                    enable_proctoring,
                    prevent_copy_paste,
                    prevent_tab_switch,
                    require_webcam,
                    require_microphone,
                    access_code,
                    ip_restrictions,
                    created_by,
                    created_at,
                    updated_at
            """),
            params,
        ).mappings().first()

        if not updated_row:
            db.rollback()
            raise HTTPException(status_code=409, detail="Exam could not be updated")

        db.commit()

        return dict(updated_row)

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while updating exam") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def add_questions_to_exam(*, course_id: int, exam_id: int, payload: ExamAddQuestionsRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can add questions to exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    question_ids = payload.question_ids

    if not question_ids:
        raise HTTPException(status_code=422, detail="question_ids is required")

    if any((not qid or qid <= 0) for qid in question_ids):
        raise HTTPException(status_code=422, detail="Invalid question_id in question_ids")

    if len(question_ids) != len(set(question_ids)):
        raise HTTPException(status_code=400, detail="Duplicate question_ids are not allowed")

    try:
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
                detail="You can only manage exams for your own course",
            )

        # =========================
        # 3) Validate exam belongs to course
        # =========================
        exam_row = db.execute(
            text("""
                SELECT id, course_id, created_by, is_published
                FROM exams
                WHERE id = :exam_id
                  AND course_id = :course_id
                LIMIT 1
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().first()

        if not exam_row:
            raise HTTPException(status_code=404, detail="Exam not found")

        if int(exam_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only add questions to your own exam",
            )
                
        if exam_row["is_published"]:
            raise HTTPException(status_code=403, detail="Cannot add questions to a published exam")

        # =========================
        # 4) Validate all questions belong to same course
        # =========================
        question_rows = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    max_score
                FROM questions
                WHERE course_id = :course_id
                  AND id = ANY(:question_ids)
            """),
            {
                "course_id": course_id,
                "question_ids": question_ids,
            },
        ).mappings().all()

        found_question_ids = {int(row["id"]) for row in question_rows}
        requested_question_ids = set(question_ids)

        missing_question_ids = requested_question_ids - found_question_ids
        if missing_question_ids:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Some questions were not found or do not belong to this course",
                    "question_ids": sorted(missing_question_ids),
                },
            )

        # =========================
        # 5) Prevent already-added questions
        # =========================
        existing_rows = db.execute(
            text("""
                SELECT question_id
                FROM exam_questions
                WHERE exam_id = :exam_id
                  AND question_id = ANY(:question_ids)
            """),
            {
                "exam_id": exam_id,
                "question_ids": question_ids,
            },
        ).mappings().all()

        existing_question_ids = [int(row["question_id"]) for row in existing_rows]

        if existing_question_ids:
            raise HTTPException(
                status_code=409,
                detail={
                    "message": "Some questions are already added to this exam",
                    "question_ids": existing_question_ids,
                },
            )

        # =========================
        # 6) Calculate next order_index
        # =========================
        max_order_row = db.execute(
            text("""
                SELECT COALESCE(MAX(order_index), 0) AS max_order_index
                FROM exam_questions
                WHERE exam_id = :exam_id
            """),
            {"exam_id": exam_id},
        ).mappings().first()

        if not max_order_row:
            raise HTTPException(status_code=500, detail="Failed to calculate exam question order")

        next_order_index = int(max_order_row["max_order_index"] or 0) + 1

        question_points_by_id = {
            int(row["id"]): float(row["max_score"]) if row["max_score"] is not None else 1.0
            for row in question_rows
        }

        # =========================
        # 7) Insert exam questions
        # =========================
        inserted_rows = []

        for index, question_id in enumerate(question_ids):
            points = question_points_by_id.get(int(question_id), 1.0)

            inserted_row = db.execute(
                text("""
                    INSERT INTO exam_questions (
                        exam_id,
                        section_id,
                        question_id,
                        order_index,
                        points,
                        custom_points,
                        custom_instructions
                    )
                    VALUES (
                        :exam_id,
                        :section_id,
                        :question_id,
                        :order_index,
                        :points,
                        :custom_points,
                        :custom_instructions
                    )
                    RETURNING
                        id,
                        exam_id,
                        section_id,
                        question_id,
                        order_index,
                        points,
                        custom_points,
                        custom_instructions
                """),
                {
                    "exam_id": exam_id,
                    "section_id": None,
                    "question_id": question_id,
                    "order_index": next_order_index + index,
                    "points": points,
                    "custom_points": None,
                    "custom_instructions": None,
                },
            ).mappings().first()

            if not inserted_row:
                db.rollback()
                raise HTTPException(status_code=503, detail="Failed to add question to exam")

            inserted_rows.append(dict(inserted_row))

        # =========================
        # 8) Update exam totals
        # =========================
        totals_row = db.execute(
            text("""
                SELECT
                    COUNT(*) AS total_questions,
                    COALESCE(SUM(points), 0) AS total_score
                FROM exam_questions
                WHERE exam_id = :exam_id
            """),
            {"exam_id": exam_id},
        ).mappings().first()

        if not totals_row:
            raise HTTPException(status_code=500, detail="Failed to calculate exam totals")

        total_questions = int(totals_row["total_questions"] or 0)
        total_score = float(totals_row["total_score"] or 0)

        db.execute(
            text("""
                UPDATE exams
                SET
                    total_questions = :total_questions,
                    total_score = :total_score,
                    updated_at = NOW()
                WHERE id = :exam_id
                  AND course_id = :course_id
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
                "total_questions": total_questions,
                "total_score": total_score,
            },
        )

        db.commit()

        return {
            "exam_id": exam_id,
            "course_id": course_id,
            "added_count": len(inserted_rows),
            "total_questions": total_questions,
            "total_score": total_score,
            "questions": inserted_rows,
        }

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while adding questions to exam") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def reorder_exam_questions(*, course_id: int, exam_id: int, payload, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can reorder exam questions")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    exam_question_ids = getattr(payload, "exam_question_ids", None)
    if not isinstance(exam_question_ids, list) or not exam_question_ids:
        raise HTTPException(status_code=400, detail="exam_question_ids must be a non-empty list")

    try:
        exam_question_ids = [int(eqid) for eqid in exam_question_ids]
    except Exception:
        raise HTTPException(status_code=400, detail="exam_question_ids must contain valid integers")

    if any(eqid <= 0 for eqid in exam_question_ids):
        raise HTTPException(status_code=400, detail="exam_question_ids must contain positive integers only")

    if len(exam_question_ids) != len(set(exam_question_ids)):
        raise HTTPException(status_code=400, detail="exam_question_ids must not contain duplicates")

    try:
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
                detail="You can only reorder exam questions for your own course",
            )

        # =========================
        # 3) Validate exam belongs to course
        # =========================
        exam_row = db.execute(
            text("""
                SELECT id, course_id, created_by, is_published
                FROM exams
                WHERE id = :exam_id
                  AND course_id = :course_id
                LIMIT 1
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().first()

        if not exam_row:
            raise HTTPException(status_code=404, detail="Exam not found")

        if int(exam_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only reorder questions for your own exam",
            )

        if exam_row["is_published"]:
            raise HTTPException(status_code=403, detail="Cannot reorder questions in a published exam")

        # =========================
        # 4) Fetch all exam questions
        # =========================
        db_exam_question_rows = db.execute(
            text("""
                SELECT id
                FROM exam_questions
                WHERE exam_id = :exam_id
                ORDER BY order_index ASC, id ASC
            """),
            {"exam_id": exam_id},
        ).mappings().all()

        db_exam_question_ids = [int(row["id"]) for row in db_exam_question_rows]

        if not db_exam_question_ids:
            raise HTTPException(status_code=404, detail="No questions found for this exam")

        if set(exam_question_ids) != set(db_exam_question_ids):
            raise HTTPException(
                status_code=400,
                detail="exam_question_ids must include all exam questions exactly once",
            )

        # =========================
        # 5) Reorder with two-phase update
        #    to avoid unique conflict on (exam_id, order_index)
        # =========================
        # phase 1: move to temporary negative order values
        for idx, exam_question_id in enumerate(exam_question_ids):
            db.execute(
                text("""
                    UPDATE exam_questions
                    SET order_index = :temp_order_index
                    WHERE id = :exam_question_id
                      AND exam_id = :exam_id
                """),
                {
                    "temp_order_index": -(idx + 1),
                    "exam_question_id": exam_question_id,
                    "exam_id": exam_id,
                },
            )

        # phase 2: assign final order values
        for idx, exam_question_id in enumerate(exam_question_ids):
            db.execute(
                text("""
                    UPDATE exam_questions
                    SET order_index = :final_order_index
                    WHERE id = :exam_question_id
                      AND exam_id = :exam_id
                """),
                {
                    "final_order_index": idx + 1,
                    "exam_question_id": exam_question_id,
                    "exam_id": exam_id,
                },
            )

        db.commit()

        return {
            "exam_id": exam_id,
            "course_id": course_id,
            "exam_question_ids": exam_question_ids,
            "message": "Exam questions reordered successfully",
        }

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while reordering exam questions") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def remove_question_from_exam(*, course_id: int, exam_id: int, exam_question_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can remove questions from exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    if not exam_question_id or exam_question_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_question_id")

    try:
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
                detail="You can only manage exams for your own course",
            )

        # =========================
        # 3) Validate exam belongs to course
        # =========================
        exam_row = db.execute(
            text("""
                SELECT id, course_id, created_by, is_published
                FROM exams
                WHERE id = :exam_id
                  AND course_id = :course_id
                LIMIT 1
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().first()

        if not exam_row:
            raise HTTPException(status_code=404, detail="Exam not found")

        if int(exam_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only modify your own exam",
            )

        if exam_row["is_published"]:
            raise HTTPException(status_code=403, detail="Cannot remove questions from a published exam")

        # =========================
        # 4) Validate exam_question exists in this exam
        # =========================
        exam_question_row = db.execute(
            text("""
                SELECT id
                FROM exam_questions
                WHERE id = :exam_question_id
                  AND exam_id = :exam_id
            """),
            {
                "exam_question_id": exam_question_id,
                "exam_id": exam_id,
            },
        ).mappings().first()

        if not exam_question_row:
            raise HTTPException(status_code=404, detail="Exam question not found in this exam")

        # =========================
        # 5) Delete exam_question
        # =========================
        db.execute(
            text("""
                DELETE FROM exam_questions
                WHERE id = :exam_question_id
                    AND exam_id = :exam_id
            """),
            {
                "exam_question_id": exam_question_id,
                "exam_id": exam_id,
            },
        )

        # =========================
        # 6) Recalculate exam totals
        # =========================
        totals_row = db.execute(
            text("""
                SELECT
                    COUNT(*) AS total_questions,
                    COALESCE(SUM(points), 0) AS total_score
                FROM exam_questions
                WHERE exam_id = :exam_id
            """),
            {"exam_id": exam_id},
        ).mappings().first()

        if not totals_row:
            total_questions = 0
            total_score = 0.0
        else:
            total_questions = int(totals_row.get("total_questions", 0))
            total_score = float(totals_row.get("total_score", 0))

        db.execute(
            text("""
                UPDATE exams
                SET
                    total_questions = :total_questions,
                    total_score = :total_score,
                    updated_at = NOW()
                WHERE id = :exam_id
                  AND course_id = :course_id
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
                "total_questions": total_questions,
                "total_score": total_score,
            },
        )

        db.commit()

        return {
            "exam_id": exam_id,
            "course_id": course_id,
            "removed_exam_question_id": exam_question_id,
            "total_questions": total_questions,
            "total_score": total_score,
            "message": "Question removed from exam successfully",
        }

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while removing exam question") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def publish_exam(*, course_id: int, exam_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can publish exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    try:
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
                detail="You can only publish exams for your own course",
            )

        # =========================
        # 3) Validate exam belongs to course
        # =========================
        exam_row = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    created_by,
                    is_published
                FROM exams
                WHERE id = :exam_id
                  AND course_id = :course_id
                LIMIT 1
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().first()

        if not exam_row:
            raise HTTPException(status_code=404, detail="Exam not found")

        if int(exam_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only publish your own exam",
            )

        if bool(exam_row["is_published"]):
            raise HTTPException(status_code=409, detail="Exam is already published")

        # =========================
        # 4) Validate exam has questions
        # =========================
        exam_question_rows = db.execute(
            text("""
                SELECT
                    eq.id,
                    eq.question_id
                FROM exam_questions eq
                WHERE eq.exam_id = :exam_id
                ORDER BY eq.order_index ASC, eq.id ASC
            """),
            {"exam_id": exam_id},
        ).mappings().all()

        if not exam_question_rows:
            raise HTTPException(status_code=400, detail="Cannot publish exam without questions")

        question_ids = [int(row["question_id"]) for row in exam_question_rows]

        # =========================
        # 5) Validate questions still belong to course
        # =========================
        question_rows = db.execute(
            text("""
                SELECT id
                FROM questions
                WHERE course_id = :course_id
                  AND id = ANY(:question_ids)
            """),
            {
                "course_id": course_id,
                "question_ids": question_ids,
            },
        ).mappings().all()

        found_question_ids = {int(row["id"]) for row in question_rows}
        missing_question_ids = set(question_ids) - found_question_ids

        if missing_question_ids:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Some exam questions were not found or do not belong to this course",
                    "question_ids": sorted(missing_question_ids),
                },
            )

        # =========================
        # 6) Store final question snapshots
        # =========================
        snapshot_rows = db.execute(
            text("""
                UPDATE exam_questions eq
                SET
                    snapshot_topic_id = q.topic_id,
                    snapshot_question_text = q.question_text,
                    snapshot_explanation = q.explanation,
                    snapshot_options = q.options,
                    snapshot_type = q.type::text,
                    snapshot_difficulty = q.difficulty::text,
                    snapshot_expected_answer = q.expected_answer,
                    snapshot_grading_rubric = q.grading_rubric,
                    snapshot_max_score = q.max_score,
                    snapshot_auto_gradable = q.auto_gradable,
                    snapshot_tags = q.tags,
                    snapshot_source_question_updated_at = q.updated_at,
                    snapshot_created_at = NOW()
                FROM questions q
                WHERE eq.exam_id = :exam_id
                    AND eq.question_id = q.id
                    AND q.course_id = :course_id
                RETURNING eq.id
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().all()

        if len(snapshot_rows) != len(question_ids):
            raise HTTPException(
                status_code=500,
                detail="Failed to create question snapshots",
            )

        # =========================
        # 7) Recalculate exam totals
        # =========================
        totals_row = db.execute(
            text("""
                SELECT
                    COUNT(*) AS total_questions,
                    COALESCE(SUM(points), 0) AS total_score
                FROM exam_questions
                WHERE exam_id = :exam_id
            """),
            {"exam_id": exam_id},
        ).mappings().first()

        if not totals_row:
            raise HTTPException(status_code=500, detail="Failed to calculate exam totals")

        total_questions = int(totals_row["total_questions"] or 0)
        total_score = float(totals_row["total_score"] or 0)

        # =========================
        # 8) Publish exam
        # =========================
        publish_row = db.execute(
            text("""
                UPDATE exams
                SET
                    total_questions = :total_questions,
                    total_score = :total_score,
                    is_published = TRUE,
                    updated_at = NOW()
                WHERE id = :exam_id
                  AND course_id = :course_id
                  AND is_published = FALSE
                RETURNING
                    id,
                    course_id,
                    is_published,
                    total_questions,
                    total_score
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
                "total_questions": total_questions,
                "total_score": total_score,
            },
        ).mappings().first()

        if not publish_row:
            db.rollback()
            raise HTTPException(status_code=409, detail="Exam could not be published")

        db.commit()

        return {
            "exam_id": int(publish_row["id"]),
            "course_id": int(publish_row["course_id"]),
            "is_published": bool(publish_row["is_published"]),
            "total_questions": int(publish_row["total_questions"]),
            "total_score": float(publish_row["total_score"]),
            "message": "Exam published successfully",
        }

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while publishing exam") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def list_exams(*, course_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can view exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    try:
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
                detail="You can only view exams for your own course",
            )

        # =========================
        # 3) Fetch exams
        # =========================
        exam_rows = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    title,
                    description,
                    exam_type,
                    duration_minutes,
                    max_attempts,
                    passing_score,
                    total_questions,
                    total_score,
                    is_published,
                    is_auto_generated,
                    shuffle_questions,
                    shuffle_options,
                    available_from,
                    available_to,
                    created_by,
                    created_at,
                    updated_at
                FROM exams
                WHERE course_id = :course_id
                ORDER BY created_at DESC, id DESC
            """),
            {"course_id": course_id},
        ).mappings().all()

        exams = [dict(row) for row in exam_rows]

        return {
            "course_id": course_id,
            "total": len(exams),
            "exams": exams,
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e



def get_exam(*, course_id: int, exam_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can view exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    try:
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
                detail="You can only view exams for your own course",
            )

        # =========================
        # 3) Fetch exam
        # =========================
        exam_row = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    title,
                    description,
                    instructions,
                    exam_type,
                    duration_minutes,
                    max_attempts,
                    passing_score,
                    total_questions,
                    total_score,
                    is_published,
                    is_auto_generated,
                    shuffle_questions,
                    shuffle_options,
                    available_from,
                    available_to,
                    enable_proctoring,
                    prevent_copy_paste,
                    prevent_tab_switch,
                    require_webcam,
                    require_microphone,
                    access_code,
                    ip_restrictions,
                    created_by,
                    created_at,
                    updated_at
                FROM exams
                WHERE id = :exam_id
                  AND course_id = :course_id
                LIMIT 1
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().first()

        if not exam_row:
            raise HTTPException(status_code=404, detail="Exam not found")

        if int(exam_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only view your own exam",
            )

        is_published = bool(exam_row["is_published"])

        # =========================
        # 4) Fetch exam questions
        # =========================
        if is_published:
            question_rows = db.execute(
                text("""
                    SELECT
                        eq.id AS exam_question_id,
                        eq.question_id,
                        eq.section_id,
                        eq.order_index,
                        eq.points,
                        eq.custom_points,
                        eq.custom_instructions,

                        eq.snapshot_topic_id AS topic_id,
                        eq.snapshot_question_text AS question_text,
                        eq.snapshot_explanation AS explanation,
                        eq.snapshot_options AS options,
                        eq.snapshot_type AS type,
                        eq.snapshot_difficulty AS difficulty,
                        q.source,
                        q.approval_status,
                        eq.snapshot_expected_answer AS expected_answer,
                        eq.snapshot_grading_rubric AS grading_rubric,
                        eq.snapshot_max_score AS max_score,
                        eq.snapshot_auto_gradable AS auto_gradable,
                        eq.snapshot_tags AS tags
                    FROM exam_questions eq
                    LEFT JOIN questions q
                      ON q.id = eq.question_id
                    WHERE eq.exam_id = :exam_id
                    ORDER BY eq.order_index ASC, eq.id ASC
                """),
                {"exam_id": exam_id},
            ).mappings().all()

        else:
            question_rows = db.execute(
                text("""
                    SELECT
                        eq.id AS exam_question_id,
                        eq.question_id,
                        eq.section_id,
                        eq.order_index,
                        eq.points,
                        eq.custom_points,
                        eq.custom_instructions,

                        q.topic_id,
                        q.question_text,
                        q.explanation,
                        q.options,
                        q.type,
                        q.difficulty,
                        q.source,
                        q.approval_status,
                        q.expected_answer,
                        q.grading_rubric,
                        q.max_score,
                        q.auto_gradable,
                        q.tags
                    FROM exam_questions eq
                    JOIN questions q
                      ON q.id = eq.question_id
                    WHERE eq.exam_id = :exam_id
                      AND q.course_id = :course_id
                    ORDER BY eq.order_index ASC, eq.id ASC
                """),
                {
                    "exam_id": exam_id,
                    "course_id": course_id,
                },
            ).mappings().all()

        exam_data = dict(exam_row)
        exam_data["questions"] = [dict(row) for row in question_rows]

        return exam_data

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e



def export_exam_pdf(*, course_id: int, exam_id: int, include_learnova_logo: bool,
                    include_course_title: bool, include_course_code: bool,
                    include_exam_metadata: bool,include_instructions: bool, include_points: bool,
                    include_student_info_fields: bool, include_answer_space: bool, shuffle_questions: bool | None,
                    shuffle_options: bool | None, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can export exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    try:
        # =========================
        # 2) Validate course exists + ownership
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, created_by, title, course_code
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
                detail="You can only export exams for your own course",
            )

        # =========================
        # 3) Fetch exam
        # =========================
        exam_row = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    title,
                    description,
                    instructions,
                    exam_type,
                    duration_minutes,
                    max_attempts,
                    passing_score,
                    total_questions,
                    total_score,
                    is_published,
                    is_auto_generated,
                    shuffle_questions,
                    shuffle_options,
                    available_from,
                    available_to,
                    created_by,
                    created_at,
                    updated_at
                FROM exams
                WHERE id = :exam_id
                  AND course_id = :course_id
                LIMIT 1
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().first()

        if not exam_row:
            raise HTTPException(status_code=404, detail="Exam not found")

        if int(exam_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only export your own exam",
            )

        is_published = bool(exam_row["is_published"])

        # =========================
        # 4) Fetch exam questions
        # =========================
        if is_published:
            question_rows = db.execute(
                text("""
                    SELECT
                        eq.id AS exam_question_id,
                        eq.question_id,
                        eq.section_id,
                        eq.order_index,
                        eq.points,
                        eq.custom_points,
                        eq.custom_instructions,

                        eq.snapshot_topic_id AS topic_id,
                        eq.snapshot_question_text AS question_text,
                        eq.snapshot_explanation AS explanation,
                        eq.snapshot_options AS options,
                        eq.snapshot_type AS type,
                        eq.snapshot_difficulty AS difficulty,
                        eq.snapshot_expected_answer AS expected_answer,
                        eq.snapshot_grading_rubric AS grading_rubric,
                        eq.snapshot_max_score AS max_score,
                        eq.snapshot_auto_gradable AS auto_gradable,
                        eq.snapshot_tags AS tags
                    FROM exam_questions eq
                    WHERE eq.exam_id = :exam_id
                    ORDER BY eq.order_index ASC, eq.id ASC
                """),
                {"exam_id": exam_id},
            ).mappings().all()

        else:
            question_rows = db.execute(
                text("""
                    SELECT
                        eq.id AS exam_question_id,
                        eq.question_id,
                        eq.section_id,
                        eq.order_index,
                        eq.points,
                        eq.custom_points,
                        eq.custom_instructions,

                        q.topic_id,
                        q.question_text,
                        q.explanation,
                        q.options,
                        q.type,
                        q.difficulty,
                        q.expected_answer,
                        q.grading_rubric,
                        q.max_score,
                        q.auto_gradable,
                        q.tags
                    FROM exam_questions eq
                    JOIN questions q
                      ON q.id = eq.question_id
                    WHERE eq.exam_id = :exam_id
                      AND q.course_id = :course_id
                    ORDER BY eq.order_index ASC, eq.id ASC
                """),
                {
                    "exam_id": exam_id,
                    "course_id": course_id,
                },
            ).mappings().all()

        if not question_rows:
            raise HTTPException(status_code=400, detail="Cannot export exam without questions")

        # =========================
        # 5) Build export context
        # =========================
        effective_shuffle_questions = (
            bool(exam_row["shuffle_questions"])
            if shuffle_questions is None
            else shuffle_questions
        )

        effective_shuffle_options = (
            bool(exam_row["shuffle_options"])
            if shuffle_options is None
            else shuffle_options
        )

        export_context = build_exam_export_context(
            exam_row=dict(exam_row),
            course_row=dict(course_row),
            question_rows=[dict(row) for row in question_rows],
            include_learnova_logo=include_learnova_logo,
            include_course_title=include_course_title,
            include_course_code=include_course_code,
            include_exam_metadata=include_exam_metadata,
            include_instructions=include_instructions,
            include_points=include_points,
            include_student_info_fields=include_student_info_fields,
            include_answer_space=include_answer_space,
            effective_shuffle_questions=effective_shuffle_questions,
            effective_shuffle_options=effective_shuffle_options,
        )

        # =========================
        # 6) Render PDF
        # =========================
        try:
            html_content = render_exam_pdf_html(export_context)
            pdf_bytes = convert_html_to_pdf(html_content)

        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail="Failed to generate PDF export",
            ) from e

        if not pdf_bytes:
            raise HTTPException(status_code=500, detail="Failed to generate PDF export")

        # =========================
        # 7) Return PDF response
        # =========================
        exam_type = str(exam_row["exam_type"]).strip().lower()
        filename = f"learnova-{exam_type}-exam-{exam_id}.pdf"

        return StreamingResponse(
            BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"'
            },
        )

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e