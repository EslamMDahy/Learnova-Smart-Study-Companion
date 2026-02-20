from sqlalchemy import (
    DateTime,
    Integer,
    ForeignKey,
    JSON,
    Enum as SQLEnum,
    Index
)
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base
from app.models.enums import PracticeSessionType, PracticeSessionStatus


class PracticeSession(Base):
    __tablename__ = "practice_sessions"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    student_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    course_id: Mapped[int] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"),
        nullable=False
    )

    question_bank_id: Mapped[int] = mapped_column(
        ForeignKey("question_banks.id", ondelete="CASCADE"),
        nullable=False
    )

    session_type: Mapped[PracticeSessionType] = mapped_column(
        SQLEnum(PracticeSessionType, name="practice_session_type_enum"),
        default=PracticeSessionType.practice
    )

    status: Mapped[PracticeSessionStatus] = mapped_column(
        SQLEnum(PracticeSessionStatus, name="practice_session_status_enum"),
        default=PracticeSessionStatus.in_progress,
        index=True
    )

    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow
    )

    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    total_questions: Mapped[int] = mapped_column(
        Integer,
        default=0
    )

    questions_answered: Mapped[int] = mapped_column(
        Integer,
        default=0
    )

    correct_answers: Mapped[int] = mapped_column(
        Integer,
        default=0
    )

    time_spent_seconds: Mapped[int] = mapped_column(
        Integer,
        default=0
    )

    session_data: Mapped[dict | None] = mapped_column(
        JSON,
        nullable=True
    )

    performance_metrics: Mapped[dict | None] = mapped_column(
        JSON,
        nullable=True
    )

    __table_args__ = (
        Index("ix_practice_sessions_student_course_started", "student_id", "course_id", "started_at"),
        Index("ix_practice_sessions_bank_started", "question_bank_id", "started_at"),
    )
