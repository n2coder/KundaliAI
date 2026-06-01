class CompatibilityModel {
  const CompatibilityModel({
    required this.overallScore,
    required this.loveScore,
    required this.careerScore,
    required this.communicationScore,
    required this.trustScore,
    required this.summary,
    required this.strengths,
    required this.challenges,
  });

  final double overallScore;
  final double loveScore;
  final double careerScore;
  final double communicationScore;
  final double trustScore;
  final String summary;
  final List<String> strengths;
  final List<String> challenges;

  factory CompatibilityModel.fromJson(Map<String, dynamic> j) => CompatibilityModel(
        overallScore: (j['overall_score'] as num).toDouble(),
        loveScore: (j['love_score'] as num).toDouble(),
        careerScore: (j['career_score'] as num).toDouble(),
        communicationScore: (j['communication_score'] as num).toDouble(),
        trustScore: (j['trust_score'] as num).toDouble(),
        summary: j['summary'] as String,
        strengths: (j['strengths'] as List<dynamic>).cast<String>(),
        challenges: (j['challenges'] as List<dynamic>).cast<String>(),
      );
}
