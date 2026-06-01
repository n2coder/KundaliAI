class InsightModel {
  const InsightModel({
    required this.category,
    required this.score,
    required this.content,
    required this.bestPeriods,
    required this.periodStart,
    required this.periodEnd,
  });

  final String category;
  final double score;
  final String content;
  final List<String> bestPeriods;
  final String periodStart;
  final String periodEnd;

  factory InsightModel.fromJson(Map<String, dynamic> j) => InsightModel(
        category: j['category'] as String,
        score: (j['score'] as num).toDouble(),
        content: j['content'] as String,
        bestPeriods: (j['best_periods'] as List<dynamic>)
            .map((p) => p as String)
            .toList(),
        periodStart: j['period_start'] as String,
        periodEnd: j['period_end'] as String,
      );

  int get scorePercent => (score * 100).round();
}
