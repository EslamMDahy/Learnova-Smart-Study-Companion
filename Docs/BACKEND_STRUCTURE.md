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
|  |  ├─ ai_service_integration/
|  |  |  ├─ ai_callback_verifier.py
|  |  |  ├─ ai_protocol.py
|  |  |  ├─ ai_request_tracking.py
|  |  |  ├─ ai_signature.py
|  |  |  └─ ai_transport.py
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
|  |  ├─ ai/
|  |  |  ├─ handlers.py
|  |  |  ├─ helpers.py
|  |  |  ├─ router.py
|  |  |  └─ service.py
|  |  |
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
|  |  |  ├─ helpers.py
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
|  |     ├─ helpers.py
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