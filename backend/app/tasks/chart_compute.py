"""
Celery task: compute Vedic birth chart for a user.
Called after birth details are saved (from users router or onboarding).
Uses asyncio.run to run async DB operations inside the sync Celery worker.
"""
from __future__ import annotations
import asyncio
import logging
import uuid

from sqlalchemy import select
from sqlalchemy.orm import selectinload

from .celery_app import celery_app
from ..database import AsyncSessionLocal
from ..models import User, BirthChart
from ..services.chart_service import get_or_compute_chart, dasha_from_chart

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=3, default_retry_delay=30)
def compute_chart_for_user(self, user_id: str) -> None:
    try:
        asyncio.run(_async_compute(user_id))
    except Exception as exc:
        logger.error("Chart computation failed for user %s: %s", user_id, exc)
        raise self.retry(exc=exc)


async def _async_compute(user_id: str) -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(User)
            .options(selectinload(User.birth_chart))
            .where(User.id == uuid.UUID(user_id))
        )
        user = result.scalar_one_or_none()

        if user is None:
            logger.warning("compute_chart_for_user: user %s not found", user_id)
            return

        if not all([user.dob, user.tob, user.birth_lat, user.birth_lng]):
            logger.warning("compute_chart_for_user: user %s has incomplete birth details", user_id)
            return

        chart_data = await get_or_compute_chart(
            dob=user.dob,
            tob=user.tob,
            lat=user.birth_lat,
            lng=user.birth_lng,
            db=db,
        )

        # Compute-time snapshot of the active Mahadasha for the denormalised
        # column. The authoritative dasha is computed fresh at read time
        # (dasha_from_chart); this column is only a convenience hint and will
        # go stale — do not rely on it for display.
        maha = dasha_from_chart(chart_data, user.dob).get("mahadasha")

        if user.birth_chart is None:
            birth_chart = BirthChart(
                user_id=user.id,
                chart_data=chart_data,
                sun_sign=chart_data.get("sun_sign"),
                moon_sign=chart_data.get("moon_sign"),
                ascendant=chart_data.get("ascendant"),
                current_dasha=maha,
            )
            db.add(birth_chart)
        else:
            user.birth_chart.chart_data = chart_data
            user.birth_chart.sun_sign = chart_data.get("sun_sign")
            user.birth_chart.moon_sign = chart_data.get("moon_sign")
            user.birth_chart.ascendant = chart_data.get("ascendant")
            user.birth_chart.current_dasha = maha

        await db.commit()
        logger.info("Chart computed for user %s: %s rising", user_id, chart_data.get("ascendant"))
