from sqlalchemy import Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class CreditTransaction(Base):
    __tablename__ = "credit_transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    organization_id: Mapped[int] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    amount: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(String(50), nullable=False)  # exam | ai | purchase
    created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
