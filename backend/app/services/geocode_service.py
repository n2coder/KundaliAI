from __future__ import annotations
from datetime import datetime, timezone

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..models.birth_chart import PlaceGeoCache

_GOOGLE_URL = "https://maps.googleapis.com/maps/api/geocode/json"


async def geocode(place_name: str, db: AsyncSession) -> tuple[float, float]:
    """
    Resolve place_name to (lat, lng) rounded to 3 decimal places.
    Checks PlaceGeoCache first; falls back to Google Geocoding API on miss.
    Raises ValueError if the place cannot be resolved.
    """
    key = place_name.strip().lower()

    result = await db.execute(
        select(PlaceGeoCache).where(PlaceGeoCache.place_name == key)
    )
    cached = result.scalar_one_or_none()

    if cached:
        cached.hit_count += 1
        cached.last_hit_at = datetime.now(timezone.utc)
        await db.commit()
        return cached.lat, cached.lng

    lat, lng = await _google_geocode(place_name)

    entry = PlaceGeoCache(place_name=key, lat=lat, lng=lng)
    db.add(entry)
    await db.commit()
    return lat, lng


async def _google_geocode(place_name: str) -> tuple[float, float]:
    if not settings.google_geocoding_api_key:
        raise ValueError("Google Geocoding API key not configured")

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            _GOOGLE_URL,
            params={"address": place_name, "key": settings.google_geocoding_api_key},
        )
        resp.raise_for_status()
        data = resp.json()

    if data.get("status") != "OK" or not data.get("results"):
        raise ValueError(f"Could not geocode '{place_name}': {data.get('status')}")

    loc = data["results"][0]["geometry"]["location"]
    lat = round(loc["lat"], 3)
    lng = round(loc["lng"], 3)
    return lat, lng
