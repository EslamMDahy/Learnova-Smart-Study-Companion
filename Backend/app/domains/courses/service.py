from __future__ import annotations
from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy import text, bindparam
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from storage3.types import CreateSignedUploadUrlOptions
from datetime import datetime, timedelta, timezone
from typing import Optional
from openpyxl import load_workbook
import secrets

import supabase

from .schemas import (CourseCreateRequest,
                      CourseUpdateRequest,
                      CourseInvitesUploadResponse,  
                      CourseInvitesSendRequest,  
                      CourseInvitesSendResponse,
                      CourseInviteAcceptRequest, 
                      CourseInviteAcceptResponse,
                      CourseInvitationsListResponse, 
                      EnrollmentRequestUpdateRequest)


from app.core.config import settings
from app.core.supabase_client import supabase
from app.core.security import hmac_sha256_hex
from app.core.emailer import send_email  
from app.core.storage_utils import split_object_key
from app.core.excel_utils import extract_emails_from_xlsx


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


def create_course(*, payload: CourseCreateRequest, db: Session, current_user: dict):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create courses")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    status_value = payload.status.value if payload.status is not None else "draft"

    try:
        # =========================
        # 2) Insert course
        # =========================
        course_row = db.execute(
            text("""
                INSERT INTO courses (
                    organization_id,
                    created_by,
                    title,
                    course_code,
                    description,
                    is_open_for_enrollment,
                    visibility_level,
                    requires_enrollment_approval,
                    category,
                    tags,
                    course_type,
                    enrollment_count,
                    total_ratings,
                    status,
                    published_at,
                    created_at,
                    updated_at
                )
                VALUES (
                    :organization_id,
                    :created_by,
                    :title,
                    :course_code,
                    :description,
                    :is_open_for_enrollment,
                    :visibility_level,
                    :requires_enrollment_approval,
                    :category,
                    :tags,
                    :course_type,
                    0,
                    0,
                    CAST(:status AS course_status_enum),
                    CASE WHEN CAST(:status AS course_status_enum) = 'published'::course_status_enum THEN NOW() ELSE NULL END,
                    NOW(),
                    NOW()
                )
                RETURNING
                    id, title, course_code, course_type, organization_id,
                    is_open_for_enrollment, visibility_level,
                    requires_enrollment_approval, status, published_at
            """).bindparams(bindparam("tags", type_=JSONB)),
            {
                "organization_id": payload.organization_id,
                "created_by": instructor_id,
                "title": payload.title,
                "course_code": payload.course_code,
                "description": payload.description,
                "is_open_for_enrollment": payload.is_open_for_enrollment,
                "visibility_level": payload.visibility_level.value,
                "requires_enrollment_approval": payload.requires_enrollment_approval,
                "category": payload.category,
                "tags": payload.tags or [],
                "course_type": payload.course_type.value,
                "status": status_value,
            },
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=503, detail="Failed to create course")

        course_id = int(course_row["id"])

        # =========================
        # 3) Create default exam templates
        # =========================
        default_templates = [
            {
                "name": "Practice",
                "exam_type": "practice",
                "duration_minutes": None,
                "max_attempts": 0,
                "passing_score": None,
            },
            {
                "name": "Quiz",
                "exam_type": "quiz",
                "duration_minutes": 30,
                "max_attempts": 3,
                "passing_score": 60,
            },
            {
                "name": "Midterm",
                "exam_type": "midterm",
                "duration_minutes": 90,
                "max_attempts": 1,
                "passing_score": 50,
            },
            {
                "name": "Final",
                "exam_type": "final",
                "duration_minutes": 120,
                "max_attempts": 1,
                "passing_score": 50,
            },
        ]

        for template in default_templates:
            db.execute(
                text("""
                    INSERT INTO exam_templates (
                        course_id,
                        name,
                        exam_type,
                        is_default,
                        duration_minutes,
                        max_attempts,
                        passing_score,
                        shuffle_questions,
                        shuffle_options,
                        total_questions,
                        total_score,
                        created_at,
                        updated_at
                    )
                    VALUES (
                        :course_id,
                        :name,
                        :exam_type,
                        TRUE,
                        :duration_minutes,
                        :max_attempts,
                        :passing_score,
                        TRUE,
                        TRUE,
                        0,
                        0,
                        NOW(),
                        NOW()
                    )
                """),
                {
                    "course_id": course_id,
                    "name": template["name"],
                    "exam_type": template["exam_type"],
                    "duration_minutes": template["duration_minutes"],
                    "max_attempts": template["max_attempts"],
                    "passing_score": template["passing_score"],
                },
            )

        db.commit()

        return dict(course_row)

    except HTTPException:
        db.rollback()
        raise
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail="Invalid course data") from e
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e
    


