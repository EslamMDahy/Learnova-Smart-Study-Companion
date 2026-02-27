from __future__ import annotations

from fastapi import HTTPException
from datetime import datetime, timezone
from sqlalchemy import text
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
import re

from app.core.config import settings
from app.core.supabase_client import supabase  # عدّل import حسب مكان supabase client عندك


_PDF_MAX_BYTES = 50 * 1024 * 1024
_ALLOWED_CONTENT_TYPES = {"application/pdf"}


def _sanitize_filename(filename: str) -> str:
    """
    - remove any path parts
    - keep safe chars
    - collapse spaces
    """
    name = (filename or "").strip()
    if not name:
        return "file.pdf"

    # take last part to avoid "C:\\x\\y.pdf" or "../../y.pdf"
    name = name.replace("\\", "/").split("/")[-1].strip()

    # replace spaces with underscores
    name = re.sub(r"\s+", "_", name)

    # allow letters, numbers, dash, underscore, dot
    name = re.sub(r"[^A-Za-z0-9._-]", "", name)

    # ensure extension
    if not name.lower().endswith(".pdf"):
        name = name + ".pdf"

    # limit length
    if len(name) > 120:
        base, ext = name.rsplit(".", 1)
        name = base[:115] + "." + ext

    return name or "file.pdf"


def init_material_upload(*, course_id: int, module_id: int, payload, db: Session, current_user: dict):
    # =========================
    # 1) AuthZ
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can upload materials")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id")
    if not module_id or module_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid module_id")

    # =========================
    # 2) Validate module belongs to course + course ownership
    # =========================
    mod = db.execute(
        text("""
            SELECT m.id AS module_id, m.course_id, c.created_by
            FROM modules m
            JOIN courses c ON c.id = m.course_id
            WHERE m.id = :mid
            LIMIT 1
        """),
        {"mid": module_id},
    ).mappings().first()

    if not mod:
        raise HTTPException(status_code=404, detail="Module not found")

    if int(mod["course_id"]) != int(course_id):
        raise HTTPException(status_code=400, detail="Module does not belong to this course")

    if mod["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only upload materials for your own course")

    # =========================
    # 3) Validate file metadata
    # =========================
    content_type = (getattr(payload, "content_type", None) or "").strip().lower()
    file_size_bytes = getattr(payload, "file_size_bytes", None)
    filename = getattr(payload, "filename", None)

    if not content_type:
        raise HTTPException(status_code=400, detail="content_type is required")

    if content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="Invalid content_type. Allowed: application/pdf")

    if file_size_bytes is None:
        raise HTTPException(status_code=400, detail="file_size_bytes is required")

    try:
        file_size_bytes = int(file_size_bytes)
    except Exception:
        raise HTTPException(status_code=400, detail="file_size_bytes must be an integer")

    if file_size_bytes <= 0:
        raise HTTPException(status_code=400, detail="file_size_bytes must be > 0")

    if file_size_bytes > _PDF_MAX_BYTES:
        raise HTTPException(status_code=400, detail="File is too large (max 50MB)")

    safe_filename = _sanitize_filename(str(filename or ""))

    # optional metadata
    title = getattr(payload, "title", None)
    if isinstance(title, str):
        title = title.strip() or None

    description = getattr(payload, "description", None)
    if isinstance(description, str):
        description = description.strip() or None

    bucket = settings.supabase_private_bucket

    # =========================
    # 4) DB: create draft material row to get material_id
    # =========================
    # storage_key is non-null -> put a temporary value, then update it
    temp_key = "tmp"

    try:
        row = db.execute(
            text("""
                INSERT INTO materials (
                    module_id,
                    title,
                    description,
                    type,
                    file_name,
                    file_size,
                    storage_key,
                    mime_type,
                    status,
                    text_extracted,
                    is_ai_processed,
                    uploaded_by,
                    uploaded_at,
                    created_at,
                    updated_at
                )
                VALUES (
                    :module_id,
                    :title,
                    :description,
                    CAST(:type AS material_type_enum),
                    :file_name,
                    :file_size,
                    :storage_key,
                    :mime_type,
                    CAST(:status AS material_status_enum),
                    FALSE,
                    FALSE,
                    :uploaded_by,
                    NOW(),
                    NOW(),
                    NOW()
                )
                RETURNING id, created_at
            """),
            {
                "module_id": module_id,
                "title": title,
                "description": description,
                "type": "pdf",
                "file_name": safe_filename,
                "file_size": file_size_bytes,
                "storage_key": temp_key,
                "mime_type": content_type,
                "status": "draft_upload",
                "uploaded_by": instructor_id,
            },
        ).mappings().first()

        if not row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to create material record")

        material_id = int(row["id"])
        created_at = row.get("created_at")

        # compute final storage key
        storage_key = (
            f"courses/{course_id}/modules/{module_id}/materials/{material_id}/{safe_filename}"
        )

        # update storage_key to final path
        db.execute(
            text("""
                UPDATE materials
                SET storage_key = :storage_key,
                    updated_at = NOW()
                WHERE id = :mid
            """),
            {"storage_key": storage_key, "mid": material_id},
        )

        db.commit()

    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Conflict while creating material") from e
    except SQLAlchemyError as e:
        db.rollback()
        print(str(e))
        raise HTTPException(status_code=500, detail="Database error") from e

    # =========================
    # 5) Supabase: create signed upload URL (private bucket)
    # =========================
    try:
        signed = supabase.storage.from_(bucket).create_signed_upload_url(storage_key)
    except Exception as e:
        # if storage failed, you may want to mark material as error later (optional)
        raise HTTPException(status_code=400, detail=f"Failed to create signed upload url: {str(e)}")

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
    token = data.get("token")
    path = data.get("path") or storage_key

    if not upload_url:
        raise HTTPException(status_code=400, detail="Signed upload URL is missing from response")

    return {
        "material_id": material_id,
        "module_id": module_id,
        "course_id": course_id,
        "upload_url": upload_url,
        "storage_key": storage_key,
        "bucket": bucket,
        "content_type": content_type,
        "max_bytes": _PDF_MAX_BYTES,
        "expires_in_seconds": None,
        "status": "draft_upload",
        "created_at": created_at if created_at else datetime.now(timezone.utc),
        # token/path لو schemas عندك بتعرضهم (اختياري)
        # "token": token,
        # "path": path,
    }


