from __future__ import annotations
from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy import text, bindparam
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from datetime import datetime, timedelta, timezone
from typing import Iterable, Any, Optional
from openpyxl import load_workbook
import hashlib
import secrets

from .schemas import (CourseCreateRequest,
                      CourseInvitesUploadResponse,  # اللي عملناه
                      CourseInvitesSendRequest,  
                      CourseInvitesSendResponse,
                      CourseInviteAcceptRequest, 
                      CourseInviteAcceptResponse)


from app.core.config import settings
from app.core.security import hmac_sha256_hex
from app.core.excel_utils import extract_emails_from_xlsx
from app.core.emailer import send_email  # <-- عدّل المسار حسب مشروعك

from .schemas import CourseInvitesSendRequest, CourseInvitesSendResponse

def create_course(*, payload: CourseCreateRequest, db: Session, current_user: dict):
    role = current_user.get("system_role")
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create courses")

    instructor_id = current_user["id"]

    stmt = text("""
        INSERT INTO courses (
            organization_id,
            created_by,
            title,
            description,
            cover_image_url,
            banner_image_url,
            is_public,
            visibility_level,
            requires_enrollment_approval,
            learning_outcomes,
            category,
            tags,
            course_type,
            enrollment_count,
            total_ratings,
            status,
            created_at,
            updated_at
        )
        VALUES (
            :organization_id,
            :created_by,
            :title,
            :description,
            :cover_image_url,
            :banner_image_url,
            :is_public,
            :visibility_level,
            :requires_enrollment_approval,
            :learning_outcomes,
            :category,
            :tags,
            :course_type,
            0,
            0,
            'draft',
            NOW(),
            NOW()
        )
        RETURNING
            id, title, course_type, organization_id, is_public, visibility_level, requires_enrollment_approval
    """).bindparams(
        bindparam("learning_outcomes", type_=JSONB),
        bindparam("tags", type_=JSONB),
    )

    params = {
        "organization_id": payload.organization_id,
        "created_by": instructor_id,
        "title": payload.title,
        "description": payload.description,
        "cover_image_url": payload.cover_image_url,
        "banner_image_url": payload.banner_image_url,
        "is_public": payload.is_public,
        "visibility_level": payload.visibility_level.value,
        "requires_enrollment_approval": payload.requires_enrollment_approval,
        "learning_outcomes": payload.learning_outcomes,  # list[str] | None
        "category": payload.category,
        "tags": payload.tags,  # list[str] | None
        "course_type": payload.course_type.value,
    }

    try:
        row = db.execute(stmt, params).mappings().first()
        if not row:
            raise HTTPException(status_code=503, detail="Failed to create course")
        db.commit()
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Course creation violates a constraint") from e
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e

    return row


# الأفضل تخليها في config.py بعدين (زي ما اتفقنا)
COMMON_EMAIL_HEADERS = (
    "email",
    "e-mail",
    "e_mail",
    "email_address",
    "e_mail_address",
    "mail",
    "invited_email",
    "invitedemail",
    "user_email",
)


