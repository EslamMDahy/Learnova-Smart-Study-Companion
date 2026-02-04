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
from app.core.jwt import create_access_token
from app.core.token_store import mark_token_used

def register_user(payload, db: Session):
    # 1) Check email unique
    existing = db.execute(
        text("SELECT 1 FROM users WHERE email = :email"),
        {"email": payload.email},
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already exists")

    # 2) Decide logic based on account_type
    account_type = (payload.account_type or "").strip().lower()
    system_role = (payload.system_role or "").strip().lower()

    ALLOWED_USER_ROLES = {"student", "instructor", "assistant"}

    if account_type == "user":
        # invite_code required
        if not payload.invite_code or not str(payload.invite_code).strip():
            raise HTTPException(
                status_code=400,
                detail="Organization code is required",
            )

        org = db.execute(
            text("SELECT id FROM organizations WHERE invite_code = :code"),
            {"code": str(payload.invite_code).strip()},
        ).first()

        if not org:
            raise HTTPException(
                status_code=400,
                detail="Invalid organization code",
            )

        # ✅ validate system role
        if system_role not in ALLOWED_USER_ROLES:
            raise HTTPException(
                status_code=400,
                detail="Invalid user role. Choose student, instructor, or assistant.",
            )

    elif account_type == "owner":
        # owner doesn't need invite_code or role from frontend
        system_role = "owner"

    else:
        raise HTTPException(
            status_code=400,
            detail="Invalid account type",
        )


    # 3) Hash password
    hashed_pw = hash_password(payload.password)

    # 4) Insert user
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
            "system_role": system_role,
            "is_email_verified": False,
        },
    ).first()

    if not row:
        raise HTTPException(status_code=500, detail="Failed to create user")

    user_id = row[0]
    db.commit()

    # 5) Create verification token
    verify_token = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)

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

    # 6) Build verification link (fallback بدل RuntimeError)
    frontend_url = os.getenv("FRONTEND_BASE_URL", "http://localhost:5173")
    verify_link = f"{frontend_url.rstrip('/')}/#/verify-email?token={verify_token}"

    text_body = f"""
    Welcome to Learnova!

    Verify your email:
    {verify_link}

    This link expires in 24 hours.
    """

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <body style="margin:0;padding:0;background:#f6f7fb;font-family:Arial,sans-serif;">
        <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
            <td align="center" style="padding:24px;">
            <table width="520" style="background:#ffffff;border-radius:12px;padding:24px;border:1px solid #e5e7eb;">
                <tr>
                <td>
                    <h2 style="margin:0 0 12px;color:#111827;">
                    Welcome to Learnova 👋
                    </h2>
                    <p style="margin:0 0 16px;color:#374151;line-height:1.6;">
                    Please confirm your email address to activate your account.
                    </p>

                    <a href="{verify_link}"
                    style="
                        display:inline-block;
                        background:#137FEC;
                        color:#ffffff;
                        text-decoration:none;
                        padding:12px 20px;
                        border-radius:8px;
                        font-weight:600;
                        margin-bottom:16px;
                    ">
                    Verify Email
                    </a>

                    <p style="margin:16px 0 0;color:#6b7280;font-size:13px;">
                    This link expires in 24 hours.
                    </p>

                    <p style="margin:12px 0 0;color:#9ca3af;font-size:12px;">
                    If the button doesn’t work, copy and paste this link:<br>
                    <span style="word-break:break-all;">{verify_link}</span>
                    </p>
                </td>
                </tr>
            </table>
            </td>
        </tr>
        </table>
    </body>
    </html>
    """


    # 7) Send verification email (متبوظش التسجيل لو الإيميل وقع)
    try:
        send_email(
            to=payload.email,
            subject="Learnova – Verify your email",
            body=text_body,
            html=html_body,
        )
    except Exception:
        pass

    return {
        "message": "Registration successful. Please check your email.",
        "email_verification_required": True,
        "account_type": account_type,
    }



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
    row = db.execute(
        text("""
             SELECT
             id, full_name, email, avatar_url,
             system_role, hashed_password, 
             is_email_verified, token_version
             FROM users
             WHERE email = :email
             """
        ),
        {"email": payload.email},
    ).first()

    # 1) email مش موجود
    if not row:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    user_id, full_name, email, avatar_url, system_role, hashed_pw, is_verified, token_version = row

    # 2) باسورد غلط (قبل verification)
    if not verify_password(payload.password, hashed_pw):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # 3) هنا فقط نكشف أنه مش verified لأن credentials صح
    if not is_verified:
        raise HTTPException(status_code=403, detail="Email not verified")

    # 4) preparing the login response data
    user = {
        "id": user_id,
        "full_name": full_name,
        "email": email,
        "avatar_url": avatar_url,
        "system_role": system_role,
    }

    orgs = []
    if system_role == "owner":
        org_rows = db.execute(
            text("""
                SELECT
                id, name, description, logo_url,
                owner_id, subscription_plan_id, invite_code,
                subscription_status, subscription_started_at,
                subscription_renews_at, trial_ends_at
                FROM organizations
                WHERE owner_id = :uid
                ORDER BY id
            """),
            {"uid": user_id},
        ).all()

        orgs = [
            {
                "id": r[0],
                "name": r[1],
                "description": r[2],
                "logo_url": r[3],
                "owner_id": r[4],
                "subscription_plan_id": r[5],
                "invite_code": r[6],
                "subscription_status": r[7],
                "subscription_started_at": r[8],
                "subscription_renews_at": r[9],
                "trial_ends_at": r[10],
            }
            for r in org_rows
        ]


    # 5) Cereating JWT
    access_token = create_access_token(
        subject=str(user_id),
        extra={"email": email, "full_name": full_name, "tv": token_version},
    )

    # 6) Sending the login response
    resp = {
    "access_token": access_token,
    "token_type": "bearer",
    "user": user,
    }

    if system_role == "owner":
        resp["organizations"] = orgs

    return resp



def forget_password_request(payload, db):
    # 1) دور على اليوزر بالايميل
    row = db.execute(
        text("SELECT id, full_name, email, is_email_verified FROM users WHERE email = :email"),
        {"email": payload.email},
    ).first()
 
    # 2) رد ثابت سواء الايميل موجود او لا عشان السيكيورتي
    ok_response = {"message": "If this email exists, a reser link has been sent."}

    if not row:
        return ok_response
    
    user_id, full_name, email, is_verified = row

    # 3) نبطل اي ريسيت توكين قديمه لليوزر
    db.execute(
        text(
            """
            UPDATE user_tokens
            SET used_at = NOW()
            WHERE user_id = :uid AND type = 'reset_password' AND used_at IS NULL
            """
        ),
        {"uid": user_id}
    )

    # 4) نكريت توكين قويه 
    resetPass_token = secrets.token_urlsafe(32)

    # 5) الاكسبيريشن دايت هنخليه 15 دقيقه
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=15)

    # 6) store the token in the DB
    db.execute(
        text(
            """
            INSERT INTO user_tokens
            (user_id, type, token, expires_at, created_at)
            VALUES
            (:uid, :type, :token, :expires_at, NOW())
            """
        ),
        {"uid": user_id, "type": "reset_password", "token": resetPass_token, "expires_at": expires_at}
    ) 
    db.commit()
    
    
    frontend_url = os.getenv("FRONTEND_BASE_URL", "http://localhost:5173")
    reset_link = f"{frontend_url.rstrip('/')}/#/reset-password?token={resetPass_token}"

    subject = "Lernova - Reset your password"
    body = (
        f"hello {full_name or ''}\n\n"
        f"Click this link to reset your passwoed:\n{reset_link}\n\n"
        f"This link expires in 15 minutes.\n"
        f"If you didn't request this ignore this email."
    )

    send_email(to=email, subject=subject, body=body)

    return ok_response

    

def reset_password(payload, db):
    # 1) هات التوكن من DB لو صالح (مش مستخدم ولسه ما انتهيش)
    row = db.execute(
        text("""
            SELECT id, user_id, expires_at, used_at
            FROM user_tokens
            WHERE token = :token AND type = 'reset_password'
            LIMIT 1
            """
        ),
        {"token": payload.token},
    ).first()

    if not row:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    token_id, user_id, expires_at, used_at = row

    # 2) check used
    if used_at is not None:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    # 3) check expiry
    now = datetime.now(timezone.utc)
    # expires_at غالبًا timezone-aware من postgres
    if expires_at <= now:
        # نقدر نعمل used_at هنا كمان عشان نقفلها
        db.execute(
            text("UPDATE user_tokens SET used_at = NOW() WHERE id = :tid"),
            {"tid": token_id},
        )
        db.commit()
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    # 4) hash new password
    new_hashed = hash_password(payload.new_password)

    # 5) update user password
    db.execute(
        text("""
            UPDATE users
            SET hashed_password = :hp, 
                updated_at = NOW(),
                token_version = token_version + 1
            WHERE id = :uid
            """
        ),
        {"hp": new_hashed, "uid": user_id},
    )

    # 6) mark token used
    db.execute(
        text("UPDATE user_tokens SET used_at = NOW() WHERE id = :tid"),
        {"tid": token_id},
    )

    db.commit()

    return {"message": "Password reset successfully"}    