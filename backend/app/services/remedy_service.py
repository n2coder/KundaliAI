from __future__ import annotations
from dataclasses import dataclass, field

# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class Remedy:
    title: str
    category: str        # gemstone | mantra | fasting | charity | ritual
    icon: str
    description: str
    instructions: list[str]
    duration: str
    difficulty: str      # Easy | Medium | Dedicated
    planets: list[str]
    reason: str          # why this remedy was triggered (not shown to user)


# ── Debilitation signs ────────────────────────────────────────────────────────

_DEBILITATION = {
    "Sun":     "Libra",
    "Moon":    "Scorpio",
    "Mars":    "Cancer",
    "Mercury": "Pisces",
    "Jupiter": "Capricorn",
    "Venus":   "Virgo",
    "Saturn":  "Aries",
}

# ── Remedy catalogue (one per planet / condition) ─────────────────────────────

_PLANET_REMEDIES: dict[str, list[Remedy]] = {
    "Sun": [
        Remedy(
            title="Wear Ruby Gemstone",
            category="gemstone", icon="💎",
            description="Ruby strengthens the Sun, enhancing confidence, vitality, and leadership.",
            instructions=[
                "Wear a natural Ruby of at least 3 carats in gold.",
                "Set it on your ring finger, right hand.",
                "Energise on a Sunday morning during sunrise.",
                "Recite 'Om Suraya Namah' 108 times before wearing.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Sun"], reason="Sun debilitated in Libra",
        ),
        Remedy(
            title="Sunday Fast for Sun",
            category="fasting", icon="🌞",
            description="Fasting on Sundays strengthens the Sun's energy in your chart.",
            instructions=[
                "Fast from sunrise to sunset on Sundays.",
                "Consume only fruits and water.",
                "Offer water to the Sun at sunrise facing East.",
                "Recite the Aditya Hridayam stotram if possible.",
            ],
            duration="Every Sunday", difficulty="Easy",
            planets=["Sun"], reason="Sun debilitated in Libra",
        ),
    ],
    "Moon": [
        Remedy(
            title="Wear Natural Pearl",
            category="gemstone", icon="🪨",
            description="Pearl balances the Moon's energy, bringing emotional stability and mental peace.",
            instructions=[
                "Wear a natural saltwater pearl of at least 4 carats in silver.",
                "Set it on your little finger, right hand.",
                "Wear on a Monday during the waxing moon (Shukla Paksha).",
                "Recite 'Om Chandraya Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Moon"], reason="Moon debilitated in Scorpio",
        ),
        Remedy(
            title="Monday Fast for Moon",
            category="fasting", icon="🌙",
            description="Fasting on Mondays pacifies the Moon and promotes emotional well-being.",
            instructions=[
                "Fast on Mondays — consume only milk, curd, and fruits.",
                "Visit a Shiva temple and offer milk to the Shivalinga.",
                "Chant 'Om Namah Shivaya' 108 times.",
                "Wear white or silver clothing.",
            ],
            duration="Every Monday", difficulty="Easy",
            planets=["Moon"], reason="Moon debilitated in Scorpio",
        ),
    ],
    "Mars": [
        Remedy(
            title="Wear Red Coral",
            category="gemstone", icon="🔴",
            description="Red Coral strengthens Mars, boosting courage, energy, and overcoming obstacles.",
            instructions=[
                "Wear natural Italian Red Coral of at least 6 carats in gold or copper.",
                "Set it on your ring finger, right hand.",
                "Wear on a Tuesday during the waxing moon.",
                "Recite 'Om Angarakaya Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Mars"], reason="Mars debilitated or afflicted",
        ),
        Remedy(
            title="Hanuman Chalisa Recitation",
            category="mantra", icon="🙏",
            description="Reciting the Hanuman Chalisa on Tuesdays pacifies Mars and removes obstacles.",
            instructions=[
                "Recite the Hanuman Chalisa on Tuesday mornings.",
                "Light a diya with mustard oil before the recitation.",
                "Offer red flowers to Hanuman.",
                "Donate red lentils (masoor dal) to the needy.",
            ],
            duration="Every Tuesday", difficulty="Easy",
            planets=["Mars"], reason="Mars debilitated or afflicted",
        ),
    ],
    "Mercury": [
        Remedy(
            title="Wear Emerald",
            category="gemstone", icon="💚",
            description="Emerald strengthens Mercury, enhancing intellect, communication, and business acumen.",
            instructions=[
                "Wear a natural Emerald of at least 3 carats in gold.",
                "Set it on your little finger, right hand.",
                "Wear on a Wednesday morning.",
                "Recite 'Om Budhaya Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Mercury"], reason="Mercury debilitated in Pisces",
        ),
        Remedy(
            title="Wednesday Charity",
            category="charity", icon="💚",
            description="Donating green items on Wednesdays strengthens Mercury's positive influence.",
            instructions=[
                "Donate green vegetables, green clothes, or green moong dal.",
                "Feed parrots or green birds on Wednesdays.",
                "Recite Vishnu Sahasranama on Wednesdays.",
            ],
            duration="Every Wednesday", difficulty="Easy",
            planets=["Mercury"], reason="Mercury debilitated in Pisces",
        ),
    ],
    "Jupiter": [
        Remedy(
            title="Wear Yellow Sapphire",
            category="gemstone", icon="💛",
            description="Yellow Sapphire strengthens Jupiter, bringing wisdom, prosperity, and good fortune.",
            instructions=[
                "Wear a natural Yellow Sapphire (Pukhraj) of at least 4 carats in gold.",
                "Set it on your index finger, right hand.",
                "Wear on a Thursday morning during Shukla Paksha.",
                "Recite 'Om Brihaspataye Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Jupiter"], reason="Jupiter debilitated in Capricorn",
        ),
        Remedy(
            title="Thursday Fast for Jupiter",
            category="fasting", icon="🟡",
            description="Fasting on Thursdays strengthens Jupiter and improves fortune and knowledge.",
            instructions=[
                "Fast on Thursdays — eat only once, yellow food preferred (chana dal, banana).",
                "Visit a Vishnu or Brihaspati temple.",
                "Donate yellow items: turmeric, yellow cloth, gold.",
                "Water a banana tree and light a lamp beside it.",
            ],
            duration="Every Thursday", difficulty="Easy",
            planets=["Jupiter"], reason="Jupiter debilitated in Capricorn",
        ),
    ],
    "Venus": [
        Remedy(
            title="Wear Diamond or White Sapphire",
            category="gemstone", icon="✨",
            description="Diamond or White Sapphire strengthens Venus, enhancing love, beauty, and luxury.",
            instructions=[
                "Wear a natural Diamond (0.5+ ct) or White Sapphire (4+ ct) in platinum or silver.",
                "Set it on your middle finger, right hand.",
                "Wear on a Friday morning.",
                "Recite 'Om Shukraya Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Venus"], reason="Venus debilitated in Virgo",
        ),
        Remedy(
            title="Lakshmi Puja on Friday",
            category="ritual", icon="🌸",
            description="Friday Lakshmi worship strengthens Venus and attracts love and prosperity.",
            instructions=[
                "Light a ghee lamp before a Lakshmi idol on Fridays.",
                "Offer white flowers (lotus or jasmine).",
                "Recite Shri Suktam or Lakshmi Stotra.",
                "Donate white sweets or milk-based sweets to women.",
            ],
            duration="Every Friday", difficulty="Easy",
            planets=["Venus"], reason="Venus debilitated in Virgo",
        ),
    ],
    "Saturn": [
        Remedy(
            title="Wear Blue Sapphire",
            category="gemstone", icon="💙",
            description="Blue Sapphire (Neelam) is Saturn's gemstone. Always test for 3 days before wearing permanently.",
            instructions=[
                "Test: keep Blue Sapphire under your pillow for 3 nights. If positive signs appear, proceed.",
                "Wear a natural Blue Sapphire of 4+ carats in silver or gold.",
                "Set it on your middle finger, right hand.",
                "Wear on a Saturday during Saturn's hora.",
                "Recite 'Om Shanaischaraya Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Dedicated",
            planets=["Saturn"], reason="Saturn debilitated or afflicted",
        ),
        Remedy(
            title="Oil Lamp on Saturday",
            category="ritual", icon="🪔",
            description="Lighting a sesame oil lamp on Saturdays pacifies Saturn and reduces its malefic effects.",
            instructions=[
                "Light a lamp filled with sesame (til) oil every Saturday evening.",
                "Place it under a peepal tree or at a Shani temple.",
                "Donate black sesame seeds, mustard oil, or black cloth.",
                "Recite the Shani Chalisa or 'Om Shanaishcharaya Namah'.",
            ],
            duration="Every Saturday", difficulty="Easy",
            planets=["Saturn"], reason="Saturn debilitated or afflicted",
        ),
    ],
    "Rahu": [
        Remedy(
            title="Wear Hessonite Garnet",
            category="gemstone", icon="🟤",
            description="Hessonite (Gomed) pacifies Rahu, reducing confusion, obsession, and unexpected setbacks.",
            instructions=[
                "Wear a natural Hessonite Garnet of 6+ carats in gold or silver.",
                "Set it on your middle finger, right hand.",
                "Wear on a Saturday or Wednesday evening.",
                "Recite 'Om Rahave Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Rahu"], reason="Rahu in chart",
        ),
        Remedy(
            title="Durga Mantra for Rahu",
            category="mantra", icon="🔱",
            description="Chanting Durga mantra neutralises Rahu's shadowy influence and provides protection.",
            instructions=[
                "Chant 'Om Dum Durgaye Namah' 108 times daily.",
                "Best done on Saturdays or during Rahu kalam.",
                "Offer blue flowers to Durga.",
                "Donate blankets or blue cloth to the needy.",
            ],
            duration="Daily — 40 days minimum", difficulty="Medium",
            planets=["Rahu"], reason="Rahu in chart",
        ),
    ],
    "Ketu": [
        Remedy(
            title="Wear Cat's Eye",
            category="gemstone", icon="🟢",
            description="Cat's Eye (Lehsunia) pacifies Ketu, reducing sudden losses and spiritual confusion.",
            instructions=[
                "Wear a natural Chrysoberyl Cat's Eye of 4+ carats in silver.",
                "Set it on your middle or little finger, right hand.",
                "Wear on a Tuesday or Saturday.",
                "Recite 'Om Ketave Namah' 108 times.",
            ],
            duration="Ongoing", difficulty="Medium",
            planets=["Ketu"], reason="Ketu in chart",
        ),
        Remedy(
            title="Ganesha Mantra for Ketu",
            category="mantra", icon="🐘",
            description="Ganesha removes obstacles and pacifies Ketu's disruptive energy.",
            instructions=[
                "Chant 'Om Gam Ganapataye Namah' 108 times daily.",
                "Offer red flowers and modak to Ganesha on Tuesdays.",
                "Donate blankets or woollen items to the poor.",
            ],
            duration="Daily — 21 days minimum", difficulty="Easy",
            planets=["Ketu"], reason="Ketu in chart",
        ),
    ],
}

# Universal remedies given to all users (always included)
_UNIVERSAL_REMEDIES = [
    Remedy(
        title="Recite Gayatri Mantra",
        category="mantra", icon="🌅",
        description="The Gayatri Mantra is the most powerful Vedic mantra, strengthening all planetary energies.",
        instructions=[
            "Chant 'Om Bhur Bhuva Swaha, Tat Savitur Varenyam...' 108 times daily.",
            "Best recited at sunrise facing East.",
            "Use a Rudraksha mala for counting.",
            "Continue for at least 40 days for full benefit.",
        ],
        duration="Daily", difficulty="Easy",
        planets=["Sun", "Moon", "All"], reason="Universal remedy",
    ),
]


# ── Public API ────────────────────────────────────────────────────────────────

def get_remedies(chart_data: dict) -> list[Remedy]:
    """
    Rule-based remedy selection from birth chart.
    Returns 4-6 remedies: triggered by debilitated planets + universal base set.
    """
    planets = {p["name"]: p for p in chart_data.get("planets", [])}
    houses = {h["house"]: h["sign"] for h in chart_data.get("houses", [])}

    selected: list[Remedy] = []
    seen_planets: set[str] = set()

    # Debilitated planets → add their remedy set
    for planet, debil_sign in _DEBILITATION.items():
        if planets.get(planet, {}).get("sign") == debil_sign:
            if planet not in seen_planets:
                selected.extend(_PLANET_REMEDIES[planet])
                seen_planets.add(planet)

    # Rahu/Ketu always get one remedy each (they're always in the chart)
    for shadow in ("Rahu", "Ketu"):
        if shadow not in seen_planets:
            # Only include one remedy for Rahu/Ketu if no debilitated planet already triggered them
            remedies = _PLANET_REMEDIES[shadow]
            # Include only the mantra (lighter remedy) unless chart is heavily afflicted
            selected.append(remedies[1])  # mantra remedy
            seen_planets.add(shadow)

    # Saturn in 7th or 10th house — add extra Saturn ritual
    saturn_house = _planet_house(planets.get("Saturn", {}), houses)
    if saturn_house in (7, 10) and "Saturn" not in seen_planets:
        selected.extend(_PLANET_REMEDIES["Saturn"])
        seen_planets.add("Saturn")

    # Always include Gayatri
    selected.extend(_UNIVERSAL_REMEDIES)

    # Cap at 6 remedies — prioritise debilitated planets
    return selected[:6]


def remedy_to_dict(r: Remedy) -> dict:
    return {
        "title": r.title,
        "category": r.category,
        "icon": r.icon,
        "description": r.description,
        "instructions": r.instructions,
        "duration": r.duration,
        "difficulty": r.difficulty,
        "planets": r.planets,
    }


# ── Helper ────────────────────────────────────────────────────────────────────

def _planet_house(planet_dict: dict, houses: dict[int, str]) -> int | None:
    sign = planet_dict.get("sign")
    if not sign:
        return None
    for house_num, house_sign in houses.items():
        if house_sign == sign:
            return house_num
    return None
