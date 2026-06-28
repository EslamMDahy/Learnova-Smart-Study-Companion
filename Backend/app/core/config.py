import os
from datetime import datetime
from typing import Literal


class Settings:
    def __init__(self):
        # Database
        self.database_url: str = os.getenv("DATABASE_URL", "")

        # App URLs
        self.api_base_url: str = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")
        self.frontend_base_url: str = os.getenv("FRONTEND_BASE_URL", "https://learnova-edu.com")

        # JWT
        self.jwt_secret: str = os.getenv("JWT_SECRET", "")
        self.jwt_alg: str = os.getenv("JWT_ALG", "HS256")
        self.jwt_expire_min: int = int(os.getenv("JWT_EXPIRE_MIN", "60"))

        # Invite tokens (HMAC)
        self.invite_token_secret: str = os.getenv("INVITE_TOKEN_SECRET", "")

        # SMTP
        self.smtp_host: str = os.getenv("SMTP_HOST", "")
        self.smtp_port: int = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user: str = os.getenv("SMTP_USER", "")
        self.smtp_pass: str = os.getenv("SMTP_PASS", "")

        # Email branding
        self.email_logo_url: str = os.getenv("EMAIL_LOGO_URL", "")
        self.email_support_email: str = os.getenv("EMAIL_SUPPORT_EMAIL", "support@learnova.com")
        self.email_brand_year: int = int(os.getenv("EMAIL_BRAND_YEAR", str(datetime.now().year)))

        # Refresh token
        self.refresh_token_secret: str = os.getenv("REFRESH_TOKEN_SECRET", "")
        self.refresh_cookie_name: str = os.getenv("REFRESH_COOKIE_NAME", "refresh_token")
        self.refresh_token_expire_days_short: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS_SHORT", "1"))
        self.refresh_token_expire_days_remember: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS_REMEMBER", "30"))

        # ─── Cookie settings ─────────────────────────────────────────────────────
        # Auto-detected from ENV variable (default = development):
        #
        # Development  → SameSite=lax,  Secure=false
        #   Works on localhost because frontend & backend share the same host.
        #   Flutter Web XHR sends cookies automatically (same-site).
        #
        # Production   → SameSite=none, Secure=true
        #   Required for cross-domain cookies (different domains with HTTPS).
        #   Set ENV=production in your server environment variables.
        # ─────────────────────────────────────────────────────────────────────────
        is_production = os.getenv("ENV", "development").lower() == "production"

        self.cookie_secure: bool = (
            os.getenv("COOKIE_SECURE", "true" if is_production else "false")
            .strip()
            .lower()
            == "true"
        )

        self.cookie_samesite: str = os.getenv("COOKIE_SAMESITE", "none" if is_production else "lax",).strip().lower()

        self.cookie_path: str = os.getenv("COOKIE_PATH", "/")

        # Supabase Storage
        self.supabase_url: str = os.getenv("SUPABASE_URL", "")
        self.supabase_service_role_key: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
        self.supabase_public_bucket: str = os.getenv("SUPABASE_PUBLIC_BUCKET", "learnova-public-assets")
        self.supabase_private_bucket: str = os.getenv("SUPABASE_PRIVATE_BUCKET", "learnova-private-assets")

        # AI Service Integration
        self.ai_service_base_url: str = os.getenv("AI_SERVICE_BASE_URL", "http://127.0.0.1:8001")
        self.ai_shared_secret: str = os.getenv("AI_SHARED_SECRET", "")
        self.ai_request_timeout_seconds: int = int(os.getenv("AI_REQUEST_TIMEOUT_SECONDS", "120"))
        self.ai_allowed_timestamp_drift_seconds: int = int(os.getenv("AI_ALLOWED_TIMESTAMP_DRIFT_SECONDS", "300"))


        # Fast exam scan defaults. Keep the request under a few seconds by avoiding
        # CPU-heavy OCR/vision models inline. Turn the accurate flags on only when
        # you explicitly accept slower processing.
        self.ocr_fast_scan: bool = os.getenv("OCR_FAST_SCAN", "true").strip().lower() in {"1", "true", "yes", "on"}
        self.ocr_skip_cover_page_bubbles: bool = os.getenv("OCR_SKIP_COVER_PAGE_BUBBLES", "true").strip().lower() in {"1", "true", "yes", "on"}
        self.ocr_bubble_max_work_longest: int = int(os.getenv("OCR_BUBBLE_MAX_WORK_LONGEST", "1800"))
        self.ocr_handwriting_engine: str = os.getenv("OCR_HANDWRITING_ENGINE", "auto").strip().lower()
        self.ocr_trocr_inline: bool = os.getenv("OCR_TROCR_INLINE", "false").strip().lower() in {"1", "true", "yes", "on"}
        self.ocr_submit_ai_require_reference: bool = os.getenv("OCR_SUBMIT_AI_REQUIRE_REFERENCE", "true").strip().lower() in {"1", "true", "yes", "on"}

        # Local/free OCR vision grading for scanned written answers.
        # Provider: ollama = local free vision model, off = keep OCR text/manual review only.
        # OCR_VISION_INLINE defaults to false because local LLaVA on CPU can take 1-2 minutes.
        self.ocr_vision_enabled: bool = os.getenv("OCR_VISION_ENABLED", "false").strip().lower() in {"1", "true", "yes", "on"}
        self.ocr_vision_inline: bool = os.getenv("OCR_VISION_INLINE", "false").strip().lower() in {"1", "true", "yes", "on"}
        self.ocr_vision_provider: str = os.getenv("OCR_VISION_PROVIDER", "ollama").strip().lower()
        self.ocr_vision_ollama_base_url: str = os.getenv("OCR_VISION_OLLAMA_BASE_URL", "http://127.0.0.1:11434").rstrip("/")
        self.ocr_vision_ollama_model: str = os.getenv("OCR_VISION_OLLAMA_MODEL", "llava:7b")
        self.ocr_vision_timeout_seconds: int = int(os.getenv("OCR_VISION_TIMEOUT_SECONDS", "8"))
        self.ocr_vision_min_confidence_to_grade: float = float(os.getenv("OCR_VISION_MIN_CONFIDENCE_TO_GRADE", "62"))
        self.ocr_vision_temperature: float = float(os.getenv("OCR_VISION_TEMPERATURE", "0"))

        # Written-answer extraction mode:
        # - local/tesseract/auto: fast local OCR crops (default)
        # - vision_page / ai_vision: one local Ollama vision request over the written pages,
        #   used to extract all essay/short-answer responses together. This is usually
        #   more accurate for handwriting than Tesseract and avoids reading only the
        #   first essay crop, but speed depends on the selected local vision model.
        self.ocr_written_extraction_mode: str = os.getenv("OCR_WRITTEN_EXTRACTION_MODE", "local").strip().lower()
        self.ocr_vision_page_max_long_side: int = int(os.getenv("OCR_VISION_PAGE_MAX_LONG_SIDE", "1400"))
        self.ocr_vision_page_jpeg_quality: int = int(os.getenv("OCR_VISION_PAGE_JPEG_QUALITY", "78"))
        self.ocr_vision_page_fallback_to_local_ocr: bool = os.getenv("OCR_VISION_PAGE_FALLBACK_TO_LOCAL_OCR", "true").strip().lower() in {"1", "true", "yes", "on"}

settings = Settings()