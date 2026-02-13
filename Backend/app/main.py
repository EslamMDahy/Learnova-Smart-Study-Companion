from fastapi import FastAPI

from app.features.auth.router import router as auth_router
from app.features.organizations.router import router as organizations_router
from app.features.settings.router import router as settings_router
from app.features.courses.router import router as courses_router

from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()
origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth_router)
app.include_router(courses_router)
app.include_router(organizations_router)
app.include_router(settings_router)