def upload_course_invitations_excel(*, course_id: int, file: UploadFile, sheet_name: str | None,
                                     email_column: str, db: Session,current_user: dict,) -> CourseInvitesUploadResponse:
    # =========================
    # 1) Authorization
    # =========================
    role = current_user.get("system_role")
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can upload course invitations")

    instructor_id = current_user["id"]

    # =========================
    # 2) Course checks (exists + owner + private)
    # =========================
    course_row = db.execute(
        text("""
            SELECT id, created_by, is_public
            FROM courses
            WHERE id = :course_id
        """),
        {"course_id": course_id},
    ).mappings().first()

    if not course_row:
        raise HTTPException(status_code=404, detail="Course not found")

    if course_row["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only invite users to your own course")

    if course_row["is_public"] is True:
        raise HTTPException(status_code=409, detail="This course is public and does not require invitations")

    # =========================
    # 3) Extract emails from Excel
    # =========================
    result = extract_emails_from_xlsx(
        file=file,
        sheet_name=sheet_name,
        email_column_hint=email_column,
        common_email_headers=COMMON_EMAIL_HEADERS,
    )
    emails = result.emails

    # =========================
    # 4) DB: skip existing invitations (append behavior)
    # =========================
    existing_rows = db.execute(
        text("""
            SELECT invited_email
            FROM course_invitations
            WHERE course_id = :course_id
              AND invited_email = ANY(:emails)
        """),
        {"course_id": course_id, "emails": emails},
    ).mappings().all()

    existing_set = {r["invited_email"].lower() for r in existing_rows}
    to_insert = [e for e in emails if e not in existing_set]
    sample_existing = list(existing_set)[:20]

    # =========================
    # 5) DB: lookup users by email (bulk)
    # =========================
    email_to_user_id: dict[str, int] = {}
    if to_insert:
        user_rows = db.execute(
            text("""
                SELECT id, email
                FROM users
                WHERE lower(email) = ANY(:emails)
            """),
            {"emails": to_insert},
        ).mappings().all()

        email_to_user_id = {r["email"].lower(): r["id"] for r in user_rows}

    # =========================
    # 7) Insert invitations (bulk)
    # =========================
    inserted = 0
    try:
        for invited_email in to_insert:

            invited_user_id = email_to_user_id.get(invited_email)

            db.execute(
                text("""
                    INSERT INTO course_invitations (
                        course_id,
                        created_by,
                        invited_email,
                        invited_user_id,
                        status,
                        created_at,
                        updated_at
                    )
                    VALUES (
                        :course_id,
                        :created_by,
                        :invited_email,
                        :invited_user_id,
                        'pending',
                        NOW(),
                        NOW()
                    )
                """),
                       
                {
                    "course_id": course_id,
                    "created_by": instructor_id,
                    "invited_email": invited_email,
                    "invited_user_id": invited_user_id,
                },
            )
            inserted += 1

        db.commit()

    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Some invitations already exist (or concurrent upload)")

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error while creating invitations") from e


    send_course_invitations(course_id=course_id, payload=None, db=db, current_user=current_user)

    # =========================
    # 8) Response
    # =========================
    return CourseInvitesUploadResponse(
        course_id=course_id,
        total_rows=result.total_rows,
        extracted_emails=result.extracted_values,
        inserted=inserted,
        skipped_existing=len(existing_set),
        invalid_emails=result.invalid_count,
        # token_expires_at=expires_at,
        sample_invalid_emails=result.sample_invalid,
        sample_existing_emails=sample_existing,)



