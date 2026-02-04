from sqlalchemy import String, DateTime, Boolean, Integer, Numeric
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base


class SubscriptionPlan(Base):
    __tablename__ = "subscription_plans"

    id: Mapped[int] = mapped_column(primary_key=True)

    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(nullable=True)

    max_teachers: Mapped[int] = mapped_column(Integer, default=1)
    max_students: Mapped[int] = mapped_column(Integer, default=10)
    max_courses: Mapped[int] = mapped_column(Integer, default=3)
    max_storage_mb: Mapped[int] = mapped_column(Integer, default=100)

    allow_ai_chat: Mapped[bool] = mapped_column(Boolean, default=True)
    allow_ai_question_gen: Mapped[bool] = mapped_column(Boolean, default=False)
    allow_video_analysis: Mapped[bool] = mapped_column(Boolean, default=False)
    allow_advanced_analytics: Mapped[bool] = mapped_column(Boolean, default=False)

    monthly_credits: Mapped[int] = mapped_column(Integer, default=100)

    price_per_month: Mapped[float] = mapped_column(
        Numeric(10, 2),
        default=0.00
    )
    price_per_year: Mapped[float | None] = mapped_column(
        Numeric(10, 2),
        nullable=True
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow
    )
