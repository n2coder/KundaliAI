from __future__ import annotations
import uuid
from datetime import datetime, date
from sqlalchemy import String, Text, Date, DateTime, ForeignKey, Boolean, func, Enum as SAEnum, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
from .base import Base


class HoroscopePeriod(str, enum.Enum):
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"


class Horoscope(Base):
    """
    Pre-generated horoscope text per user per period.
    Nightly Celery Beat batch pre-fills next day's horoscopes for active users.
    """
    __tablename__ = "horoscopes"
    __table_args__ = (
        UniqueConstraint("user_id", "period", "for_date", name="uq_horoscope_user_period_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    period: Mapped[HoroscopePeriod] = mapped_column(
        SAEnum(HoroscopePeriod, name="horoscope_period_enum"), nullable=False
    )
    for_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    language: Mapped[str] = mapped_column(String(5), default="en")  # "en" | "hi"

    content_en: Mapped[str | None] = mapped_column(Text)
    content_hi: Mapped[str | None] = mapped_column(Text)

    # WhatsApp delivery state
    whatsapp_sent: Mapped[bool] = mapped_column(Boolean, default=False)
    whatsapp_sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="horoscopes")


from .user import User  # noqa: E402
