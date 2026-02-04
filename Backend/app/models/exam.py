from sqlalchemy import Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class Exam(Base):
    __tablename__ = "exams"

    id: Mapped[int] = mapped_column(primary_key=True)
    course_id: Mapped[int] = mapped_column(ForeignKey("courses.id"), nullable=False)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    created_by: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
