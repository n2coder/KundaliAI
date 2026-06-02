"""
Nightly batch: pre-generate tomorrow's daily horoscope for all active users.
Runs at 23:30 IST via Celery Beat.
"""
from __future__ import annotations
import asyncio
import logging
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import selectinload

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

    # Fetch the candidate IDs in one short-lived session…
    async with AsyncSessionLocal() as db:
        user_ids = (
            await db.execute(
                select(User.id).where(
                    User.subscription_status.in_([
                        SubscriptionStatus.trial,
                        SubscriptionStatus.active,
                    ])
                )
            )
        ).scalars().all()

    # …then process each user in its own session, eagerly loading birth_chart
    # so accessing the relationship never triggers a lazy load on a detached
    # instance (which raises under async SQLAlchemy). One failing user no
    # longer affects the others.
    generated = 0
    for user_id in user_ids:
        try:
            async with AsyncSessionLocal() as db:
                user = (
                    await db.execute(
                        select(User)
                        .options(selectinload(User.birth_chart))
                        .where(User.id == user_id)
                    )
                ).scalar_one_or_none()
                if user is None or user.birth_chart is None:
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
            logger.error("Horoscope batch failed for user %s: %s", user_id, exc)

    logger.info("Horoscope batch complete: %d/%d users", generated, len(user_ids))
