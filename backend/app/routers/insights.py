from __future__ import annotations
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from ..database import get_db
from ..dependencies import get_current_user
from ..models import User
from ..models.insight_prediction import InsightCategory
from ..services import insight_service
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

_VALID_CATEGORIES = {c.value for c in InsightCategory}


# ── Schemas ───────────────────────────────────────────────────────────────────

class InsightOut(BaseModel):
    category: str
    score: float
    content: str
    best_periods: list[str]
    period_start: date
    period_end: date


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/{category}",
    response_model=InsightOut,
    summary="Get monthly insight prediction for a life area",
)
async def get_insight(
    category: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Returns AI-generated monthly insight for career / love / money / health.
    Generated on first request and cached until the end of the month.
    Requires a computed birth chart.
    """
    if category not in _VALID_CATEGORIES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid category. Must be one of: {', '.join(sorted(_VALID_CATEGORIES))}",
        )
    if current_user.birth_chart is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Birth chart not found. Submit birth details first via POST /birth-chart/compute",
        )

    cat = InsightCategory(category)
    lang = current_user.language.value if hasattr(current_user.language, "value") else str(current_user.language)

    prediction = await insight_service.get_or_generate(
        user=current_user,
        birth_chart=current_user.birth_chart,
        category=cat,
        db=db,
    )

    content = prediction.content_hi if lang == "hi" else prediction.content_en

    # best_period_label is a single string; reconstruct a list for the schema
    best_periods: list[str] = []
    if prediction.best_period_label:
        best_periods = [prediction.best_period_label]

    return InsightOut(
        category=category,
        score=prediction.score or 0.5,
        content=content or "",
        best_periods=best_periods,
        period_start=prediction.period_start,
        period_end=prediction.period_end,
    )


@router.get(
    "",
    response_model=list[InsightOut],
    summary="Get all four monthly insights in one call",
)
async def get_all_insights(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Convenience endpoint — fetches career, love, money, health in sequence."""
    if current_user.birth_chart is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Birth chart not found.",
        )

    lang = current_user.language.value if hasattr(current_user.language, "value") else str(current_user.language)
    results = []

    for cat in InsightCategory:
        prediction = await insight_service.get_or_generate(
            user=current_user,
            birth_chart=current_user.birth_chart,
            category=cat,
            db=db,
        )
        content = prediction.content_hi if lang == "hi" else prediction.content_en
        best_periods = [prediction.best_period_label] if prediction.best_period_label else []
        results.append(InsightOut(
            category=cat.value,
            score=prediction.score or 0.5,
            content=content or "",
            best_periods=best_periods,
            period_start=prediction.period_start,
            period_end=prediction.period_end,
        ))

    return results