def update_course(*, course_id: int, payload: CourseUpdateRequest, db: Session, current_user: dict):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can update courses")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    try:
        # =========================
        # 2) Validate course exists + ownership
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, created_by
                FROM courses
                WHERE id = :course_id
                LIMIT 1
            """),
            {"course_id": course_id},
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=404, detail="Course not found")

        if int(course_row["created_by"]) != int(instructor_id):
            raise HTTPException(status_code=403, detail="You can only update your own courses")

        # =========================
        # 3) Build dynamic update fields
        # =========================
        update_fields = {}

        if payload.title is not None:
            title = payload.title.strip()
            if not title:
                raise HTTPException(status_code=422, detail="Title cannot be empty")
            update_fields["title"] = title

        if payload.description is not None:
            description = payload.description.strip()
            update_fields["description"] = description if description else None

        if payload.category is not None:
            category = payload.category.strip()
            update_fields["category"] = category if category else None

        if payload.course_code is not None:
            course_code = payload.course_code.strip()
            update_fields["course_code"] = course_code if course_code else None

        if payload.is_open_for_enrollment is not None:
            update_fields["is_open_for_enrollment"] = payload.is_open_for_enrollment

        if payload.requires_enrollment_approval is not None:
            update_fields["requires_enrollment_approval"] = payload.requires_enrollment_approval

        if payload.visibility_level is not None:
            update_fields["visibility_level"] = payload.visibility_level.value

        if payload.tags is not None:
            update_fields["tags"] = payload.tags

        if not update_fields:
            raise HTTPException(status_code=400, detail="No updatable fields provided")

        # =========================
        # 4) Update course
        # =========================
        set_clauses = []
        params = {"course_id": course_id}

        for col in [
            "title",
            "description",
            "category",
            "course_code",
            "is_open_for_enrollment",
            "requires_enrollment_approval",
            "visibility_level",
            "tags",
        ]:
            if col in update_fields:
                if col == "tags":
                    set_clauses.append("tags = :tags::json")
                else:
                    set_clauses.append(f"{col} = :{col}")
                params[col] = update_fields[col]

        set_clauses.append("updated_at = NOW()")

        updated_row = db.execute(
            text(f"""
                UPDATE courses
                SET {", ".join(set_clauses)}
                WHERE id = :course_id
                RETURNING
                    id,
                    title,
                    course_code,
                    course_type,
                    organization_id,
                    is_open_for_enrollment,
                    visibility_level,
                    status,
                    category,
                    created_by,
                    created_at,
                    updated_at,
                    enrollment_count
            """),
            params,
        ).mappings().first()

        if not updated_row:
            raise HTTPException(status_code=409, detail="Course could not be updated")

        db.commit()

        return dict(updated_row)

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while updating course") from e

    except SQLAlchemyError as e:
        db.rollback()
        print(e)
        raise HTTPException(status_code=500, detail="Database error") from e



def initiate_course_cover_upload(*, course_id: int, payload, db: Session, current_user: dict):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can upload course cover images")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    # =========================
    # 2) Validate payload
    # =========================
    content_type = (getattr(payload, "content_type", None) or "").strip().lower()
    file_size_bytes = getattr(payload, "file_size_bytes", None)

    _ALLOWED_CONTENT_TYPES = {"image/png", "image/jpeg", "image/jpg"}
    _COVER_MAX_BYTES = 5 * 1024 * 1024

    if not content_type:
        raise HTTPException(status_code=400, detail="content_type is required")

    if content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="Invalid content_type. Allowed: image/png, image/jpeg, image/jpg")

    if file_size_bytes is None:
        raise HTTPException(status_code=400, detail="file_size_bytes is required")

    try:
        file_size_bytes = int(file_size_bytes)
    except Exception:
        raise HTTPException(status_code=400, detail="file_size_bytes must be an integer")

    if file_size_bytes <= 0:
        raise HTTPException(status_code=400, detail="file_size_bytes must be greater than 0")

    if file_size_bytes > _COVER_MAX_BYTES:
        raise HTTPException(status_code=400, detail="Cover image is too large (max 5MB)")

    try:
        # =========================
        # 3) Validate course exists + ownership
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, created_by
                FROM courses
                WHERE id = :course_id
                LIMIT 1
            """),
            {"course_id": course_id},
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=404, detail="Course not found")

        if int(course_row["created_by"]) != int(instructor_id):
            raise HTTPException(status_code=403, detail="You can only upload cover images for your own courses")

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e

    # =========================
    # 4) Build storage key + create signed upload URL
    # =========================
    bucket = settings.supabase_public_bucket
    storage_key = f"courses/{course_id}/assets/cover"

    options = CreateSignedUploadUrlOptions(upsert="true")
    try:
        signed = supabase.storage.from_(bucket).create_signed_upload_url(storage_key, options)
    except TypeError:
        signed = supabase.storage.from_(bucket).create_signed_upload_url(storage_key)

    data = None
    error = None

    if isinstance(signed, dict):
        error = signed.get("error")
        if signed.get("signedUrl") or signed.get("signed_url") or signed.get("url"):
            data = signed
    else:
        data = getattr(signed, "data", None)
        error = getattr(signed, "error", None)

    if error:
        msg = error.get("message") if isinstance(error, dict) else str(error)
        raise HTTPException(status_code=400, detail=f"Failed to create signed upload url: {msg}")

    if not data:
        raise HTTPException(status_code=400, detail="Failed to create signed upload url")

    upload_url = data.get("signedUrl") or data.get("signed_url") or data.get("url")

    if not upload_url:
        raise HTTPException(status_code=400, detail="Signed upload URL is missing from response")

    return {
        "upload_url": upload_url,
        "storage_key": storage_key,
        "content_type": content_type,
        "max_bytes": _COVER_MAX_BYTES,
    }



