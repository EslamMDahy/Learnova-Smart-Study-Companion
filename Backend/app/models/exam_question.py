from sqlalchemy import Integer, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class ExamQuestion(Base):
    __tablename__ = "exam_questions"

    id: Mapped[int] = mapped_column(primary_key=True)
    exam_id: Mapped[int] = mapped_column(ForeignKey("exams.id"), nullable=False)
    question_id: Mapped[int] = mapped_column(ForeignKey("questions.id"), nullable=False)
