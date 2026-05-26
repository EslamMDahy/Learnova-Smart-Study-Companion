from __future__ import annotations

from fastapi import HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from io import BytesIO

from .schemas import (ExamCreateRequest,
                      ExamUpdateRequest,
                      ExamSectionCreateRequest,
                      ExamSectionUpdateRequest,
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



def add_section_to_exam(*, course_id: int, exam_id: int, payload: ExamSectionCreateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can add sections to exams")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=422, detail="Section title is required")

    question_type = payload.question_type.strip().lower()
    if question_type not in {
        "multiple_choice",
        "multi_select",
        "true_false",
        "short_answer",
        "essay",
    }:
        raise HTTPException(status_code=422, detail="Invalid question_type")

    if payload.time_limit_minutes is not None and payload.time_limit_minutes <= 0:
        raise HTTPException(status_code=422, detail="Invalid time_limit_minutes")

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
                detail="You can only add sections to exams for your own course",
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
                detail="You can only add sections to your own exam",
            )

        if exam_row["is_published"]:
            raise HTTPException(status_code=403, detail="Cannot add sections to a published exam")

        # =========================
        # 4) Calculate next section order
        # =========================
        max_order_row = db.execute(
            text("""
                SELECT COALESCE(MAX(order_index), 0) AS max_order_index
                FROM exam_sections
                WHERE exam_id = :exam_id
            """),
            {"exam_id": exam_id},
        ).mappings().first()

        if not max_order_row:
            raise HTTPException(status_code=500, detail="Failed to calculate section order")

        next_order_index = int(max_order_row["max_order_index"] or 0) + 1

        # =========================
        # 5) Insert exam section
        # =========================
        section_row = db.execute(
            text("""
                INSERT INTO exam_sections (
                    exam_id,
                    title,
                    description,
                    question_type,
                    order_index,
                    question_count,
                    section_score,
                    time_limit_minutes,
                    must_complete,
                    created_at,
                    updated_at
                )
                VALUES (
                    :exam_id,
                    :title,
                    :description,
                    :question_type,
                    :order_index,
                    :question_count,
                    :section_score,
                    :time_limit_minutes,
                    :must_complete,
                    NOW(),
                    NOW()
                )
                RETURNING
                    id,
                    exam_id,
                    title,
                    description,
                    question_type,
                    order_index,
                    question_count,
                    section_score,
                    time_limit_minutes,
                    must_complete,
                    created_at,
                    updated_at
            """),
            {
                "exam_id": exam_id,
                "title": title,
                "description": payload.description.strip() if payload.description else None,
                "question_type": question_type,
                "order_index": next_order_index,
                "question_count": 0,
                "section_score": 0,
                "time_limit_minutes": payload.time_limit_minutes,
                "must_complete": payload.must_complete,
            },
        ).mappings().first()

        if not section_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to add section to exam")

        db.commit()

        return dict(section_row)

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while adding section to exam") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def update_exam_section(*, course_id: int, exam_id: int, section_id: int, payload: ExamSectionUpdateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can update exam sections")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    if not section_id or section_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid section_id")

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
                detail="You can only update sections for exams in your own course",
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
                detail="You can only update sections in your own exam",
            )

        if exam_row["is_published"]:
            raise HTTPException(status_code=403, detail="Cannot update sections in a published exam")

        # =========================
        # 4) Validate section belongs to exam
        # =========================
        section_row = db.execute(
            text("""
                SELECT
                    id,
                    exam_id,
                    question_type,
                    question_count
                FROM exam_sections
                WHERE id = :section_id
                  AND exam_id = :exam_id
                LIMIT 1
                FOR UPDATE
            """),
            {
                "section_id": section_id,
                "exam_id": exam_id,
            },
        ).mappings().first()

        if not section_row:
            raise HTTPException(status_code=404, detail="Exam section not found")

        # =========================
        # 5) Build dynamic update fields
        # =========================
        update_fields = {}

        if payload.title is not None:
            title = payload.title.strip()
            if not title:
                raise HTTPException(status_code=422, detail="Section title is required")
            update_fields["title"] = title

        if payload.description is not None:
            update_fields["description"] = payload.description.strip() if payload.description.strip() else None

        if payload.question_type is not None:
            question_type = payload.question_type.strip().lower()
            if question_type not in {
                "multiple_choice",
                "multi_select",
                "true_false",
                "short_answer",
                "essay",
            }:
                raise HTTPException(status_code=422, detail="Invalid question_type")

            if question_type != section_row["question_type"] and int(section_row["question_count"] or 0) > 0:
                raise HTTPException(
                    status_code=400,
                    detail="Cannot change section question_type while section has questions",
                )

            update_fields["question_type"] = question_type

        if payload.time_limit_minutes is not None:
            if payload.time_limit_minutes <= 0:
                raise HTTPException(status_code=422, detail="Invalid time_limit_minutes")
            update_fields["time_limit_minutes"] = payload.time_limit_minutes

        if payload.must_complete is not None:
            update_fields["must_complete"] = payload.must_complete

        if not update_fields:
            raise HTTPException(status_code=400, detail="No updatable fields provided")

        # =========================
        # 6) Update exam section
        # =========================
        set_clauses = []
        params = {
            "section_id": section_id,
            "exam_id": exam_id,
        }

        for col in [
            "title",
            "description",
            "question_type",
            "time_limit_minutes",
            "must_complete",
        ]:
            if col in update_fields:
                set_clauses.append(f"{col} = :{col}")
                params[col] = update_fields[col]

        set_clauses.append("updated_at = NOW()")

        updated_row = db.execute(
            text(f"""
                UPDATE exam_sections
                SET {", ".join(set_clauses)}
                WHERE id = :section_id
                  AND exam_id = :exam_id
                RETURNING
                    id,
                    exam_id,
                    title,
                    description,
                    question_type,
                    order_index,
                    question_count,
                    section_score,
                    time_limit_minutes,
                    must_complete,
                    created_at,
                    updated_at
            """),
            params,
        ).mappings().first()

        if not updated_row:
            db.rollback()
            raise HTTPException(status_code=409, detail="Exam section could not be updated")

        db.commit()

        return dict(updated_row)

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while updating exam section") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def delete_exam_section(*, course_id: int, exam_id: int, section_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can delete exam sections")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    if not section_id or section_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid section_id")

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
                detail="You can only delete sections from exams in your own course",
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
                detail="You can only delete sections from your own exam",
            )

        if exam_row["is_published"]:
            raise HTTPException(status_code=403, detail="Cannot delete sections from a published exam")

        # =========================
        # 4) Validate section belongs to exam
        # =========================
        section_row = db.execute(
            text("""
                SELECT id
                FROM exam_sections
                WHERE id = :section_id
                  AND exam_id = :exam_id
                LIMIT 1
            """),
            {
                "section_id": section_id,
                "exam_id": exam_id,
            },
        ).mappings().first()

        if not section_row:
            raise HTTPException(status_code=404, detail="Exam section not found")

        # =========================
        # 5) Delete exam section
        # =========================
        db.execute(
            text("""
                DELETE FROM exam_sections
                WHERE id = :section_id
                  AND exam_id = :exam_id
            """),
            {
                "section_id": section_id,
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
            "deleted_section_id": section_id,
            "message": "Exam section deleted successfully",
        }

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while deleting exam section") from e

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def add_questions_to_exam_section(*, course_id: int, exam_id: int, section_id: int, payload: ExamAddQuestionsRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can add questions to exam sections")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not exam_id or exam_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid exam_id")

    if not section_id or section_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid section_id")

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
        # 4) Validate section belongs to exam
        # =========================
        section_row = db.execute(
            text("""
                SELECT
                    id,
                    exam_id,
                    question_type
                FROM exam_sections
                WHERE id = :section_id
                  AND exam_id = :exam_id
                LIMIT 1
            """),
            {
                "section_id": section_id,
                "exam_id": exam_id,
            },
        ).mappings().first()

        if not section_row:
            raise HTTPException(status_code=404, detail="Exam section not found")

        section_question_type = str(section_row["question_type"]).strip().lower()

        # =========================
        # 5) Validate all questions belong to same course and match section type
        # =========================
        question_rows = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    type,
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

        invalid_type_question_ids = [
            int(row["id"])
            for row in question_rows
            if str(row["type"]).strip().lower() != section_question_type
        ]

        if invalid_type_question_ids:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Some questions do not match the section question type",
                    "section_question_type": section_question_type,
                    "question_ids": invalid_type_question_ids,
                },
            )

        # =========================
        # 6) Prevent already-added questions
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
        # 7) Calculate next order_index inside section
        # =========================
        max_order_row = db.execute(
            text("""
                SELECT COALESCE(MAX(order_index), 0) AS max_order_index
                FROM exam_questions
                WHERE section_id = :section_id
            """),
            {"section_id": section_id},
        ).mappings().first()

        if not max_order_row:
            raise HTTPException(status_code=500, detail="Failed to calculate exam question order")

        next_order_index = int(max_order_row["max_order_index"] or 0) + 1

        question_points_by_id = {
            int(row["id"]): float(row["max_score"]) if row["max_score"] is not None else 1.0
            for row in question_rows
        }

        # =========================
        # 8) Insert exam section questions
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
                    "section_id": section_id,
                    "question_id": question_id,
                    "order_index": next_order_index + index,
                    "points": points,
                    "custom_points": None,
                    "custom_instructions": None,
                },
            ).mappings().first()

            if not inserted_row:
                db.rollback()
                raise HTTPException(status_code=503, detail="Failed to add question to exam section")

            inserted_rows.append(dict(inserted_row))

        # =========================
        # 9) Update section totals
        # =========================
        section_totals_row = db.execute(
            text("""
                SELECT
                    COUNT(*) AS question_count,
                    COALESCE(SUM(points), 0) AS section_score
                FROM exam_questions
                WHERE section_id = :section_id
            """),
            {"section_id": section_id},
        ).mappings().first()

        if not section_totals_row:
            raise HTTPException(status_code=500, detail="Failed to calculate section totals")

        section_question_count = int(section_totals_row["question_count"] or 0)
        section_score = float(section_totals_row["section_score"] or 0)

        db.execute(
            text("""
                UPDATE exam_sections
                SET
                    question_count = :question_count,
                    section_score = :section_score,
                    updated_at = NOW()
                WHERE id = :section_id
                  AND exam_id = :exam_id
            """),
            {
                "section_id": section_id,
                "exam_id": exam_id,
                "question_count": section_question_count,
                "section_score": section_score,
            },
        )

        # =========================
        # 10) Update exam totals
        # =========================
        exam_totals_row = db.execute(
            text("""
                SELECT
                    COUNT(*) AS total_questions,
                    COALESCE(SUM(points), 0) AS total_score
                FROM exam_questions
                WHERE exam_id = :exam_id
            """),
            {"exam_id": exam_id},
        ).mappings().first()

        if not exam_totals_row:
            raise HTTPException(status_code=500, detail="Failed to calculate exam totals")

        exam_total_questions = int(exam_totals_row["total_questions"] or 0)
        exam_total_score = float(exam_totals_row["total_score"] or 0)

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
                "total_questions": exam_total_questions,
                "total_score": exam_total_score,
            },
        )

        db.commit()

        return {
            "exam_id": exam_id,
            "course_id": course_id,
            "section_id": section_id,
            "added_count": len(inserted_rows),
            "section_question_count": section_question_count,
            "section_score": section_score,
            "exam_total_questions": exam_total_questions,
            "exam_total_score": exam_total_score,
            "questions": inserted_rows,
        }

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while adding questions to exam section") from e

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
        # 4) Validate exam has sections
        # =========================
        section_rows = db.execute(
            text("""
                SELECT
                    id,
                    question_type,
                    question_count
                FROM exam_sections
                WHERE exam_id = :exam_id
                ORDER BY order_index ASC, id ASC
            """),
            {"exam_id": exam_id},
        ).mappings().all()

        if not section_rows:
            raise HTTPException(status_code=400, detail="Cannot publish exam without sections")

        empty_section_ids = [
            int(row["id"])
            for row in section_rows
            if int(row["question_count"] or 0) <= 0
        ]

        if empty_section_ids:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Cannot publish exam with empty sections",
                    "section_ids": empty_section_ids,
                },
            )

        # =========================
        # 5) Validate exam questions and section types
        # =========================
        exam_question_rows = db.execute(
            text("""
                SELECT
                    eq.id,
                    eq.question_id,
                    eq.section_id,
                    es.question_type AS section_question_type,
                    q.type AS question_type
                FROM exam_questions eq
                JOIN exam_sections es
                  ON es.id = eq.section_id
                 AND es.exam_id = eq.exam_id
                JOIN questions q
                  ON q.id = eq.question_id
                 AND q.course_id = :course_id
                WHERE eq.exam_id = :exam_id
                ORDER BY es.order_index ASC, eq.order_index ASC, eq.id ASC
            """),
            {
                "exam_id": exam_id,
                "course_id": course_id,
            },
        ).mappings().all()

        if not exam_question_rows:
            raise HTTPException(status_code=400, detail="Cannot publish exam without questions")

        question_ids = [int(row["question_id"]) for row in exam_question_rows]

        section_ids_with_questions = {int(row["section_id"]) for row in exam_question_rows}
        all_section_ids = {int(row["id"]) for row in section_rows}

        missing_question_section_ids = all_section_ids - section_ids_with_questions
        if missing_question_section_ids:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Cannot publish exam with sections that have no valid questions",
                    "section_ids": sorted(missing_question_section_ids),
                },
            )

        invalid_type_rows = [
            {
                "exam_question_id": int(row["id"]),
                "question_id": int(row["question_id"]),
                "section_id": int(row["section_id"]),
                "section_question_type": str(row["section_question_type"]),
                "question_type": str(row["question_type"]),
            }
            for row in exam_question_rows
            if str(row["section_question_type"]).strip().lower() != str(row["question_type"]).strip().lower()
        ]

        if invalid_type_rows:
            raise HTTPException(
                status_code=400,
                detail={
                    "message": "Some questions do not match their section question type",
                    "items": invalid_type_rows,
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
        # 7) Recalculate section totals
        # =========================
        db.execute(
            text("""
                UPDATE exam_sections es
                SET
                    question_count = totals.question_count,
                    section_score = totals.section_score,
                    updated_at = NOW()
                FROM (
                    SELECT
                        section_id,
                        COUNT(*) AS question_count,
                        COALESCE(SUM(points), 0) AS section_score
                    FROM exam_questions
                    WHERE exam_id = :exam_id
                    GROUP BY section_id
                ) totals
                WHERE es.id = totals.section_id
                  AND es.exam_id = :exam_id
            """),
            {"exam_id": exam_id},
        )

        # =========================
        # 8) Recalculate exam totals
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
        # 9) Publish exam
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
        # 4) Fetch exam sections
        # =========================
        section_rows = db.execute(
            text("""
                SELECT
                    id,
                    exam_id,
                    title,
                    description,
                    question_type,
                    order_index,
                    question_count,
                    section_score,
                    time_limit_minutes,
                    must_complete,
                    created_at,
                    updated_at
                FROM exam_sections
                WHERE exam_id = :exam_id
                ORDER BY order_index ASC, id ASC
            """),
            {"exam_id": exam_id},
        ).mappings().all()

        sections = [dict(row) for row in section_rows]

        # =========================
        # 5) Fetch exam questions
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
                        NULL AS source,
                        NULL AS approval_status,
                        eq.snapshot_expected_answer AS expected_answer,
                        eq.snapshot_grading_rubric AS grading_rubric,
                        eq.snapshot_max_score AS max_score,
                        eq.snapshot_auto_gradable AS auto_gradable,
                        eq.snapshot_tags AS tags
                    FROM exam_questions eq
                    WHERE eq.exam_id = :exam_id
                    ORDER BY eq.section_id ASC, eq.order_index ASC, eq.id ASC
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
                    ORDER BY eq.section_id ASC, eq.order_index ASC, eq.id ASC
                """),
                {
                    "exam_id": exam_id,
                    "course_id": course_id,
                },
            ).mappings().all()

        questions_by_section_id = {}

        for row in question_rows:
            question = dict(row)
            current_section_id = int(question["section_id"])
            questions_by_section_id.setdefault(current_section_id, [])
            questions_by_section_id[current_section_id].append(question)

        for section in sections:
            section["questions"] = questions_by_section_id.get(int(section["id"]), [])

        exam_data = dict(exam_row)
        exam_data["sections"] = sections

        return exam_data

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e



def export_exam_pdf(*, course_id: int, exam_id: int, include_learnova_logo: bool,
                    include_course_title: bool, include_course_code: bool,
                    include_exam_metadata: bool, include_instructions: bool,
                    include_section_descriptions: bool, include_points: bool,
                    include_student_info_fields: bool, include_answer_space: bool, 
                    shuffle_questions: bool | None, shuffle_options: bool | None, 
                    db: Session, current_user: dict,):
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
        # 4) Fetch exam section
        # =========================
        section_rows = db.execute(
            text("""
                SELECT
                    es.id AS section_id,
                    es.exam_id,
                    es.title,
                    es.description,
                    es.question_type,
                    es.order_index,
                    COUNT(eq.id) AS total_questions,
                    COALESCE(SUM(eq.points), 0) AS total_score
                FROM exam_sections es
                LEFT JOIN exam_questions eq
                ON eq.section_id = es.id
                AND eq.exam_id = es.exam_id
                WHERE es.exam_id = :exam_id
                GROUP BY
                    es.id,
                    es.exam_id,
                    es.title,
                    es.description,
                    es.question_type,
                    es.order_index
                ORDER BY es.order_index ASC, es.id ASC
            """),
            {"exam_id": exam_id},
        ).mappings().all()

        if not section_rows:
            raise HTTPException(status_code=400, detail="Cannot export exam without sections")
        
        # =========================
        # 5) Fetch exam questions
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
                    JOIN exam_sections es
                      ON es.id = eq.section_id
                     AND es.exam_id = eq.exam_id
                    WHERE eq.exam_id = :exam_id
                    ORDER BY es.order_index ASC, eq.order_index ASC, eq.id ASC
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
                    JOIN exam_sections es
                      ON es.id = eq.section_id
                     AND es.exam_id = eq.exam_id
                    JOIN questions q
                      ON q.id = eq.question_id
                    WHERE eq.exam_id = :exam_id
                      AND q.course_id = :course_id
                    ORDER BY es.order_index ASC, eq.order_index ASC, eq.id ASC
                """),
                {
                    "exam_id": exam_id,
                    "course_id": course_id,
                },
            ).mappings().all()

        if not question_rows:
            raise HTTPException(status_code=400, detail="Cannot export exam without questions")

        # =========================
        # 6) Build export context
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
            section_rows=[dict(row) for row in section_rows],
            question_rows=[dict(row) for row in question_rows],
            include_learnova_logo=include_learnova_logo,
            include_course_title=include_course_title,
            include_course_code=include_course_code,
            include_exam_metadata=include_exam_metadata,
            include_instructions=include_instructions,
            include_section_descriptions=include_section_descriptions,
            include_points=include_points,
            include_student_info_fields=include_student_info_fields,
            include_answer_space=include_answer_space,
            effective_shuffle_questions=effective_shuffle_questions,
            effective_shuffle_options=effective_shuffle_options,
        )

        # =========================
        # 7) Render PDF
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
        # 8) Return PDF response
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