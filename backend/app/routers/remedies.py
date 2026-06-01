from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from ..dependencies import get_current_user
from ..models import User
from ..services.remedy_service import get_remedies, remedy_to_dict

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class RemedyOut(BaseModel):
    title: str
    category: str
    icon: str
    description: str
    instructions: list[str]
    duration: str
    difficulty: str
    planets: list[str]


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "",
    response_model=list[RemedyOut],
    summary="Get personalised Vedic remedies based on birth chart",
)
async def list_remedies(current_user: User = Depends(get_current_user)):
    """
    Returns 4–6 rule-based remedies tailored to the user's birth chart.
    Debilitated planets and afflicted houses trigger specific remedies.
    The Gayatri Mantra remedy is always included as a universal base.
    Requires a computed birth chart — returns 400 if chart is missing.
    """
    if current_user.birth_chart is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Birth chart not found. Submit birth details first via POST /birth-chart/compute",
        )
    remedies = get_remedies(current_user.birth_chart.chart_data)
    return [RemedyOut(**remedy_to_dict(r)) for r in remedies]


@router.get(
    "/{title}",
    response_model=RemedyOut,
    summary="Get a specific remedy by title",
)
async def get_remedy(title: str, current_user: User = Depends(get_current_user)):
    """
    Fetch a single remedy's full detail by its URL-encoded title.
    Used by the remedy detail screen when tapping a remedy card.
    """
    if current_user.birth_chart is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Birth chart not found.",
        )
    import urllib.parse
    decoded_title = urllib.parse.unquote(title)
    remedies = get_remedies(current_user.birth_chart.chart_data)
    match = next((r for r in remedies if r.title == decoded_title), None)
    if match is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Remedy '{decoded_title}' not found for this chart",
        )
    return RemedyOut(**remedy_to_dict(match))
