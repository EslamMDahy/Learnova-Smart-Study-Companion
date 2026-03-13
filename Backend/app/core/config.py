import os
from dataclasses import dataclass
from datetime import datetime
from typing import Literal


@dataclass(frozen=True)
class Settings:
    # App URLs
    api_base_url: str = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")
    frontend_base_url: str = os.getenv("FRONTEND_BASE_URL", "http://localhost:5173")

    # JWT
    jwt_secret: str = os.getenv("JWT_SECRET", "")
    jwt_alg: str = os.getenv("JWT_ALG", "HS256")
    jwt_expire_min: int = int(os.getenv("JWT_EXPIRE_MIN", "60"))

    # Invite tokens (HMAC)
    invite_token_secret: str = os.getenv("INVITE_TOKEN_SECRET", "")

    # SMTP
    smtp_host: str = os.getenv("SMTP_HOST", "")
    smtp_port: int = int(os.getenv("SMTP_PORT", "587"))
    smtp_user: str = os.getenv("SMTP_USER", "")
    smtp_pass: str = os.getenv("SMTP_PASS", "")

    # Email branding
    email_logo_url: str = os.getenv("EMAIL_LOGO_URL", "")
    email_support_email: str = os.getenv("EMAIL_SUPPORT_EMAIL", "support@learnova.com")
    email_brand_year: int = int(os.getenv("EMAIL_BRAND_YEAR", str(datetime.now().year)))

    # Refresh token
    refresh_token_secret: str = os.getenv("REFRESH_TOKEN_SECRET", "")
    refresh_cookie_name: str = os.getenv("REFRESH_COOKIE_NAME", "refresh_token")
    refresh_token_expire_days_short: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS_SHORT", "1"))
    refresh_token_expire_days_remember: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS_REMEMBER", "30"))

    # ─── Cookie settings ────────────────────────────────────────────────────────
    # IMPORTANT — Flutter Web on localhost:
    #
    # The frontend (:5173) and backend (:8000) are different ports = cross-origin.
    # For the HttpOnly refresh-token cookie to be sent on a credentialed cross-origin
    # POST from Flutter Web XHR (withCredentials=true), you MUST use:
    #
    #   COOKIE_SAMESITE=none   → tells browser: send cookie on cross-origin requests
    #   COOKIE_SECURE=false    → Chrome on localhost allows SameSite=none without Secure
    #   COOKIE_PATH=/          → cookie must reach /auth/refresh (a subpath of /)
    #
    # Setting COOKIE_SAMESITE=lax causes the browser to silently drop the cookie on
    # cross-origin POST requests, so the backend receives no cookie → 401.
    # ────────────────────────────────────────────────────────────────────────────
    cookie_secure: bool = os.getenv("COOKIE_SECURE", "false").lower() == "true"
    cookie_samesite: Literal["lax", "strict", "none"] = os.getenv("COOKIE_SAMESITE", "none")  # type: ignore
    cookie_path: str = os.getenv("COOKIE_PATH", "/")

    # Supabase Storage
    supabase_url: str = os.getenv("SUPABASE_URL", "")
    supabase_service_role_key: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    supabase_public_bucket: str = os.getenv("SUPABASE_PUBLIC_BUCKET", "learnova-public-assets")
    supabase_private_bucket: str = os.getenv("SUPABASE_PRIVATE_BUCKET", "learnova-private-assets")


settings = Settings()