from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text

from .schemas import UpdateProfileRequest


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
