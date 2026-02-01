from sqlalchemy import Integer, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime

from app.db.base import Base


class CreditWallet(Base):
    __tablename__ = "credit_wallet"

    id: Mapped[int] = mapped_column(primary_key=True)

    organization_member_id: Mapped[int] = mapped_column(
        ForeignKey("organization_members.id", ondelete="CASCADE"),
        nullable=False,
        unique=True
    )

    balance_credits: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    monthly_allowance: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_earned: Mapped[int] = mapped_column(Integer, default=0)
    total_spent: Mapped[int] = mapped_column(Integer, default=0)

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )

    __table_args__ = (
        UniqueConstraint("organization_member_id", name="uq_member_credit_wallet_member"),
    )