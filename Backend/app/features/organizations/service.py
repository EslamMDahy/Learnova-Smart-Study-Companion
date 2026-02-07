from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text

from typing import Dict, Any, List
import secrets

from app.core.emailer import send_email

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


def list_join_requests(*, organization_id: int, view: str, db: Session, current_user) -> Dict[str, Any]:
    """
    Returns join requests for a given organization owned by the current owner.

    view:
      - "pending"  -> status IN ("pending")
      - "accepted" -> status IN ("accepted", "suspended")
    """

    # 1) Owner-only
    if current_user.get("system_role") != "owner":
        raise HTTPException(status_code=403, detail="Only owners can view join requests")

    owner_id = current_user.get("id")
    if owner_id is None:
        # Defensive: get_current_user should always include id
        raise HTTPException(status_code=401, detail="Invalid token")

    # 2) Validate view
    view = (view or "").strip().lower()
    if view not in {"pending", "accepted"}:
        raise HTTPException(status_code=400, detail="Invalid view")

    if view == "pending":
        statuses = ("pending",)
    else:
        # "accepted" view shows accepted + suspended together (per your leader decision)
        statuses = ("accepted", "suspended")

    # 3) Ownership check: organization_id must belong to this owner
    org_exists = db.execute(
        text("""
            SELECT 1
            FROM organizations
            WHERE id = :org_id AND owner_id = :owner_id
        """),
        {"org_id": organization_id, "owner_id": owner_id},
    ).first()

    if not org_exists:
        # Either org doesn't exist OR not owned by this owner (security)
        raise HTTPException(status_code=403, detail="Access denied")

    # 4) Fetch users from organization_members + users
    rows = db.execute(
        text("""
            SELECT
                u.id,
                u.full_name,
                u.email,
                u.avatar_url,
                u.system_role,
                om.status,
                om.id
            FROM organization_members om
            JOIN users u ON u.id = om.user_id
            WHERE om.organization_id = :org_id
              AND om.status = ANY(:statuses)
            ORDER BY u.id ASC
        """),
        {"org_id": organization_id, "statuses": list(statuses)},
    ).all()

    users: List[Dict[str, Any]] = [
        {
            "id": r[0],
            "org_member_id": r[6],
            "full_name": r[1],
            "email": r[2],
            "avatar_url": r[3],
            "system_role": r[4],
            "status": r[5],
        }
        for r in rows
    ]

    return {"count": len(users), "users": users}





def update_member_status(
    *,
    organization_id: int,
    org_member_id: int,
    new_status: str,
    db: Session,
    current_user,
):
    # 1) Owner-only
    if current_user.get("system_role") != "owner":
        raise HTTPException(status_code=403, detail="Only owners can update member status")

    owner_id = current_user.get("id")
    if owner_id is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    new_status = (new_status or "").strip().lower()
    allowed_statuses = {"pending", "accepted", "suspended", "declinate"}
    if new_status not in allowed_statuses:
        raise HTTPException(status_code=400, detail="Invalid status")

    # 2) Verify organization ownership (security)
    org_ok = db.execute(
        text("""
            SELECT 1
            FROM organizations
            WHERE id = :org_id AND owner_id = :owner_id
        """),
        {"org_id": organization_id, "owner_id": owner_id},
    ).first()
    if not org_ok:
        raise HTTPException(status_code=403, detail="Access denied")

    # 3) Load membership row + user info (and ensure member belongs to this org)
    row = db.execute(
        text("""
            SELECT
                om.id,
                om.organization_id,
                om.user_id,
                om.status,
                u.email,
                u.full_name
            FROM organization_members om
            JOIN users u ON u.id = om.user_id
            WHERE om.id = :om_id
        """),
        {"om_id": org_member_id},
    ).first()

    if not row:
        raise HTTPException(status_code=404, detail="Member not found")

    om_id, om_org_id, user_id, old_status, user_email, user_full_name = row

    if om_org_id != organization_id:
        # Prevent cross-org tampering
        raise HTTPException(status_code=403, detail="Access denied")

    old_status = (old_status or "").strip().lower()

    # 4) Transition rules (حسب اللي اتفقنا عليه)
    allowed_transitions = {
        "pending": {"accepted", "declinate"},
        "accepted": {"suspended"},
        "suspended": {"accepted"},
        "declinate": set(),  # terminal
    }

    if old_status not in allowed_transitions:
        raise HTTPException(status_code=500, detail="Invalid stored status")

    if new_status == old_status:
        # Idempotent-ish: اعتبرها OK بدون تغيير
        return {
            "org_member_id": om_id,
            "user_id": user_id,
            "organization_id": om_org_id,
            "old_status": old_status,
            "new_status": old_status,
        }

    if new_status not in allowed_transitions[old_status]:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status transition: {old_status} -> {new_status}",
        )

    # 5) Update status (+ joined_at لو أول مرة accepted من pending)
    if old_status == "pending" and new_status == "accepted":
        db.execute(
            text("""
                UPDATE organization_members
                SET status = :new_status,
                    joined_at = COALESCE(joined_at, NOW())
                WHERE id = :om_id
            """),
            {"new_status": new_status, "om_id": om_id},
        )
    else:
        db.execute(
            text("""
                UPDATE organization_members
                SET status = :new_status
                WHERE id = :om_id
            """),
            {"new_status": new_status, "om_id": om_id},
        )

    db.commit()

    # 6) Send email (simple placeholder)
    # الليدر يقدر يبدّل HTML later
    subject = "Learnova – Membership update"
    body = f"Hello {user_full_name},\n\nYour membership status has been updated to: {new_status}\n"
    try:
        send_email(to=user_email, subject=subject, body=body, html=None)
    except Exception:
        pass

    return {
        "org_member_id": om_id,
        "user_id": user_id,
        "organization_id": om_org_id,
        "old_status": old_status,
        "new_status": new_status,
    }
