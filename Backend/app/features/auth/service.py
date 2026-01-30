from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException

from app.core.security import hash_password
from app.core.emailer import send_email

from .schemas import RegisterRequest

# pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def register_user(payload: RegisterRequest, db: Session):
    # 1) Check email unique
    existing = db.execute(
        text("SELECT 1 FROM users WHERE email = :email"),
        {"email": payload.email},
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already exists")

    # 2) Check invite code exists (organizations table)
    org = db.execute(
        text("SELECT id FROM organizations WHERE invite_code = :code"),
        {"code": payload.invite_code},
    ).first()
    if not org:
        raise HTTPException(status_code=400, detail="Invalid invite code")

    # 3) Hash password
    hashed_pw = hash_password(payload.password)

    # 4) Insert user
    db.execute(
        text(
            "INSERT INTO users (full_name, email, password) "
            "VALUES (:full_name, :email, :password)"
        ),
        {"full_name": payload.full_name, "email": payload.email, "password": hashed_pw},
    )
    db.commit()

    return {"ok": True, "email": payload.email, "full_name": payload.full_name}
