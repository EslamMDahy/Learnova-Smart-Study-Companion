import os
from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class Settings:
    # App URLs
    api_base_url: str = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")
    frontend_base_url: str = os.getenv("FRONTEND_BASE_URL", "http://localhost:5173")

    # JWT
    jwt_secret: str = os.getenv("JWT_SECRET", "")
    jwt_alg: str = os.getenv("JWT_ALG", "HS256")
    jwt_expire_min: int = int(os.getenv("JWT_EXPIRE_MIN", "60"))

    # SMTP
    smtp_host: str = os.getenv("SMTP_HOST", "")
    smtp_port: int = int(os.getenv("SMTP_PORT", "587"))
    smtp_user: str = os.getenv("SMTP_USER", "")
    smtp_pass: str = os.getenv("SMTP_PASS", "")

    # Email branding
    email_logo_url: str = os.getenv("EMAIL_LOGO_URL", "")
    email_support_email: str = os.getenv("EMAIL_SUPPORT_EMAIL", "support@learnova.com")
    email_brand_year: int = int(os.getenv("EMAIL_BRAND_YEAR", str(datetime.now().year)))


settings = Settings()
