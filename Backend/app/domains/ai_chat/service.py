from __future__ import annotations

import json

from fastapi.responses import StreamingResponse
from fastapi import HTTPException

from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

from typing import Any

from app.db.session import SessionLocal
from app.core.config import settings
from app.core.event_bus.subscribe import subscribe
from app.core.ai_service_integration.ai_transport import send_ai_request

from .helpers import save_rag_chat_response
from .normalization import normalize_message_row, normalize_sources
from .schemas import SessionCreateRequest


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
                    status,
                    created_at
                )
                VALUES (
                    :session_id,
                    'user',
                    :content,
                    'pending',
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
                endpoint_path="/api/v1/courses/rag/answer",
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
        except Exception as exc:
            _save_ai_dispatch_failure_response(
                db=db,
                session_id=int(session_row["id"]),
                user_message_id=int(message_row["id"]),
                exc=exc,
            )

        db.commit()

        return {
            "session": dict(session_row),
            "message": normalize_message_row(message_row),
        }

    except IntegrityError as e:
        db.rollback()
        print(e)
        raise HTTPException(status_code=409, detail="Conflict while creating session") from e

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def _save_ai_dispatch_failure_response(*, db: Session, session_id: int, user_message_id: int, exc: Exception,) -> None:
    # Keep the chat flow usable even when the external AI worker is down or
    # misconfigured. The user message is saved, the frontend can still call the
    # stream endpoint, and the stream returns this completed assistant message
    # immediately instead of failing the whole POST with 503. The real root
    # cause is still stored in ai_request_logs by send_ai_request when possible.
    save_rag_chat_response(
        db=db,
        session_id=session_id,
        user_message_id=user_message_id,
        content=(
            "AI service is currently unavailable. Please make sure the AI "
            "worker is running and AI_SERVICE_BASE_URL points to it, then try again."
        ),
        sources=[],
    )


def list_sessions(*, course_id: int, db: Session, current_user: dict,):
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

    try:
        # =========================
        # 2) Validate course exists + access
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
        # 3) Fetch sessions
        # =========================
        session_rows = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    is_active,
                    session_title,
                    started_at,
                    last_message_at
                FROM ai_chat_sessions
                WHERE course_id = :course_id
                  AND user_id = :user_id
                ORDER BY last_message_at DESC
            """),
            {
                "course_id": course_id,
                "user_id": user_id,
            },
        ).mappings().all()

        sessions = [dict(row) for row in session_rows]

        return {
            "course_id": course_id,
            "total": len(sessions),
            "sessions": sessions,
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e



def get_session(*, course_id: int, session_id: int, db: Session, current_user: dict,):
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

    if not session_id or session_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid session_id")

    try:
        # =========================
        # 2) Validate course exists + access
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
        # 3) Validate session ownership
        # =========================
        session_row = db.execute(
            text("""
                SELECT
                    id,
                    course_id,
                    context_type,
                    session_title,
                    is_active,
                    started_at,
                    last_message_at
                FROM ai_chat_sessions
                WHERE id = :session_id
                  AND course_id = :course_id
                  AND user_id = :user_id
                LIMIT 1
            """),
            {
                "session_id": session_id,
                "course_id": course_id,
                "user_id": user_id,
            },
        ).mappings().first()

        if not session_row:
            raise HTTPException(status_code=404, detail="Session not found")

        # =========================
        # 4) Fetch messages
        # =========================
        message_rows = db.execute(
            text("""
                SELECT
                    id,
                    session_id,
                    message_type,
                    content,
                    sources,
                    created_at
                FROM ai_chat_messages
                WHERE session_id = :session_id
                 AND status = 'completed'
                ORDER BY created_at ASC
            """),
            {"session_id": session_id},
        ).mappings().all()

        return {
            **dict(session_row),
            "messages": [normalize_message_row(row) for row in message_rows],
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e



def send_message(*, course_id: int, session_id: int, payload: SessionCreateRequest, db: Session, current_user: dict,):
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

    if not session_id or session_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid session_id")

    content = payload.content.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Message content is required")

    try:
        # =========================
        # 2) Validate course exists + access
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
        # 3) Validate session ownership + is_active
        # =========================
        session_row = db.execute(
            text("""
                SELECT id, is_active
                FROM ai_chat_sessions
                WHERE id = :session_id
                  AND course_id = :course_id
                  AND user_id = :user_id
                LIMIT 1
            """),
            {
                "session_id": session_id,
                "course_id": course_id,
                "user_id": user_id,
            },
        ).mappings().first()

        if not session_row:
            raise HTTPException(status_code=404, detail="Session not found")

        if not session_row["is_active"]:
            raise HTTPException(status_code=400, detail="Session is no longer active")

        # =========================
        # 4) Fetch chat history
        # =========================
        history_rows = db.execute(
            text("""
                SELECT message_type, content
                FROM ai_chat_messages
                WHERE session_id = :session_id
                 AND status = 'completed'
                ORDER BY created_at ASC
            """),
            {"session_id": session_id},
        ).mappings().all()

        history = [
            {
                "role": "user" if row["message_type"] == "user" else "assistant",
                "content": row["content"],
            }
            for row in history_rows
        ]

        # =========================
        # 5) Save user message
        # =========================
        message_row = db.execute(
            text("""
                INSERT INTO ai_chat_messages (
                    session_id,
                    message_type,
                    content,
                    status,
                    created_at
                )
                VALUES (
                    :session_id,
                    'user',
                    :content,
                    'pending',
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
                "session_id": session_id,
                "content": content,
            },
        ).mappings().first()

        if not message_row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to save message")

        # =========================
        # 6) Update session last_message_at
        # =========================
        db.execute(
            text("""
                UPDATE ai_chat_sessions
                SET last_message_at = NOW()
                WHERE id = :session_id
            """),
            {"session_id": session_id},
        )

        # =========================
        # 7) Send AI request
        # =========================
        try:
            send_ai_request(
                db,
                operation_type="rag_chat",
                endpoint_path="/api/v1/courses/rag/answer",
                course_id=course_id,
                primary_entity_type="session",
                primary_entity_id=session_id,
                body={
                    "session_id": session_id,
                    "message_id": int(message_row["id"]),
                    "user_role": role,
                    "message": content,
                    "history": history,
                },
            )
        except Exception as exc:
            _save_ai_dispatch_failure_response(
                db=db,
                session_id=session_id,
                user_message_id=int(message_row["id"]),
                exc=exc,
            )

        db.commit()

        return normalize_message_row(message_row)

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while sending message") from e

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



