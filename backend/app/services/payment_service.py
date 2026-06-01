from __future__ import annotations
import hashlib
import hmac
import logging
from datetime import datetime, timedelta, timezone

import razorpay
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..models import User
from ..models.payment import Payment, PaymentStatus
from ..models.user import SubscriptionStatus

logger = logging.getLogger(__name__)


def _razorpay_client() -> razorpay.Client:
    return razorpay.Client(
        auth=(settings.razorpay_key_id, settings.razorpay_key_secret)
    )


def verify_webhook_signature(body: bytes, signature: str) -> bool:
    if not settings.razorpay_webhook_secret:
        return True  # dev mode — skip verification
    expected = hmac.new(
        settings.razorpay_webhook_secret.encode(), body, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)


async def create_subscription(user: User) -> dict:
    """
    Create a Razorpay subscription for the user and return the short URL for checkout.
    """
    client = _razorpay_client()
    subscription = client.subscription.create({
        "plan_id": settings.razorpay_plan_id_monthly,
        "total_count": 12,
        "quantity": 1,
        "customer_notify": 1,
        "notify_info": {"notify_phone": user.phone},
        "notes": {"user_id": str(user.id)},
    })
    return {
        "subscription_id": subscription["id"],
        "short_url": subscription.get("short_url", ""),
        "status": subscription["status"],
    }


async def handle_subscription_charged(event: dict, db: AsyncSession) -> None:
    """Payment captured → activate user subscription."""
    payload = event.get("payload", {})
    payment_entity = payload.get("payment", {}).get("entity", {})
    sub_entity = payload.get("subscription", {}).get("entity", {})

    payment_id = payment_entity.get("id")
    if not payment_id:
        return

    # UNIQUE guard — silently skip duplicate webhook deliveries
    existing = await db.execute(
        select(Payment).where(Payment.razorpay_payment_id == payment_id)
    )
    if existing.scalar_one_or_none():
        logger.info("Duplicate webhook for payment %s — skipped", payment_id)
        return

    # Find user by subscription ID
    sub_id = sub_entity.get("id") or payment_entity.get("subscription_id")
    user = await _find_user_by_subscription(sub_id, db)
    if user is None:
        logger.warning("No user found for subscription %s", sub_id)
        return

    now = datetime.now(timezone.utc)
    amount_paise = payment_entity.get("amount", 3000)

    # Record payment
    payment = Payment(
        user_id=user.id,
        razorpay_payment_id=payment_id,
        razorpay_subscription_id=sub_id,
        razorpay_order_id=payment_entity.get("order_id"),
        amount_paise=amount_paise,
        status=PaymentStatus.captured,
        webhook_event="subscription.charged",
    )
    db.add(payment)

    # Activate subscription
    user.subscription_status = SubscriptionStatus.active
    user.razorpay_subscription_id = sub_id
    user.subscription_ends_at = now + timedelta(days=32)  # ~1 month buffer

    await db.commit()
    logger.info("Subscription activated for user %s", user.id)


async def handle_subscription_cancelled(event: dict, db: AsyncSession) -> None:
    sub_id = (
        event.get("payload", {})
        .get("subscription", {})
        .get("entity", {})
        .get("id")
    )
    user = await _find_user_by_subscription(sub_id, db)
    if user:
        user.subscription_status = SubscriptionStatus.cancelled
        await db.commit()
        logger.info("Subscription cancelled for user %s", user.id)


async def handle_subscription_completed(event: dict, db: AsyncSession) -> None:
    sub_id = (
        event.get("payload", {})
        .get("subscription", {})
        .get("entity", {})
        .get("id")
    )
    user = await _find_user_by_subscription(sub_id, db)
    if user:
        user.subscription_status = SubscriptionStatus.expired
        await db.commit()
        logger.info("Subscription completed/expired for user %s", user.id)


async def _find_user_by_subscription(sub_id: str | None, db: AsyncSession) -> User | None:
    if not sub_id:
        return None
    result = await db.execute(
        select(User).where(User.razorpay_subscription_id == sub_id)
    )
    return result.scalar_one_or_none()
