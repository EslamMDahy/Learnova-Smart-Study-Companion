from dotenv import load_dotenv
load_dotenv() 

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.core.event_bus.connections import init_event_bus, close_event_bus

from app.core.config import settings
from app.domains.auth.router                    import router as auth_router
from app.domains.courses.router                 import router as courses_router
from app.domains.learningOutcomes.router        import router as learningOutcomes_router
from app.domains.modules.router                 import router as modules_router
from app.domains.materials.router               import router as materials_router
from app.domains.topics.router                  import router as topics_router
from app.domains.questions.router               import router as questions_router
from app.domains.exams.router                   import router as exams_router
from app.domains.ai_chat.router                 import router as ai_chat_router
from app.domains.organizations.router           import router as organizations_router
from app.domains.settings.router                import router as settings_router
from app.domains.ai.router                      import router as ai_router
from app.domains.ocr.router                     import router as ocr_router
from fastapi.middleware.cors import CORSMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_event_bus()
    yield
    await close_event_bus()

app = FastAPI(lifespan=lifespan)

allow_origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "https://www.learnova-edu.com",
    "http://www.learnova-edu.com",
    "https://www.learnova-edu.com/api",
    "https://learnova-edu.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_origin_regex=r"https://.*\.ngrok-free\.dev",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(courses_router)
app.include_router(learningOutcomes_router)
app.include_router(modules_router)
app.include_router(materials_router)
app.include_router(topics_router)
app.include_router(questions_router)
app.include_router(exams_router)
app.include_router(ai_chat_router)
app.include_router(organizations_router)
app.include_router(settings_router)
app.include_router(ai_router)
app.include_router(ocr_router)