def confirm_course_cover_upload(*, course_id: int, db: Session, current_user: dict):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can confirm course cover uploads")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    try:
        # =========================
        # 2) Validate course exists + ownership
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, created_by
                FROM courses
                WHERE id = :course_id
                LIMIT 1
            """),
            {"course_id": course_id},
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=404, detail="Course not found")

        if int(course_row["created_by"]) != int(instructor_id):
            raise HTTPException(status_code=403, detail="You can only confirm cover uploads for your own courses")

        # =========================
        # 3) Verify file exists in storage
        # =========================
        bucket = settings.supabase_public_bucket
        storage_key = f"courses/{course_id}/assets/cover"
        folder, expected_filename = split_object_key(storage_key)

        try:
            items = supabase.storage.from_(bucket).list(path=folder)
        except Exception:
            items = None

        exists = False
        if isinstance(items, list):
            for it in items:
                if isinstance(it, dict) and it.get("name") == expected_filename:
                    exists = True
                    break

        if not exists:
            raise HTTPException(
                status_code=400,
                detail="Cover image not found in storage. Upload the file first, then confirm.",
            )

        # =========================
        # 4) Save key to DB
        # =========================
        updated_row = db.execute(
            text("""
                UPDATE courses
                SET
                    cover_image_key = :storage_key,
                    updated_at = NOW()
                WHERE id = :course_id
                RETURNING updated_at
            """),
            {"storage_key": storage_key, "course_id": course_id},
        ).first()

        if not updated_row:
            db.rollback()
            raise HTTPException(status_code=409, detail="Course could not be updated")

        db.commit()

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e

    # =========================
    # 5) Build public URL + return
    # =========================
    updated_at = updated_row[0]

    base_url = supabase.storage.from_(bucket).get_public_url(storage_key)

    try:
        dt = updated_at if isinstance(updated_at, datetime) else datetime.fromisoformat(str(updated_at).replace("Z", "+00:00"))
        v = int(dt.timestamp())
    except Exception:
        v = int(datetime.now(timezone.utc).timestamp())

    cover_url = f"{base_url}?v={v}"
    updated_at_iso = updated_at.isoformat() if hasattr(updated_at, "isoformat") else str(updated_at)

    return {
        "cover_url": cover_url,
        "updated_at": updated_at_iso,
    }



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
            SELECT id, created_by, is_open_for_enrollment
            FROM courses
            WHERE id = :course_id
        """),
        {"course_id": course_id},
    ).mappings().first()

    if not course_row:
        raise HTTPException(status_code=404, detail="Course not found")

    if course_row["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only invite users to your own course")

    if course_row["is_open_for_enrollment"] is True:
        raise HTTPException(status_code=409, detail="This course is open for enrollment and does not require invitations")

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
            SELECT id, created_by, is_open_for_enrollment, title
            FROM courses
            WHERE id = :course_id
        """),
        {"course_id": course_id},
    ).mappings().first()

    if not course_row:
        raise HTTPException(status_code=404, detail="Course not found")

    if course_row["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only send invites for your own course")

    if course_row["is_open_for_enrollment"] is True:
        raise HTTPException(status_code=409, detail="This course is open for enrollment and does not require invitations")

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



def accept_course_invitation(*, payload: CourseInviteAcceptRequest, db: Session,
                                current_user: dict,) -> CourseInviteAcceptResponse:
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
            {"id": invitation_id, "user_id": user_id},)
        db.execute(
            text("""
                UPDATE courses
                SET
                    enrollment_count = enrollment_count + 1,
                    updated_at = NOW()
                WHERE id = :course_id
                """),
            {"course_id": course_id},
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



def get_my_courses(*, db: Session, current_user: dict):
    user_id = current_user.get("id")
    role = (current_user.get("system_role") or "").strip().lower()

    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if role not in ("instructor", "student"):
        raise HTTPException(status_code=403, detail="Unsupported role for this endpoint")

    bucket = settings.supabase_public_bucket

    try:
        # =========================
        # Instructor: courses created by me
        # =========================
        if role == "instructor":
            rows = db.execute(
                text("""
                    SELECT
                        c.id,
                        c.title,
                        u.full_name AS instructor_name,
                        u.avatar_key AS instructor_avatar_key,
                        c.course_code,
                        c.description,
                        c.cover_image_key,
                        c.course_type::text AS course_type,
                        c.organization_id,
                        c.is_open_for_enrollment,
                        c.visibility_level::text AS visibility_level,
                        c.status::text AS status,
                        c.category,
                        c.tags,
                        c.created_by,
                        c.created_at,
                        c.updated_at,
                        c.average_rating,
                        c.total_ratings,
                        c.enrollment_count,
                        COALESCE(inv.pending_invites, 0) AS pending_invites
                    FROM courses c
                    LEFT JOIN (
                        SELECT course_id, COUNT(*)::int AS pending_invites
                        FROM course_invitations
                        WHERE status = 'pending'
                        GROUP BY course_id
                    ) inv ON inv.course_id = c.id
                    LEFT JOIN users u ON u.id = c.created_by
                    WHERE c.created_by = :uid
                    ORDER BY c.created_at DESC
                """),
                {"uid": user_id},
            ).mappings().all()

        # =========================
        # Student: courses I'm enrolled in
        # =========================
        else:
            rows = db.execute(
                text("""
                    SELECT
                        c.id,
                        c.title,
                        c.description,
                        u.full_name AS instructor_name,
                        u.avatar_key AS instructor_avatar_key,
                        c.course_code,
                        c.cover_image_key,
                        c.course_type::text AS course_type,
                        c.organization_id,
                        c.is_open_for_enrollment,
                        c.visibility_level::text AS visibility_level,
                        c.status::text AS status,
                        c.category,
                        c.tags,
                        c.created_by,
                        c.created_at,
                        c.updated_at,
                        c.average_rating,
                        c.total_ratings,
                        c.enrollment_count,
                        NULL::int AS pending_invites
                    FROM course_enrollments e
                    JOIN courses c ON c.id = e.course_id
                    LEFT JOIN users u ON u.id = c.created_by
                    WHERE e.student_id = :uid
                      AND e.status IN ('active', 'pending', 'suspended', 'completed')
                    ORDER BY e.enrolled_at DESC
                """),
                {"uid": user_id},
            ).mappings().all()

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e

    items = []
    for r in rows:
        cover_key = r.get("cover_image_key")
        cover_url = supabase.storage.from_(bucket).get_public_url(cover_key) if cover_key else None
        instructor_avatar_key = r.get("instructor_avatar_key")
        instructor_avatar_url = supabase.storage.from_(bucket).get_public_url(instructor_avatar_key) if instructor_avatar_key else None
        
        items.append(
            {
                "id": r["id"],
                "title": r["title"],
                "description": r.get("description"),
                "instructor_name": r["instructor_name"],
                "instructor_avatar_url": instructor_avatar_url,
                "course_code": r.get("course_code"),
                "cover_url": cover_url,
                "course_type": r["course_type"],
                "organization_id": r["organization_id"],
                "status": r["status"],
                "visibility_level": r["visibility_level"],
                "is_open_for_enrollment": r["is_open_for_enrollment"],
                "category": r["category"],
                "tags": r.get("tags") or [],
                "created_by": r["created_by"],
                "created_at": r["created_at"],
                "updated_at": r["updated_at"],
                "average_rating": r["average_rating"],
                "total_ratings": r["total_ratings"],
                "enrollment_count": r["enrollment_count"],
                "pending_invites": r["pending_invites"],
            }
        )

    return {
        "items": items,
        "total": len(items),
    }



def publish_course(*, course_id, db: Session, current_user: dict):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can publish coruse")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")
    

    try:
        # =========================
        # 2) Validate course exists + ownership
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, created_by, status
                FROM courses
                WHERE id = :course_id
                LIMIT 1
            """),
            {"course_id": course_id},
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=404, detail="Course not found")

        if int(course_row["created_by"]) != int(instructor_id):
            raise HTTPException(
                status_code=403,
                detail="You can only publish your own course",
            )
        
        if course_row["status"] != "draft":
            raise HTTPException(
                status_code=409,
                detail="Only draft courses can be published",
            )
        
        # =========================
        # 3) Publish course
        # =========================
        publish_row = db.execute(
            text("""
                UPDATE courses
                SET
                    status = 'published',
                    published_at = NOW(),
                    updated_at = NOW()
                WHERE id = :course_id
                RETURNING
                    id,
                    status
            """),
            {"course_id": course_id,},
        ).mappings().first()

        if not publish_row:
            db.rollback()
            raise HTTPException(status_code=409, detail="Coures could not be published")

        db.commit()

        return {
            "id": int(publish_row["id"]),
            "status": publish_row["status"],
            "message": "Course published successfully",
        }

    except HTTPException:
        db.rollback()
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while publishing course") from e
        


