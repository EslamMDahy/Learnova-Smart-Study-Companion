from sqlalchemy import (
    DateTime,
    Integer,
    Float,
    Boolean,
    Text,
    ForeignKey,
    Index
)
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base


class StudentAnswer(Base):
    __tablename__ = "student_answers"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    attempt_id: Mapped[int] = mapped_column(
        ForeignKey("student_exam_attempts.id", ondelete="CASCADE"),
        nullable=False
    )

    exam_question_id: Mapped[int] = mapped_column(
        ForeignKey("exam_questions.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    selected_option_id: Mapped[int | None] = mapped_column(
        ForeignKey("question_options.id", ondelete="SET NULL"),
        nullable=True
    )

    answer_text: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    is_correct: Mapped[bool | None] = mapped_column(
        Boolean,
        nullable=True
    )

    points_earned: Mapped[float | None] = mapped_column(
        Float,
        nullable=True
    )

    auto_graded: Mapped[bool] = mapped_column(
        Boolean,
        default=False
    )

    teacher_feedback: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    teacher_reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    time_taken_seconds: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
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
        # unique (attempt_id, exam_question_id)
        Index(
            "uq_student_answers_attempt_exam_question",
            "attempt_id",
            "exam_question_id",
            unique=True
        ),
    )
