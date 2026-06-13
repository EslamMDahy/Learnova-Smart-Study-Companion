from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user

from . import service
from .schemas import (SessionCreateRequest,
                      CreateSessionResponse,)


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