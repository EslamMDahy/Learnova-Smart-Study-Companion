from sqlalchemy import String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)

    owner_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    invite_code: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)

    subscription_id: Mapped[int] = mapped_column(ForeignKey("subscriptions.id"), nullable=False)
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
