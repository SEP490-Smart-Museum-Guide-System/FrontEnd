class Artifact {
  const Artifact({
    required this.id,
    required this.name,
    required this.category,
    required this.museumId,
    required this.imageUrl,
    required this.period,
    required this.location,
    required this.summary,
    required this.story,
    required this.aiGuide,
    required this.quizPrompt,
  });

  final String id;
  final String name;
  final String category;
  final String museumId;
  final String imageUrl;
  final String period;
  final String location;
  final String summary;
  final String story;
  final String aiGuide;
  final String quizPrompt;
}
