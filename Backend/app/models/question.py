from sqlalchemy import Integer, String, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Question(Base):
    __tablename__ = "questions"

    id: Mapped[int] = mapped_column(primary_key=True)
    bank_id: Mapped[int] = mapped_column(ForeignKey("question_banks.id"), nullable=False)
    topic_id: Mapped[int] = mapped_column(ForeignKey("topics.id"), nullable=False)

    question_text: Mapped[str] = mapped_column(Text, nullable=False)

    type: Mapped[str] = mapped_column(String(50), nullable=False)       # MCQ | TF | SHORT
    difficulty: Mapped[str] = mapped_column(String(50), nullable=False) # easy | medium | hard
    source: Mapped[str] = mapped_column(String(50), nullable=False)     # manual | ai
