from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db

from .schemas import UpdateProfileRequest
from .schemas import UpdateProfileResponse
from .schemas import ChangePasswordRequest
from .schemas import ChangePasswordResponse
from .schemas import RequestDeleteAccountRequest
from .schemas import RequestDeleteAccountResponse
from .schemas import ConfirmDeleteAccountRequest
from .schemas import ConfirmDeleteAccountResponse

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

@router.patch("/password", response_model=ChangePasswordResponse)
def change_password(
    payload: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),):
    return service.change_password(
        payload=payload, 
        db=db, 
        current_user=current_user)

@router.post("/delete/request", response_model=RequestDeleteAccountResponse)
def request_delete_account(
    payload: RequestDeleteAccountRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),):
    return service.request_delete_account(
        payload=payload, 
        db=db, 
        current_user=current_user)


@router.delete("/delete/confirm", response_model=ConfirmDeleteAccountResponse)
def confirm_delete_account(
    payload: ConfirmDeleteAccountRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),):
    return service.confirm_delete_account(
        payload=payload, 
        db=db, 
        current_user=current_user)