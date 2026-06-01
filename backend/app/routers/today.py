from __future__ import annotations

from datetime import date, datetime, timezone

import swisseph as swe
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..models import User
from ..models.daily_score import DailyScore
from ..services import today_service
from ..services.transit_service import get_transit_positions

router = APIRouter()

# ── Aspect-score weights (mirrors score_batch.py) ─────────────────────────────

_WEIGHTS = {
    "career": {"Jupiter": 0.35, "Saturn": 0.25, "Sun": 0.20, "Mars": 0.20},
    "love":   {"Venus":   0.40, "Moon":   0.30, "Jupiter": 0.30},
    "money":  {"Jupiter": 0.35, "Venus":  0.25, "Mercury": 0.25, "Saturn": 0.15},
    "health": {"Sun":     0.35, "Mars":   0.30, "Moon":    0.20, "Saturn": 0.15},
}

# ── Moon-phase constants ──────────────────────────────────────────────────────

_MOON_PHASES = [
    (0,   8,   "🌑", "New Moon",             "A powerful time for new beginnings and setting intentions."),
    (8,   83,  "🌒", "Waxing Crescent",      "Energy builds; plant seeds and take initial steps toward goals."),
    (83,  97,  "🌓", "First Quarter",        "Push through challenges; momentum is building."),
    (97,  172, "🌔", "Waxing Gibbous",       "Refine and adjust; you are close to fruition."),
    (172, 188, "🌕", "Full Moon",            "Heightened emotions and manifestation; release what no longer serves."),
    (188, 263, "🌖", "Waning Gibbous",       "Share your harvest; express gratitude and give back."),
    (263, 277, "🌗", "Last Quarter",         "Let go and forgive; clearing space for the new cycle."),
    (277, 360, "🌘", "Waning Crescent",      "Rest, reflect, and recuperate before the new cycle begins."),
]

# ── Planetary influence glyphs & sign effects ─────────────────────────────────

_PLANET_GLYPHS = {
    "Sun": "☀️", "Moon": "🌙", "Mars": "♂", "Mercury": "☿",
    "Jupiter": "♃", "Venus": "♀", "Saturn": "♄", "Rahu": "☊", "Ketu": "☋",
}

_SUN_EFFECTS: dict[str, str] = {
    "Aries":       "High vitality and leadership impulses; good for bold new ventures.",
    "Taurus":      "Focus on stability, finances, and sensory pleasures.",
    "Gemini":      "Communication shines; excellent for networking and learning.",
    "Cancer":      "Emotional sensitivity heightened; nurture home and family.",
    "Leo":         "Confidence peaks; creative expression and recognition favoured.",
    "Virgo":       "Attention to detail and health matters; refine your routines.",
    "Libra":       "Harmony, partnerships, and diplomacy in the spotlight.",
    "Scorpio":     "Deep transformation and research; hidden matters surface.",
    "Sagittarius": "Optimism and expansion; travel and higher learning are favoured.",
    "Capricorn":   "Career ambitions intensified; discipline brings rewards.",
    "Aquarius":    "Innovation and community focus; humanitarian causes thrive.",
    "Pisces":      "Intuition and spirituality deepened; creative imagination flows.",
}

_MOON_EFFECTS: dict[str, str] = {
    "Aries":       "Impulsive emotions; channel energy into action rather than reaction.",
    "Taurus":      "Emotional grounding; comfort, food, and nature restore the mind.",
    "Gemini":      "Restless mind; social interaction and variety satisfy the mood.",
    "Cancer":      "Strong nurturing instincts; home and family bring deep comfort.",
    "Leo":         "Need for appreciation; express yourself boldly and warmly.",
    "Virgo":       "Analytical emotions; service and helpfulness feel fulfilling.",
    "Libra":       "Desire for balance and beauty; relationships take centre stage.",
    "Scorpio":     "Intense emotional depths; transformation and deep bonds are highlighted.",
    "Sagittarius": "Adventurous mood; seek inspiration, philosophy, and freedom.",
    "Capricorn":   "Practical emotions; duty and achievement bring satisfaction.",
    "Aquarius":    "Detached yet humanitarian; ideals and group causes motivate.",
    "Pisces":      "Dreamy and empathic; meditation and creative pursuits nourish.",
}

# Vara lord effects
_VARA_LORD_EFFECTS: dict[str, str] = {
    "Sun":     "Authority and vitality are emphasised; good for leadership actions.",
    "Moon":    "Intuition and emotions guide the day; nurture relationships.",
    "Mars":    "Drive and courage are heightened; take decisive action.",
    "Mercury": "Intellect and communication flow easily; ideal for business matters.",
    "Jupiter": "Wisdom, optimism, and abundance are favoured; seek blessings.",
    "Venus":   "Love, beauty, and creativity flourish; enjoy life's pleasures.",
    "Saturn":  "Discipline and perseverance are rewarded; focus on long-term goals.",
}

