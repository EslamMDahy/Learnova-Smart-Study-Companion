
# Learnova Backend – Commands

## 1) Activate Virtual Environment (Windows CMD)
```bat
cd /d "X:\NCTU  (ICT)\Graduation Project II\learnova"
.venv\Scripts\activate.bat
```
## 2) Run FastAPI Dev Server
```bat
fastapi dev app/main.py
```
## 3) PostgreSQL (ZIP install) – Start/Stop Server
### Start
```bat
C:\pgsql\bin\pg_ctl -D C:\pgsql\data -l C:\pgsql\logfile.log start
```
### End
```bat
C:\pgsql\bin\pg_ctl -D C:\pgsql\data stop
```
## 4) Check Databases / Connect / List Tables
### List databases
```bat
C:\pgsql\bin\psql -U postgres -l
```
### Connect to project DB
```bat
C:\pgsql\bin\psql -U postgres -d learnova
```
### Inside psql: list tables
```bat
\dt
```
### Insert intilization values to test
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
## 5) Alembic (Migrations)
>must be in the root of the project (besaide `alembic.ini`)

## Create a new migration (auto-generate)
```bat
alembic revision --autogenerate -m "your message here"
```
## Apply migrations to DB
```bat
alembic upgrade head
```
## Check current migration version
```bat
alembic current
```
## View migration history
```bat
alembic history
```
## Downgrade one step (if needed)
```bat
alembic downgrade -1
```
<!-- ```
FirstAPI/
├─ app/
│  ├─ main.py
│  ├─ core/
│  │  └─ config.py
│  ├─ db/
│  │  ├─ session.py
│  │  └─ base.py
│  ├─ models/
│  │  └─ user.py
│  ├─ schemas/
│  │  └─ auth.py
│  ├─ routers/
│  │  └─ auth.py
│  └─ services/
│     └─ auth_service.py
│
├─ alembic/
├─ alembic.ini
├─ .venv/
└─ requirements.txt
```

```
app/
├─ main.py
├─ core/
│  └─ config.py
├─ db/
│  ├─ session.py
│  └─ base.py
├─ models/
│  ├─ __init__.py
│  └─ user.py
└─ features/
   └─ auth/
      ├─ router.py
      ├─ schemas.py
      └─ service.py
``` -->