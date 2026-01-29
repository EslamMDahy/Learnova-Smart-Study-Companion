from sqlalchemy import Integer, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class WeakPoint(Base):
    __tablename__ = "weak_points"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    topic_id: Mapped[int] = mapped_column(ForeignKey("topics.id"), nullable=False)

    weakness_level: Mapped[int] = mapped_column(Integer, nullable=False)
