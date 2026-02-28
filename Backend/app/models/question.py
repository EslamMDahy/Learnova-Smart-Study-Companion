from sqlalchemy import (
    DateTime,
    Integer,
    Float,
    Text,
    ForeignKey,
    JSON,
    Enum as SQLEnum,
    Index,
    Boolean,
    CheckConstraint
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

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    topic_id: Mapped[int | None] = mapped_column(
        ForeignKey("topics.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    module_id: Mapped[int | None] = mapped_column(
        ForeignKey("modules.id", ondelete="CASCADE"),
        nullable=True,
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

    # For choice-based questions (mcq, multi_select, true_false, etc.)
    # Example: [{"option_text": "...", "is_correct": true, "order_index": 0, "explanation": "..."}]
    options: Mapped[list | None] = mapped_column(
        JSON,
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
        # (course_id, topic_id)
                # Fast filtering inside a course question bank
        Index("ix_questions_course_topic", "course_id", "topic_id"),
        Index("ix_questions_course_module", "course_id", "module_id"),
        Index("ix_questions_course_material", "course_id", "material_id"),
        # Ensure question is attached to at least a topic or a module
        CheckConstraint(
            "(topic_id IS NOT NULL) OR (module_id IS NOT NULL) OR (material_id IS NOT NULL)",
            name="ck_questions_scope_required"
        ),
    )
