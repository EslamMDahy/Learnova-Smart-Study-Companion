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

from .schemas import CourseCreateRequest
from .schemas import CourseInvitesUploadResponse  # اللي عملناه

from app.core.config import settings
from app.core.security import hmac_sha256_hex
from app.core.excel_utils import extract_emails_from_xlsx



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


# TODO (Refactor لاحقاً):
# انقل ده لملف core/tokens.py أو core/security.py كدالة generate_invite_token()
def _generate_raw_invite_token() -> str:
    # raw token URL-safe
    return secrets.token_urlsafe(32)


def upload_course_invitations_excel(
    *,
    course_id: int,
    file: UploadFile,
    sheet_name: str | None,
    email_column: str,
    db: Session,
    current_user: dict,) -> CourseInvitesUploadResponse:
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
    # 6) Token policy (keep it here for now)
    # =========================
    # TODO (Refactor لاحقاً):
    # - انقل creation + hashing للتوكين لملف core/security.py أو core/tokens.py
    # - وبعد ما نعمل endpoint الإرسال، ممكن نخلي token يتولد هناك بدل هنا
    if not settings.invite_token_secret:
        raise HTTPException(status_code=500, detail="Server misconfigured: INVITE_TOKEN_SECRET is missing")

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(days=7)

    # =========================
    # 7) Insert invitations (bulk)
    # =========================
    inserted = 0
    try:
        for invited_email in to_insert:
            raw_token = _generate_raw_invite_token()
            token_hash = hmac_sha256_hex(raw_token, settings.invite_token_secret)

            invited_user_id = email_to_user_id.get(invited_email)

            db.execute(
                text("""
                    INSERT INTO course_invitations (
                        course_id,
                        created_by,
                        invited_email,
                        invited_user_id,
                        token_hash,
                        token_expires_at,
                        status,
                        created_at,
                        updated_at
                    )
                    VALUES (
                        :course_id,
                        :created_by,
                        :invited_email,
                        :invited_user_id,
                        :token_hash,
                        :token_expires_at,
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
                    "token_hash": token_hash,
                    "token_expires_at": expires_at,
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
        token_expires_at=expires_at,
        sample_invalid_emails=result.sample_invalid,
        sample_existing_emails=sample_existing,
    )

