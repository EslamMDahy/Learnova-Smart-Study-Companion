from sqlalchemy import Integer, Text, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class StudentAnswer(Base):
    __tablename__ = "student_answers"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_exam_id: Mapped[int] = mapped_column(ForeignKey("student_exams.id"), nullable=False)
    question_id: Mapped[int] = mapped_column(ForeignKey("questions.id"), nullable=False)

    selected_option: Mapped[int | None] = mapped_column(ForeignKey("question_options.id"), nullable=True)
    answer_text: Mapped[str | None] = mapped_column(Text)

    is_correct: Mapped[bool | None] = mapped_column(Boolean)
