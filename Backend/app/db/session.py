from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .url import build_db_url

DATABASE_URL = build_db_url(driver="postgresql+psycopg")

engine = create_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=30,
    pool_timeout=30,
    pool_recycle=1800,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
