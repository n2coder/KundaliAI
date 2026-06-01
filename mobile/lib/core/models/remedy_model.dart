class RemedyModel {
  const RemedyModel({
    required this.title,
    required this.category,
    required this.icon,
    required this.description,
    required this.instructions,
    required this.duration,
    required this.difficulty,
    required this.planets,
  });

  final String title;
  final String category;
  final String icon;
  final String description;
  final List<String> instructions;
  final String duration;
  final String difficulty;
  final List<String> planets;

  factory RemedyModel.fromJson(Map<String, dynamic> j) => RemedyModel(
        title: j['title'] as String,
        category: j['category'] as String,
        icon: j['icon'] as String,
        description: j['description'] as String,
        instructions: (j['instructions'] as List<dynamic>)
            .map((i) => i as String)
            .toList(),
        duration: j['duration'] as String,
        difficulty: j['difficulty'] as String,
        planets: (j['planets'] as List<dynamic>)
            .map((p) => p as String)
            .toList(),
      );
}
