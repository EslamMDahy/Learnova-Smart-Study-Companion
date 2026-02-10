from sqlalchemy import (
    DateTime,
    Integer,
    Float,
    Text,
    ForeignKey,
    JSON,
    Enum as SQLEnum,
    Index,
    Boolean
)
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base
from app.models.enums import (
    QuestionType,
    QuestionDifficulty,
    QuestionSource,
    QuestionApprovalStatus
)


class Question(Base):
    __tablename__ = "questions"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    bank_id: Mapped[int] = mapped_column(
        ForeignKey("question_banks.id", ondelete="CASCADE"),
        nullable=False
    )

    topic_id: Mapped[int] = mapped_column(
        ForeignKey("topics.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    material_id: Mapped[int | None] = mapped_column(
        ForeignKey("materials.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    video_timestamp_id: Mapped[int | None] = mapped_column(
        ForeignKey("video_timestamps.id", ondelete="SET NULL"),
        nullable=True
    )

    question_text: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )

    explanation: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    type: Mapped[QuestionType] = mapped_column(
        SQLEnum(QuestionType, name="question_type_enum"),
        nullable=False
    )

    difficulty: Mapped[QuestionDifficulty] = mapped_column(
        SQLEnum(QuestionDifficulty, name="question_difficulty_enum"),
        nullable=False,
        index=True
    )

    source: Mapped[QuestionSource] = mapped_column(
        SQLEnum(QuestionSource, name="question_source_enum"),
        nullable=False
    )

    approval_status: Mapped[QuestionApprovalStatus] = mapped_column(
        SQLEnum(
            QuestionApprovalStatus,
            name="question_approval_status_enum"
        ),
        default=QuestionApprovalStatus.approved,
        index=True
    )

    reviewed_by: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    review_notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    expected_answer: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    grading_rubric: Mapped[dict | None] = mapped_column(
        JSON,
        nullable=True
    )

    max_score: Mapped[int] = mapped_column(
        Integer,
        default=1
    )

    auto_gradable: Mapped[bool] = mapped_column(
        Boolean,
        default=True
    )

    usage_count: Mapped[int] = mapped_column(
        Integer,
        default=0,
        index=True
    )

    success_rate: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )

    average_time_seconds: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )

    tags: Mapped[list | None] = mapped_column(
        JSON,
        nullable=True
    )

    created_by: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )

    __table_args__ = (
        # (bank_id, topic_id)
        Index("ix_questions_bank_topic", "bank_id", "topic_id"),
    )
