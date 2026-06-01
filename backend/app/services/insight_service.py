from __future__ import annotations
import json
import logging
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import User
from ..models.birth_chart import BirthChart
from ..models.insight_prediction import InsightPrediction, InsightCategory
from .horoscope_service import _chart_summary
from .openai_client import get_client

logger = logging.getLogger(__name__)
_MODEL = "gpt-4o-mini"

_CATEGORY_LABELS = {
    InsightCategory.career: "Career & Finance",
    InsightCategory.love:   "Love & Relationships",
    InsightCategory.money:  "Wealth & Investments",
    InsightCategory.health: "Health & Wellbeing",
}

_LANG_INSTRUCTION = {
    "en": "Respond in English.",
    "hi": "Respond in Hindi (Devanagari script).",
}


async def get_or_generate(
    user: User,
    birth_chart: BirthChart,
    category: InsightCategory,
    db: AsyncSession,
) -> InsightPrediction:
    lang = user.language.value if hasattr(user.language, "value") else str(user.language)
    month_start = date.today().replace(day=1)
    # Last day of month
    month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)

    result = await db.execute(
        select(InsightPrediction).where(
            InsightPrediction.user_id == user.id,
            InsightPrediction.category == category,
            InsightPrediction.period_start == month_start,
        )
    )
    prediction = result.scalar_one_or_none()

    existing_content = (prediction.content_hi if lang == "hi" else prediction.content_en) if prediction else None

    if prediction and existing_content:
        return prediction

    data = await _generate(birth_chart.chart_data, category, month_start, lang)

    if prediction is None:
        prediction = InsightPrediction(
            user_id=user.id,
            category=category,
            period_start=month_start,
            period_end=month_end,
        )
        db.add(prediction)

    prediction.score = data.get("score", 0.5)
    prediction.best_period_label = data.get("best_periods", [""])[0] if data.get("best_periods") else None

    if lang == "hi":
        prediction.content_hi = data.get("content", "")
    else:
        prediction.content_en = data.get("content", "")

    await db.commit()
    await db.refresh(prediction)
    return prediction


async def _generate(
    chart_data: dict,
    category: InsightCategory,
    month_start: date,
    lang: str,
) -> dict:
    summary = _chart_summary(chart_data)
    cat_label = _CATEGORY_LABELS[category]
    lang_instr = _LANG_INSTRUCTION.get(lang, _LANG_INSTRUCTION["en"])
    month_label = month_start.strftime("%B %Y")

    system = (
        "You are a precise Vedic astrologer generating monthly insight predictions. "
        f"User's birth chart:\n{summary}\n\n"
        f"{lang_instr} "
        "Always respond with valid JSON only — no markdown, no code fences."
    )
    user_msg = (
        f"Generate a {cat_label} insight for {month_label}.\n"
        "Return exactly this JSON structure:\n"
        '{"score": <float 0.0-1.0 representing overall favorability>, '
        '"content": "<250-300 word monthly insight>", '
        '"best_periods": ["<date range 1>", "<date range 2>", "<date range 3>"]}'
    )

    try:
        resp = await get_client().chat.completions.create(
            model=_MODEL,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user_msg},
            ],
            response_format={"type": "json_object"},
            max_tokens=600,
            temperature=0.65,
        )
        return json.loads(resp.choices[0].message.content)
    except Exception as exc:
        logger.error("Insight generation failed for %s: %s", category, exc)
        return {"score": 0.5, "content": "", "best_periods": []}
