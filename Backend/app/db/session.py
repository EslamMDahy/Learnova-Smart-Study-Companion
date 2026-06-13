from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .url import build_db_url

DATABASE_URL = build_db_url(driver="postgresql+psycopg")

engine = create_engine(DATABASE_URL)

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
