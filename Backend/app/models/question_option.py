from sqlalchemy import Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class QuestionOption(Base):
    __tablename__ = "question_options"

    id: Mapped[int] = mapped_column(primary_key=True)
    question_id: Mapped[int] = mapped_column(ForeignKey("questions.id"), nullable=False)

    option_text: Mapped[str] = mapped_column(String(500), nullable=False)
    is_correct: Mapped[bool] = mapped_column(Boolean, nullable=False)
