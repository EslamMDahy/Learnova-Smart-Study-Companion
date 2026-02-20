from sqlalchemy import (
    String,
    DateTime,
    Boolean,
    Integer,
    Text,
    ForeignKey,
    JSON,
    Enum as SQLEnum,
    Index
)
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base
from app.models.enums import MaterialType, MaterialStatus


class Material(Base):
    __tablename__ = "materials"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    topic_id: Mapped[int] = mapped_column(
        ForeignKey("topics.id", ondelete="CASCADE"),
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

    type: Mapped[MaterialType] = mapped_column(
        SQLEnum(MaterialType, name="material_type_enum"),
        nullable=False,
        index=True
    )

    file_name: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    file_size: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    file_url: Mapped[str] = mapped_column(
        String(1024),
        nullable=False
    )

    thumbnail_url: Mapped[str | None] = mapped_column(
        String(1024),
        nullable=True
    )

    mime_type: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    status: Mapped[MaterialStatus] = mapped_column(
        SQLEnum(MaterialStatus, name="material_status_enum"),
        nullable=False,
        default=MaterialStatus.uploaded,
        index=True
    )

    text_extracted: Mapped[bool] = mapped_column(
        Boolean,
        default=False
    )

    transcript_text: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    extracted_text: Mapped[str | None] = mapped_column(
        Text,
        nullable=True
    )

    duration_seconds: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    page_count: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    dimensions: Mapped[dict | None] = mapped_column(
        JSON,
        nullable=True
    )

    is_ai_processed: Mapped[bool] = mapped_column(
        Boolean,
        default=False
    )

    ai_processed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    uploaded_by: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False
    )

    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow
    )

    processed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    __table_args__ = (
        Index("ix_materials_topic_type", "topic_id", "type"),
    )