def list_course_invitations(*, course_id: int, limit: int, offset: int,db: Session, current_user: dict,) -> CourseInvitationsListResponse:

    # 1) Auth: instructor only
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can view invitations")

    instructor_id = current_user["id"]

    # 2) Validate course exists + ownership + private
    course_row = db.execute(
        text("""
            SELECT id, created_by, is_open_for_enrollment
            FROM courses
            WHERE id = :course_id
        """),
        {"course_id": course_id},
    ).mappings().first()

    if not course_row:
        raise HTTPException(status_code=404, detail="Course not found")

    if course_row["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only view invitations for your own course")

    if course_row["is_open_for_enrollment"] is True:
        raise HTTPException(status_code=409, detail="This course is open for enrollment and has no invitations")

    params: dict = {"course_id": course_id}

    # 3) Fetch total + items (pagination)
    total = db.execute(
        text("""
            SELECT COUNT(*)
            FROM course_invitations ci
            WHERE ci.course_id = :course_id
        """),
        params,
    ).scalar() or 0

    rows = db.execute(
        text("""
            SELECT
                ci.id,
                ci.course_id,
                ci.created_by,
                ci.invited_email,
                ci.invited_user_id,
                ci.token_expires_at,
                ci.status,
                ci.sent_at,
                ci.last_sent_at,
                ci.send_count,
                ci.accepted_at,
                ci.revoked_at,
                ci.created_at,
                ci.updated_at
            FROM course_invitations ci
            WHERE ci.course_id = :course_id
            ORDER BY ci.created_at DESC
            LIMIT :limit OFFSET :offset
        """),
        {"course_id": course_id, "limit": limit, "offset": offset},
    ).mappings().all()

    now = datetime.now(timezone.utc)

    items = []
    for r in rows:
        # runtime status override (only for pending)
        status_val = str(r["status"])  # e.g. "pending"
        token_expires_at = r["token_expires_at"]

        if status_val == "pending" and token_expires_at is not None:
            # token_expires_at is timestamptz from Postgres; usually tz-aware already
            if token_expires_at < now:
                status_val = "expired"

        items.append({
            "id": r["id"],
            "course_id": r["course_id"],
            "created_by": r["created_by"],
            "invited_email": r["invited_email"],
            "invited_user_id": r["invited_user_id"],
            "status": status_val,  # <- هنا بنرجّع القيمة المعدلة (string) لكنها هتتعمل validate على enum
            "token_expires_at": r["token_expires_at"],
            "sent_at": r["sent_at"],
            "last_sent_at": r["last_sent_at"],
            "send_count": r["send_count"],
            "accepted_at": r["accepted_at"],
            "revoked_at": r["revoked_at"],
            "created_at": r["created_at"],
            "updated_at": r["updated_at"],
            "invited_user_exists": (r["invited_user_id"] is not None),
        })

    return CourseInvitationsListResponse(
        course_id=course_id,
        total=int(total),
        items=items,
    )
    


