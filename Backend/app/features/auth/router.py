from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.db.session import get_db

from .schemas import RegisterRequest
from .schemas import LoginRequest
from .schemas import ForgetPasswordRequest
from .schemas import ForgetPasswordResponse
from .schemas import ResetPasswordRequest
from .schemas import ResetPasswordResponse
from . import service
from app.core.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", status_code=201)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    return service.register_user(payload, db)

@router.get("/verify-email")
def verify_email(token: str = Query(...), db: Session = Depends(get_db)):
    return service.verify_email_token(token, db)

@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    return service.login_user(payload, db)

@router.get("/me")
def me(user = Depends(get_current_user)):
    return {"user": user}

@router.post("/forgot-password", response_model=ForgetPasswordResponse)
def forget_password(payload:ForgetPasswordRequest, db: Session = Depends(get_db)):
    return service.forget_password_request(payload, db)

@router.post("/reset-password", response_model=ResetPasswordResponse)
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    return service.reset_password(payload, db)