_VARA_LORD = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"]  # 0=Sun

# ── Activity rules ────────────────────────────────────────────────────────────

_DO_TODAY: dict[str, list[str]] = {
    "Sunday":    [
        "Engage in leadership activities and assert your authority",
        "Make requests to those in power or authority figures",
        "Perform spiritual practices, prayers, or sun salutations",
        "Focus on personal ambitions and long-term goals",
    ],
    "Monday":    [
        "Address home or family matters requiring care",
        "Have nurturing, emotionally supportive conversations",
        "Start creative or artistic projects that feed the soul",
        "Connect with loved ones and strengthen relationships",
    ],
    "Tuesday":   [
        "Take courageous steps toward overcoming obstacles",
        "Engage in physical exercise, sports, or outdoor activity",
        "Tackle competitive challenges or difficult confrontations",
        "Begin new initiatives that require energy and drive",
    ],
    "Wednesday": [
        "Send important business communications or sign contracts",
        "Focus on learning, studying, or skill development",
        "Network with colleagues and attend meetings",
        "Plan, strategise, and organise upcoming projects",
    ],
    "Thursday":  [
        "Make financial investments or seek wealth-building advice",
        "Pursue education, attend workshops, or seek a guru's guidance",
        "Perform acts of charity and seek divine blessings",
        "Expand your knowledge base and engage in philosophical study",
    ],
    "Friday":    [
        "Express love and deepen romantic relationships",
        "Engage in creative work, art, or musical pursuits",
        "Beautify your home or personal appearance",
        "Enjoy social gatherings and celebratory events",
    ],
    "Saturday":  [
        "Practice discipline and adhere to long-term plans",
        "Perform acts of charity, especially for the underprivileged",
        "Attend to delayed tasks, debts, or old obligations",
        "Engage in meditation and grounding practices",
    ],
}

_AVOID_TODAY: dict[str, list[str]] = {
    "Sunday":    ["Starting new ventures in water-related fields", "Over-indulgence in leisure"],
    "Monday":    ["Making major financial decisions", "Engaging in confrontational arguments"],
    "Tuesday":   ["Beginning long journeys or travel", "Signing important contracts"],
    "Wednesday": ["Emotional confrontations without clear thinking", "Risky financial speculation"],
    "Thursday":  ["Petty gossip and unethical behaviour", "Rushing important long-term decisions"],
    "Friday":    ["Heavy physical labour or strenuous work", "Attending funerals or inauspicious events"],
    "Saturday":  ["Starting new projects or ventures", "Excessive speed or haste in decisions"],
}

SIGNS = [
    "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
    "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
]

_DEFAULT_LAT, _DEFAULT_LNG = 19.076, 72.878  # Mumbai fallback


# ── Schemas ───────────────────────────────────────────────────────────────────

class PanchangOut(BaseModel):
    tithi:     str
    nakshatra: str
    yoga:      str
    karana:    str
    vara:      str
    sunrise:   str
    sunset:    str


class MuhurtaOut(BaseModel):
    name:    str
    start:   str
    end:     str
    quality: str  # "auspicious" | "inauspicious"


class LifeScoresOut(BaseModel):
    love:         float
    career:       float
    health:       float
    money:        float
    day_score:    int
    day_title:    str
    day_subtitle: str


class MoonPhaseOut(BaseModel):
    emoji:       str
    name:        str
    description: str
    percent:     int
    sign:        str


class PlanetInfluenceOut(BaseModel):
    glyph:  str
    sign:   str
    effect: str


class TodayOut(BaseModel):
    date:               date
    panchang:           PanchangOut
    muhurtas:           list[MuhurtaOut]
    lucky_color:        str
    lucky_number:       int
    lucky_direction:    str
    lucky_gem:          str
    mantra:             str
    life_scores:        LifeScoresOut | None = None
    moon_phase:         MoonPhaseOut  | None = None
    do_today:           list[str]     | None = None
    avoid_today:        list[str]     | None = None
    planetary_influences: list[PlanetInfluenceOut] | None = None


# ── Endpoint ──────────────────────────────────────────────────────────────────

