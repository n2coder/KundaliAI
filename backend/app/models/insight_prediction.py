from __future__ import annotations
import uuid
from datetime import datetime, date
from sqlalchemy import String, Text, Date, DateTime, ForeignKey, func, UniqueConstraint, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
from .base import Base


class InsightCategory(str, enum.Enum):
    career = "career"
    love = "love"
    money = "money"
    health = "health"


class InsightPrediction(Base):
    """
    Monthly batch AI-generated insight text per user per category per month.
    Celery Beat generates on 1st of each month for active users.
    """
    __tablename__ = "insight_predictions"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "category", "period_start",
            name="uq_insight_user_category_period"
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    category: Mapped[InsightCategory] = mapped_column(
        SAEnum(InsightCategory, name="insight_category_enum"), nullable=False
    )
    period_start: Mapped[date] = mapped_column(Date, nullable=False)  # always 1st of month
    period_end: Mapped[date] = mapped_column(Date, nullable=False)    # last day of month

    content_en: Mapped[str | None] = mapped_column(Text)
    content_hi: Mapped[str | None] = mapped_column(Text)
    score: Mapped[float | None]    # 0.0–1.0 headline score for this period
    best_period_label: Mapped[str | None] = mapped_column(String(40))  # e.g. "May – Jul"

    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="insight_predictions")


from .user import User  # noqa: E402