async def stream_message(*, course_id: int, session_id: int, message_id: int, db: Session, current_user: dict,):
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

    if not session_id or session_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid session_id")

    if not message_id or message_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid message_id")

    # =========================
    # 2) Validate course exists + access
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
    # 3) Validate session ownership
    # =========================
    session_row = db.execute(
        text("""
            SELECT id
            FROM ai_chat_sessions
            WHERE id = :session_id
              AND course_id = :course_id
              AND user_id = :user_id
            LIMIT 1
        """),
        {
            "session_id": session_id,
            "course_id": course_id,
            "user_id": user_id,
        },
    ).mappings().first()

    if not session_row:
        raise HTTPException(status_code=404, detail="Session not found")

    # =========================
    # 4) Validate message exists
    # =========================
    message_row = db.execute(
        text("""
            SELECT id, status
            FROM ai_chat_messages
            WHERE id = :message_id
              AND session_id = :session_id
              AND message_type = 'user'
            LIMIT 1
        """),
        {
            "message_id": message_id,
            "session_id": session_id,
        },
    ).mappings().first()

    if not message_row:
        raise HTTPException(status_code=404, detail="Message not found")

    if message_row["status"] == "failed":
        raise HTTPException(status_code=400, detail="Message processing failed")

    if message_row["status"] == "completed":
        assistant_row = db.execute(
            text("""
                SELECT
                    id,
                    session_id,
                    message_type,
                    content,
                    sources,
                    created_at
                FROM ai_chat_messages
                WHERE user_message_id = :message_id
                  AND status = 'completed'
                LIMIT 1
            """),
            {"message_id": message_id},
        ).mappings().first()

        if not assistant_row:
            raise HTTPException(status_code=404, detail="Assistant message not found")

        assistant_data = dict(assistant_row)

        db.close()

        async def completed_generator():
            data = json.dumps({
                "id": assistant_data["id"],
                "session_id": assistant_data["session_id"],
                "message_type": assistant_data["message_type"],
                "content": assistant_data["content"],
                "sources": normalize_sources(assistant_data["sources"]),
                "created_at": assistant_data["created_at"].isoformat(),
            })
            yield f"event: message\ndata: {data}\n\n"

        return StreamingResponse(
            completed_generator(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
            },
        )
    
    # =========================
    # 6) Stream response
    # =========================
    async def event_generator():
        async for payload in subscribe(
            channel=f"chat_{message_id}",
            timeout=float(settings.ai_request_timeout_seconds),
        ):
            if not payload:
                # =========================
                # 7) Timeout — mark message as failed
                # =========================
                local_db = SessionLocal()
                try:
                    local_db.execute(
                        text("""
                            UPDATE ai_chat_messages
                            SET status = 'failed'
                            WHERE id = :message_id
                        """),
                        {"message_id": message_id},
                    )
                    local_db.commit()
                except SQLAlchemyError:
                    local_db.rollback()
                finally:
                    local_db.close()

                yield "event: timeout\ndata: {\"detail\": \"AI response timed out\"}\n\n"
                return

            # =========================
            # 8) Fetch assistant message and send to frontend
            # =========================
            local_db = SessionLocal()
            try:
                assistant_row = local_db.execute(
                    text("""
                        SELECT
                            id,
                            session_id,
                            message_type,
                            content,
                            sources,
                            created_at
                        FROM ai_chat_messages
                        WHERE user_message_id = :message_id
                          AND status = 'completed'
                        LIMIT 1
                    """),
                    {"message_id": message_id},
                ).mappings().first()

                if not assistant_row:
                    yield "event: error\ndata: {\"detail\": \"Assistant message not found\"}\n\n"
                    return

                data = json.dumps({
                    "id": assistant_row["id"],
                    "session_id": assistant_row["session_id"],
                    "message_type": assistant_row["message_type"],
                    "content": assistant_row["content"],
                    "sources": normalize_sources(assistant_row["sources"]),
                    "created_at": assistant_row["created_at"].isoformat(),
                })

                yield f"event: message\ndata: {data}\n\n"

            except SQLAlchemyError:
                yield "event: error\ndata: {\"detail\": \"Database error\"}\n\n"

            finally:
                local_db.close()

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )



