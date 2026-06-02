from __future__ import annotations
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import User
from ..models.birth_chart import BirthChart
from ..models.horoscope import Horoscope, HoroscopePeriod
from .chart_service import dasha_from_chart
from .openai_client import chat_complete

_MODEL = "gpt-4o-mini"

_PERIOD_INSTRUCTIONS = {
    HoroscopePeriod.daily: (
        "Write a daily horoscope for {date}. "
        "150–200 words. Cover: general energy, love/relationships, career/finances, health tip. "
        "Be specific to their planetary positions."
    ),
    HoroscopePeriod.weekly: (
        "Write a weekly horoscope for the week of {date}. "
        "250–300 words. Give day-by-day energy shifts, highlight the best day and the day to avoid big decisions."
    ),
    HoroscopePeriod.monthly: (
        "Write a monthly horoscope for {date:%B %Y}. "
        "400–500 words. Identify the strongest and most challenging weeks, "
        "give best dates for love, career, and finance decisions."
    ),
}

_LANG_INSTRUCTION = {
    "en": "Respond entirely in English.",
    "hi": "Respond entirely in Hindi (Devanagari script). Keep it natural and warm.",
}


async def get_or_generate(
    user: User,
    birth_chart: BirthChart,
    period: HoroscopePeriod,
    for_date: date,
    db: AsyncSession,
) -> Horoscope:
    lang = user.language.value if hasattr(user.language, "value") else str(user.language)

    result = await db.execute(
        select(Horoscope).where(
            Horoscope.user_id == user.id,
            Horoscope.period == period,
            Horoscope.for_date == for_date,
        )
    )
    horoscope = result.scalar_one_or_none()

    # Return if the right language content already exists
    if horoscope:
        existing_content = horoscope.content_hi if lang == "hi" else horoscope.content_en
        if existing_content:
            return horoscope

    content = await _generate(birth_chart.chart_data, period, for_date, lang, user.dob)

    if horoscope is None:
        horoscope = Horoscope(
            user_id=user.id,
            period=period,
            for_date=for_date,
            language=lang,
        )
        db.add(horoscope)

    if lang == "hi":
        horoscope.content_hi = content
    else:
        horoscope.content_en = content

    await db.commit()
    await db.refresh(horoscope)
    return horoscope


async def _generate(
    chart_data: dict, period: HoroscopePeriod, for_date: date, lang: str, dob: date
) -> str:
    summary = _chart_summary(chart_data, dob)
    period_instr = _PERIOD_INSTRUCTIONS[period].format(date=for_date)
    lang_instr = _LANG_INSTRUCTION.get(lang, _LANG_INSTRUCTION["en"])

    system = (
        "You are a warm, insightful Vedic astrologer. "
        "The user's birth chart:\n"
        f"{summary}\n\n"
        f"{lang_instr}"
    )
    user_msg = period_instr

    return await chat_complete(
        [{"role": "system", "content": system}, {"role": "user", "content": user_msg}],
        model=_MODEL,
        max_tokens=700,
        temperature=0.75,
    )


def _chart_summary(chart_data: dict, dob: date | None = None) -> str:
    planets = {p["name"]: p["sign"] for p in chart_data.get("planets", [])}
    dasha = dasha_from_chart(chart_data, dob)
    retro = [p["name"] for p in chart_data.get("planets", []) if p.get("retrograde")]
    retro_str = f"Retrograde: {', '.join(retro)}" if retro else ""
    return (
        f"Sun: {planets.get('Sun', '?')} | Moon: {planets.get('Moon', '?')} | "
        f"Ascendant: {chart_data.get('ascendant', '?')}\n"
        f"Jupiter: {planets.get('Jupiter', '?')} | Venus: {planets.get('Venus', '?')} | "
        f"Saturn: {planets.get('Saturn', '?')} | Mars: {planets.get('Mars', '?')}\n"
        f"Rahu: {planets.get('Rahu', '?')} | Ketu: {planets.get('Ketu', '?')}\n"
        f"Dasha: {dasha.get('mahadasha', '?')} / {dasha.get('antardasha', '?')} "
        f"({dasha.get('antardasha_remaining_years', '?')}y remaining)\n"
        + (retro_str or "")
    ).strip()
