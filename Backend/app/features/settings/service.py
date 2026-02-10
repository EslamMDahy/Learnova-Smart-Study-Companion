from fastapi import HTTPException

from sqlalchemy.orm import Session
from sqlalchemy import text

import secrets
import os

from datetime import datetime, timezone, timedelta

from .schemas import UpdateProfileRequest

from app.core.security import hash_password
from app.core.security import verify_password  # عدّل import حسب مكانهم عندك
from app.core.emailer import send_email 

# DELETE_OTP_TTL_MINUTES = 10
# DELETE_OTP_TYPE = "delete_account_otp"


def _generate_otp() -> str:
    return secrets.token_hex(3)

def update_profile(*, payload: UpdateProfileRequest, db: Session, current_user):
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    # NOTE: phone/bio intentionally ignored for now (no DB columns yet)

    update_fields = {}
    if payload.full_name != "":
        if payload.full_name is not None:
            update_fields["full_name"] = payload.full_name.strip()
    # avatar url can be updated to nothing or "" (deleted)
    if payload.avatar_url is not None:
        update_fields["avatar_url"] = payload.avatar_url.strip()

    if not update_fields:
        # مفيش حاجة تتعمل
        raise HTTPException(status_code=400, detail="No updatable fields provided")

    # Build dynamic SQL safely (only whitelisted columns)
    set_clauses = []
    params = {"uid": user_id}

    if "full_name" in update_fields:
        set_clauses.append("full_name = :full_name")
        params["full_name"] = update_fields["full_name"]

    if "avatar_url" in update_fields:
        set_clauses.append("avatar_url = :avatar_url")
        params["avatar_url"] = update_fields["avatar_url"]

    set_clauses.append("updated_at = NOW()")

    row = db.execute(
        text(f"""
            UPDATE users
            SET {", ".join(set_clauses)}
            WHERE id = :uid
            RETURNING id, full_name, email, avatar_url, system_role
        """),
        params,
    ).first()

    if not row:
        raise HTTPException(status_code=404, detail="User not found")

    db.commit()

    return {
        "id": row[0],
        "full_name": row[1],
        "email": row[2],
        "avatar_url": row[3],
        "system_role": row[4],
    }


def change_password(*, payload, db: Session, current_user):
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    # 1) basic validation (خفيف)
    if not payload.current_password or not payload.new_password:
        raise HTTPException(status_code=400, detail="Missing password fields")

    if payload.current_password == payload.new_password:
        raise HTTPException(status_code=400, detail="New password must be different")

    # 2) load user hashed password + email/name (نحتاجهم للتحقق + الإيميل)
    row = db.execute(
        text("""
            SELECT id, full_name, email, hashed_password
            FROM users
            WHERE id = :uid
            LIMIT 1
        """),
        {"uid": user_id},
    ).first()

    if not row:
        raise HTTPException(status_code=401, detail="Invalid token")

    _, full_name, email, hashed_pw = row

    # 3) verify current password
    if not verify_password(payload.current_password, hashed_pw):
        raise HTTPException(status_code=401, detail="Invalid current password")

    # 4) update password + bump token_version
    new_hashed = hash_password(payload.new_password)

    db.execute(
        text("""
            UPDATE users
            SET hashed_password = :hp,
                updated_at = NOW(),
                token_version = token_version + 1
            WHERE id = :uid
        """),
        {"hp": new_hashed, "uid": user_id},
    )

    # 5) invalidate any previous reset_password tokens (زي forget-password)
    db.execute(
        text("""
            UPDATE user_tokens
            SET used_at = NOW()
            WHERE user_id = :uid
              AND type = 'reset_password'
              AND used_at IS NULL
        """),
        {"uid": user_id},
    )

    # 6) create a new reset token for "If this wasn't you" link
    reset_token = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)

    db.execute(
        text("""
            INSERT INTO user_tokens (user_id, type, token, expires_at, created_at)
            VALUES (:uid, 'reset_password', :token, :expires_at, NOW())
        """),
        {"uid": user_id, "token": reset_token, "expires_at": expires_at},
    )

    db.commit()

    # 7) send notification email (best-effort)
    frontend_url = os.getenv("FRONTEND_BASE_URL", "http://localhost:5173")
    reset_link = f"{frontend_url.rstrip('/')}/#/reset-password?token={reset_token}"

    subject = "Learnova – Password changed"
    text_body = f"""
        Hello {full_name or ''}

        Your Learnova password was just changed.

        If this wasn't you, secure your account immediately by setting a new password using this link:
        {reset_link}

        This link expires in 15 minutes.
        """

    sent = False
    try:
        send_email(
            to=email,
            subject=subject,
            body=text_body,
            html=None,
        )
        sent = True
    except Exception:
        pass

    return {
        "message": "Password updated successfully",
        "email_notification_sent": sent,
    }