def send_course_invitations(*, course_id: int,
                            payload: Optional[CourseInvitesSendRequest],  # لو None => send all (pending+expired)
                            db: Session, current_user: dict,) -> CourseInvitesSendResponse:
    """
    One function to be called from:
      1) POST /courses/{course_id}/invitations/send  (payload comes from request)
      2) At the end of upload invitations endpoint      (pass payload=None)
    """
    # -------------------------
    # Defaults when called internally
    # -------------------------
    target_email = None
    include_expired = True
    force = False  # TODO for rate limiting later

    if payload is not None:
        target_email = payload.email
        include_expired = payload.include_expired
        force = payload.force

    # =========================
    # 1) Authorization
    # =========================
    role = current_user.get("system_role")
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can send course invitations")

    instructor_id = current_user["id"]

    # =========================
    # 2) Course checks
    # =========================
    course_row = db.execute(
        text("""
            SELECT id, created_by, is_public, title
            FROM courses
            WHERE id = :course_id
        """),
        {"course_id": course_id},
    ).mappings().first()

    if not course_row:
        raise HTTPException(status_code=404, detail="Course not found")

    if course_row["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only send invites for your own course")

    if course_row["is_public"] is True:
        raise HTTPException(status_code=409, detail="This course is public and does not require invitations")

    course_title = course_row.get("title") or "your course"

    # =========================
    # 3) Config check
    # =========================
    if not settings.invite_token_secret:
        raise HTTPException(status_code=500, detail="Server misconfigured: INVITE_TOKEN_SECRET is missing")

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(days=7)

    # =========================
    # 4) Select invitations
    # =========================
    statuses = ["pending"]
    if include_expired:
        statuses.append("expired")

    if target_email:
        email_norm = target_email.strip().lower()

        inv = db.execute(
            text("""
                SELECT id, invited_email, status
                FROM course_invitations
                WHERE course_id = :course_id
                  AND lower(invited_email) = :email
                LIMIT 1
            """),
            {"course_id": course_id, "email": email_norm},
        ).mappings().first()

        if not inv:
            raise HTTPException(status_code=404, detail="Invitation not found for this email")

        invitations = [inv]
    else:
        invitations = db.execute(
            text("""
                SELECT id, invited_email, status
                FROM course_invitations
                WHERE course_id = :course_id
                  AND status = ANY(:statuses)
                ORDER BY id ASC
            """),
            {"course_id": course_id, "statuses": statuses},
        ).mappings().all()

    attempted = len(invitations)
    if attempted == 0:
        return CourseInvitesSendResponse(
            course_id=course_id,
            sent=0,
            failed=0,
            skipped_not_eligible=0,
            attempted=0,
            target_email=target_email,
            last_sent_at=None,
            sample_failed_emails=[],
            sample_skipped_emails=[],
        )

    # =========================
    # 5) Filter eligible (block accepted/revoked)
    # =========================
    eligible = []
    skipped_emails: list[str] = []

    for inv in invitations:
        st = (inv["status"] or "").lower()
        if st in ("accepted", "revoked"):
            skipped_emails.append(inv["invited_email"])
            continue
        if st not in ("pending", "expired"):
            skipped_emails.append(inv["invited_email"])
            continue
        eligible.append(inv)

    if target_email and not eligible:
        raise HTTPException(status_code=409, detail="Invitation is not eligible to be sent (accepted/revoked)")

    # =========================
    # 6) Update DB first (Option B) + keep raw tokens in memory to send
    # =========================
    to_send: list[tuple[str, str]] = []  # (email, raw_token)

    try:
        for inv in eligible:
            invited_email = inv["invited_email"]

            raw_token = secrets.token_urlsafe(32)
            token_hash = hmac_sha256_hex(raw_token, settings.invite_token_secret)

            db.execute(
                text("""
                    UPDATE course_invitations
                    SET
                        token_hash = :token_hash,
                        token_expires_at = :expires_at,
                        status = 'pending',
                        sent_at = COALESCE(sent_at, NOW()),
                        last_sent_at = NOW(),
                        send_count = send_count + 1,
                        updated_at = NOW()
                    WHERE id = :id
                """),
                {"id": inv["id"], "token_hash": token_hash, "expires_at": expires_at},
            )

            to_send.append((invited_email, raw_token))

        db.commit()

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error while preparing invitations") from e

    # =========================
    # 7) Send emails (text + HTML)
    # =========================
    sent = 0
    failed = 0
    failed_emails: list[str] = []
    last_sent_at: Optional[datetime] = None

    frontend_url = settings.frontend_base_url.rstrip("/")

    for invited_email, raw_token in to_send:
        invite_link = f"{frontend_url}/#/course-invite?token={raw_token}"

        subject = f"Learnova – You're invited to {course_title}"
        body = f"""
                Hello,

                You have been invited to join "{course_title}" on Learnova.

                Invitation link:
                {invite_link}

                This link expires in 7 days.

                If you did not expect this invitation, you can ignore this email.
                """

        html_body = f"""
                    <!DOCTYPE html>
                    <html lang="en">
                    <body style="margin:0;padding:0;background:#f6f7fb;font-family:Arial,sans-serif;">
                        <!-- Preheader -->
                        <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">
                        You’re invited to join "{course_title}" on Learnova. This link expires in 7 days.
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
                                            Course Invitation
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
                                            You're invited 🎉
                                        </h2>

                                        <p style="margin:10px 0 0;color:#374151;line-height:1.7;font-size:14px;">
                                            You have been invited to join <strong style="color:#111827;">"{course_title}"</strong> on Learnova.
                                        </p>

                                        <p style="margin:10px 0 0;color:#374151;line-height:1.7;font-size:14px;">
                                            Click the button below to accept the invitation.
                                        </p>

                                        <!-- Button -->
                                        <table cellpadding="0" cellspacing="0" style="margin-top:18px;">
                                            <tr>
                                            <td align="center" bgcolor="#137FEC" style="border-radius:10px;">
                                                <a href="{invite_link}"
                                                style="display:inline-block;padding:12px 18px;font-size:14px;font-weight:700;
                                                        color:#ffffff;text-decoration:none;border-radius:10px;">
                                                Accept Invitation
                                                </a>
                                            </td>
                                            </tr>
                                        </table>

                                        <!-- Info chips -->
                                        <table cellpadding="0" cellspacing="0" style="margin-top:16px;">
                                            <tr>
                                            <td style="background:#F3F4F6;border:1px solid #E5E7EB;border-radius:999px;padding:6px 10px;">
                                                <span style="font-size:12px;color:#374151;">
                                                ⏳ Expires in 7 days
                                                </span>
                                            </td>
                                            <td style="width:10px;"></td>
                                            <td style="background:#EAF3FF;border:1px solid #BBD9FF;border-radius:999px;padding:6px 10px;">
                                                <span style="font-size:12px;color:#1F4B99;">
                                                📚 Course invite
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
                                            <a href="{invite_link}" style="color:#137FEC;text-decoration:none;word-break:break-all;">
                                            {invite_link}
                                            </a>
                                        </p>

                                        <p style="margin:16px 0 0;color:#9ca3af;font-size:12px;line-height:1.6;">
                                            If you did not expect this invitation, you can safely ignore this email.
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

        try:
            send_email(to=invited_email, subject=subject, body=body, html=html_body)
            sent += 1
            last_sent_at = datetime.now(timezone.utc)
        except Exception:
            failed += 1
            if len(failed_emails) < 20:
                failed_emails.append(invited_email)


    return CourseInvitesSendResponse(
        course_id=course_id,
        sent=sent,
        failed=failed,
        skipped_not_eligible=len(skipped_emails),
        attempted=attempted,
        target_email=target_email,
        last_sent_at=last_sent_at,
        sample_failed_emails=failed_emails,
        sample_skipped_emails=skipped_emails[:20],
    )




def accept_course_invitation(
    *,
    payload: CourseInviteAcceptRequest,
    db: Session,
    current_user: dict,
) -> CourseInviteAcceptResponse:
    # =========================
    # 1) Auth + role check
    # =========================
    # get_current_user already ensures JWT exists, otherwise 401
    user_id = current_user.get("id")
    user_email = (current_user.get("email") or "").strip().lower()
    role = (current_user.get("system_role") or "").strip().lower()

    if not user_id or not user_email:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if role != "student":
        raise HTTPException(status_code=403, detail="Only students can accept course invitations")

    # =========================
    # 2) Config check
    # =========================
    if not settings.invite_token_secret:
        raise HTTPException(status_code=500, detail="Server misconfigured: INVITE_TOKEN_SECRET is missing")

    raw_token = (payload.token or "").strip()
    if not raw_token:
        raise HTTPException(status_code=422, detail="Token is required")

    token_hash = hmac_sha256_hex(raw_token, settings.invite_token_secret)

    # =========================
    # 3) Load invitation by token_hash
    # =========================
    inv = db.execute(
        text("""
            SELECT
                id,
                course_id,
                invited_email,
                invited_user_id,
                token_expires_at,
                status,
                accepted_at,
                revoked_at
            FROM course_invitations
            WHERE token_hash = :token_hash
            LIMIT 1
        """),
        {"token_hash": token_hash},
    ).mappings().first()

    if not inv:
        raise HTTPException(status_code=404, detail="Invalid invitation token")

    invitation_id = inv["id"]
    course_id = inv["course_id"]
    invited_email = (inv["invited_email"] or "").strip().lower()
    status = (inv["status"] or "").strip().lower()
    expires_at = inv["token_expires_at"]
    revoked_at = inv["revoked_at"]
    accepted_at = inv["accepted_at"]

    # =========================
    # 4) Validate invitation state
    # =========================
    # email must match logged-in user
    if invited_email and invited_email != user_email:
        raise HTTPException(status_code=403, detail="This invitation is not for your account")

    if revoked_at is not None or status == "revoked":
        raise HTTPException(status_code=403, detail="Invitation has been revoked")

    if status == "accepted" or accepted_at is not None:
        # idempotent: already accepted -> return OK
        return CourseInviteAcceptResponse(
            message="Invitation already accepted",
            course_id=course_id,
            enrollment_id=None,
            enrolled=True,
            accepted_at=accepted_at,
        )

    now = datetime.now(timezone.utc)
    if expires_at is not None and expires_at <= now:
        # optional: mark as expired if not already
        if status != "expired":
            try:
                db.execute(
                    text("""
                        UPDATE course_invitations
                        SET status = 'expired', updated_at = NOW()
                        WHERE id = :id
                    """),
                    {"id": invitation_id},
                )
                db.commit()
            except Exception:
                db.rollback()
        raise HTTPException(status_code=410, detail="Invitation token expired. Please request a new invitation.")

    if status not in ("pending", "expired"):
        raise HTTPException(status_code=409, detail="Invitation is not in a valid state to be accepted")

    # =========================
    # 5) Ensure course exists
    # =========================
    course = db.execute(
        text("SELECT id FROM courses WHERE id = :course_id"),
        {"course_id": course_id},
    ).first()

    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    # =========================
    # 6) Insert enrollment (idempotent with unique constraint)
    # =========================
    enrollment_id = None

    try:
        row = db.execute(
            text("""
                INSERT INTO course_enrollments (
                    student_id,
                    course_id,
                    status,
                    enrollment_type,
                    enrolled_at
                )
                VALUES (
                    :student_id,
                    :course_id,
                    CAST(:status AS course_enrollment_status_enum),
                    CAST(:enrollment_type AS course_enrollment_type_enum),
                    NOW()
                )
                ON CONFLICT (student_id, course_id) DO NOTHING
                RETURNING id
            """),
            {
                "student_id": user_id,
                "course_id": course_id,
                "status": "active",
                "enrollment_type": "invited",
            },
        ).first()

        if row:
            enrollment_id = row[0]
        else:
            # already enrolled, fetch existing id
            existing = db.execute(
                text("""
                    SELECT id
                    FROM course_enrollments
                    WHERE student_id = :student_id AND course_id = :course_id
                    LIMIT 1
                """),
                {"student_id": user_id, "course_id": course_id},
            ).first()
            if existing:
                enrollment_id = existing[0]

        # =========================
        # 7) Update invitation -> accepted
        # =========================
        db.execute(
            text("""
                UPDATE course_invitations
                SET
                    status = 'accepted',
                    accepted_at = NOW(),
                    invited_user_id = COALESCE(invited_user_id, :user_id),
                    updated_at = NOW()
                WHERE id = :id
            """),
            {"id": invitation_id, "user_id": user_id},
        )

        db.commit()

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error while accepting invitation") from e

    return CourseInviteAcceptResponse(
        message="Invitation accepted. You are now enrolled in the course.",
        course_id=course_id,
        enrollment_id=enrollment_id,
        enrolled=True,
        accepted_at=datetime.now(timezone.utc),
    )
