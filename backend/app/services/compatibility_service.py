"""
Vedic compatibility (Ashtakoot Milan, simplified 4-factor) service.
Computes Nadi, Gana, Bhakoot, and Graha Maitri scores, derives life-area
scores, then calls gpt-4o-mini for a narrative summary.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import date, time

from sqlalchemy.ext.asyncio import AsyncSession

from .chart_service import compute_vedic_chart
from .geocode_service import geocode
from .openai_client import chat_complete
from ..models import User

logger = logging.getLogger(__name__)

SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

# ── Ashtakoot tables ──────────────────────────────────────────────────────────

# Nadi groups by nakshatra index (0–26)
_NADI_ADI    = {0, 5, 6, 11, 12, 17, 18, 23, 24}
_NADI_MADHYA = {1, 4, 7, 10, 13, 16, 19, 22, 25}
_NADI_ANTYA  = {2, 3, 8, 9, 14, 15, 20, 21, 26}


def _nadi_group(nak_idx: int) -> int:
    if nak_idx in _NADI_ADI:
        return 0
    if nak_idx in _NADI_MADHYA:
        return 1
    return 2  # Antya


# Gana groups by nakshatra index
_GANA_DEVA     = {0, 4, 6, 7, 12, 14, 16, 21, 26}
_GANA_MANUSHYA = {1, 3, 5, 10, 11, 19, 20, 24, 25}
_GANA_RAKSHASA = {2, 8, 9, 13, 15, 17, 18, 22, 23}


def _gana_group(nak_idx: int) -> int:
    if nak_idx in _GANA_DEVA:
        return 0
    if nak_idx in _GANA_MANUSHYA:
        return 1
    return 2  # Rakshasa


# Sign lords
_SIGN_LORDS: dict[str, str] = {
    "Aries":       "Mars",
    "Taurus":      "Venus",
    "Gemini":      "Mercury",
    "Cancer":      "Moon",
    "Leo":         "Sun",
    "Virgo":       "Mercury",
    "Libra":       "Venus",
    "Scorpio":     "Mars",
    "Sagittarius": "Jupiter",
    "Capricorn":   "Saturn",
    "Aquarius":    "Saturn",
    "Pisces":      "Jupiter",
}

# Planetary friendship tables
_FRIENDS: dict[str, frozenset[str]] = {
    "Sun":     frozenset({"Moon", "Mars", "Jupiter"}),
    "Moon":    frozenset({"Sun", "Mercury"}),
    "Mars":    frozenset({"Sun", "Moon", "Jupiter"}),
    "Mercury": frozenset({"Sun", "Venus"}),
    "Jupiter": frozenset({"Sun", "Moon", "Mars"}),
    "Venus":   frozenset({"Mercury", "Saturn"}),
    "Saturn":  frozenset({"Mercury", "Venus"}),
}

_ENEMIES: dict[str, frozenset[str]] = {
    "Sun":     frozenset({"Saturn", "Venus"}),
    "Moon":    frozenset(),
    "Mars":    frozenset({"Mercury"}),
    "Mercury": frozenset({"Moon"}),
    "Jupiter": frozenset({"Mercury", "Venus"}),
    "Venus":   frozenset({"Sun", "Moon"}),
    "Saturn":  frozenset({"Sun", "Moon", "Mars"}),
}


# ── Result dataclass ──────────────────────────────────────────────────────────

@dataclass
class CompatibilityResult:
    overall_score:       float
    love_score:          float
    career_score:        float
    communication_score: float
    trust_score:         float
    summary:             str
    strengths:           list[str]
    challenges:          list[str]


# ── Public API ────────────────────────────────────────────────────────────────

async def check_compatibility(
    user: "User",
    partner_dob: date,
    partner_tob: time,
    partner_birth_place: str,
    db: AsyncSession,
) -> CompatibilityResult:
    """
    Compute Vedic compatibility between the user (using their stored birth chart)
    and a partner whose birth details are provided.
    """
    # ── User chart ────────────────────────────────────────────────────────────
    user_chart = user.birth_chart.chart_data  # already computed; read from relationship

    # ── Partner chart ─────────────────────────────────────────────────────────
    partner_lat, partner_lng = await geocode(partner_birth_place, db)
    partner_chart = compute_vedic_chart(partner_dob, partner_tob, partner_lat, partner_lng)

    # ── Extract Moon longitudes ───────────────────────────────────────────────
    user_moon_lon    = _moon_longitude(user_chart)
    partner_moon_lon = _moon_longitude(partner_chart)

    nak_span = 360.0 / 27.0
    user_nak_idx    = int(user_moon_lon    / nak_span) % 27
    partner_nak_idx = int(partner_moon_lon / nak_span) % 27

    user_moon_sign_idx    = int(user_moon_lon    / 30) % 12
    partner_moon_sign_idx = int(partner_moon_lon / 30) % 12

    # ── 1. Nadi (8 pts) ───────────────────────────────────────────────────────
    nadi_score = 0.0 if _nadi_group(user_nak_idx) == _nadi_group(partner_nak_idx) else 8.0

    # ── 2. Gana (6 pts) ───────────────────────────────────────────────────────
    u_gana = _gana_group(user_nak_idx)
    p_gana = _gana_group(partner_nak_idx)
    gana_score = _gana_points(u_gana, p_gana)

    # ── 3. Bhakoot (7 pts) ────────────────────────────────────────────────────
    diff = abs(user_moon_sign_idx - partner_moon_sign_idx)
    if diff == 0:
        diff = 12  # same sign → treat as 12th from itself
    bhakoot_score = 7.0 if diff in {1, 3, 5, 7, 9, 11} else 0.0

    # ── 4. Graha Maitri (5 pts) ──────────────────────────────────────────────
    u_lord = _SIGN_LORDS[SIGNS[user_moon_sign_idx]]
    p_lord = _SIGN_LORDS[SIGNS[partner_moon_sign_idx]]
    graha_score = _graha_points(u_lord, p_lord)

    # ── Life area scores ──────────────────────────────────────────────────────
    love_score = (
        (gana_score / 6) * 0.40
        + (bhakoot_score / 7) * 0.35
        + (nadi_score / 8) * 0.25
    )
    career_score = (
        (graha_score / 5) * 0.60
        + (gana_score / 6) * 0.40
    )
    communication_score = (
        (nadi_score / 8) * 0.50
        + (graha_score / 5) * 0.50
    )
    trust_score = (
        (nadi_score / 8) * 0.50
        + (bhakoot_score / 7) * 0.50
    )
    overall_score = (nadi_score + gana_score + bhakoot_score + graha_score) / 26.0

    # ── OpenAI narrative ──────────────────────────────────────────────────────
    summary, strengths, challenges = await _generate_narrative(
        user_chart=user_chart,
        partner_chart=partner_chart,
        nadi=nadi_score,
        gana=gana_score,
        bhakoot=bhakoot_score,
        graha=graha_score,
        overall=overall_score,
    )

    return CompatibilityResult(
        overall_score=round(overall_score, 3),
        love_score=round(love_score, 3),
        career_score=round(career_score, 3),
        communication_score=round(communication_score, 3),
        trust_score=round(trust_score, 3),
        summary=summary,
        strengths=strengths,
        challenges=challenges,
    )


# ── Scoring helpers ───────────────────────────────────────────────────────────

def _gana_points(u: int, p: int) -> float:
    """
    0=Deva, 1=Manushya, 2=Rakshasa
    Same gana=6, Deva-Manushya=5, Manushya-Rakshasa=4, Deva-Rakshasa=0
    """
    if u == p:
        return 6.0
    pair = frozenset({u, p})
    if pair == frozenset({0, 1}):   # Deva–Manushya
        return 5.0
    if pair == frozenset({1, 2}):   # Manushya–Rakshasa
        return 4.0
    # Deva–Rakshasa
    return 0.0


def _graha_points(lord1: str, lord2: str) -> float:
    """
    Both same planet=5, mutual friends=4, one friend one neutral=3,
    both neutral=2, one friend one enemy=1, both enemies=0.
    """
    if lord1 == lord2:
        return 5.0

    l1_to_l2 = _relation(lord1, lord2)
    l2_to_l1 = _relation(lord2, lord1)

    combo = frozenset({l1_to_l2, l2_to_l1})
    if combo == frozenset({"friend"}):
        return 4.0
    if "friend" in combo and "neutral" in combo:
        return 3.0
    if combo == frozenset({"neutral"}):
        return 2.0
    if "friend" in combo and "enemy" in combo:
        return 1.0
    # both enemies or neutral+enemy
    return 0.0


def _relation(from_planet: str, to_planet: str) -> str:
    if to_planet in _FRIENDS.get(from_planet, frozenset()):
        return "friend"
    if to_planet in _ENEMIES.get(from_planet, frozenset()):
        return "enemy"
    return "neutral"


def _moon_longitude(chart: dict) -> float:
    for p in chart.get("planets", []):
        if p["name"] == "Moon":
            return float(p["longitude"])
    return 0.0


# ── OpenAI narrative ──────────────────────────────────────────────────────────

async def _generate_narrative(
    user_chart: dict,
    partner_chart: dict,
    nadi: float,
    gana: float,
    bhakoot: float,
    graha: float,
    overall: float,
) -> tuple[str, list[str], list[str]]:
    u_asc  = user_chart.get("ascendant", "Unknown")
    u_sun  = user_chart.get("sun_sign",  "Unknown")
    u_moon = user_chart.get("moon_sign", "Unknown")
    p_asc  = partner_chart.get("ascendant", "Unknown")
    p_sun  = partner_chart.get("sun_sign",  "Unknown")
    p_moon = partner_chart.get("moon_sign", "Unknown")

    prompt = (
        "You are a Vedic astrology expert. Analyse the following compatibility data and provide:\n"
        "1. A summary paragraph (150-200 words) describing the overall relationship compatibility.\n"
        "2. Three strengths (concise bullet-point phrases).\n"
        "3. Three challenges (concise bullet-point phrases).\n\n"
        f"Person 1 — Ascendant: {u_asc}, Sun: {u_sun}, Moon: {u_moon}\n"
        f"Person 2 — Ascendant: {p_asc}, Sun: {p_sun}, Moon: {p_moon}\n\n"
        f"Ashtakoot scores:\n"
        f"  Nadi (out of 8):         {nadi:.1f}\n"
        f"  Gana (out of 6):         {gana:.1f}\n"
        f"  Bhakoot (out of 7):      {bhakoot:.1f}\n"
        f"  Graha Maitri (out of 5): {graha:.1f}\n"
        f"  Overall (0-1 scale):     {overall:.2f}\n\n"
        "Reply in exactly this JSON format:\n"
        '{ "summary": "...", "strengths": ["...", "...", "..."], "challenges": ["...", "...", "..."] }'
    )

    try:
        content = await chat_complete(
            [{"role": "user", "content": prompt}],
            max_tokens=600,
            temperature=0.7,
            response_format={"type": "json_object"},
        )
        data = json.loads(content)
        summary    = data.get("summary", "")
        strengths  = data.get("strengths", [])[:3]
        challenges = data.get("challenges", [])[:3]
        return summary, strengths, challenges
    except Exception as exc:
        logger.warning("OpenAI compatibility narrative failed: %s", exc)
        pct = int(overall * 100)
        return (
            f"This compatibility analysis shows a {pct}% overall match based on Vedic Ashtakoot principles. "
            "The chart comparison reveals a relationship with its own unique blend of harmony and growth areas.",
            ["Shared karmic path", "Complementary energies", "Mutual growth potential"],
            ["Communication needs conscious effort", "Differing life approaches", "Emotional adjustment required"],
        )
