from __future__ import annotations
import uuid
from datetime import datetime
from sqlalchemy import String, Integer, DateTime, ForeignKey, func, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
from .base import Base


class PaymentStatus(str, enum.Enum):
    created = "created"
    authorized = "authorized"
    captured = "captured"
    refunded = "refunded"
    failed = "failed"


class Payment(Base):
    """Razorpay subscription payment record. payment_id is unique to prevent double-crediting."""
    __tablename__ = "payments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Razorpay identifiers
    razorpay_payment_id: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    razorpay_subscription_id: Mapped[str | None] = mapped_column(String(64), index=True)
    razorpay_order_id: Mapped[str | None] = mapped_column(String(64))

    amount_paise: Mapped[int] = mapped_column(Integer, nullable=False)  # ₹30 = 3000 paise
    currency: Mapped[str] = mapped_column(String(5), default="INR")
    status: Mapped[PaymentStatus] = mapped_column(
        SAEnum(PaymentStatus, name="payment_status_enum"),
        default=PaymentStatus.created,
        index=True,
    )
    webhook_event: Mapped[str | None] = mapped_column(String(80))  # raw event name
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship("User", back_populates="payments")


from .user import User  # noqa: E402
