from sqlalchemy import Integer, Text, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class AIChatHistory(Base):
    __tablename__ = "ai_chat_history"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    organization_id: Mapped[int] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    course_id: Mapped[int] = mapped_column(ForeignKey("courses.id"), nullable=False)

    question: Mapped[str] = mapped_column(Text, nullable=False)
    answer: Mapped[str] = mapped_column(Text, nullable=False)

    used_credits: Mapped[int] = mapped_column(Integer, nullable=False)
    asked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
