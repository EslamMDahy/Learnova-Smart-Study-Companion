from sqlalchemy import Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class Analytics(Base):
    __tablename__ = "analytics"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    course_id: Mapped[int] = mapped_column(ForeignKey("courses.id"), nullable=False)

    progress_percentage: Mapped[float | None] = mapped_column(Float)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
