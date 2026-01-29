from sqlalchemy import Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class CreditWallet(Base):
    __tablename__ = "credit_wallets"

    id: Mapped[int] = mapped_column(primary_key=True)
    organization_id: Mapped[int] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    total_credits: Mapped[int] = mapped_column(Integer, nullable=False)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
