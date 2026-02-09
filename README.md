# Learnova-Smart-Study-Companion
Graduation Project

## How to setup Learnova in your machine
### What you need

- **Python 3.10+** (recommended **3.11**)
- **Flutter**
- **PostgreSQL** (portable ZIP or normal installer)
- **Git**

---

### 1) Clone & enter project
```bat
git clone "https://github.com/EslamMDahy/Learnova-Smart-Study-Companion"
cd Learnova-Smart-Study-Companion
```

---

### 2) Create & activate venv
- Create the `venv`
```bat
cd Learnova-Smart-Study-Companion\Backend
python -m venv .venv
```
- Activate the `venv`
```bat
.venv\Scripts\activate.bat
```
>Notes: every time you open the terminal you will activate the `venv`.

---

### 3) Install dependencies

```bat
pip install -r requirements.txt
```
>Notes: `psycopg` / `psycopg-binary` is included in requirements and is used as the PostgreSQL driver. 

---

### 4) Make sure you have Setup Flutter

- Download Flutter SDK (zip)
- Extract Flutter SDK in the path you chose
- Adding the Flutter SDK to the system environment variables
- Make sure Flutter is instaled
```bat
flutter doctor
```
- Get Flutter dependencies
```bat
cd Flutter
flutter pub get
```

---

### 5) PostgreSQL setup 

#### Using the ZIP version
- Extract PostgreSQL in the `C:\`
- Initialize DB directory (one time only)

>Skip if `C:\pgsql\data` already exists:

```bat
C:\pgsql\bin\initdb -D C:\pgsql\data -U postgres -A password -W
```
- Create the database

Start:
```bat
C:\pgsql\bin\pg_ctl -D C:\pgsql\data -l C:\pgsql\logfile.log start
```

Open psql:
```bat
C:\pgsql\bin\psql -U postgres
```

Create DB:
```sql
CREATE DATABASE learnova;
\q
```
- Connect the DB to FastAPI

change the `sqlalchemy.url` in the `alembic.ini`

```py
sqlalchemy.url = postgresql+psycopg://<password>@localhost:5432/learnova
```
> add your DB password

---

### 6) Alembic migrations

> Important: run commands from the **backend root** (same folder as `alembic.ini`).

<!-- - Create a new migration (auto-generate)
```bat
alembic revision --autogenerate -m "initialize the DB"
``` -->
- Apply migrations to DB
```bat
alembic upgrade head
```
> Note: migrations are already included in the repo. Do NOT run `alembic revision --autogenerate` during setup.
---

## How to run Learnova

### Ports
- Backend API: http://127.0.0.1:8000
- Flutter Web:  http://127.0.0.1:5173


### 1) Set the environment variables in the (.venv) CMD

Set this variables in every new terminal befor runing Learnova

```bat
set SMTP_HOST=smtp.gmail.com
set SMTP_PORT=587
set SMTP_USER=your_email@gmail.com
set SMTP_PASS=your_app_password
set "API_BASE_URL=http://127.0.0.1:8000" 
set JWT_SECRET=CHANGE_ME_TO_A_LONG_RANDOM_SECRET
set JWT_ALG=HS256
set JWT_EXPIRE_MIN=60
```
> add your email and app password

---

### 2) Start the PostgreSQL DB server
```bat
C:\pgsql\bin\pg_ctl -D C:\pgsql\data -l C:\pgsql\logfile.log start
```

---

### 3) Run the FastAPI server
```bat
fastapi dev app\main.py
```

---

### 4) Run the Flutter Web app

```bat
flutter run -d chrome --web-port=5173
```
> you can change `chrome` by the browser you use
---

## 👥 Team Members

- **[Eslam Dahy:](https://github.com/EslamMDahy)** **Technical Lead & Project Manager**
- **[Ahmed Waheed: ](https://github.com/Waheed7000)** **Backend Engineer (FastAPI) – Service Owner** 
- **[Farouk Mohsen:](https://github.com/faroukmohsen)** **QA & Testing**
- **[Khaled Ibrahim:](https://github.com/ikhalled)** **Flutter Engineer & UI/UX Designer**

---
