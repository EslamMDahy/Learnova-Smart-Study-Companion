from sqlalchemy import Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class Material(Base):
    __tablename__ = "materials"

    id: Mapped[int] = mapped_column(primary_key=True)
    course_id: Mapped[int] = mapped_column(ForeignKey("courses.id"), nullable=False)

    type: Mapped[str] = mapped_column(String(50), nullable=False)  # pdf | doc | slide | video
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)

    uploaded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
