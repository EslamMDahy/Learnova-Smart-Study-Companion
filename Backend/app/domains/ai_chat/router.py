from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user

from . import service
from .schemas import (SessionCreateRequest,
                      CreateSessionResponse,
                      SessionListResponse,
                      SessionWithMessagesResponse)


router = APIRouter(prefix="/courses/{course_id}/ai-chat", tags=["AI Chat"],)


@router.post("/sessions", response_model=CreateSessionResponse, status_code=status.HTTP_201_CREATED,)
def create_session_endpoint(
    course_id: int,
    payload: SessionCreateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.create_session(
        course_id=course_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.get("/sessions", response_model=SessionListResponse,)
def list_sessions_endpoint(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_sessions(
        course_id=course_id,
        db=db,
        current_user=current_user,)

@router.get("/sessions/{session_id}", response_model=SessionWithMessagesResponse,)
def get_session_endpoint(
    course_id: int,
    session_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.get_session(
        course_id=course_id,
        session_id=session_id,
        db=db,
        current_user=current_user,)

@router.get("/sessions/{session_id}/messages/{message_id}/stream",)
async def stream_message_endpoint(
    course_id: int,
    session_id: int,
    message_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return await service.stream_message(
        course_id=course_id,
        session_id=session_id,
        message_id=message_id,
        db=db,
        current_user=current_user,)

