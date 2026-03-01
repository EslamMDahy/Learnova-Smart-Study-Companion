# app/features/questions/router.py
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user

from app.features.questions import service
from app.features.questions.schemas import (MaterialQuestionsBatchCreateRequest,
                                            MaterialQuestionsBatchCreateResponse,)

router = APIRouter(prefix="/courses/{course_id}", tags=["Questions"],)

@router.post("/modules/{module_id}/materials/{material_id}/questions", response_model=MaterialQuestionsBatchCreateResponse,status_code=status.HTTP_201_CREATED,)
def create_material_questions_batch(
    course_id: int,
    module_id: int,
    material_id: int,
    payload: MaterialQuestionsBatchCreateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.create_material_questions_batch(
        course_id=course_id,
        module_id=module_id,
        material_id=material_id,
        payload=payload,
        db=db,
        current_user=current_user,)