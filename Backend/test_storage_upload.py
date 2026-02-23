from dotenv import load_dotenv
load_dotenv()

import os
from app.core.supabase_client import supabase
from app.core.config import settings
from storage3.types import FileOptions


def main():
    # 1) تأكد إن env vars موجودة
    assert settings.supabase_url, "SUPABASE_URL is missing"
    assert settings.supabase_service_role_key, "SUPABASE_SERVICE_ROLE_KEY is missing"

    bucket = settings.supabase_public_bucket  # هنرفع في public bucket
    local_path = "assets/logo.ico"             # غيّر الاسم لو ملفك مختلف

    if not os.path.exists(local_path):
        raise FileNotFoundError(f"File not found: {local_path}")

    # 2) key (مكان التخزين جوه bucket)
    key = "emails/assets/logo.ico"

    # 3) ارفع الملف
    with open(local_path, "rb") as f:
        content = f.read()

    
    # مهم: محتوى الملف + نوعه
    res = supabase.storage.from_(bucket).upload(
    path=key,
    file=content,
    file_options={
        "content-type": "image/x-icon",
        "x-upsert": "true",
    },
)

    print("Upload response:", res)

    # 4) هات public URL
    public_url = supabase.storage.from_(bucket).get_public_url(key)
    print("Public URL:", public_url)

if __name__ == "__main__":
    main()