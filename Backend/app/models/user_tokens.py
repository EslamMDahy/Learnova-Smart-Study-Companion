from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base


class UserToken(Base):
    __tablename__ = "user_tokens"

    id: Mapped[int] = mapped_column(primary_key=True)

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    type: Mapped[str] = mapped_column(String(50), nullable=False)
    token: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)

    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    used_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow
    )
