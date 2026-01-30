
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