@router.get(
    "",
    response_model=TodayOut,
    summary="Panchang, muhurtas, personalised lucky elements, scores, and moon phase for today",
)
async def get_today(
    current_user: User         = Depends(get_current_user),
    db:           AsyncSession = Depends(get_db),
):
    """
    Returns today's Vedic panchang + muhurtas computed from the user's birth location.
    Lucky elements, daily life scores, moon phase, activity guidance, and
    planetary influences are also included when a birth chart exists.
    """
    today_data = await today_service.get_or_compute_today(
        user=current_user,
        birth_chart=current_user.birth_chart,
        db=db,
    )

    lang   = current_user.language.value if hasattr(current_user.language, "value") else str(current_user.language)
    mantra = today_data.mantra_hi if lang == "hi" else today_data.mantra_en

    today = today_data.for_date
    lat   = current_user.birth_lat or _DEFAULT_LAT
    lng   = current_user.birth_lng or _DEFAULT_LNG

    # ── Daily life scores ─────────────────────────────────────────────────────
    life_scores_out: LifeScoresOut | None = None
    if current_user.birth_chart is not None:
        ds = await _get_or_compute_daily_score(current_user, today, db)
        if ds:
            life_scores_out = _build_life_scores(ds)

    # ── Moon phase ────────────────────────────────────────────────────────────
    moon_phase_out = _compute_moon_phase(today)

    # ── Activity guidance ─────────────────────────────────────────────────────
    vara = today_data.panchang.get("vara", "Sunday") if isinstance(today_data.panchang, dict) else "Sunday"
    rahu_kaal = _find_rahu_kaal(today_data.muhurtas)
    do_list    = _DO_TODAY.get(vara, _DO_TODAY["Sunday"])
    avoid_base = _AVOID_TODAY.get(vara, [])
    avoid_list = ([f"Avoid starting new activities during Rahu Kaal ({rahu_kaal})"] + avoid_base)[:3]

    # ── Planetary influences ──────────────────────────────────────────────────
    planet_influences = _compute_planetary_influences(today, vara)

    return TodayOut(
        date=today_data.for_date,
        panchang=PanchangOut(**today_data.panchang),
        muhurtas=[MuhurtaOut(**m) for m in today_data.muhurtas],
        lucky_color=today_data.lucky_color or "",
        lucky_number=today_data.lucky_number or 1,
        lucky_direction=today_data.lucky_direction or "",
        lucky_gem=today_data.lucky_gem or "",
        mantra=mantra or "",
        life_scores=life_scores_out,
        moon_phase=moon_phase_out,
        do_today=do_list,
        avoid_today=avoid_list,
        planetary_influences=planet_influences,
    )


# ── Daily score helpers ───────────────────────────────────────────────────────

