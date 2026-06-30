from sqlalchemy import (
    DateTime,
    Integer,
    Float,
    Text,
    ForeignKey,
    Enum as SQLEnum,
    Index,
    Boolean,
    CheckConstraint
)
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime

from app.db.base import Base
from app.models.enums import (
    QuestionType,
    QuestionDifficulty,
    QuestionSource,
    QuestionApprovalStatus
)

class QuestionPool(Base):
    __tablename__ = "questions_pool"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"),
        nullable=False,
    )

    topic_id: Mapped[int] = mapped_column(
        ForeignKey("topics.id", ondelete="CASCADE"),
        nullable=False,
    )

    question_text: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )

    explanation: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )


    options: Mapped[list | None] = mapped_column(
        JSONB,
        nullable=True
    )

    type: Mapped[QuestionType] = mapped_column(
        SQLEnum(QuestionType, name="question_type_enum"),
        nullable=False
    )

    difficulty: Mapped[QuestionDifficulty] = mapped_column(
        SQLEnum(QuestionDifficulty, name="question_difficulty_enum"),
        nullable=False,
        default=QuestionDifficulty.medium
    )

    source: Mapped[QuestionSource] = mapped_column(
        SQLEnum(QuestionSource, name="question_source_enum"),
        nullable=False,
        default=QuestionSource.manual
    )

    expected_answer: Mapped[dict | list | str | None] = mapped_column(
        JSONB,
        nullable=True
    )

    grading_rubric: Mapped[dict | None] = mapped_column(
        JSONB,
        nullable=True
    )

    max_score: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=1
    )

    auto_gradable: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True
    )

    is_used: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=datetime.utcnow
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )

    __table_args__ = (
        Index("ix_pool_topic_type_difficulty", "topic_id", "type", "difficulty"),

        CheckConstraint("max_score > 0", name="ck_questions_pool_max_score_positive"),
    )