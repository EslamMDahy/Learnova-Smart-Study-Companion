from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user

from . import service
from .schemas import QuestionCreateRequest, QuestionCreateResponse

router = APIRouter(prefix="/courses/{course_id}/questions", tags=["Questions"],)


@router.post("", response_model=QuestionCreateResponse, status_code=status.HTTP_201_CREATED)
def create_question(
    course_id: int,
    payload: QuestionCreateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.create_question(
        course_id=course_id,
        payload=payload,
        db=db,
        current_user=current_user,)