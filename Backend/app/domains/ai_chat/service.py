from __future__ import annotations

from typing import Any

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

from app.core.ai_service_integration.ai_transport import send_ai_request
from .schemas import SessionCreateRequest, CreateSessionResponse


def create_session(*, course_id: int, payload: SessionCreateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role not in ("instructor", "student"):
        raise HTTPException(status_code=403, detail="Access denied")

    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Message content is required")
    
    # =========================
    # 2) Validate course access
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

    if role == "instructor":
        if int(course_row["created_by"]) != int(user_id):
            raise HTTPException(status_code=403, detail="You can only chat within your own courses")

    if role == "student":
        enrollment_row = db.execute(
            text("""
                SELECT id
                FROM course_enrollments
                WHERE course_id = :course_id
                  AND student_id = :student_id
                  AND status = 'active'
                LIMIT 1
            """),
            {"course_id": course_id, "student_id": user_id},
        ).mappings().first()

        if not enrollment_row:
            raise HTTPException(status_code=403, detail="You are not enrolled in this course")
    # =========================
    # 3) Create session
    # =========================
    try:
        session_row = db.execute(
            text("""
                INSERT INTO ai_chat_sessions (
                    user_id,
                    course_id,
                    session_title,
                    context_type,
                    context_id,
                    is_active,
                    started_at
                )
                VALUES (
                    :user_id,
                    :course_id,
                    :session_title,
                    :context_type,
                    :context_id,
                    :is_active,
                    NOW()
                )
                RETURNING
                    id,
                    course_id,
                    session_title,
                    context_type,
                    is_active,
                    started_at,
                    last_message_at
            """),
            {
                "user_id": user_id,
                "course_id": course_id,
                "session_title": content[:50],
                "context_type": "course",
                "context_id": course_id,
                "is_active": True,
            },
        ).mappings().first()

        if not session_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to create session")

        # =========================
        # 4) Save user message
        # =========================
        message_row = db.execute(
            text("""
                INSERT INTO ai_chat_messages (
                    session_id,
                    message_type,
                    content,
                    created_at
                )
                VALUES (
                    :session_id,
                    'user',
                    :content,
                    NOW()
                )
                RETURNING
                    id,
                    session_id,
                    message_type,
                    content,
                    sources,
                    created_at
            """),
            {
                "session_id": int(session_row["id"]),
                "content": content,
            },
        ).mappings().first()

        if not message_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to save message")

        # =========================
        # 5) Update session last_message_at
        # =========================
        db.execute(
            text("""
                UPDATE ai_chat_sessions
                SET last_message_at = NOW()
                WHERE id = :session_id
            """),
            {"session_id": int(session_row["id"])},
        )

        # =========================
        # 7) Send AI request
        # =========================
        try:
            send_ai_request(
                db,
                operation_type="rag_chat",
                endpoint_path="/api/v1/courses/{project_id}/rag/answer",
                course_id=course_id,
                primary_entity_type="session",
                primary_entity_id=int(session_row["id"]),
                body={
                    "session_id": int(session_row["id"]),
                    "message_id": int(message_row["id"]),
                    "user_role": role,
                    "message": content,
                    "history": [],
                },
            )
        except Exception:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to send AI request")

        db.commit()

        return {
            "session": dict(session_row),
            "message": dict(message_row),
        }

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while creating session") from e

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e




