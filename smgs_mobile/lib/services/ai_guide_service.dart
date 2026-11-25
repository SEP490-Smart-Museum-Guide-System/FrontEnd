import '../models/artifact.dart';
import 'backend_api.dart';

class GuideTurn {
  const GuideTurn(this.role, this.text);
  final String role;
  final String text;
  Map<String, String> toJson() => {'role': role, 'text': text};
}

class GuideSource {
  const GuideSource(this.contentVersionId, this.versionNo, this.title, [this.languageCode = 'vi']);
  final int contentVersionId;
  final int versionNo;
  final String title;
  final String languageCode;
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

class GuideChatMessage {
  const GuideChatMessage({
    required this.id,
    required this.artifactId,
    required this.artifactName,
    required this.question,
    required this.answer,
    required this.supported,
    required this.createdAt,
    this.sources = const [],
  });

  final int id;
  final int artifactId;
  final String artifactName;
  final String question;
  final String answer;
  final bool supported;
  final DateTime createdAt;
  final List<GuideSource> sources;

  factory GuideChatMessage.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as List? ?? [];
    return GuideChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      artifactId: (json['artifactId'] as num?)?.toInt() ?? 0,
      artifactName: json['artifactName'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      supported: json['supported'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sources: rawSources
          .whereType<Map>()
          .map((s) {
            final m = Map<String, dynamic>.from(s);
            return GuideSource(
              (m['contentVersionId'] as num?)?.toInt() ?? 0,
              (m['versionNo'] as num?)?.toInt() ?? 0,
              m['title'] as String? ?? '',
              m['languageCode'] as String? ?? 'vi',
            );
          })
          .toList(),
    );
  }
}

class GuideConversationItem {
  const GuideConversationItem({
    required this.artifactId,
    required this.artifactName,
    required this.museumId,
    required this.museumName,
    required this.exchangeCount,
    required this.lastQuestion,
    required this.lastAnswer,
    required this.lastSupported,
    required this.lastAskedAt,
  });

  final int artifactId;
  final String artifactName;
  final int museumId;
  final String museumName;
  final int exchangeCount;
  final String lastQuestion;
  final String lastAnswer;
  final bool lastSupported;
  final DateTime lastAskedAt;

  factory GuideConversationItem.fromJson(Map<String, dynamic> json) {
    return GuideConversationItem(
      artifactId: (json['artifactId'] as num?)?.toInt() ?? 0,
      artifactName: json['artifactName'] as String? ?? '',
      museumId: (json['museumId'] as num?)?.toInt() ?? 0,
      museumName: json['museumName'] as String? ?? '',
      exchangeCount: (json['exchangeCount'] as num?)?.toInt() ?? 0,
      lastQuestion: json['lastQuestion'] as String? ?? '',
      lastAnswer: json['lastAnswer'] as String? ?? '',
      lastSupported: json['lastSupported'] as bool? ?? true,
      lastAskedAt: json['lastAskedAt'] != null
          ? DateTime.tryParse(json['lastAskedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

abstract class AiGuideService {
  List<String> get suggestions;
  Future<GuideReply> answer(
    Artifact artifact,
    String question, {
    List<GuideTurn> history = const [],
    bool useSavedHistory = true,
  });
  Future<List<GuideChatMessage>> getArtifactHistory(int artifactId, {int limit = 50});
  Future<int> clearArtifactHistory(int artifactId);
  Future<List<GuideConversationItem>> getMyConversations({int? museumId, int page = 1, int pageSize = 20});
  Future<List<GuideChatMessage>> getMyMessagesFeed({int? museumId, int? artifactId, int page = 1, int pageSize = 20});
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
    bool useSavedHistory = true,
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
        if (useSavedHistory) 'useSavedHistory': true,
      },
    );
    if (data is! Map ||
        (data['artifactId'] as num?)?.toInt() != id ||
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
    for (final rawItem in data['sources'] as List) {
      if (rawItem is! Map) {
        throw const FormatException('Nguồn tham khảo của trợ lý không hợp lệ.');
      }
      final item = Map<String, dynamic>.from(rawItem);
      final cvId = (item['contentVersionId'] as num?)?.toInt();
      final vNo = (item['versionNo'] as num?)?.toInt();
      final title = item['title'] as String?;
      final lang = (item['languageCode'] as String?) ?? 'vi';
      if (cvId == null || vNo == null || title == null) {
        throw const FormatException('Nguồn tham khảo của trợ lý không hợp lệ.');
      }
      sources.add(
        GuideSource(
          cvId,
          vNo,
          title,
          lang,
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

  @override
  Future<List<GuideChatMessage>> getArtifactHistory(int artifactId, {int limit = 50}) async {
    final data = await BackendApi.request('artifacts/$artifactId/guide/messages?limit=$limit');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => GuideChatMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  @override
  Future<int> clearArtifactHistory(int artifactId) async {
    final data = await BackendApi.request(
      'artifacts/$artifactId/guide/messages',
      method: 'DELETE',
    );
    if (data is num) return data.toInt();
    return 0;
  }

  @override
  Future<List<GuideConversationItem>> getMyConversations({int? museumId, int page = 1, int pageSize = 20}) async {
    final query = <String>[];
    if (museumId != null) query.add('museumId=$museumId');
    query.add('page=$page');
    query.add('pageSize=$pageSize');
    final data = await BackendApi.request('guide/conversations/me?${query.join('&')}');
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((m) => GuideConversationItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  @override
  Future<List<GuideChatMessage>> getMyMessagesFeed({int? museumId, int? artifactId, int page = 1, int pageSize = 20}) async {
    final query = <String>[];
    if (museumId != null) query.add('museumId=$museumId');
    if (artifactId != null) query.add('artifactId=$artifactId');
    query.add('page=$page');
    query.add('pageSize=$pageSize');
    final data = await BackendApi.request('guide/messages/me?${query.join('&')}');
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((m) => GuideChatMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }
}
