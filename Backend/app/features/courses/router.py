from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user
from . import service
from .schemas import CourseCreateRequest, CourseCreateResponse

router = APIRouter(prefix="/courses", tags=["courses"])

@router.post("", response_model=CourseCreateResponse, status_code=status.HTTP_201_CREATED)
def create_course(
    payload: CourseCreateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.create_course(
        payload=payload, 
        db=db, 
        current_user=current_user)
