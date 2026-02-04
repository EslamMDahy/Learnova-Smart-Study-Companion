from sqlalchemy import Integer, String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class VideoTimestamp(Base):
    __tablename__ = "video_timestamps"

    id: Mapped[int] = mapped_column(primary_key=True)
    material_id: Mapped[int] = mapped_column(ForeignKey("materials.id"), nullable=False)
    topic_id: Mapped[int] = mapped_column(ForeignKey("topics.id"), nullable=False)

    start_time: Mapped[str] = mapped_column(String(50), nullable=False)
    end_time: Mapped[str] = mapped_column(String(50), nullable=False)
