import '../models/artifact.dart';
import 'backend_api.dart';

class GuideTurn {
  const GuideTurn(this.role, this.text);
  final String role;
  final String text;
  Map<String, String> toJson() => {'role': role, 'text': text};
}

class GuideSource {
  const GuideSource(this.contentVersionId, this.versionNo, this.title);
  final int contentVersionId;
  final int versionNo;
  final String title;
}

class GuideReply {
  const GuideReply({
    required this.text,
    required this.supported,
    this.sources = const [],
  });
  final String text;
  final bool supported;
  final List<GuideSource> sources;
}

abstract class AiGuideService {
  List<String> get suggestions;
  Future<GuideReply> answer(
    Artifact artifact,
    String question, {
    List<GuideTurn> history = const [],
  });
}

class BackendAiGuideService implements AiGuideService {
  @override
  List<String> get suggestions => const [
    'Hiện vật này có ý nghĩa gì?',
    'Hiện vật thuộc thời kỳ nào?',
    'Tôi nên chú ý chi tiết nào?',
  ];

  @override
  Future<GuideReply> answer(
    Artifact artifact,
    String question, {
    List<GuideTurn> history = const [],
  }) async {
    final id = int.tryParse(artifact.id);
    if (id == null || id <= 0) {
      throw const FormatException(
        'Hãy chọn hiện vật trong bộ sưu tập bảo tàng để hỏi trợ lý.',
      );
    }
    if (question.trim().isEmpty || question.length > 1000) {
      throw const FormatException('Vui lòng nhập câu hỏi tối đa 1.000 ký tự.');
    }
    final data = await BackendApi.request(
      'artifacts/$id/guide/messages',
      method: 'POST',
      timeout: const Duration(seconds: 65),
      body: {
        'question': question.trim(),
        'history': history
            .skip(history.length > 8 ? history.length - 8 : 0)
            .map((t) => t.toJson())
            .toList(),
      },
    );
    if (data is! Map<String, dynamic> ||
        data['artifactId'] != id ||
        data['answer'] is! String ||
        (data['answer'] as String).trim().isEmpty ||
        (data['answer'] as String).length > 4000 ||
        data['supported'] is! bool ||
        data['sources'] is! List) {
      throw const FormatException(
        'Phản hồi trợ lý không hợp lệ. Vui lòng thử lại.',
      );
    }
    final supported = data['supported'] as bool;
    final sources = <GuideSource>[];
    for (final item in data['sources'] as List) {
      if (item is! Map<String, dynamic> ||
          item['contentVersionId'] is! int ||
          item['versionNo'] is! int ||
          item['title'] is! String ||
          item['languageCode'] != 'vi') {
        throw const FormatException('Nguồn tham khảo của trợ lý không hợp lệ.');
      }
      sources.add(
        GuideSource(
          item['contentVersionId'] as int,
          item['versionNo'] as int,
          item['title'] as String,
        ),
      );
    }
    if ((supported && sources.isEmpty) || (!supported && sources.isNotEmpty)) {
      throw const FormatException(
        'Phản hồi trợ lý thiếu nguồn nội dung phù hợp.',
      );
    }
    return GuideReply(
      text: (data['answer'] as String).trim(),
      supported: supported,
      sources: sources,
    );
  }
}
