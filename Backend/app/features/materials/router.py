from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user

from . import service
from .schemas import (
    MaterialInitUploadRequest,
    MaterialInitUploadResponse,
    MaterialConfirmUploadRequest,
    MaterialConfirmUploadResponse,)

router = APIRouter(tags=["Materials"])


# =========================
# Init upload (nested under course + module)
# =========================
@router.post("/courses/{course_id}/modules/{module_id}/materials/init-upload",
    response_model=MaterialInitUploadResponse,
    status_code=status.HTTP_201_CREATED,)
def init_material_upload(
    course_id: int,
    module_id: int,
    payload: MaterialInitUploadRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.init_material_upload(
        course_id=course_id,
        module_id=module_id,
        payload=payload,
        db=db,
        current_user=current_user,)


# =========================
# Confirm upload (by material id)
# =========================
@router.post("/materials/{material_id}/confirm-upload",
    response_model=MaterialConfirmUploadResponse,
    status_code=status.HTTP_200_OK,)
def confirm_material_upload(
    material_id: int,
    payload: MaterialConfirmUploadRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.confirm_material_upload(
        material_id=material_id,
        payload=payload,
        db=db,
        current_user=current_user,)