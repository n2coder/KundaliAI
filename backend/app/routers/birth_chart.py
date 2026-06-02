from __future__ import annotations
from datetime import date, time

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..models import User
from ..services.geocode_service import geocode
from ..tasks.chart_compute import compute_chart_for_user

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class GeocodeResponse(BaseModel):
    place: str
    lat: float
    lng: float
    timezone: str | None = None


class BirthDetailsSubmit(BaseModel):
    """Submit birth details and optional place; triggers async chart computation."""
    name: str | None = None
    dob: date
    tob: time
    birth_place: str
    birth_lat: float | None = None   # if omitted, geocoded from birth_place
    birth_lng: float | None = None


class DashaOut(BaseModel):
    mahadasha: str
    mahadasha_remaining_years: float
    antardasha: str
    antardasha_remaining_years: float


class PlanetOut(BaseModel):
    name: str
    longitude: float
    sign: str
    degree: float
    retrograde: bool


class HouseOut(BaseModel):
    house: int
    sign: str


class BirthChartOut(BaseModel):
    ayanamsa: float
    ascendant: str
    ascendant_degree: float
    sun_sign: str
    moon_sign: str
    planets: list[PlanetOut]
    houses: list[HouseOut]
    dasha: DashaOut


class ComputeResponse(BaseModel):
    status: str   # "enqueued" | "already_exists"
    message: str


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/geocode",
    response_model=GeocodeResponse,
    summary="Resolve a place name to lat/lng (used by onboarding form)",
)
async def geocode_place(
    place: str = Query(..., min_length=2, description="City or place name, e.g. 'Mumbai'"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        lat, lng = await geocode(place, db)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))

    from timezonefinder import TimezoneFinder
    tz = TimezoneFinder().timezone_at(lat=lat, lng=lng)
    return GeocodeResponse(place=place, lat=lat, lng=lng, timezone=tz)


@router.post(
    "/compute",
    response_model=ComputeResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Save birth details and enqueue chart computation",
)
async def submit_birth_details(
    body: BirthDetailsSubmit,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Geocode if lat/lng not supplied
    lat, lng = body.birth_lat, body.birth_lng
    if lat is None or lng is None:
        try:
            lat, lng = await geocode(body.birth_place, db)
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))

    # Persist birth details onto User
    if body.name:
        current_user.name = body.name
    current_user.dob = body.dob
    current_user.tob = body.tob
    current_user.birth_place = body.birth_place
    current_user.birth_lat = lat
    current_user.birth_lng = lng
    await db.commit()

    # Enqueue Celery task — non-fatal if broker is unavailable
    already_had = current_user.birth_chart is not None
    try:
        compute_chart_for_user.delay(str(current_user.id))
        queued = True
    except Exception:
        queued = False

    return ComputeResponse(
        status="enqueued" if queued else "saved",
        message=(
            "Birth details saved. Chart computation has been queued."
            if queued and not already_had
            else "Birth details updated. Chart is being recomputed."
            if queued
            else "Birth details saved. Chart will be computed shortly."
        ),
    )


@router.get(
    "",
    response_model=BirthChartOut,
    summary="Get the current user's computed birth chart",
)
async def get_birth_chart(current_user: User = Depends(get_current_user)):
    if current_user.birth_chart is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Birth chart not yet computed. POST /birth-chart/compute first.",
        )
    return BirthChartOut(**current_user.birth_chart.chart_data)
