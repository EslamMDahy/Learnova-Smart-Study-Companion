from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db

from .schemas import UpdateProfileRequest
from .schemas import UpdateProfileResponse
from . import service


router = APIRouter(prefix="/settings", tags=["settings"])


@router.patch("/profile", response_model=UpdateProfileResponse)
def update_profile(
    payload: UpdateProfileRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),):
    return service.update_profile(
        payload=payload, 
        db=db, 
        current_user=current_user)
