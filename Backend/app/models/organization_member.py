from sqlalchemy import String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class OrganizationMember(Base):
    __tablename__ = "organization_members"

    id: Mapped[int] = mapped_column(primary_key=True)
    organization_id: Mapped[int] = mapped_column(ForeignKey("organizations.id"), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    role: Mapped[str] = mapped_column(String(50), nullable=False)    # OWNER | TEACHER | STUDENT
    status: Mapped[str] = mapped_column(String(50), nullable=False)  # pending | approved | rejected

    joined_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
