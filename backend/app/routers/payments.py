from __future__ import annotations
import json
import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..models import User
from ..models.user import SubscriptionStatus
from ..services import payment_service

logger = logging.getLogger(__name__)
router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class CreateSubscriptionResponse(BaseModel):
    subscription_id: str
    short_url: str
    status: str


class SubscriptionStatusOut(BaseModel):
    subscription_status: str
    trial_ends_at: str | None
    subscription_ends_at: str | None
    razorpay_subscription_id: str | None


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post(
    "/create-subscription",
    response_model=CreateSubscriptionResponse,
    summary="Create a Razorpay monthly subscription and return checkout URL",
)
async def create_subscription(
    current_user: User = Depends(get_current_user),
):
    if current_user.subscription_status == SubscriptionStatus.active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already has an active subscription",
        )
    if not __import__("app.config", fromlist=["settings"]).settings.razorpay_key_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Payment gateway not configured",
        )
    result = await payment_service.create_subscription(current_user)
    return CreateSubscriptionResponse(**result)


@router.get(
    "/status",
    response_model=SubscriptionStatusOut,
    summary="Get current subscription status",
)
async def subscription_status(current_user: User = Depends(get_current_user)):
    return SubscriptionStatusOut(
        subscription_status=current_user.subscription_status.value,
        trial_ends_at=current_user.trial_ends_at.isoformat() if current_user.trial_ends_at else None,
        subscription_ends_at=current_user.subscription_ends_at.isoformat() if current_user.subscription_ends_at else None,
        razorpay_subscription_id=current_user.razorpay_subscription_id,
    )


@router.post(
    "/webhook",
    status_code=status.HTTP_200_OK,
    summary="Razorpay webhook receiver (HMAC-verified)",
    include_in_schema=False,  # hide from public docs
)
async def razorpay_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    body = await request.body()
    signature = request.headers.get("X-Razorpay-Signature", "")

    if not payment_service.verify_webhook_signature(body, signature):
        logger.warning("Razorpay webhook signature mismatch")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid signature")

    try:
        event = json.loads(body)
    except json.JSONDecodeError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid JSON")

    event_type: str = event.get("event", "")
    logger.info("Razorpay webhook: %s", event_type)

    if event_type == "subscription.charged":
        await payment_service.handle_subscription_charged(event, db)
    elif event_type == "subscription.cancelled":
        await payment_service.handle_subscription_cancelled(event, db)
    elif event_type in ("subscription.completed", "subscription.expired"):
        await payment_service.handle_subscription_completed(event, db)
    # Other events (payment.failed, etc.) are logged but no action required

    return {"status": "ok"}
