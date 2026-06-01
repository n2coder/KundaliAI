from __future__ import annotations
from datetime import date, datetime, timezone

import swisseph as swe
from timezonefinder import TimezoneFinder
from zoneinfo import ZoneInfo
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import User
from ..models.birth_chart import BirthChart
from ..models.today_data import TodayData

_tf = TimezoneFinder()

# ── Lookup tables ─────────────────────────────────────────────────────────────

_TITHIS = [
    "Pratipada", "Dvitiya", "Tritiya", "Chaturthi", "Panchami",
    "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
    "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",
    "Pratipada", "Dvitiya", "Tritiya", "Chaturthi", "Panchami",
    "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
    "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya",
]

_NAKSHATRAS = [
    "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
    "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni",
    "Uttara Phalguni", "Hasta", "Chitra", "Swati", "Vishakha",
    "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha", "Uttara Ashadha",
    "Shravana", "Dhanishtha", "Shatabhisha", "Purva Bhadrapada",
    "Uttara Bhadrapada", "Revati",
]

_YOGAS = [
    "Vishkamba", "Priti", "Ayushman", "Saubhagya", "Shobhana",
    "Atiganda", "Sukarman", "Dhriti", "Shula", "Ganda", "Vriddhi",
    "Dhruva", "Vyaghata", "Harshana", "Vajra", "Siddhi", "Vyatipata",
    "Variyana", "Parigha", "Shiva", "Siddha", "Sadhya", "Shubha",
    "Shukla", "Brahma", "Indra", "Vaidhriti",
]

_KARANAS = [
    "Bava", "Balava", "Kaulava", "Taitila", "Garaja",
    "Vanija", "Vishti", "Shakuni", "Chatushpada", "Nagava", "Kimstughna",
]

_VARAS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

# Lucky elements by weekday (0=Sun … 6=Sat)
_LUCKY_BY_VARA = [
    {"color": "Red",        "number": 1, "direction": "East",      "gem": "Ruby"},
    {"color": "White",      "number": 2, "direction": "North-West","gem": "Pearl"},
    {"color": "Coral Red",  "number": 9, "direction": "South",     "gem": "Red Coral"},
    {"color": "Green",      "number": 5, "direction": "North",     "gem": "Emerald"},
    {"color": "Yellow",     "number": 3, "direction": "North-East","gem": "Yellow Sapphire"},
    {"color": "White",      "number": 6, "direction": "South-East","gem": "Diamond"},
    {"color": "Dark Blue",  "number": 8, "direction": "West",      "gem": "Blue Sapphire"},
]

# Mantra by nakshatra lord (en, hi)
_NAKSHATRA_LORDS = [
    "Ketu", "Venus", "Sun", "Moon", "Mars",
    "Rahu", "Jupiter", "Saturn", "Mercury",
] * 3

_MANTRA = {
    "Sun":     ("Om Suraya Namah",          "ॐ सूर्याय नमः"),
    "Moon":    ("Om Chandraya Namah",        "ॐ चन्द्राय नमः"),
    "Mars":    ("Om Angarakaya Namah",       "ॐ अङ्गारकाय नमः"),
    "Mercury": ("Om Budhaya Namah",          "ॐ बुधाय नमः"),
    "Jupiter": ("Om Brihaspataye Namah",     "ॐ बृहस्पतये नमः"),
    "Venus":   ("Om Shukraya Namah",         "ॐ शुक्राय नमः"),
    "Saturn":  ("Om Shanaischaraya Namah",   "ॐ शनैश्चराय नमः"),
    "Rahu":    ("Om Rahave Namah",           "ॐ राहवे नमः"),
    "Ketu":    ("Om Ketave Namah",           "ॐ केतवे नमः"),
}

