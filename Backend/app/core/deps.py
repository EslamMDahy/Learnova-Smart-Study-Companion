from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.core.jwt import decode_access_token
from app.db.session import get_db  # <-- عدّل المسار لو مختلف عندك

bearer_scheme = HTTPBearer(auto_error=False)

def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
):
    # 1) لازم يبقى فيه Authorization header
    if not creds or creds.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Not authenticated")

    token = creds.credentials

    # 2) فك التوكين وتحقق منه
    payload = decode_access_token(token)

    user_id = payload.get("sub")
    token_version = int(payload.get("tv", -1))

    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    # 3) هات اليوزر من DB
    row = db.execute(
        text("""
            SELECT id, email, full_name, is_email_verified, token_version
            FROM users
            WHERE id = :id
        """),
        {"id": int(user_id)},
    ).first()

    if not row:
        raise HTTPException(status_code=401, detail="User not found")

    uid, email, full_name, is_verified, db_tv = row

    # (اختياري لكن بروفيشنال): لو حد اتسربتله توكين قديم قبل التفعيل
    if not is_verified:
        raise HTTPException(status_code=403, detail="Email not verified")
    
    if token_version != db_tv:
        raise HTTPException(401, "Token revoked")

    # رجّع dict بسيط
    return {"id": uid, "email": email, "full_name": full_name}
