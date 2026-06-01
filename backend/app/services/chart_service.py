from __future__ import annotations
from datetime import date, time, datetime, timezone

import swisseph as swe
from timezonefinder import TimezoneFinder
from zoneinfo import ZoneInfo
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.birth_chart import BirthChartCache

_tf = TimezoneFinder()

SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

_PLANET_IDS = [
    (swe.SUN,       "Sun"),
    (swe.MOON,      "Moon"),
    (swe.MARS,      "Mars"),
    (swe.MERCURY,   "Mercury"),
    (swe.JUPITER,   "Jupiter"),
    (swe.VENUS,     "Venus"),
    (swe.SATURN,    "Saturn"),
    (swe.TRUE_NODE, "Rahu"),
]

# Vimshottari: nakshatra lord sequence (repeats × 3 = 27)
_NAKSHATRA_LORDS = [
    "Ketu", "Venus", "Sun", "Moon", "Mars",
    "Rahu", "Jupiter", "Saturn", "Mercury",
] * 3

_DASHA_ORDER = ["Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury"]
_DASHA_YEARS = {
    "Ketu": 7, "Venus": 20, "Sun": 6, "Moon": 10, "Mars": 7,
    "Rahu": 18, "Jupiter": 16, "Saturn": 19, "Mercury": 17,
}  # total = 120 years


# ── Public API ────────────────────────────────────────────────────────────────

async def get_or_compute_chart(
    dob: date, tob: time, lat: float, lng: float, db: AsyncSession
) -> dict:
    """Two-layer cache lookup → compute on miss."""
    lat_r = round(lat, 3)
    lng_r = round(lng, 3)

    result = await db.execute(
        select(BirthChartCache).where(
            BirthChartCache.dob == dob,
            BirthChartCache.tob == tob,
            BirthChartCache.lat == lat_r,
            BirthChartCache.lng == lng_r,
        )
    )
    cached = result.scalar_one_or_none()

    if cached:
        cached.hit_count += 1
        cached.last_hit_at = datetime.now(timezone.utc)
        await db.commit()
        return cached.chart_data

    chart_data = compute_vedic_chart(dob, tob, lat_r, lng_r)

    entry = BirthChartCache(dob=dob, tob=tob, lat=lat_r, lng=lng_r, chart_data=chart_data)
    db.add(entry)
    await db.commit()
    return chart_data


def compute_vedic_chart(dob: date, tob: time, lat: float, lng: float) -> dict:
    """
    Compute a sidereal Vedic birth chart using pyswisseph (Lahiri ayanamsa,
    whole-sign houses, Moshier ephemeris — no file download needed).
    """
    ut_hour = _local_to_ut(dob, tob, lat, lng)
    jd = swe.julday(dob.year, dob.month, dob.day, ut_hour)

    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED

    # ── Planets ───────────────────────────────────────────────────────────────
    planets: list[dict] = []
    moon_lon = 0.0

    for pid, name in _PLANET_IDS:
        pos, _ = swe.calc_ut(jd, pid, flags)
        lon = pos[0] % 360
        retrograde = pos[3] < 0
        planets.append(_planet_dict(name, lon, retrograde))
        if name == "Moon":
            moon_lon = lon

    # Ketu = Rahu + 180°
    rahu_lon = next(p["longitude"] for p in planets if p["name"] == "Rahu")
    ketu_lon = (rahu_lon + 180.0) % 360.0
    planets.append(_planet_dict("Ketu", ketu_lon, retrograde=True))

    # ── Ascendant (sidereal) ──────────────────────────────────────────────────
    # Use Placidus cusp[1] as tropical ascendant then subtract ayanamsa
    cusps, ascmc = swe.houses(jd, lat, lng, b"P")
    ayanamsa = swe.get_ayanamsa_ut(jd)
    asc_sidereal = (ascmc[0] - ayanamsa) % 360.0
    asc_sign_idx = int(asc_sidereal / 30)

    # ── Houses (whole-sign from ascendant) ────────────────────────────────────
    houses = [
        {"house": i + 1, "sign": SIGNS[(asc_sign_idx + i) % 12]}
        for i in range(12)
    ]

    # ── Derived signs ─────────────────────────────────────────────────────────
    sun_sign = next(p["sign"] for p in planets if p["name"] == "Sun")
    moon_sign = next(p["sign"] for p in planets if p["name"] == "Moon")

    return {
        "ayanamsa": round(ayanamsa, 4),
        "ascendant": SIGNS[asc_sign_idx],
        "ascendant_degree": round(asc_sidereal % 30, 4),
        "sun_sign": sun_sign,
        "moon_sign": moon_sign,
        "planets": planets,
        "houses": houses,
        "dasha": _vimshottari_dasha(moon_lon, dob),
    }