# Rahu Kalam / Yamaganda / Gulika portion indices (1-indexed, 8 portions in the day)
_RAHU_PORTION  = {0: 8, 1: 2, 2: 7, 3: 5, 4: 6, 5: 4, 6: 3}
_YAMA_PORTION  = {0: 5, 1: 4, 2: 3, 3: 2, 4: 1, 5: 7, 6: 6}
_GULI_PORTION  = {0: 7, 1: 6, 2: 5, 3: 4, 4: 3, 5: 2, 6: 1}

_DEFAULT_LAT, _DEFAULT_LNG = 19.076, 72.878  # Mumbai fallback


# ── Public API ────────────────────────────────────────────────────────────────

async def get_or_compute_today(
    user: User,
    birth_chart: BirthChart | None,
    db: AsyncSession,
) -> TodayData:
    today = date.today()

    result = await db.execute(
        select(TodayData).where(
            TodayData.user_id == user.id,
            TodayData.for_date == today,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        return existing

    lat = user.birth_lat or _DEFAULT_LAT
    lng = user.birth_lng or _DEFAULT_LNG

    panchang, meta = _compute_panchang(today, lat, lng)
    muhurtas = _compute_muhurtas(meta, lat, lng)
    lucky = _LUCKY_BY_VARA[meta["weekday"]]

    # Mantra from user's natal moon nakshatra, or today's nakshatra if no chart
    moon_nakshatra_idx = _moon_nakshatra_idx(birth_chart, meta)
    lord = _NAKSHATRA_LORDS[moon_nakshatra_idx]
    mantra_en, mantra_hi = _MANTRA.get(lord, ("Om Namah Shivaya", "ॐ नमः शिवाय"))

    today_data = TodayData(
        user_id=user.id,
        for_date=today,
        panchang=panchang,
        muhurtas=muhurtas,
        lucky_color=lucky["color"],
        lucky_number=lucky["number"],
        lucky_direction=lucky["direction"],
        lucky_gem=lucky["gem"],
        mantra_en=mantra_en,
        mantra_hi=mantra_hi,
    )
    db.add(today_data)
    await db.commit()
    await db.refresh(today_data)
    return today_data


# ── Panchang computation ──────────────────────────────────────────────────────

def _compute_panchang(for_date: date, lat: float, lng: float) -> tuple[dict, dict]:
    """
    Returns (panchang_dict_for_storage, meta_dict_with_jd_floats).
    meta is not stored — it's used internally for muhurta calculation.
    """
    jd_noon = swe.julday(for_date.year, for_date.month, for_date.day, 12.0)

    swe.set_sid_mode(swe.SIDM_LAHIRI)
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL

    sun_pos, _ = swe.calc_ut(jd_noon, swe.SUN, flags)
    moon_pos, _ = swe.calc_ut(jd_noon, swe.MOON, flags)
    sun_lon = sun_pos[0] % 360
    moon_lon = moon_pos[0] % 360

    tithi_num = int((moon_lon - sun_lon) % 360 / 12)  # 0-indexed
    nakshatra_idx = int(moon_lon / (360 / 27))
    yoga_idx = int((sun_lon + moon_lon) % 360 / (360 / 27))
    karana_num = int((moon_lon - sun_lon) % 360 / 6)
    weekday = int(jd_noon + 1.5) % 7  # 0=Sun

    # Sunrise/sunset
    jd_midnight = swe.julday(for_date.year, for_date.month, for_date.day, 0.0)
    rc_r, t_rise = swe.rise_trans(
        jd_midnight, swe.SUN, b"", swe.CALC_RISE, [lng, lat, 0], 1013.25, 15
    )
    rc_s, t_set = swe.rise_trans(
        jd_midnight, swe.SUN, b"", swe.CALC_SET, [lng, lat, 0], 1013.25, 15
    )

    sunrise_jd = t_rise[0] if rc_r == 0 else None
    sunset_jd = t_set[0] if rc_s == 0 else None
    tz_name = _tf.timezone_at(lat=lat, lng=lng) or "Asia/Kolkata"

    sunrise_str = _jd_to_local_time(sunrise_jd, tz_name) if sunrise_jd else "06:00"
    sunset_str = _jd_to_local_time(sunset_jd, tz_name) if sunset_jd else "18:30"

    panchang = {
        "tithi": _TITHIS[tithi_num % 30],
        "nakshatra": _NAKSHATRAS[nakshatra_idx],
        "yoga": _YOGAS[yoga_idx],
        "karana": _KARANAS[karana_num % 11],
        "vara": _VARAS[weekday],
        "sunrise": sunrise_str,
        "sunset": sunset_str,
    }
    meta = {
        "weekday": weekday,
        "sunrise_jd": sunrise_jd,
        "sunset_jd": sunset_jd,
        "tz_name": tz_name,
        "moon_nakshatra_idx": nakshatra_idx,
    }
    return panchang, meta


# ── Muhurta computation ───────────────────────────────────────────────────────

def _compute_muhurtas(meta: dict, lat: float, lng: float) -> list[dict]:
    sr = meta.get("sunrise_jd")
    ss = meta.get("sunset_jd")
    tz = meta.get("tz_name", "Asia/Kolkata")
    wd = meta.get("weekday", 0)

    if not sr or not ss:
        return []

    portion = (ss - sr) / 8  # each of 8 day portions in JD days

    def portion_window(n: int) -> tuple[float, float]:
        return sr + (n - 1) * portion, sr + n * portion

    def t(jd: float) -> str:
        return _jd_to_local_time(jd, tz)

    muhurtas = []

    # Brahma Muhurta: 1h 36m before sunrise, 48 min long
    brahma_end = sr - (12 / 1440)        # 12 min before sunrise
    brahma_start = brahma_end - (48 / 1440)
    muhurtas.append({"name": "Brahma Muhurta", "start": t(brahma_start),
                      "end": t(brahma_end), "quality": "auspicious"})

    # Abhijit: midday ± 24 min (most universally auspicious)
    mid = (sr + ss) / 2
    muhurtas.append({"name": "Abhijit Muhurta", "start": t(mid - 24 / 1440),
                      "end": t(mid + 24 / 1440), "quality": "auspicious"})

    # Rahu Kalam (avoid for new starts)
    rs, re = portion_window(_RAHU_PORTION[wd])
    muhurtas.append({"name": "Rahu Kalam", "start": t(rs),
                      "end": t(re), "quality": "inauspicious"})

    # Yamaganda (avoid)
    ys, ye = portion_window(_YAMA_PORTION[wd])
    muhurtas.append({"name": "Yamaganda", "start": t(ys),
                      "end": t(ye), "quality": "inauspicious"})

    # Gulika Kalam (mildly inauspicious)
    gs, ge = portion_window(_GULI_PORTION[wd])
    muhurtas.append({"name": "Gulika Kalam", "start": t(gs),
                      "end": t(ge), "quality": "inauspicious"})

    return muhurtas


# ── Helpers ───────────────────────────────────────────────────────────────────

def _jd_to_local_time(jd: float, tz_name: str) -> str:
    y, mo, d, h = swe.revjul(jd)
    hour = int(h)
    minute = int((h - hour) * 60)
    second = int(((h - hour) * 60 - minute) * 60)
    utc_dt = datetime(y, mo, d, hour, minute, second, tzinfo=timezone.utc)
    local_dt = utc_dt.astimezone(ZoneInfo(tz_name))
    return local_dt.strftime("%H:%M")


def _moon_nakshatra_idx(birth_chart: BirthChart | None, meta: dict) -> int:
    """Use natal moon nakshatra if chart available, else today's moon nakshatra."""
    if birth_chart:
        moon_lon = next(
            (p["longitude"] for p in birth_chart.chart_data.get("planets", [])
             if p["name"] == "Moon"),
            None,
        )
        if moon_lon is not None:
            return int(moon_lon / (360 / 27))
    return meta.get("moon_nakshatra_idx", 0)
