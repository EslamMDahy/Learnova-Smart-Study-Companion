from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException

from .schemas import RegisterRequest

from app.core.security import hash_password
from app.core.emailer import send_email

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
        {"code": str(payload.invite_code)},
    ).first()
    if not org:
        raise HTTPException(status_code=400, detail="Invalid invite code")

    # 3) Hash password
    hashed_pw = hash_password(payload.password)

    # 4) Insert user (لاحظ: hashed_password + أعمدة NOT NULL)
    db.execute(
        text(
            """
            INSERT INTO users
            (full_name, email, hashed_password, system_role, is_email_verified, created_at, updated_at)
            VALUES
            (:full_name, :email, :hashed_password, :system_role, :is_email_verified, NOW(), NOW())
            """
        ),
        {
            "full_name": payload.full_name,
            "email": payload.email,
            "hashed_password": hashed_pw,
            "system_role": "student",
            "is_email_verified": False,
        },
    )
    db.commit()

    # 5) Send dummy email (بعد الـ commit)
    try:
        send_email(
            to=payload.email,
            subject="Learnova - Test Email",
            body="Hello! This is a test email after registration."
        )

    except Exception:
        # مهم: منبوّظش التسجيل لو الإيميل وقع
        pass

    return {"message": "Registration successful. Please check your email."}
