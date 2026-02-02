import os
from datetime import datetime, timedelta, timezone
from jose import jwt

JWT_SECRET = os.getenv("JWT_SECRET")
JWT_ALG = os.getenv("JWT_ALG", "HS256")
JWT_EXPIRE_MIN = int(os.getenv("JWT_EXPIRE_MIN", "60"))

def create_access_token(*, subject: str, extra: dict | None = None) -> str:
    """
    subject: غالبًا user_id كنص
    extra: claims إضافية بسيطة (email, full_name, role...)
    """
    if not JWT_SECRET:
        raise RuntimeError("JWT_SECRET is missing")

    now = datetime.now(timezone.utc)
    payload = {
        "sub": subject,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=JWT_EXPIRE_MIN)).timestamp()),
    }
    if extra:
        payload.update(extra)

    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)
