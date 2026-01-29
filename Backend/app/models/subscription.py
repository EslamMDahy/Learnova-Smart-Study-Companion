from sqlalchemy import String, Integer, Float
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class Subscription(Base):
    __tablename__ = "subscriptions"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)  # FREE | PRO | UNIVERSITY
    max_teachers: Mapped[int] = mapped_column(Integer, nullable=False)
    max_students: Mapped[int] = mapped_column(Integer, nullable=False)
    monthly_credits: Mapped[int] = mapped_column(Integer, nullable=False)
    price: Mapped[float] = mapped_column(Float, nullable=False)
