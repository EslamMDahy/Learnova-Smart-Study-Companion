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
# from app.core.token_store import mark_token_used

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

        org_code = org[0]

        # validate system role
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

    # 4.5) Insert organization_member for normal users (pending by default)
    if account_type == "user":
        db.execute(
            text(
                """
                INSERT INTO organization_members (organization_id, user_id, role, status)
                VALUES (:org_id, :user_id, :role, :status)
                """
            ),
            {
                "org_id": org_code, # type: ignore
                "user_id": user_id,
                "role": system_role,  # نفس users.system_role (انت أكدت)
                "status": "pending",
            },
        )


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
    logo_url = ""
    brand_year = 2026
    support_email = "support@learnova.com"

    text_body = f"""
    Welcome to Learnova!

    Verify your email:
    {verify_link}

    This link expires in 24 hours.
    """
    html_body = f"""
    <!DOCTYPE html>
    <html lang="en">
    <body style="margin:0;padding:0;background:#f6f7fb;font-family:Arial,sans-serif;">
        <!-- Preheader (hidden) -->
        <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">
        Verify your email to activate your Learnova account.
        </div>

        <table width="100%" cellpadding="0" cellspacing="0" style="background:#f6f7fb;">
        <tr>
            <td align="center" style="padding:28px 16px;">

            <!-- Outer container -->
            <table width="560" cellpadding="0" cellspacing="0" style="width:560px;max-width:560px;">

                <!-- Brand header -->
                <tr>
                <td align="left" style="padding:0 8px 14px;">
                    <table cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="vertical-align:middle;">
                        <img src="{logo_url}" width="40" height="40" alt="Learnova"
                            style="display:block;border:0;outline:none;border-radius:10px;" />
                        </td>
                        <td style="vertical-align:middle;padding-left:10px;">
                        <div style="font-size:16px;font-weight:800;color:#111827;line-height:1;">
                            Learnova
                        </div>
                        <div style="font-size:12px;color:#6b7280;margin-top:2px;">
                            Email Verification
                        </div>
                        </td>
                    </tr>
                    </table>
                </td>
                </tr>

                <!-- Card -->
                <tr>
                <td style="background:#ffffff;border:1px solid #e5e7eb;border-radius:16px;overflow:hidden;">
                    <!-- Top accent -->
                    <div style="height:6px;background:#137FEC;"></div>

                    <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="padding:26px 26px 10px;">
                        <h2 style="margin:0;color:#111827;font-size:22px;line-height:1.25;">
                            Welcome to Learnova 👋
                        </h2>
                        <p style="margin:10px 0 0;color:#374151;line-height:1.7;font-size:14px;">
                            Please confirm your email address to activate your account.
                        </p>

                        <!-- Button -->
                        <table cellpadding="0" cellspacing="0" style="margin-top:18px;">
                            <tr>
                            <td align="center" bgcolor="#137FEC" style="border-radius:10px;">
                                <a href="{verify_link}"
                                style="display:inline-block;padding:12px 18px;font-size:14px;font-weight:700;
                                        color:#ffffff;text-decoration:none;border-radius:10px;">
                                Verify Email
                                </a>
                            </td>
                            </tr>
                        </table>

                        <!-- Info chips -->
                        <table cellpadding="0" cellspacing="0" style="margin-top:16px;">
                            <tr>
                            <td style="background:#F3F4F6;border:1px solid #E5E7EB;border-radius:999px;padding:6px 10px;">
                                <span style="font-size:12px;color:#374151;">
                                ⏳ Expires in 24 hours
                                </span>
                            </td>
                            <td style="width:10px;"></td>
                            <td style="background:#EAF3FF;border:1px solid #BBD9FF;border-radius:999px;padding:6px 10px;">
                                <span style="font-size:12px;color:#1F4B99;">
                                🔒 Secure link
                                </span>
                            </td>
                            </tr>
                        </table>

                        </td>
                    </tr>

                    <!-- Divider -->
                    <tr>
                        <td style="padding:0 26px;">
                        <div style="height:1px;background:#E5E7EB;"></div>
                        </td>
                    </tr>

                    <!-- Fallback link -->
                    <tr>
                        <td style="padding:14px 26px 24px;">
                        <p style="margin:0;color:#6b7280;font-size:12px;line-height:1.6;">
                            If the button doesn’t work, copy and paste this link into your browser:
                        </p>
                        <p style="margin:10px 0 0;font-size:12px;line-height:1.6;">
                            <a href="{verify_link}" style="color:#137FEC;text-decoration:none;word-break:break-all;">
                            {verify_link}
                            </a>
                        </p>

                        <p style="margin:16px 0 0;color:#9ca3af;font-size:12px;line-height:1.6;">
                            If you didn’t create an account, you can safely ignore this email.
                        </p>
                        </td>
                    </tr>
                    </table>
                </td>
                </tr>

                <!-- Footer -->
                <tr>
                <td align="center" style="padding:14px 10px 0;">
                    <p style="margin:0;color:#9ca3af;font-size:12px;line-height:1.6;">
                    © {brand_year} Learnova. All rights reserved.
                    </p>
                    <p style="margin:6px 0 0;color:#9ca3af;font-size:12px;line-height:1.6;">
                    Need help? Contact us at <a href="mailto:{support_email}" style="color:#137FEC;text-decoration:none;">{support_email}</a>
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

    plan_name = None

    if system_role != "owner":
        plan_name = db.execute(
            text("""
                SELECT sp.name
                FROM organization_members om
                JOIN organizations o ON o.id = om.organization_id
                JOIN subscription_plans sp ON sp.id = o.subscription_plan_id
                WHERE om.user_id = :uid
                LIMIT 1
            """),
            {"uid": user_id},
        ).scalar()

        user["subscription_plan_name"] = plan_name

    # 5) Cereating JWT
    access_token = create_access_token(
        subject=str(user_id),
        extra={"email": email, "full_name": full_name, "tv": token_version, "system_role": system_role},
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

    logo_url = ""

    brand_year = 2026
    support_email = "support@learnova.com"

    subject = "Learnova – Reset your password"

    text_body = f"""
    Hello {full_name or ''}

    We received a request to reset your Learnova password.

    Reset your password:
    {reset_link}

    This link expires in 15 minutes.

    If you didn't request this, you can safely ignore this email.
    """
    html_body = f"""
    <!DOCTYPE html>
    <html lang="en">
    <body style="margin:0;padding:0;background:#f6f7fb;font-family:Arial,sans-serif;">
        <!-- Preheader -->
        <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">
        Reset your Learnova password
        </div>

        <table width="100%" cellpadding="0" cellspacing="0" style="background:#f6f7fb;">
        <tr>
            <td align="center" style="padding:28px 16px;">

            <table width="560" cellpadding="0" cellspacing="0" style="max-width:560px;">

                <!-- Brand -->
                <tr>
                <td style="padding:0 8px 14px;">
                    <table cellpadding="0" cellspacing="0">
                    <tr>
                        <td>
                        <img src="{logo_url}" width="40" height="40" alt="Learnova"
                            style="display:block;border-radius:10px;" />
                        </td>
                        <td style="padding-left:10px;">
                        <div style="font-size:16px;font-weight:800;color:#111827;">
                            Learnova
                        </div>
                        <div style="font-size:12px;color:#6b7280;">
                            Password Reset
                        </div>
                        </td>
                    </tr>
                    </table>
                </td>
                </tr>

                <!-- Card -->
                <tr>
                <td style="background:#ffffff;border:1px solid #e5e7eb;border-radius:16px;">
                    <div style="height:6px;background:#137FEC;border-radius:16px 16px 0 0;"></div>

                    <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="padding:26px;">
                        <h2 style="margin:0 0 12px;color:#111827;font-size:22px;">
                            Reset your password 🔒
                        </h2>

                        <p style="margin:0 0 18px;color:#374151;line-height:1.7;font-size:14px;">
                            We received a request to reset your password. Click the button
                            below to choose a new one.
                        </p>

                        <!-- Button -->
                        <table cellpadding="0" cellspacing="0">
                            <tr>
                            <td bgcolor="#137FEC" style="border-radius:10px;">
                                <a href="{reset_link}"
                                style="display:inline-block;padding:12px 18px;
                                        font-size:14px;font-weight:700;
                                        color:#ffffff;text-decoration:none;
                                        border-radius:10px;">
                                Reset Password
                                </a>
                            </td>
                            </tr>
                        </table>

                        <!-- Info -->
                        <table cellpadding="0" cellspacing="0" style="margin-top:16px;">
                            <tr>
                            <td style="background:#FFF7ED;border:1px solid #FED7AA;
                                        border-radius:999px;padding:6px 10px;">
                                <span style="font-size:12px;color:#9A3412;">
                                ⏳ Expires in 15 minutes
                                </span>
                            </td>
                            </tr>
                        </table>

                        <p style="margin:16px 0 0;color:#6b7280;font-size:12px;line-height:1.6;">
                            If you didn’t request a password reset, you can safely ignore
                            this email.
                        </p>

                        </td>
                    </tr>

                    <!-- Divider -->
                    <tr>
                        <td style="padding:0 26px;">
                        <div style="height:1px;background:#e5e7eb;"></div>
                        </td>
                    </tr>

                    <!-- Fallback -->
                    <tr>
                        <td style="padding:14px 26px 24px;">
                        <p style="margin:0;color:#9ca3af;font-size:12px;">
                            If the button doesn’t work, copy and paste this link:
                        </p>
                        <p style="margin:8px 0 0;font-size:12px;word-break:break-all;">
                            <a href="{reset_link}"
                            style="color:#137FEC;text-decoration:none;">
                            {reset_link}
                            </a>
                        </p>
                        </td>
                    </tr>

                    </table>
                </td>
                </tr>

                <!-- Footer -->
                <tr>
                <td align="center" style="padding:14px 10px 0;">
                    <p style="margin:0;color:#9ca3af;font-size:12px;">
                    © {datetime.now().year} Learnova. All rights reserved.
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


    try:
        send_email(
            to=email,
            subject=subject,
            body=text_body,
            html=html_body,
        )
    except Exception:
        pass


    return ok_response

    

def reset_password(payload, db):
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