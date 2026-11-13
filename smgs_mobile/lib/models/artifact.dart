import '../core/network/api_config.dart';

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
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final String category;
  final String museumId;
  final String imageUrl;
  final List<String> imageUrls;

  List<String> get photos => <String>{
    ...imageUrls,
    if (imageUrl.isNotEmpty) imageUrl,
  }.where((url) => url.trim().isNotEmpty).toList();
  final String period;
  final String location;
  final String summary;
  final String story;
  final String aiGuide;
  final String quizPrompt;
  final String exhibition;
  final String? modelUrl;

  factory Artifact.fromBackendJson(Map<String, dynamic> json) {
    final media =
        (json['media'] as List? ?? [])
            .whereType<Map>()
            .where(
              (item) => item['mediaType']?.toString().toLowerCase() == 'image',
            )
            .toList()
          ..sort(
            (a, b) => ((a['sortOrder'] as num?) ?? 0).compareTo(
              (b['sortOrder'] as num?) ?? 0,
            ),
          );
    final images = media
        .map((item) => ApiConfig.mediaUrl(item['fileUrl'] as String?))
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
    final id = json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? 'Hiện vật di sản';
    final galleryName = json['galleryName'] as String? ?? 'Phòng trưng bày';
    return Artifact(
      id: id,
      name: name,
      category: 'Hiện vật bảo tàng',
      museumId: json['museumId']?.toString() ?? '',
      imageUrl: images.firstOrNull ?? '',
      imageUrls: images,
      period: json['period'] as String? ?? '',
      location: galleryName,
      summary: 'Hiện vật $name lưu giữ tại bảo tàng. Mã: ${json['code'] ?? id}',
      story: json['description'] as String? ?? '',
      aiGuide: 'Bạn có thể hỏi Trợ lý AI về chi tiết hiện vật $name.',
      quizPrompt: 'Tìm hiểu về $name',
      modelUrl: json['model3D'] == null
          ? null
          : ApiConfig.mediaUrl(json['model3D']?['modelUrl'] as String?),
    );
  }
}