def request_delete_account(*, payload, db: Session, current_user):
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    # 1) load user credentials
    row = db.execute(
        text("""
            SELECT id, full_name, email, hashed_password
            FROM users
            WHERE id = :uid
            LIMIT 1
             """),
        {"uid": user_id},
    ).first()

    if not row:
        raise HTTPException(status_code=401, detail="Invalid token")

    _, full_name, email, hashed_pw = row

    # 2) verify current password
    if not payload.current_password or not verify_password(payload.current_password, hashed_pw):
        raise HTTPException(status_code=401, detail="Invalid current password")

    # 3) invalidate any previous delete OTPs (prevent multiple valid OTPs)
    db.execute(
        text("""
            UPDATE user_tokens
            SET used_at = NOW()
            WHERE user_id = :uid
              AND type = :type
              AND used_at IS NULL
             """),
        {"uid": user_id, "type": "delete_account_otp"},
    )

    # 4) create OTP token
    otp = _generate_otp()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)

    db.execute(
        text("""
            INSERT INTO user_tokens (user_id, type, token, expires_at, created_at)
            VALUES (:uid, :type, :token, :expires_at, NOW())
        """),
        {"uid": user_id, "type": "delete_account_otp", "token": otp, "expires_at": expires_at},
    )

    db.commit()

    # 5) send OTP email (best-effort)
    subject = "Learnova – Confirm account deletion (OTP)"
    text_body = f"""
                Hello {full_name or ""}

                You requested to delete your Learnova account.

                Your OTP code is:
                {otp}

                This code expires in {10} minutes.

                If you didn't request this, you can ignore this email.
                """

    sent = False
    try:
        send_email(to=email, subject=subject, body=text_body, html=None)
        sent = True
    except Exception:
        pass

    return {
        "message": "Deletion OTP sent to your email.",
        "email_sent": sent,
    }


def confirm_delete_account(*, payload, db: Session, current_user):
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    otp = (payload.otp or "").strip()
    if not otp:
        raise HTTPException(status_code=400, detail="OTP is required")

    # OPTIONAL: enforce digits only + length
    if not ( len(otp) == 6): # otp.isdigit() and
        raise HTTPException(status_code=400, detail="Invalid OTP format")

    # 1) find token row for this user + otp
    row = db.execute(
        text("""
            SELECT id, expires_at, used_at
            FROM user_tokens
            WHERE user_id = :uid
              AND type = :type
              AND token = :token
            LIMIT 1
        """),
        {"uid": user_id, "type": "delete_account_otp", "token": otp},
    ).first()

    if not row:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    token_id, expires_at, used_at = row

    # 2) used?
    if used_at is not None:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    # 3) expired?
    now = datetime.now(timezone.utc)
    if expires_at <= now:
        # mark used to close it (same style as your reset_password)
        db.execute(
            text("UPDATE user_tokens SET used_at = NOW() WHERE id = :tid"),
            {"tid": token_id},
        )
        db.commit()
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    # 4) mark OTP used FIRST (your requirement for history correctness)
    db.execute(
        text("UPDATE user_tokens SET used_at = NOW() WHERE id = :tid"),
        {"tid": token_id},
    )

    # 5) delete user (CASCADE will remove dependent rows where configured)
    db.execute(
        text("DELETE FROM users WHERE id = :uid"),
        {"uid": user_id},
    )

    db.commit()

    return {"message": "Account deleted successfully"}