async def _get_or_compute_daily_score(
    user: User, today: date, db: AsyncSession
) -> DailyScore | None:
    """Return today's DailyScore from DB, or compute on-demand if missing."""
    result = await db.execute(
        select(DailyScore).where(
            DailyScore.user_id   == user.id,
            DailyScore.score_date == today,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        return existing

    if user.birth_chart is None:
        return None

    try:
        natal = {
            p["name"]: p["longitude"]
            for p in user.birth_chart.chart_data.get("planets", [])
        }
        transits = get_transit_positions(today)
        scores: dict[str, float] = {}
        for area, weights in _WEIGHTS.items():
            total = 0.0
            for planet, weight in weights.items():
                natal_lon   = natal.get(planet, 0.0)
                transit_lon = transits.get(planet, 0.0)
                total      += _aspect_score(natal_lon, transit_lon) * weight
            scores[area] = round(min(max(total, 0.0), 1.0), 3)
        scores["overall"] = round(sum(scores.values()) / len(scores), 3)

        daily_score = DailyScore(
            user_id=user.id,
            score_date=today,
            **scores,
        )
        db.add(daily_score)
        await db.commit()
        await db.refresh(daily_score)
        return daily_score
    except Exception:
        return None


def _aspect_score(natal_lon: float, transit_lon: float) -> float:
    diff = abs((transit_lon - natal_lon) % 360)
    if diff > 180:
        diff = 360 - diff
    if diff <= 8:             return 0.75
    if abs(diff - 60)  <= 6:  return 0.85
    if abs(diff - 90)  <= 6:  return 0.25
    if abs(diff - 120) <= 6:  return 0.95
    if abs(diff - 150) <= 6:  return 0.40
    if abs(diff - 180) <= 6:  return 0.20
    return 0.55


def _build_life_scores(ds: DailyScore) -> LifeScoresOut:
    overall = ds.overall
    if overall >= 0.80:
        title    = "An Exceptional Day"
        subtitle = "Bold Moves Favoured"
    elif overall >= 0.65:
        title    = "A Favourable Day for Progress"
        subtitle = "Move forward with confidence"
    elif overall >= 0.50:
        title    = "A Balanced Day"
        subtitle = "Trust the Process"
    elif overall >= 0.35:
        title    = "A Day for Patience & Reflection"
        subtitle = "Avoid hasty decisions"
    else:
        title    = "A Challenging Day"
        subtitle = "Proceed with Care"

    return LifeScoresOut(
        love=round(ds.love, 3),
        career=round(ds.career, 3),
        health=round(ds.health, 3),
        money=round(ds.money, 3),
        day_score=round(overall * 100),
        day_title=title,
        day_subtitle=subtitle,
    )


# ── Moon phase ────────────────────────────────────────────────────────────────

def _compute_moon_phase(for_date: date) -> MoonPhaseOut:
    jd = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL

    sun_pos,  _ = swe.calc_ut(jd, swe.SUN,  flags)
    moon_pos, _ = swe.calc_ut(jd, swe.MOON, flags)
    sun_lon  = sun_pos[0]  % 360
    moon_lon = moon_pos[0] % 360

    elongation = (moon_lon - sun_lon) % 360
    percent    = int(round((1 - abs(elongation - 180) / 180) * 100))

    emoji = "🌑"
    name  = "New Moon"
    desc  = "A powerful time for new beginnings and setting intentions."
    for lo, hi, em, nm, dc in _MOON_PHASES:
        if lo <= elongation < hi:
            emoji, name, desc = em, nm, dc
            break

    moon_sign_idx = int(moon_lon / 30) % 12
    sign          = SIGNS[moon_sign_idx]

    return MoonPhaseOut(emoji=emoji, name=name, description=desc, percent=percent, sign=sign)


# ── Planetary influences ──────────────────────────────────────────────────────

def _compute_planetary_influences(for_date: date, vara: str) -> list[PlanetInfluenceOut]:
    jd = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL

    sun_pos,  _ = swe.calc_ut(jd, swe.SUN,  flags)
    moon_pos, _ = swe.calc_ut(jd, swe.MOON, flags)
    sun_lon  = sun_pos[0]  % 360
    moon_lon = moon_pos[0] % 360

    sun_sign  = SIGNS[int(sun_lon  / 30) % 12]
    moon_sign = SIGNS[int(moon_lon / 30) % 12]

    vara_lord        = _vara_lord_name(vara)
    vara_lord_effect = _VARA_LORD_EFFECTS.get(vara_lord, "Today's planetary ruler brings its characteristic influence.")

    return [
        PlanetInfluenceOut(
            glyph=_PLANET_GLYPHS.get("Sun", "☀️"),
            sign=sun_sign,
            effect=_SUN_EFFECTS.get(sun_sign, f"Sun in {sun_sign} influences the day's energy."),
        ),
        PlanetInfluenceOut(
            glyph=_PLANET_GLYPHS.get("Moon", "🌙"),
            sign=moon_sign,
            effect=_MOON_EFFECTS.get(moon_sign, f"Moon in {moon_sign} colours today's emotional tone."),
        ),
        PlanetInfluenceOut(
            glyph=_PLANET_GLYPHS.get(vara_lord, "✦"),
            sign=_vara_lord_sign(vara_lord, for_date),
            effect=vara_lord_effect,
        ),
    ]


def _vara_lord_name(vara: str) -> str:
    mapping = {
        "Sunday": "Sun", "Monday": "Moon", "Tuesday": "Mars",
        "Wednesday": "Mercury", "Thursday": "Jupiter",
        "Friday": "Venus", "Saturday": "Saturn",
    }
    return mapping.get(vara, "Sun")


def _vara_lord_sign(lord: str, for_date: date) -> str:
    """Return current sidereal sign for the vara lord."""
    lord_swe = {
        "Sun": swe.SUN, "Moon": swe.MOON, "Mars": swe.MARS,
        "Mercury": swe.MERCURY, "Jupiter": swe.JUPITER,
        "Venus": swe.VENUS, "Saturn": swe.SATURN,
    }
    pid = lord_swe.get(lord)
    if pid is None:
        return "Unknown"
    jd = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL
    pos, _ = swe.calc_ut(jd, pid, flags)
    return SIGNS[int(pos[0] % 360 / 30) % 12]


# ── Muhurta helpers ───────────────────────────────────────────────────────────

def _find_rahu_kaal(muhurtas: list[dict]) -> str:
    """Return Rahu Kaal time window string, e.g. '09:00–10:30'."""
    for m in muhurtas:
        if m.get("name") == "Rahu Kalam":
            return f"{m['start']}–{m['end']}"
    return "check panchang"
