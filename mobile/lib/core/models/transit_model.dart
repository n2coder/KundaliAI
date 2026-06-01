class TransitModel {
  const TransitModel({
    required this.planet,
    required this.glyph,
    required this.from,
    required this.to,
    required this.period,
    required this.impact,
    required this.description,
    required this.advice,
  });

  final String planet;
  final String glyph;
  final String from;
  final String to;
  final String period;
  final String impact; // "High" | "Medium" | "Low"
  final String description;
  final String advice;

  factory TransitModel.fromJson(Map<String, dynamic> j) => TransitModel(
        planet: j['planet'] as String,
        glyph: j['glyph'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        period: j['period'] as String,
        impact: j['impact'] as String,
        description: j['description'] as String,
        advice: j['advice'] as String,
      );
}
