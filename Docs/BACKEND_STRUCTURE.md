# Backend Structure
<pre>
Backend/
├─ .venv/
|
├─ alembic/
│  ├─ versions/
|  └─ env.py
|
├─ app/
│  ├─ core/
|  |  ├─ ai_callback_verifier.py
|  |  ├─ ai_request_tracking.py
|  |  ├─ ai_signature.py
|  |  ├─ config.py
|  |  ├─ deps.py
|  |  ├─ emailer.py
|  |  ├─ excel_utils.py
|  |  ├─ jwt.py
|  |  ├─ security.py
|  |  ├─ storage_utils.py
|  |  ├─ supabase_clint.py
│  │  └─ token_store.py
|  |
│  ├─ db/
│  │  ├─ base.py
│  │  └─ session.py
|  | 
│  ├─ features/
|  |  ├─ auth/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  └─ service.py
|  |  |
|  |  ├─ courses/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  └─ service.py
|  |  |
|  |  ├─ learningOutcomes/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  └─ service.py
|  |  |
|  |  ├─ materials/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  └─ service.py
|  |  |
|  |  ├─ modules/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  └─ service.py
|  |  |
|  |  ├─ organizations/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  └─ service.py
|  |  |
|  |  ├─ questions/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  ├─ service.py
|  |  |  └─ helpers.py
|  |  |
|  |  ├─ settings/
|  |  |  ├─ router.py
|  |  |  ├─ schemas.py
|  |  |  └─ service.py
|  |  |
|  |  └─ topics/
|  |     ├─ router.py
|  |     ├─ schemas.py
|  |     └─ service.py
|  | 
│  ├─ models/
|  |
│  └─ main.py
|
├─ assets/
|  └─ logo.png
|
├─ alembic.ini
├─ README.md
└─ requirements.txt
</pre>