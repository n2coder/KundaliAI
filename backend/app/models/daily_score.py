from __future__ import annotations
import uuid
from datetime import datetime, date
from sqlalchemy import Float, Date, DateTime, ForeignKey, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from .base import Base


class DailyScore(Base):
    """
    Formula-based life-area scores (0.0–1.0) per user per day.
    Computed from transiting planet positions relative to natal chart.
    Stored to avoid recomputation on every app load.
    """
    __tablename__ = "daily_scores"
    __table_args__ = (
        UniqueConstraint("user_id", "score_date", name="uq_daily_score_user_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    score_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # Scores 0.0–1.0
    career: Mapped[float] = mapped_column(Float, nullable=False)
    love: Mapped[float] = mapped_column(Float, nullable=False)
    money: Mapped[float] = mapped_column(Float, nullable=False)
    health: Mapped[float] = mapped_column(Float, nullable=False)
    overall: Mapped[float] = mapped_column(Float, nullable=False)

    computed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="daily_scores")


from .user import User  # noqa: E402
