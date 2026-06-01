"""
Nightly batch: pre-generate tomorrow's daily horoscope for all active users.
Runs at 23:30 IST via Celery Beat.
"""
from __future__ import annotations
import asyncio
import logging
from datetime import date, timedelta

from sqlalchemy import select

from .celery_app import celery_app
from ..database import AsyncSessionLocal
from ..models import User
from ..models.user import SubscriptionStatus
from ..models.birth_chart import BirthChart
from ..models.horoscope import HoroscopePeriod
from ..services.horoscope_service import get_or_generate

logger = logging.getLogger(__name__)


@celery_app.task
def generate_all() -> None:
    asyncio.run(_async_generate_all())


async def _async_generate_all() -> None:
    tomorrow = date.today() + timedelta(days=1)
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(User).where(
                User.subscription_status.in_([
                    SubscriptionStatus.trial,
                    SubscriptionStatus.active,
                ])
            )
        )
        users = result.scalars().all()

    generated = 0
    for user in users:
        try:
            async with AsyncSessionLocal() as db:
                if user.birth_chart is None:
                    continue
                await get_or_generate(
                    user=user,
                    birth_chart=user.birth_chart,
                    period=HoroscopePeriod.daily,
                    for_date=tomorrow,
                    db=db,
                )
            generated += 1
        except Exception as exc:
            logger.error("Horoscope batch failed for user %s: %s", user.id, exc)

    logger.info("Horoscope batch complete: %d/%d users", generated, len(users))
