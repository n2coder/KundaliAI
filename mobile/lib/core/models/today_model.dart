class PanchangModel {
  const PanchangModel({
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.vara,
    required this.sunrise,
    required this.sunset,
  });

  final String tithi;
  final String nakshatra;
  final String yoga;
  final String karana;
  final String vara;
  final String sunrise;
  final String sunset;

  factory PanchangModel.fromJson(Map<String, dynamic> j) => PanchangModel(
        tithi: j['tithi'] as String,
        nakshatra: j['nakshatra'] as String,
        yoga: j['yoga'] as String,
        karana: j['karana'] as String,
        vara: j['vara'] as String,
        sunrise: j['sunrise'] as String,
        sunset: j['sunset'] as String,
      );
}

class MuhurtaModel {
  const MuhurtaModel({
    required this.name,
    required this.start,
    required this.end,
    required this.quality,
  });

  final String name;
  final String start;
  final String end;
  final String quality; // "auspicious" | "inauspicious"

  bool get isAuspicious => quality == 'auspicious';

  factory MuhurtaModel.fromJson(Map<String, dynamic> j) => MuhurtaModel(
        name: j['name'] as String,
        start: j['start'] as String,
        end: j['end'] as String,
        quality: j['quality'] as String,
      );
}

class LifeScoresModel {
  const LifeScoresModel({
    required this.love,
    required this.career,
    required this.health,
    required this.money,
    required this.dayScore,
    required this.dayTitle,
    this.daySubtitle = '',
  });

  final double love;
  final double career;
  final double health;
  final double money;
  final int dayScore;
  final String dayTitle;
  final String daySubtitle;

  factory LifeScoresModel.fromJson(Map<String, dynamic> j) => LifeScoresModel(
        love: (j['love'] as num).toDouble(),
        career: (j['career'] as num).toDouble(),
        health: (j['health'] as num).toDouble(),
        money: (j['money'] as num).toDouble(),
        dayScore: j['day_score'] as int,
        dayTitle: j['day_title'] as String,
        daySubtitle: (j['day_subtitle'] as String?) ?? '',
      );
}

class MoonPhaseModel {
  const MoonPhaseModel({
    required this.emoji,
    required this.name,
    required this.description,
    required this.percent,
    required this.sign,
  });

  final String emoji;
  final String name;
  final String description;
  final int percent;
  final String sign;

  factory MoonPhaseModel.fromJson(Map<String, dynamic> j) => MoonPhaseModel(
        emoji: j['emoji'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        percent: j['percent'] as int,
        sign: j['sign'] as String,
      );
}

class PlanetaryInfluenceModel {
  const PlanetaryInfluenceModel({
    required this.glyph,
    required this.sign,
    required this.effect,
  });

  final String glyph;
  final String sign;
  final String effect;

  factory PlanetaryInfluenceModel.fromJson(Map<String, dynamic> j) =>
      PlanetaryInfluenceModel(
        glyph: j['glyph'] as String,
        sign: j['sign'] as String,
        effect: j['effect'] as String,
      );
}

class TodayModel {
  const TodayModel({
    required this.date,
    required this.panchang,
    required this.muhurtas,
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyDirection,
    required this.luckyGem,
    required this.mantra,
    this.lifeScores,
    this.moonPhase,
    this.doToday,
    this.avoidToday,
    this.planetaryInfluences,
  });

  final String date;
  final PanchangModel panchang;
  final List<MuhurtaModel> muhurtas;
  final String luckyColor;
  final int luckyNumber;
  final String luckyDirection;
  final String luckyGem;
  final String mantra;
  final LifeScoresModel? lifeScores;
  final MoonPhaseModel? moonPhase;
  final List<String>? doToday;
  final List<String>? avoidToday;
  final List<PlanetaryInfluenceModel>? planetaryInfluences;

  factory TodayModel.fromJson(Map<String, dynamic> j) => TodayModel(
        date: j['date'] as String,
        panchang:
            PanchangModel.fromJson(j['panchang'] as Map<String, dynamic>),
        muhurtas: (j['muhurtas'] as List<dynamic>)
            .map((m) => MuhurtaModel.fromJson(m as Map<String, dynamic>))
            .toList(),
        luckyColor: j['lucky_color'] as String,
        luckyNumber: j['lucky_number'] as int,
        luckyDirection: j['lucky_direction'] as String,
        luckyGem: j['lucky_gem'] as String,
        mantra: j['mantra'] as String,
        lifeScores: j['life_scores'] != null
            ? LifeScoresModel.fromJson(
                j['life_scores'] as Map<String, dynamic>)
            : null,
        moonPhase: j['moon_phase'] != null
            ? MoonPhaseModel.fromJson(
                j['moon_phase'] as Map<String, dynamic>)
            : null,
        doToday: (j['do_today'] as List<dynamic>?)?.cast<String>(),
        avoidToday: (j['avoid_today'] as List<dynamic>?)?.cast<String>(),
        planetaryInfluences:
            (j['planetary_influences'] as List<dynamic>?)
                ?.map((p) => PlanetaryInfluenceModel.fromJson(
                    p as Map<String, dynamic>))
                .toList(),
      );
}
