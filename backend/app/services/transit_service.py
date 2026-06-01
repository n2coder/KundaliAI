"""
Vedic transit service: current planetary positions, sign-entry/exit dates,
and OpenAI-generated descriptions.  Results are cached in-memory per
(planet, sign) key and refreshed automatically when a sign change is detected.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import date, datetime, timezone
from typing import Any

import swisseph as swe

from .openai_client import get_client

logger = logging.getLogger(__name__)

# ── Constants ─────────────────────────────────────────────────────────────────

SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

_GLYPHS = {
    "Jupiter": "♃",
    "Saturn":  "♄",
    "Rahu":    "☊",
    "Ketu":    "☋",
    "Mars":    "♂",
    "Venus":   "♀",
}

_IMPACTS = {
    "Jupiter": "High",
    "Saturn":  "High",
    "Rahu":    "High",
    "Ketu":    "Medium",
    "Mars":    "Low",
    "Venus":   "Low",
}

# Step size (JD days) for entry/exit date search
_STEP = {
    "Jupiter": 8,
    "Saturn":  15,
    "Rahu":    8,
    "Ketu":    8,
    "Mars":    2,
    "Venus":   1,
}

_MAX_ITER = 600

# Planets to compute transits for (Ketu is derived from Rahu)
_TRANSIT_PLANETS = ["Jupiter", "Saturn", "Rahu", "Mars", "Venus"]

# Swiss Ephemeris planet IDs
_SWE_ID = {
    "Sun":     swe.SUN,
    "Moon":    swe.MOON,
    "Mars":    swe.MARS,
    "Mercury": swe.MERCURY,
    "Jupiter": swe.JUPITER,
    "Venus":   swe.VENUS,
    "Saturn":  swe.SATURN,
    "Rahu":    swe.TRUE_NODE,
}

# Desired return order
_ORDER = ["Jupiter", "Saturn", "Rahu", "Ketu", "Mars", "Venus"]

# ── In-memory cache ───────────────────────────────────────────────────────────

# Maps (planet, sign) → transit dict
_cache: dict[tuple[str, str], dict[str, Any]] = {}
_cache_lock = asyncio.Lock()


# ── Public API ────────────────────────────────────────────────────────────────

async def get_current_transits(for_date: date) -> list[dict[str, Any]]:
    """
    Return list of transit dicts for Jupiter, Saturn, Rahu, Ketu, Mars, Venus
    sorted in that order.  Descriptions are generated via gpt-4o-mini and cached
    in-memory for the lifetime of the current sign placement.
    """
    raw = _get_raw_positions(for_date)  # {planet: longitude}
    results: list[dict[str, Any]] = []

    for planet in _ORDER:
        lon = raw[planet]
        sign_idx = int(lon / 30) % 12
        sign = SIGNS[sign_idx]
        cache_key = (planet, sign)

        # Fast path: already cached
        if cache_key in _cache:
            results.append(_cache[cache_key])
            continue

        # Slow path: compute entry/exit dates + generate description
        async with _cache_lock:
            # Double-check after acquiring lock (another coroutine may have populated it)
            if cache_key in _cache:
                results.append(_cache[cache_key])
                continue

            entry_date, exit_date = _find_transit_window(planet, for_date, lon, sign_idx)
            description, advice = await _generate_description(planet, sign, entry_date, exit_date)

            transit = {
                "planet":      planet,
                "glyph":       _GLYPHS[planet],
                "from":        SIGNS[(sign_idx - 1) % 12],  # previous sign
                "to":          sign,                          # current sign
                "period":      _format_period(entry_date, exit_date),
                "impact":      _IMPACTS[planet],
                "description": description,
                "advice":      advice,
            }
            _cache[cache_key] = transit
            results.append(transit)

    return results


def get_transit_positions(for_date: date) -> dict[str, float]:
    """
    Sync helper: return sidereal longitudes for Sun, Moon, Mars, Mercury,
    Jupiter, Venus, Saturn at noon on for_date.
    Used by today_service for on-demand daily score computation.
    """
    jd = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL
    positions: dict[str, float] = {}
    for name, pid in _SWE_ID.items():
        pos, _ = swe.calc_ut(jd, pid, flags)
        positions[name] = pos[0] % 360
    return positions


# ── Internal helpers ──────────────────────────────────────────────────────────

def _get_raw_positions(for_date: date) -> dict[str, float]:
    """Return sidereal longitudes for all transit planets including Ketu."""
    jd = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL

    raw: dict[str, float] = {}
    for planet in _TRANSIT_PLANETS:
        pid = _SWE_ID[planet]
        pos, _ = swe.calc_ut(jd, pid, flags)
        raw[planet] = pos[0] % 360

    raw["Ketu"] = (raw["Rahu"] + 180.0) % 360.0
    return raw


def _lon_at_jd(planet: str, jd: float) -> float:
    """Return sidereal longitude for planet at given Julian Day."""
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL

    if planet == "Ketu":
        pos, _ = swe.calc_ut(jd, swe.TRUE_NODE, flags)
        return (pos[0] + 180.0) % 360.0

    pid = _SWE_ID[planet]
    pos, _ = swe.calc_ut(jd, pid, flags)
    return pos[0] % 360


def _sign_idx(lon: float) -> int:
    return int(lon / 30) % 12


def _find_transit_window(
    planet: str, for_date: date, current_lon: float, current_sign_idx: int
) -> tuple[date, date]:
    """Step backward and forward to find when the planet entered / will leave the current sign."""
    step = _STEP[planet]
    jd_today = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)

    # ── Find entry date: step backward ────────────────────────────────────────
    entry_jd = jd_today
    for _ in range(_MAX_ITER):
        prev_jd = entry_jd - step
        prev_lon = _lon_at_jd(planet, prev_jd)
        if _sign_idx(prev_lon) != current_sign_idx:
            break
        entry_jd = prev_jd
    entry_date = _jd_to_date(entry_jd)

    # ── Find exit date: step forward ──────────────────────────────────────────
    exit_jd = jd_today
    for _ in range(_MAX_ITER):
        next_jd = exit_jd + step
        next_lon = _lon_at_jd(planet, next_jd)
        if _sign_idx(next_lon) != current_sign_idx:
            break
        exit_jd = next_jd
    exit_date = _jd_to_date(exit_jd)

    return entry_date, exit_date


def _jd_to_date(jd: float) -> date:
    y, m, d, _ = swe.revjul(jd)
    return date(y, m, d)


def _format_period(entry: date, exit: date) -> str:
    """Format transit period as 'Mon YYYY – Mon YYYY'."""
    def fmt(d: date) -> str:
        return d.strftime("%b %Y")
    return f"{fmt(entry)} – {fmt(exit)}"


async def _generate_description(
    planet: str, sign: str, entry: date, exit: date
) -> tuple[str, str]:
    """Call gpt-4o-mini to generate a transit description and advice paragraph."""
    period = _format_period(entry, exit)
    prompt = (
        f"You are a Vedic astrology expert. "
        f"{planet} is currently transiting {sign} ({period}). "
        f"Write a concise transit interpretation in two parts:\n"
        f"1. DESCRIPTION (2-3 sentences): explain the general themes and effects of this transit.\n"
        f"2. ADVICE (1-2 sentences): practical guidance for navigating this transit.\n"
        f"Reply in exactly this JSON format:\n"
        f'{{ "description": "...", "advice": "..." }}'
    )

    try:
        client = get_client()
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=300,
            response_format={"type": "json_object"},
        )
        import json
        data = json.loads(resp.choices[0].message.content or "{}")
        description = data.get("description", f"{planet} transiting {sign}.")
        advice = data.get("advice", "Observe planetary energies with awareness.")
        return description, advice
    except Exception as exc:
        logger.warning("OpenAI transit description failed for %s in %s: %s", planet, sign, exc)
        return (
            f"{planet} is currently transiting {sign}, bringing its characteristic energies to bear on this sign's themes.",
            "Stay attuned to the planetary energies and adapt your plans accordingly.",
        )
