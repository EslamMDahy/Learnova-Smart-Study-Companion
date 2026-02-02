from fastapi import HTTPException

from sqlalchemy.orm import Session
from sqlalchemy import text

import secrets
import os

from datetime import datetime, timedelta, timezone

from .schemas import RegisterRequest
from .schemas import LoginRequest

from app.core.security import hash_password
from app.core.security import verify_password
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
    row = db.execute(
    text(
        """
        INSERT INTO users (full_name, email, hashed_password, system_role, is_email_verified, created_at, updated_at)
        VALUES (:full_name, :email, :hashed_password, :system_role, :is_email_verified, NOW(), NOW())
        RETURNING id
        """
    ),
    {
        "full_name": payload.full_name,
        "email": payload.email,
        "hashed_password": hashed_pw,
        "system_role": "student",         # أو أي default عندك
        "is_email_verified": False,
    },
    ).first()

    user_id = row[0] # type: ignore
    db.commit()

    # 5) Create verification token
    verify_token = secrets.token_urlsafe(32)

    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)  # مثال: 30 دقيقة

    db.execute(
        text(
            """
            INSERT INTO user_tokens (user_id, type, token, expires_at, created_at)
            VALUES (:user_id, :type, :token, :expires_at, NOW())
            """
        ),
        {
            "user_id": user_id,
            "type": "verify_email",
            "token": verify_token,
            "expires_at": expires_at,
        },
    )
    db.commit()

    # 6) building the verification link
    base_url = os.getenv("API_BASE_URL")
    if not base_url:
        raise RuntimeError("Missing API_BASE_URL env var")

    verify_link = f"{base_url.rstrip('/')}/auth/verify-email?token={verify_token}"


    # 7) Send verification email (بعد الـ commit)
    try:
        send_email(
            to=payload.email,
            subject="Learnova - Verify your email",
            body=f"Welcome to Learnova!\n\nVerify your email:\n{verify_link}\n\nThis link expires in 24 hours.",
        )

    except Exception:
        # مهم: منبوّظش التسجيل لو الإيميل وقع
        pass

    return {"message": "Registration successful. Please check your email."}


def verify_email_token(token: str, db: Session):
    # 1) fetch token row
    row = db.execute(
        text("""
            SELECT id, user_id, expires_at, used_at
            FROM user_tokens
            WHERE token = :token AND type = 'verify_email'
        """),
        {"token": token},
    ).first()

    if row is None:
        raise HTTPException(status_code=400, detail="Invalid verification token")

    token_id, user_id, expires_at, used_at = row

    # 2) already used?
    if used_at is not None:
        raise HTTPException(status_code=400, detail="Token already used")

    # 3) expired?
    # expires_at جاي من DB كـ timestamp with time zone، فالمقارنة مباشرة مع NOW() أسهل داخل SQL
    expired = db.execute(
        text("SELECT (NOW() > :expires_at)"),
        {"expires_at": expires_at},
    ).scalar()

    if expired:
        raise HTTPException(status_code=400, detail="Token expired")

    # 4) mark user verified + mark token used
    db.execute(
        text("UPDATE users SET is_email_verified = TRUE, updated_at = NOW() WHERE id = :uid"),
        {"uid": user_id},
    )

    db.execute(
        text("UPDATE user_tokens SET used_at = NOW() WHERE id = :tid"),
        {"tid": token_id},
    )

    db.commit()

    return {"message": "Email verified successfully"}

def login_user(payload: LoginRequest, db: Session):
    # 1) هات بيانات اليوزر الأساسية (بـ email)
    row = db.execute( # type: ignore
        text(
            """
            SELECT id, full_name, email, hashed_password, is_email_verified
            FROM users
            WHERE email = :email
            """
        ),
        {"email": payload.email},
    ).first()

    # 2) لو الإيميل مش موجود => 401 (نفس رسالة الباسورد الغلط)
    if not row:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    user_id, full_name, email, hashed_pw, is_verified = row

    # 3) لو مش verified => 403
    if not is_verified:
        raise HTTPException(status_code=403, detail="Email not verified")

    # 4) لو الباسورد غلط => 401
    if not verify_password(payload.password, hashed_pw):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # 5) نجاح (لسه مفيش JWT هنا)
    return {
        "message": "Login OK",
        "user": {"id": user_id, "email": email, "full_name": full_name},
    }