# صلاحية لينك الداونلود (ثواني)
DOWNLOAD_URL_EXPIRES = 60 * 60  # 1 hour


def _split_storage_key(storage_key: str):
    """
    Returns (folder, filename) from storage_key
    e.g. "a/b/c/file.pdf" -> ("a/b/c", "file.pdf")
    """
    key = (storage_key or "").strip().strip("/")
    if not key or "/" not in key:
        return "", key
    folder, filename = key.rsplit("/", 1)
    return folder, filename


def confirm_material_upload(*, material_id: int, db: Session, current_user: dict):
    # =========================
    # 1) AuthZ
    # =========================
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can confirm material uploads")

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    if not material_id or material_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid material_id")

    bucket = settings.supabase_private_bucket

    # =========================
    # 2) Fetch material + ownership (material -> module -> course)
    # =========================
    mat = db.execute(
        text("""
            SELECT
                mt.id AS material_id,
                mt.module_id,
                mt.storage_key,
                mt.status,
                mt.file_name,
                m.course_id,
                c.created_by
            FROM materials mt
            JOIN modules m ON m.id = mt.module_id
            JOIN courses c ON c.id = m.course_id
            WHERE mt.id = :mid
            LIMIT 1
        """),
        {"mid": material_id},
    ).mappings().first()

    if not mat:
        raise HTTPException(status_code=404, detail="Material not found")

    if mat["created_by"] != instructor_id:
        raise HTTPException(status_code=403, detail="You can only manage materials for your own course")

    storage_key = (mat["storage_key"] or "").strip()
    if not storage_key:
        raise HTTPException(status_code=500, detail="Material storage_key is missing")

    current_status = (mat["status"] or "").strip()

    # =========================
    # 3) Idempotency / status check
    # =========================
    if current_status != "draft_upload":
        # لو بالفعل confirmed قبل كده (أو حالة تانية) رجّع 409 أو 200 حسب اللي تفضله
        # أنا هخليه 409 عشان يبين misuse واضح
        raise HTTPException(
            status_code=409,
            detail=f"Material status must be 'draft_upload' to confirm upload (current: '{current_status}')",
        )

    # =========================
    # 4) Verify file exists in storage (no download)
    # =========================
    folder, expected_filename = _split_storage_key(storage_key)

    try:
        items = supabase.storage.from_(bucket).list(path=folder)
    except Exception:
        items = None

    exists = False
    if isinstance(items, list):
        for it in items:
            # غالبًا dict فيه "name"
            if isinstance(it, dict) and it.get("name") == expected_filename:
                exists = True
                break

    if not exists:
        raise HTTPException(
            status_code=400,
            detail="Uploaded file not found in storage. Upload the file first, then confirm.",
        )

    # =========================
    # 5) Update DB status to READY
    # =========================
    try:
        row = db.execute(
            text("""
                UPDATE materials
                SET
                    status = CAST(:new_status AS material_status_enum),
                    uploaded_at = NOW(),
                    updated_at = NOW()
                WHERE id = :mid
                RETURNING updated_at
            """),
            {"mid": material_id, "new_status": "uploaded"},
        ).first()

        if not row:
            db.rollback()
            raise HTTPException(status_code=503, detail="Failed to confirm material upload")

        db.commit()

    except SQLAlchemyError as e:
        db.rollback()
        # مهم: ده ممكن يطلع لو READY_STATUS مش موجود في enum
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}") from e

    updated_at = row[0].isoformat() if row and row[0] else datetime.now(timezone.utc).isoformat()

    # =========================
    # 6) Create signed download URL (private bucket)
    # =========================
    download_url = None
    try:
        signed = supabase.storage.from_(bucket).create_signed_url(storage_key, DOWNLOAD_URL_EXPIRES)
    except Exception:
        signed = None

    if isinstance(signed, dict):
        download_url = signed.get("signedUrl") or signed.get("signed_url") or signed.get("url")
    else:
        data = getattr(signed, "data", None) if signed is not None else None
        if isinstance(data, dict):
            download_url = data.get("signedUrl") or data.get("signed_url") or data.get("url")

    # download_url اختياري — لو فشل، confirm نفسه يفضل ناجح
    return {
        "material_id": int(mat["material_id"]),
        "module_id": int(mat["module_id"]),
        "course_id": int(mat["course_id"]),
        "status": "uploaded",
        "updated_at": updated_at,
        "download_url": download_url,
        "download_url_expires_in": DOWNLOAD_URL_EXPIRES,
    }