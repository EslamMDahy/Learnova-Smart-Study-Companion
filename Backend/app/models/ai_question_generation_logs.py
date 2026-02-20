from sqlalchemy import (
    String,
    DateTime,
    Integer,
    Text,
    ForeignKey,
    Enum as SQLEnum,
    Index
)
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base
from app.models.enums import AIQuestionGenerationStatus


class AIQuestionGenerationLog(Base):
    __tablename__ = "ai_question_generation_logs"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    material_id: Mapped[int] = mapped_column(
        ForeignKey("materials.id", ondelete="CASCADE"),
        nullable=False
    )

    topic_id: Mapped[int] = mapped_column(
        ForeignKey("topics.id", ondelete="CASCADE"),
        nullable=False
    )

    model_used: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    credits_used: Mapped[int] = mapped_column(
        Integer,
        default=0
    )

    status: Mapped[AIQuestionGenerationStatus] = mapped_column(
        SQLEnum(
            AIQuestionGenerationStatus,
            name="ai_question_generation_status_enum"
        ),
        default=AIQuestionGenerationStatus.completed,
        index=True
    )

    error_message: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow
    )

    __table_args__ = (
        # (material_id, topic_id, created_at)
        Index(
            "ix_ai_qgen_material_topic_created",
            "material_id",
            "topic_id",
            "created_at"
        ),
    )
