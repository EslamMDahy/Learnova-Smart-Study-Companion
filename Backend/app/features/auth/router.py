from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.core.emailer import send_email
from app.db.session import get_db
from .schemas import RegisterRequest
from . import service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", status_code=201)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    return service.register_user(payload, db)

@router.post("/send-test-email")
def send_test_email():
    try:
        send_email(
            to_email="YOUR_EMAIL_HERE",
            subject="Learnova Test Email",
            body="Hello from Learnova backend ✅",
        )
        return {"ok": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
