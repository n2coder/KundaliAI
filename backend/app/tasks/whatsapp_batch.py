"""
Morning batch: dispatch WhatsApp daily horoscope to opted-in users.
Runs at 01:30 UTC (07:00 IST) via Celery Beat.
"""
from __future__ import annotations
import asyncio
import logging
from datetime import date

import httpx
from sqlalchemy import select

from .celery_app import celery_app
from ..config import settings
from ..database import AsyncSessionLocal
from ..models import User
from ..models.user import SubscriptionStatus
from ..models.horoscope import Horoscope, HoroscopePeriod
from ..models.whatsapp_delivery import WhatsAppDelivery, DeliveryStatus

logger = logging.getLogger(__name__)

_META_URL = "https://graph.facebook.com/v19.0/{phone_id}/messages"


@celery_app.task
def dispatch_all() -> None:
    asyncio.run(_async_dispatch_all())


async def _async_dispatch_all() -> None:
    today = date.today()
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(User).where(
                User.whatsapp_enabled.is_(True),
                User.subscription_status.in_([
                    SubscriptionStatus.trial,
                    SubscriptionStatus.active,
                ]),
            )
        )
        users = result.scalars().all()

    sent = 0
    for user in users:
        try:
            await _send_to_user(user, today)
            sent += 1
        except Exception as exc:
            logger.error("WhatsApp dispatch failed for user %s: %s", user.id, exc)

    logger.info("WhatsApp batch: %d/%d sent", sent, len(users))


async def _send_to_user(user: User, today: date) -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Horoscope).where(
                Horoscope.user_id == user.id,
                Horoscope.period == HoroscopePeriod.daily,
                Horoscope.for_date == today,
                Horoscope.whatsapp_sent.is_(False),
            )
        )
        horoscope = result.scalar_one_or_none()
        if not horoscope:
            return

        lang = user.language.value if hasattr(user.language, "value") else str(user.language)
        content = horoscope.content_hi if lang == "hi" else horoscope.content_en
        if not content:
            return

        template = (
            settings.meta_template_daily_hi if lang == "hi"
            else settings.meta_template_daily_en
        )

        delivery = WhatsAppDelivery(
            user_id=user.id,
            for_date=today,
            language=lang,
            template_name=template,
            status=DeliveryStatus.queued,
        )
        db.add(delivery)
        await db.flush()

        try:
            msg_id = await _call_meta_api(user.phone, template, content)
            delivery.meta_message_id = msg_id
            delivery.status = DeliveryStatus.sent
            horoscope.whatsapp_sent = True
            from datetime import datetime, timezone
            horoscope.whatsapp_sent_at = datetime.now(timezone.utc)
        except Exception as exc:
            delivery.status = DeliveryStatus.failed
            delivery.error_message = str(exc)[:300]
            raise

        await db.commit()


async def _call_meta_api(phone: str, template: str, body_text: str) -> str:
    url = _META_URL.format(phone_id=settings.meta_phone_number_id)
    payload = {
        "messaging_product": "whatsapp",
        "to": phone,
        "type": "template",
        "template": {
            "name": template,
            "language": {"code": "en_IN"},
            "components": [
                {"type": "body", "parameters": [{"type": "text", "text": body_text[:1000]}]}
            ],
        },
    }
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(
            url,
            json=payload,
            headers={"Authorization": f"Bearer {settings.meta_whatsapp_token}"},
        )
        resp.raise_for_status()
        return resp.json()["messages"][0]["id"]
