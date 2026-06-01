"""
Nightly batch: compute formula-based life-area scores for all active users.
Runs at 23:45 IST (18:15 UTC) via Celery Beat.
Scores are derived from transiting planet positions vs natal chart.
"""
from __future__ import annotations
import asyncio
import logging
from datetime import date

import swisseph as swe
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from .celery_app import celery_app
from ..database import AsyncSessionLocal
from ..models import User
from ..models.daily_score import DailyScore
from ..models.user import SubscriptionStatus

logger = logging.getLogger(__name__)

# Planet weights per life area (transit planet → weight in score formula)
_WEIGHTS = {
    "career": {"Jupiter": 0.35, "Saturn": 0.25, "Sun": 0.20, "Mars": 0.20},
    "love":   {"Venus": 0.40, "Moon": 0.30, "Jupiter": 0.30},
    "money":  {"Jupiter": 0.35, "Venus": 0.25, "Mercury": 0.25, "Saturn": 0.15},
    "health": {"Sun": 0.35, "Mars": 0.30, "Moon": 0.20, "Saturn": 0.15},
}

_PLANET_IDS = {
    "Sun": swe.SUN, "Moon": swe.MOON, "Mars": swe.MARS, "Mercury": swe.MERCURY,
    "Jupiter": swe.JUPITER, "Venus": swe.VENUS, "Saturn": swe.SATURN,
}


@celery_app.task
def compute_all() -> None:
    asyncio.run(_async_compute_all())


async def _async_compute_all() -> None:
    today = date.today()
    transit_positions = _get_transit_positions(today)

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(User)
            .options(selectinload(User.birth_chart))
            .where(
                User.subscription_status.in_([
                    SubscriptionStatus.trial,
                    SubscriptionStatus.active,
                ])
            )
        )
        users = result.scalars().all()

    computed = 0
    for user in users:
        if user.birth_chart is None:
            continue
        try:
            async with AsyncSessionLocal() as db:
                await _compute_for_user(user, today, transit_positions, db)
            computed += 1
        except Exception as exc:
            logger.error("Score batch failed for user %s: %s", user.id, exc)

    logger.info("Score batch complete: %d users", computed)


async def _compute_for_user(user: User, today: date, transits: dict, db) -> None:
    natal = {p["name"]: p["longitude"] for p in user.birth_chart.chart_data.get("planets", [])}

    scores = {}
    for area, weights in _WEIGHTS.items():
        total = 0.0
        for planet, weight in weights.items():
            natal_lon = natal.get(planet, 0)
            transit_lon = transits.get(planet, 0)
            aspect_score = _aspect_score(natal_lon, transit_lon)
            total += aspect_score * weight
        scores[area] = round(min(max(total, 0.0), 1.0), 3)

    scores["overall"] = round(sum(scores.values()) / len(scores), 3)

    daily_score = DailyScore(
        user_id=user.id,
        score_date=today,
        **scores,
    )
    db.add(daily_score)
    await db.commit()


def _get_transit_positions(for_date: date) -> dict[str, float]:
    jd = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL
    positions = {}
    for name, pid in _PLANET_IDS.items():
        pos, _ = swe.calc_ut(jd, pid, flags)
        positions[name] = pos[0] % 360
    return positions


def _aspect_score(natal_lon: float, transit_lon: float) -> float:
    """
    Score 0.0–1.0 based on angular distance between transit and natal planet.
    Trine (120°) and sextile (60°) → high. Square (90°) and opposition (180°) → low.
    Conjunction (0°) → neutral-high.
    """
    diff = abs((transit_lon - natal_lon) % 360)
    if diff > 180:
        diff = 360 - diff

    if diff <= 8:       return 0.75   # conjunction
    if abs(diff - 60)  <= 6: return 0.85  # sextile
    if abs(diff - 90)  <= 6: return 0.25  # square
    if abs(diff - 120) <= 6: return 0.95  # trine
    if abs(diff - 150) <= 6: return 0.40  # quincunx
    if abs(diff - 180) <= 6: return 0.20  # opposition
    return 0.55  # neutral
