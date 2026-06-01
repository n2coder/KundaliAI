from __future__ import annotations
import uuid
from datetime import datetime, date
from sqlalchemy import String, Date, DateTime, ForeignKey, func, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
from .base import Base


class DeliveryStatus(str, enum.Enum):
    queued = "queued"
    sent = "sent"
    delivered = "delivered"
    failed = "failed"


class WhatsAppDelivery(Base):
    """Audit log of every WhatsApp message dispatch attempt."""
    __tablename__ = "whatsapp_deliveries"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    for_date: Mapped[date] = mapped_column(Date, nullable=False)
    language: Mapped[str] = mapped_column(String(5), default="en")
    template_name: Mapped[str] = mapped_column(String(80))
    meta_message_id: Mapped[str | None] = mapped_column(String(120), unique=True)
    status: Mapped[DeliveryStatus] = mapped_column(
        SAEnum(DeliveryStatus, name="delivery_status_enum"),
        default=DeliveryStatus.queued,
        index=True,
    )
    error_message: Mapped[str | None] = mapped_column(String(300))
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="whatsapp_deliveries")


from .user import User  # noqa: E402
