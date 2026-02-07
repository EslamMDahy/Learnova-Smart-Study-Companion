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
|  |  ├─ deps.py
|  |  ├─ emailer.py
|  |  ├─ jwt.py
|  |  ├─ security.py
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
|  |  └─ organizations/
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