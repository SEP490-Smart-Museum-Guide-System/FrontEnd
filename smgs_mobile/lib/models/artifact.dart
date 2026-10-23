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
    this.exhibition = 'Trưng bày thường xuyên',
    this.modelUrl,
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
  final String exhibition;
  final String? modelUrl;

  factory Artifact.fromBackendJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '1';
    final name = json['name'] as String? ?? 'Hiện vật di sản';
    final galleryName = json['galleryName'] as String? ?? 'Phòng trưng bày';
    return Artifact(
      id: id,
      name: name,
      category: 'Hiện vật bảo tàng',
      museumId: json['museumId']?.toString() ?? '1',
      imageUrl: 'assets/images/ngoc-lu-web.jpg',
      period: 'Thời kỳ lịch sử',
      location: galleryName,
      summary: 'Hiện vật $name lưu giữ tại bảo tàng. Mã: ${json['code'] ?? id}',
      story: 'Hiện vật đã được kiểm định và cấp mã định danh số SMGS.',
      aiGuide: 'Bạn có thể hỏi Trợ lý AI về chi tiết hiện vật $name.',
      quizPrompt: 'Tìm hiểu về $name',
      modelUrl: null,
    );
  }
}
