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
from app.core.config import settings


def _generate_otp() -> str:
    return secrets.token_hex(3)

def update_profile(*, payload: UpdateProfileRequest, db: Session, current_user):
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    update_fields = {}
    if payload.full_name != "":
        if payload.full_name is not None:
            update_fields["full_name"] = payload.full_name.strip()
    # avatar url can be updated to nothing or "" (deleted)
    if payload.avatar_url is not None:
        update_fields["avatar_url"] = payload.avatar_url.strip()
    if payload.phone is not None:
        update_fields["phone_number"] = payload.phone.strip()
    if payload.bio is not None:
        update_fields["bio"] = payload.bio.strip()

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

    if "phone_number" in update_fields:
        set_clauses.append("phone_number = :phone_number")
        params["phone_number"] = update_fields["phone_number"]

    if "bio" in update_fields:
        set_clauses.append("bio = :bio")
        params["bio"] = update_fields["bio"]

    set_clauses.append("updated_at = NOW()")

    row = db.execute(
        text(f"""
            UPDATE users
            SET {", ".join(set_clauses)}
            WHERE id = :uid
            RETURNING id, full_name, email, avatar_url, phone_number, bio, system_role
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
        "phone_number": row[4],
        "bio": row[5],
        "system_role": row[6],
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
                last_password_change = NOW()
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
    frontend_url = settings.frontend_base_url
    secure_link = f"{frontend_url.rstrip('/')}/#/reset-password?token={reset_token}"

    subject = "Learnova – Password changed"
    text_body = f"""
    Hello {full_name or ''}

    Your Learnova password was just changed.

    If this wasn't you, secure your account immediately by setting a new password using this link:
    {secure_link}

    This link expires in 15 minutes.
    """

    html_body = f"""
    <!DOCTYPE html>
    <html lang="en">
    <body style="margin:0;padding:0;background:#f6f7fb;font-family:Arial,sans-serif;">
        <!-- Preheader -->
        <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">
        Your Learnova password was changed. If this wasn’t you, secure your account now.
        </div>

        <table width="100%" cellpadding="0" cellspacing="0" style="background:#f6f7fb;">
        <tr>
            <td align="center" style="padding:28px 16px;">

            <table width="560" cellpadding="0" cellspacing="0" style="width:560px;max-width:560px;">

                <!-- Brand -->
                <tr>
                <td style="padding:0 8px 14px;">
                    <table cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="vertical-align:middle;">
                        <img src="{settings.email_logo_url}" width="40" height="40" alt="Learnova"
                            style="display:block;border:0;outline:none;border-radius:10px;" />
                        </td>
                        <td style="vertical-align:middle;padding-left:10px;">
                        <div style="font-size:16px;font-weight:800;color:#111827;line-height:1;">
                            Learnova
                        </div>
                        <div style="font-size:12px;color:#6b7280;margin-top:2px;">
                            Security Alert
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
                            Your password was changed 🔐
                        </h2>

                        <p style="margin:10px 0 0;color:#374151;line-height:1.7;font-size:14px;">
                            Hello {full_name or ''}, your Learnova password was just changed.
                        </p>

                        <p style="margin:10px 0 0;color:#374151;line-height:1.7;font-size:14px;">
                            If this wasn’t you, please secure your account immediately by setting a new password.
                        </p>

                        <!-- Button -->
                        <table cellpadding="0" cellspacing="0" style="margin-top:18px;">
                            <tr>
                            <td align="center" bgcolor="#137FEC" style="border-radius:10px;">
                                <a href="{secure_link}"
                                style="display:inline-block;padding:12px 18px;font-size:14px;font-weight:700;
                                        color:#ffffff;text-decoration:none;border-radius:10px;">
                                Secure Account
                                </a>
                            </td>
                            </tr>
                        </table>

                        <!-- Info chips -->
                        <table cellpadding="0" cellspacing="0" style="margin-top:16px;">
                            <tr>
                            <td style="background:#FFF7ED;border:1px solid #FED7AA;border-radius:999px;padding:6px 10px;">
                                <span style="font-size:12px;color:#9A3412;">
                                ⏳ Link expires in 15 minutes
                                </span>
                            </td>
                            <td style="width:10px;"></td>
                            <td style="background:#EAF3FF;border:1px solid #BBD9FF;border-radius:999px;padding:6px 10px;">
                                <span style="font-size:12px;color:#1F4B99;">
                                🔒 Security action
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

                    <!-- Fallback -->
                    <tr>
                        <td style="padding:14px 26px 24px;">
                        <p style="margin:0;color:#6b7280;font-size:12px;line-height:1.6;">
                            If the button doesn’t work, copy and paste this link into your browser:
                        </p>
                        <p style="margin:10px 0 0;font-size:12px;line-height:1.6;">
                            <a href="{secure_link}" style="color:#137FEC;text-decoration:none;word-break:break-all;">
                            {secure_link}
                            </a>
                        </p>

                        <p style="margin:16px 0 0;color:#9ca3af;font-size:12px;line-height:1.6;">
                            If you changed your password, you can safely ignore this email.
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
                    © {settings.email_brand_year} Learnova. All rights reserved.
                    </p>
                    <p style="margin:6px 0 0;color:#9ca3af;font-size:12px;line-height:1.6;">
                    Need help? Contact us at <a href="mailto:{settings.email_support_email}" style="color:#137FEC;text-decoration:none;">{settings.email_support_email}</a>
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

    sent = False
    try:
        send_email(
            to=email,
            subject=subject,
            body=text_body,
            html=html_body,
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
    Hello {full_name or ''}

    You requested to delete your Learnova account.

    Your OTP code is:
    {otp}

    This code expires in 10 minutes.

    If you didn't request this, you can ignore this email.
    """

    html_body = f"""
    <!DOCTYPE html>
    <html lang="en">
    <body style="margin:0;padding:0;background:#f6f7fb;font-family:Arial,sans-serif;">
        <!-- Preheader -->
        <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">
        Your OTP code to confirm Learnova account deletion (expires in 10 minutes).
        </div>

        <table width="100%" cellpadding="0" cellspacing="0" style="background:#f6f7fb;">
        <tr>
            <td align="center" style="padding:28px 16px;">

            <table width="560" cellpadding="0" cellspacing="0" style="width:560px;max-width:560px;">

                <!-- Brand -->
                <tr>
                <td style="padding:0 8px 14px;">
                    <table cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="vertical-align:middle;">
                        <img src="{settings.email_logo_url}" width="40" height="40" alt="Learnova"
                            style="display:block;border:0;outline:none;border-radius:10px;" />
                        </td>
                        <td style="vertical-align:middle;padding-left:10px;">
                        <div style="font-size:16px;font-weight:800;color:#111827;line-height:1;">
                            Learnova
                        </div>
                        <div style="font-size:12px;color:#6b7280;margin-top:2px;">
                            Account Deletion (OTP)
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
                            Confirm account deletion 🧾
                        </h2>

                        <p style="margin:10px 0 0;color:#374151;line-height:1.7;font-size:14px;">
                            Hello {full_name or ''}, you requested to permanently delete your Learnova account.
                        </p>

                        <p style="margin:10px 0 0;color:#374151;line-height:1.7;font-size:14px;">
                            Use the OTP code below to confirm. <strong style="color:#111827;">Do not share this code</strong> with anyone.
                        </p>

                        <!-- OTP Box -->
                        <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:16px;">
                            <tr>
                            <td align="center"
                                style="background:#F9FAFB;border:1px solid #E5E7EB;border-radius:12px;padding:14px 12px;">
                                <div style="font-size:26px;font-weight:800;letter-spacing:6px;color:#111827;line-height:1.2;">
                                    {otp}
                                </div>
                                <div style="margin-top:6px;font-size:12px;color:#6b7280;line-height:1.4;">
                                    OTP code
                                </div>
                            </td>
                            </tr>
                        </table>

                        <!-- Info chips -->
                        <table cellpadding="0" cellspacing="0" style="margin-top:16px;">
                            <tr>
                            <td style="background:#FFF7ED;border:1px solid #FED7AA;border-radius:999px;padding:6px 10px;">
                                <span style="font-size:12px;color:#9A3412;">
                                ⏳ Expires in 10 minutes
                                </span>
                            </td>
                            <td style="width:10px;"></td>
                            <td style="background:#FEE2E2;border:1px solid #FCA5A5;border-radius:999px;padding:6px 10px;">
                                <span style="font-size:12px;color:#991B1B;">
                                ⚠️ Irreversible action
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

                    <!-- Footer note -->
                    <tr>
                        <td style="padding:14px 26px 24px;">
                        <p style="margin:0;color:#9ca3af;font-size:12px;line-height:1.6;">
                            If you didn’t request this, you can ignore this email. Your account will remain unchanged.
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
                    © {settings.email_brand_year} Learnova. All rights reserved.
                    </p>
                    <p style="margin:6px 0 0;color:#9ca3af;font-size:12px;line-height:1.6;">
                    Need help? Contact us at <a href="mailto:{settings.email_support_email}" style="color:#137FEC;text-decoration:none;">{settings.email_support_email}</a>
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

    sent = False
    try:
        send_email(to=email, subject=subject, body=text_body, html=html_body)
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