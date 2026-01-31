from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from fastapi import HTTPException

# from app.core.emailer import send_email
from app.db.session import get_db
from .schemas import RegisterRequest
from . import service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", status_code=201)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    return service.register_user(payload, db)


