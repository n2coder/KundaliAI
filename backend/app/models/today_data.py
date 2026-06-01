from __future__ import annotations
import uuid
from datetime import datetime, date
from sqlalchemy import Text, Date, DateTime, ForeignKey, func, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from .base import Base


class TodayData(Base):
    """
    Pre-computed "Today" panel data per user per day:
    panchang, muhurtas, lucky colour/number/direction, lucky gem, mantra.
    Computed by Celery nightly batch using pyswisseph.
    """
    __tablename__ = "today_data"
    __table_args__ = (
        UniqueConstraint("user_id", "for_date", name="uq_today_data_user_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    for_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # Panchang fields
    panchang: Mapped[dict] = mapped_column(JSONB, nullable=False)
    # {tithi, nakshatra, yoga, karana, vara, sunrise, sunset}

    # Muhurta windows (list of {name, start, end, quality})
    muhurtas: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)

    # Lucky elements
    lucky_color: Mapped[str | None] = mapped_column(Text)
    lucky_number: Mapped[int | None]
    lucky_direction: Mapped[str | None] = mapped_column(Text)
    lucky_gem: Mapped[str | None] = mapped_column(Text)

    # Mantra (language-keyed)
    mantra_en: Mapped[str | None] = mapped_column(Text)
    mantra_hi: Mapped[str | None] = mapped_column(Text)

    computed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="today_data")


from .user import User  # noqa: E402
