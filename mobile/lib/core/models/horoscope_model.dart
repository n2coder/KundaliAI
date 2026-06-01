class HoroscopeModel {
  const HoroscopeModel({
    required this.period,
    required this.forDate,
    required this.language,
    required this.content,
  });

  final String period;
  final String forDate;
  final String language;
  final String content;

  factory HoroscopeModel.fromJson(Map<String, dynamic> j) => HoroscopeModel(
        period: j['period'] as String,
        forDate: j['for_date'] as String,
        language: j['language'] as String,
        content: j['content'] as String,
      );
}
