from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

import json


def save_rag_chat_response(*, db: Session, session_id: int, user_message_id: int, content: str, sources: list | None,) -> dict:
    try:
        # =========================
        # 1) Insert assistant message
        # =========================
        assistant_row = db.execute(
            text("""
                INSERT INTO ai_chat_messages (
                    session_id,
                    message_type,
                    content,
                    sources,
                    user_message_id,
                    status,
                    created_at
                )
                VALUES (
                    :session_id,
                    'assistant',
                    :content,
                    CAST(:sources AS jsonb),
                    :user_message_id,
                    'completed',
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
                "sources": json.dumps(sources) if sources is not None else None,
                "user_message_id": user_message_id,
            },
        ).mappings().first()

        if not assistant_row:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Failed to save assistant message",
            )

        # =========================
        # 2) Mark user message as completed
        # =========================
        db.execute(
            text("""
                UPDATE ai_chat_messages
                SET status = 'completed'
                WHERE id = :user_message_id
            """),
            {"user_message_id": user_message_id},
        )

        # =========================
        # 3) Update session last_message_at
        # =========================
        db.execute(
            text("""
                UPDATE ai_chat_sessions
                SET last_message_at = NOW()
                WHERE id = :session_id
            """),
            {"session_id": session_id},
        )

        return dict(assistant_row)

    except HTTPException:
        raise

    except IntegrityError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Conflict while saving assistant message",
        ) from e

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error while saving assistant message",
        ) from e