from sqlalchemy import (
    DateTime,
    Integer,
    Text,
    Boolean,
    ForeignKey,
    Index
)
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base


class QuestionOption(Base):
    __tablename__ = "question_options"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    question_id: Mapped[int] = mapped_column(
        ForeignKey("questions.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    option_text: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )

    is_correct: Mapped[bool] = mapped_column(
        Boolean,
        default=False
    )

    order_index: Mapped[int] = mapped_column(
        Integer,
        default=0
    )

    explanation: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    __table_args__ = (
        # unique (question_id, order_index)
        Index(
            "uq_question_options_question_order",
            "question_id",
            "order_index",
            unique=True
        ),
    )
