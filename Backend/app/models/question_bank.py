from sqlalchemy import (
    String,
    DateTime,
    Boolean,
    Integer,
    Text,
    ForeignKey,
    Enum as SQLEnum,
    Index
)
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base
from app.models.enums import (
    QuestionBankPurpose,
    QuestionBankAccessLevel
)


class QuestionBank(Base):
    __tablename__ = "question_banks"

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

    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    purpose: Mapped[QuestionBankPurpose] = mapped_column(
        SQLEnum(
            QuestionBankPurpose,
            name="question_bank_purpose_enum"
        ),
        default=QuestionBankPurpose.practice,
        index=True
    )

    is_shared: Mapped[bool] = mapped_column(
        Boolean,
        default=False
    )

    show_answers: Mapped[bool] = mapped_column(
        Boolean,
        default=True
    )

    show_explanations: Mapped[bool] = mapped_column(
        Boolean,
        default=True
    )

    allow_retry: Mapped[bool] = mapped_column(
        Boolean,
        default=True
    )

    shuffle_questions: Mapped[bool] = mapped_column(
        Boolean,
        default=False
    )

    access_level: Mapped[QuestionBankAccessLevel] = mapped_column(
        SQLEnum(
            QuestionBankAccessLevel,
            name="question_bank_access_level_enum"
        ),
        default=QuestionBankAccessLevel.private,
        index=True
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
