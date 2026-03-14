# Learnova Backend

FastAPI + PostgreSQL + SQLAlchemy + Alembic

This guide is for teammates who want to run the **backend locally** (Windows-focused, with Linux/macOS notes).

---

## What you need

- **Python 3.10+** (recommended **3.11**)
- **Git**
- **PostgreSQL** (portable ZIP or normal installer)
- (Optional) pgAdmin

> Important: run commands from the **backend root** (same folder as `alembic.ini`).

---

## 1) Clone & enter project

```bat
git clone <REPO_URL>
cd Learnova-Smart-Study-Companion\Backend
```

---

## 2) Create & activate venv

**CMD**
```bat
python -m venv .venv
.venv\Scripts\activate.bat
```

**PowerShell**
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

---

## 3) Install dependencies

```bat
pip install -r requirements.txt
```

Notes:
- `psycopg` / `psycopg-binary` is included in requirements and is used as the PostgreSQL driver. fileciteturn4file2L27-L29  
<!-- - `passlib` / `bcrypt` are also in requirements (legacy). If your local hashing uses `app/core/security.py` (PBKDF2), you **do not need them**, but keeping them installed is harmless. -->

---

## 4) PostgreSQL setup (Windows ZIP / Portable)

### Extract PostgreSQL
Example:
```
C:\pgsql\
```

Required binaries:
- `C:\pgsql\bin\psql.exe`
- `C:\pgsql\bin\pg_ctl.exe`
- `C:\pgsql\bin\initdb.exe` fileciteturn4file0L53-L57

### Initialize DB directory (one time only)

Skip if `C:\pgsql\data` already exists:
```bat
C:\pgsql\bin\initdb -D C:\pgsql\data -U postgres -A password -W
```

### Start / stop PostgreSQL

Start:
```bat
C:\pgsql\bin\pg_ctl -D C:\pgsql\data -l C:\pgsql\logfile.log start
```

Stop:
```bat
C:\pgsql\bin\pg_ctl -D C:\pgsql\data stop
```

---

## 5) Create the database

Open psql:
```bat
C:\pgsql\bin\psql -U postgres
```

Create DB:
```sql
CREATE DATABASE learnova;
\q
```

---

## 6) Environment variables (SMTP + Base URL + DB)

### Recommended: `.env` (DO NOT COMMIT)

Create a `.env` file in the backend root (same level as `alembic.ini`):

```env
# Database (pick ONE style that matches your driver)
DATABASE_URL=postgresql+psycopg://postgres:<PASSWORD>@localhost:5432/learnova
# If your project uses psycopg2 instead:
# DATABASE_URL=postgresql+psycopg2://postgres:<PASSWORD>@localhost:5432/learnova

# SMTP (Gmail App Password)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_gmail_app_password
SMTP_FROM=your_email@gmail.com

# App
API_BASE_URL=http://127.0.0.1:8000
```
<!-- This format matches the earlier README template.-->

### If you prefer setting env vars in CMD (Windows)

**Important detail:** use quotes when the value contains `http://` so CMD doesn’t parse it weirdly.

```bat
set SMTP_HOST=smtp.gmail.com
set SMTP_PORT=587
set SMTP_USER=your_email@gmail.com
set SMTP_PASS=your_app_password
set "API_BASE_URL=http://127.0.0.1:8000"
```

---

## 7) Run Alembic migrations

Apply migrations:
```bat
python -m alembic -c alembic.ini upgrade head

```

Useful:
```bat
alembic current
alembic history

```

---

## 8) Seed test data (Subscription plans + Owner users + Organizations)

Connect to DB:
```bat
C:\pgsql\bin\psql -U postgres -d learnova

```

### Generate a real password hash (recommended)
Instead of using `TEMP_HASH`, generate a PBKDF2 hash using the project code:

```bat
python -c "from app.core.security import hash_password; print(hash_password('ChangeMe123'))"
```

Copy the output and paste it into the SQL below (replace `TEMP_HASH`).

### Seed SQL
```sql
-- 1) Subscription plans (2 rows)
INSERT INTO subscription_plans
(name, description, max_teachers, max_students, max_courses, max_storage_mb,
 allow_ai_chat, allow_ai_question_gen, allow_video_analysis, allow_advanced_analytics,
 monthly_credits, price_per_month, price_per_year, is_active, created_at)
VALUES
('FREE', 'Free plan', 5, 200, 10, 500,
 true, false, false, false,
 50, 0.00, NULL, true, NOW()),
('PRO', 'Pro plan', 50, 2000, 200, 20000,
 true, true, true, true,
 1000, 29.99, 299.99, true, NOW())
ON CONFLICT (name) DO NOTHING;

-- 2) Owner users (2 rows)
INSERT INTO users
(full_name, email, hashed_password, system_role, is_email_verified, created_at, updated_at)
VALUES
('Owner One', 'owner1@learnova.local', 'TEMP_HASH', 'owner', true, NOW(), NOW()),
('Owner Two', 'owner2@learnova.local', 'TEMP_HASH', 'owner', true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- 3) Organizations (2 rows) using invite codes
INSERT INTO organizations
(name, description, logo_url, owner_id, subscription_plan_id, invite_code,
 subscription_status, subscription_started_at, subscription_renews_at, trial_ends_at,
 created_at, updated_at)
VALUES
(
 'Org A', 'Test org A', NULL,
 (SELECT id FROM users WHERE email='owner1@learnova.local'),
 (SELECT id FROM subscription_plans WHERE name='FREE'),
 '7035',
 'active', NOW(), NOW() + INTERVAL '30 days', NOW() + INTERVAL '14 days',
 NOW(), NOW()
),
(
 'Org B', 'Test org B', NULL,
 (SELECT id FROM users WHERE email='owner2@learnova.local'),
 (SELECT id FROM subscription_plans WHERE name='PRO'),
 '6532',
 'active', NOW(), NOW() + INTERVAL '30 days', NOW() + INTERVAL '14 days',
 NOW(), NOW()
)
ON CONFLICT (invite_code) DO NOTHING;
```

---

## 9) Run the API server

Option A (uvicorn):
```bat
uvicorn app.main:app --reload
```

Option B (fastapi dev):
```bat
fastapi dev app/main.py
```

Server:
```
http://127.0.0.1:8000
```

---

## 10) Helpful DB cleanup for testing

Delete a user by email:
```sql
DELETE FROM users WHERE email = 'your@email.com';
```

> If you have related rows (tokens, memberships, etc.), make sure the FK rules are `ON DELETE CASCADE` where needed.

---

## Troubleshooting

- **SMTP env vars missing** → confirm you set `SMTP_HOST/SMTP_USER/SMTP_PASS` and restarted your terminal or loaded `.env`.
- **CMD: `'http:' is not recognized`** → use:
  ```bat
  set "API_BASE_URL=http://127.0.0.1:8000"
  ```
  (quotes matter on Windows CMD) fileciteturn4file1L117-L118
- **Alembic errors** → run:
  ```bat
  alembic current
  alembic upgrade head
  ```

---

## Security notes

- Never commit `.env` or SMTP credentials. fileciteturn4file0L262-L265
- Gmail needs **App Password** (not your normal password). 