def enroll_in_course(*, course_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "student":
        raise HTTPException(status_code=403, detail="Only students can enroll in courses")

    student_id = current_user.get("id")
    if not student_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    try:
        # =========================
        # 2) Validate course exists + is published + is open for enrollment
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, status, is_open_for_enrollment, requires_enrollment_approval
                FROM courses
                WHERE id = :course_id
                LIMIT 1
            """),
            {"course_id": course_id},
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=404, detail="Course not found")

        if course_row["status"] != "published":
            raise HTTPException(status_code=403, detail="Course is not available for enrollment")

        if not course_row["is_open_for_enrollment"]:
            raise HTTPException(status_code=403, detail="Course is not open for enrollment")

        # =========================
        # 3) Check for existing enrollment
        # =========================
        existing_enrollment = db.execute(
            text("""
                SELECT id, status
                FROM course_enrollments
                WHERE course_id  = :course_id
                  AND student_id = :student_id
                LIMIT 1
            """),
            {
                "course_id":  course_id,
                "student_id": student_id,
            },
        ).mappings().first()

        if existing_enrollment:
            if existing_enrollment["status"] == "active":
                raise HTTPException(status_code=409, detail="You are already enrolled in this course")
            if existing_enrollment["status"] == "pending":
                raise HTTPException(status_code=409, detail="Your enrollment request is already pending")
            if existing_enrollment["status"] == "suspended":
                raise HTTPException(status_code=403, detail="Your enrollment has been suspended")

        # =========================
        # 4) Create enrollment
        # =========================
        requires_approval = course_row["requires_enrollment_approval"]
        enrollment_status = "pending" if requires_approval else "active"
        now               = datetime.now(timezone.utc)

        enrollment_row = db.execute(
            text("""
                INSERT INTO course_enrollments (
                    student_id, course_id,
                    status, enrollment_type,
                    enrolled_at, completed_at
                )
                VALUES (
                    :student_id, :course_id,
                    :status, 'self',
                    :enrolled_at, NULL
                )
                ON CONFLICT (student_id, course_id)
                DO UPDATE SET
                    status          = EXCLUDED.status,
                    enrollment_type = EXCLUDED.enrollment_type,
                    enrolled_at     = EXCLUDED.enrolled_at,
                    completed_at    = NULL
                WHERE course_enrollments.status IN ('dropped', 'completed')
                RETURNING id, student_id, course_id, status, enrollment_type, enrolled_at
            """),
            {
                "student_id":  student_id,
                "course_id":   course_id,
                "status":      enrollment_status,
                "enrolled_at": now,
            },
        ).mappings().first()

        if not enrollment_row:
            raise HTTPException(status_code=500, detail="Failed to create enrollment")

        # =========================
        # 5) Increment enrollment_count if active
        # =========================
        if not requires_approval:
            db.execute(
                text("""
                    UPDATE courses
                    SET enrollment_count = enrollment_count + 1,
                        updated_at       = NOW()
                    WHERE id = :course_id
                """),
                {"course_id": course_id},
            )

        db.commit()

        return {
            "enrollment_id":   int(enrollment_row["id"]),
            "course_id":       int(enrollment_row["course_id"]),
            "status":          enrollment_row["status"],
            "enrollment_type": enrollment_row["enrollment_type"],
            "enrolled_at":     enrollment_row["enrolled_at"],
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def list_enrollment_requests(*, course_id: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can view enrollment requests")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    try:
        # =========================
        # 2) Validate course exists + ownership
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, created_by
                FROM courses
                WHERE id = :course_id
                LIMIT 1
            """),
            {"course_id": course_id},
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=404, detail="Course not found")

        if int(course_row["created_by"]) != int(instructor_id):
            raise HTTPException(status_code=403, detail="You can only view enrollment requests for your own course")

        # =========================
        # 3) Fetch pending enrollment requests
        # =========================
        request_rows = db.execute(
            text("""
                SELECT
                    ce.id          AS enrollment_id,
                    ce.student_id,
                    ce.status,
                    ce.enrolled_at,
                    u.full_name,
                    u.email
                FROM course_enrollments ce
                JOIN users u
                  ON u.id = ce.student_id
                WHERE ce.course_id = :course_id
                  AND ce.status    = 'pending'
                ORDER BY ce.enrolled_at ASC
            """),
            {"course_id": course_id},
        ).mappings().all()

        requests = [dict(row) for row in request_rows]

        return {
            "course_id": course_id,
            "total":     len(requests),
            "requests":  requests,
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e
    


def update_enrollment_request(*, course_id: int, enrollment_id: int, payload: EnrollmentRequestUpdateRequest, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can update enrollment requests")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")

    if not enrollment_id or enrollment_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid enrollment_id")

    try:
        # =========================
        # 2) Validate course exists + ownership
        # =========================
        course_row = db.execute(
            text("""
                SELECT id, created_by
                FROM courses
                WHERE id = :course_id
                LIMIT 1
            """),
            {"course_id": course_id},
        ).mappings().first()

        if not course_row:
            raise HTTPException(status_code=404, detail="Course not found")

        if int(course_row["created_by"]) != int(instructor_id):
            raise HTTPException(status_code=403, detail="You can only manage enrollment requests for your own course")

        # =========================
        # 3) Validate enrollment exists + belongs to course + is pending
        # =========================
        enrollment_row = db.execute(
            text("""
                SELECT id, course_id, student_id, status
                FROM course_enrollments
                WHERE id        = :enrollment_id
                  AND course_id = :course_id
                LIMIT 1
            """),
            {
                "enrollment_id": enrollment_id,
                "course_id":     course_id,
            },
        ).mappings().first()

        if not enrollment_row:
            raise HTTPException(status_code=404, detail="Enrollment request not found")

        if enrollment_row["status"] != "pending":
            raise HTTPException(status_code=409, detail="Enrollment request is no longer pending")

        # =========================
        # 4) Update enrollment status
        # =========================
        new_status = "active" if payload.status == "approved" else "dropped"

        db.execute(
            text("""
                UPDATE course_enrollments
                SET status = :status
                WHERE id = :enrollment_id
            """),
            {
                "enrollment_id": enrollment_id,
                "status":        new_status,
            },
        )

        # =========================
        # 5) Increment enrollment_count if approved
        # =========================
        if new_status == "active":
            db.execute(
                text("""
                    UPDATE courses
                    SET enrollment_count = enrollment_count + 1,
                        updated_at       = NOW()
                    WHERE id = :course_id
                """),
                {"course_id": course_id},
            )

        db.commit()

        return {
            "enrollment_id": enrollment_id,
            "status":        payload.status,
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e



def course_autocomplete(*, q: str, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    # =========================
    # 2) Validate query
    # =========================
    q = (q or "").strip()
    if len(q) < 1:
        return {"suggestions": []}
    if len(q) > 100:
        raise HTTPException(status_code=422, detail="Search query is too long")

    try:
        # =========================
        # 3) Fetch tag suggestions
        # =========================
        tag_rows = db.execute(
            text("""
                SELECT DISTINCT value AS suggestion
                FROM courses, json_array_elements_text(tags) AS value
                WHERE status           = 'published'
                  AND visibility_level = 'public'
                  AND tags             IS NOT NULL
                  AND value ILIKE :query
                LIMIT 4
            """),
            {"query": f"{q}%"},
        ).mappings().all()

        tag_suggestions = [row["suggestion"] for row in tag_rows]

        # =========================
        # 4) Fetch title suggestions
        # =========================
        title_rows = db.execute(
            text("""
                SELECT DISTINCT title AS suggestion
                FROM courses
                WHERE status           = 'published'
                  AND visibility_level = 'public'
                  AND title ILIKE :query
                LIMIT 4
            """),
            {"query": f"{q}%"},
        ).mappings().all()

        title_suggestions = [row["suggestion"] for row in title_rows]

        # =========================
        # 5) Merge + deduplicate (tags first)
        # =========================
        seen:        set[str] = set()
        suggestions: list[str] = []

        for suggestion in tag_suggestions + title_suggestions:
            normalized = suggestion.strip().lower()
            if normalized not in seen:
                seen.add(normalized)
                suggestions.append(suggestion)

        return {"suggestions": suggestions[:8]}

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e



def course_search(*, q: str, limit: int, offset: int, db: Session, current_user: dict,):
    # =========================
    # 1) Authorization
    # =========================
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    # =========================
    # 2) Validate query
    # =========================
    q = (q or "").strip()
    if len(q) < 1:
        raise HTTPException(status_code=422, detail="Search query is too short")
    if len(q) > 100:
        raise HTTPException(status_code=422, detail="Search query is too long")

    if limit < 1 or limit > 50:
        raise HTTPException(status_code=422, detail="limit must be between 1 and 50")
    if offset < 0:
        raise HTTPException(status_code=422, detail="offset must be 0 or greater")

    try:
        # =========================
        # 3) Count total results
        # =========================
        count_row = db.execute(
            text("""
                SELECT COUNT(*) AS total
                FROM courses
                WHERE status                = 'published'
                  AND visibility_level      = 'public'
                  AND is_open_for_enrollment = TRUE
                  AND search_vector         @@ plainto_tsquery('english', :query)
            """),
            {"query": q},
        ).mappings().first()

        if not count_row:
            raise HTTPException(
                status_code=500,
                detail="Failed to count search results",
            )

        total = int(count_row["total"])

        # =========================
        # 4) Fetch paginated results
        # =========================
        result_rows = db.execute(
            text("""
                SELECT
                    c.id,
                    c.title,
                    c.description,
                    c.course_code,
                    c.category,
                    c.tags,
                    c.cover_image_key,
                    c.banner_image_key,
                    c.course_type::text AS course_type,
                    c.organization_id,
                    c.visibility_level::text AS visibility_level,
                    c.is_open_for_enrollment,
                    c.status::text AS status,
                    c.created_by,
                    c.created_at,
                    c.updated_at,
                    c.enrollment_count,
                    c.average_rating,
                    c.total_ratings,
                    c.requires_enrollment_approval,
                    u.full_name AS instructor_name,
                    u.avatar_key AS instructor_avatar_key,
                    ts_rank(c.search_vector, plainto_tsquery('english', :query)) AS rank
                FROM courses c
                LEFT JOIN users u ON u.id = c.created_by
                WHERE c.status                = 'published'
                  AND c.visibility_level      = 'public'
                  AND c.is_open_for_enrollment = TRUE
                  AND c.search_vector         @@ plainto_tsquery('english', :query)
                ORDER BY rank DESC
                LIMIT  :limit
                OFFSET :offset
            """),
            {
                "query":  q,
                "limit":  limit,
                "offset": offset,
            },
        ).mappings().all()

        bucket = settings.supabase_public_bucket
        results = []
        for row in result_rows:
            item = dict(row)
            cover_key = item.get("cover_image_key")
            banner_key = item.get("banner_image_key")
            instructor_avatar_key = item.get("instructor_avatar_key")

            item["cover_url"] = (
                supabase.storage.from_(bucket).get_public_url(cover_key)
                if cover_key
                else None
            )
            item["banner_url"] = (
                supabase.storage.from_(bucket).get_public_url(banner_key)
                if banner_key
                else None
            )
            item["instructor_avatar_url"] = (
                supabase.storage.from_(bucket).get_public_url(instructor_avatar_key)
                if instructor_avatar_key
                else None
            )
            item.pop("instructor_avatar_key", None)
            results.append(item)

        return {
            "total":   total,
            "limit":   limit,
            "offset":  offset,
            "results": results,
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail="Database error") from e


