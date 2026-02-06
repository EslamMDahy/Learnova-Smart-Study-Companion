import secrets
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException


def _generate_invite_code() -> str:
    # كود قصير عملي (ممكن تغييره لاحقًا)
    return secrets.token_hex(3)  # 6 chars تقريبًا


def create_organization(payload, db: Session, current_user):
    # 1) السماح للـ owner فقط
    if current_user.get("system_role") != "owner":
        raise HTTPException(status_code=403, detail="Only owners can create organizations")

    owner_id = current_user["id"]

    
    # 3) توليد invite_code (مع إعادة المحاولة لو حصل collision)
    invite_code = _generate_invite_code()
    for _ in range(5):
        exists = db.execute(
            text("SELECT 1 FROM organizations WHERE invite_code = :code"),
            {"code": invite_code},
        ).first()
        if not exists:
            break
        invite_code = _generate_invite_code()
    else:
        raise HTTPException(status_code=500, detail="Failed to generate invite code")

    # 4) Insert organization
    row = db.execute(
        text("""
            INSERT INTO organizations
            (name, description, logo_url, owner_id, invite_code, subscription_status, created_at, updated_at)
            VALUES
            (:name, :desc, :logo, :owner_id, :invite_code, 'active', NOW(), NOW())
            RETURNING
            id, name, description, logo_url, owner_id, subscription_plan_id, invite_code, subscription_status
            """
        ),
        {
            "name": payload.name,
            "desc": payload.description,  # الليدر قال type = description
            "logo": payload.logo_url,
            "owner_id": owner_id,
            "invite_code": invite_code,
        },
    ).first()

    db.commit()

    if not row:
        raise HTTPException(status_code=400, detail="somthing went wrong")

    return {
        "organization": {
            "id": row[0],
            "name": row[1],
            "description": row[2],
            "logo_url": row[3],
            "owner_id": row[4],
            "subscription_plan_id": row[5],
            "invite_code": row[6],
            "subscription_status": row[7],
        }
    }