# ── Internal helpers ──────────────────────────────────────────────────────────

def _planet_dict(name: str, lon: float, retrograde: bool) -> dict:
    sign_idx = int(lon / 30)
    return {
        "name": name,
        "longitude": round(lon, 4),
        "sign": SIGNS[sign_idx],
        "degree": round(lon % 30, 4),
        "retrograde": retrograde,
    }


def _local_to_ut(dob: date, tob: time, lat: float, lng: float) -> float:
    """Convert local birth datetime to UT decimal hours."""
    tz_name = _tf.timezone_at(lat=lat, lng=lng) or "UTC"
    tz = ZoneInfo(tz_name)
    local_dt = datetime(dob.year, dob.month, dob.day,
                        tob.hour, tob.minute, tob.second, tzinfo=tz)
    ut = local_dt.astimezone(timezone.utc)
    return ut.hour + ut.minute / 60.0 + ut.second / 3600.0


def _vimshottari_dasha(moon_lon: float, dob: date) -> dict:
    """Return current Mahadasha and Antardasha."""
    nakshatra_span = 360.0 / 27.0
    nakshatra_idx = int(moon_lon / nakshatra_span)
    lord = _NAKSHATRA_LORDS[nakshatra_idx]

    completed_fraction = (moon_lon % nakshatra_span) / nakshatra_span
    years_elapsed_in_start = _DASHA_YEARS[lord] * completed_fraction

    today = date.today()
    years_since_birth = (today - dob).days / 365.25

    # Walk dasha chain from birth
    start_idx = _DASHA_ORDER.index(lord)
    cumulative = -years_elapsed_in_start  # dasha started before birth

    i = start_idx
    while cumulative + _DASHA_YEARS[_DASHA_ORDER[i % 9]] <= years_since_birth:
        cumulative += _DASHA_YEARS[_DASHA_ORDER[i % 9]]
        i += 1

    current_lord = _DASHA_ORDER[i % 9]
    years_into_maha = years_since_birth - cumulative
    maha_remaining = _DASHA_YEARS[current_lord] - years_into_maha

    antar_lord, antar_remaining = _current_antardasha(current_lord, years_into_maha)

    return {
        "mahadasha": current_lord,
        "mahadasha_remaining_years": round(maha_remaining, 2),
        "antardasha": antar_lord,
        "antardasha_remaining_years": round(antar_remaining, 2),
    }


def _current_antardasha(maha_lord: str, years_into_maha: float) -> tuple[str, float]:
    maha_total = _DASHA_YEARS[maha_lord]
    start_idx = _DASHA_ORDER.index(maha_lord)
    cumulative = 0.0

    for j in range(9):
        sub_lord = _DASHA_ORDER[(start_idx + j) % 9]
        sub_years = (_DASHA_YEARS[sub_lord] / 120.0) * maha_total
        if cumulative + sub_years > years_into_maha:
            remaining = sub_years - (years_into_maha - cumulative)
            return sub_lord, round(remaining, 2)
        cumulative += sub_years

    return maha_lord, 0.0
