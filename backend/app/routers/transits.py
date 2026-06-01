from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field

from ..dependencies import get_current_user
from ..models import User
from ..services import transit_service

router = APIRouter()


class TransitOut(BaseModel):
    planet:      str
    glyph:       str
    from_:       str = Field(alias="from")
    to:          str
    period:      str
    impact:      str
    description: str
    advice:      str

    model_config = ConfigDict(populate_by_name=True)


@router.get(
    "",
    response_model=list[TransitOut],
    summary="Current Vedic planetary transits with sign, period, and interpretation",
)
async def get_transits(
    current_user: User = Depends(get_current_user),
) -> list[dict]:
    """
    Returns the current sidereal transit positions for Jupiter, Saturn, Rahu,
    Ketu, Mars, and Venus.  Descriptions are generated via gpt-4o-mini and
    cached in-memory per (planet, sign) pair for the duration of the transit.
    """
    return await transit_service.get_current_transits(date.today())
