from __future__ import annotations
import json
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..database import get_db
from ..models.whatsapp_delivery import WhatsAppDelivery, DeliveryStatus

logger = logging.getLogger(__name__)
router = APIRouter()


# ── Meta webhook verification (GET) ──────────────────────────────────────────

@router.get(
    "/webhook",
    summary="Meta webhook verification challenge",
    include_in_schema=False,
)
async def verify_webhook(
    hub_mode: str = Query(alias="hub.mode", default=""),
    hub_challenge: str = Query(alias="hub.challenge", default=""),
    hub_verify_token: str = Query(alias="hub.verify_token", default=""),
):
    """
    Meta calls this endpoint when you register the webhook URL in the
    Meta developer dashboard. It expects the hub.challenge echoed back.
    """
    if hub_mode == "subscribe" and hub_verify_token == settings.meta_webhook_verify_token:
        return int(hub_challenge)
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verification failed")


# ── Inbound webhook events (POST) ─────────────────────────────────────────────

@router.post(
    "/webhook",
    status_code=status.HTTP_200_OK,
    summary="Receive WhatsApp delivery status updates from Meta",
    include_in_schema=False,
)
async def receive_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Handles status update events from Meta Cloud API:
    - sent → mark delivery as sent
    - delivered → mark as delivered
    - read → no action (informational)
    - failed → mark as failed with error

    Meta requires a 200 response within 20s or it will retry.
    """
    try:
        body = await request.json()
    except Exception:
        # Always return 200 to Meta — never let parse errors cause retries
        return {"status": "ok"}

    try:
        await _process_status_updates(body, db)
    except Exception as exc:
        logger.error("WhatsApp webhook processing error: %s", exc)

    return {"status": "ok"}


async def _process_status_updates(body: dict, db: AsyncSession) -> None:
    entries = body.get("entry", [])
    for entry in entries:
        for change in entry.get("changes", []):
            value = change.get("value", {})
            for status_update in value.get("statuses", []):
                msg_id = status_update.get("id")
                msg_status = status_update.get("status")  # sent | delivered | read | failed
                if not msg_id or not msg_status:
                    continue

                result = await db.execute(
                    select(WhatsAppDelivery).where(WhatsAppDelivery.meta_message_id == msg_id)
                )
                delivery = result.scalar_one_or_none()
                if delivery is None:
                    continue

                if msg_status == "delivered":
                    delivery.status = DeliveryStatus.delivered
                elif msg_status == "failed":
                    errors = status_update.get("errors", [])
                    error_msg = errors[0].get("message", "unknown") if errors else "failed"
                    delivery.status = DeliveryStatus.failed
                    delivery.error_message = error_msg[:300]

                # "sent" and "read" need no DB update — delivery was already marked sent by the batch

    await db.commit()
