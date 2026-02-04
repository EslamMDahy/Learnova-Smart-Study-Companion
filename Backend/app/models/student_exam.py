from sqlalchemy import Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class StudentExam(Base):
    __tablename__ = "student_exams"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    exam_id: Mapped[int] = mapped_column(ForeignKey("exams.id"), nullable=False)

    score: Mapped[float | None] = mapped_column(Float)
    taken_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
