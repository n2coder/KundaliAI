from __future__ import annotations
import uuid
from datetime import datetime, date, time
from sqlalchemy import String, Boolean, Date, Time, Float, DateTime, func, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
from .base import Base


class SubscriptionStatus(str, enum.Enum):
    trial = "trial"
    active = "active"
    expired = "expired"
    cancelled = "cancelled"


class Language(str, enum.Enum):
    en = "en"
    hi = "hi"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    phone: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    firebase_uid: Mapped[str | None] = mapped_column(String(128), unique=True, index=True)
    name: Mapped[str | None] = mapped_column(String(120))
    language: Mapped[Language] = mapped_column(
        SAEnum(Language, name="language_enum"), default=Language.en
    )

    # Birth details
    dob: Mapped[date | None] = mapped_column(Date)
    tob: Mapped[time | None] = mapped_column(Time)
    birth_place: Mapped[str | None] = mapped_column(String(200))
    birth_lat: Mapped[float | None] = mapped_column(Float)
    birth_lng: Mapped[float | None] = mapped_column(Float)

    # WhatsApp delivery
    whatsapp_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    whatsapp_delivery_time: Mapped[str | None] = mapped_column(String(8))  # "07:00"

    # Subscription
    subscription_status: Mapped[SubscriptionStatus] = mapped_column(
        SAEnum(SubscriptionStatus, name="subscription_status_enum"),
        default=SubscriptionStatus.trial,
        index=True,
    )
    trial_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    subscription_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    razorpay_subscription_id: Mapped[str | None] = mapped_column(String(64), unique=True)

    # Metadata
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    last_active_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Relationships
    birth_chart: Mapped[BirthChart | None] = relationship(
        "BirthChart", back_populates="user", uselist=False, lazy="select"
    )
    chat_messages: Mapped[list[ChatMessage]] = relationship(
        "ChatMessage", back_populates="user", lazy="select"
    )
    horoscopes: Mapped[list[Horoscope]] = relationship(
        "Horoscope", back_populates="user", lazy="select"
    )
    payments: Mapped[list[Payment]] = relationship(
        "Payment", back_populates="user", lazy="select"
    )
    daily_scores: Mapped[list[DailyScore]] = relationship(
        "DailyScore", back_populates="user", lazy="select"
    )
    insight_predictions: Mapped[list[InsightPrediction]] = relationship(
        "InsightPrediction", back_populates="user", lazy="select"
    )
    today_data: Mapped[list[TodayData]] = relationship(
        "TodayData", back_populates="user", lazy="select"
    )
    whatsapp_deliveries: Mapped[list[WhatsAppDelivery]] = relationship(
        "WhatsAppDelivery", back_populates="user", lazy="select"
    )


# Late imports to avoid circular refs — models imported in __init__.py
from .birth_chart import BirthChart  # noqa: E402
from .chat_message import ChatMessage  # noqa: E402
from .horoscope import Horoscope  # noqa: E402
from .payment import Payment  # noqa: E402
from .daily_score import DailyScore  # noqa: E402
from .insight_prediction import InsightPrediction  # noqa: E402
from .today_data import TodayData  # noqa: E402
from .whatsapp_delivery import WhatsAppDelivery  # noqa: E402
