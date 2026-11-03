import 'package:flutter/foundation.dart';

import '../models/experience.dart';
import '../models/artifact.dart';
import '../models/museum.dart';
import 'backend_api.dart';

abstract class AuthService extends ChangeNotifier {
  VisitorUser? get user;
  Future<void> login(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<void> recover(String email);
  Future<void> logout();
}

abstract class CatalogService {
  Future<void> load() async {}
  String museumName(String id) =>
      museums.where((m) => m.id == id).firstOrNull?.name ??
      'Chưa có thông tin bảo tàng';
  List<Museum> get museums;
  List<Artifact> get artifacts;
  List<Artifact> inMuseum(String id);
}

abstract class RecognitionService {
  Future<Artifact?> recognize(String museumId, {bool match = true});
}

class MockRecognitionService implements RecognitionService {
  MockRecognitionService(this.catalog);
  final CatalogService catalog;
  @override
  Future<Artifact?> recognize(String museumId, {bool match = true}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final artifacts = catalog.inMuseum(museumId);
    return match && artifacts.isNotEmpty ? artifacts.first : null;
  }
}

abstract class AiGuideService {
  List<String> get suggestions;
  Future<String> answer(Artifact artifact, String question);
}

class MockAiGuideService implements AiGuideService {
  @override
  List<String> get suggestions => const [
    'Hiện vật này có ý nghĩa gì?',
    'Hiện vật thuộc thời kỳ nào?',
    'Tôi nên chú ý chi tiết nào?',
  ];
  @override
  Future<String> answer(Artifact a, String question) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (question == suggestions[0]) return a.summary;
    if (question == suggestions[1]) {
      return 'Hiện vật được giới thiệu trong bối cảnh: ${a.period}.';
    }
    if (question == suggestions[2]) return a.aiGuide;
    return 'Mình chưa có câu trả lời được kiểm chứng cho câu hỏi này trong bản trải nghiệm. Bạn có thể chọn câu hỏi gợi ý hoặc hỏi nhân viên bảo tàng để tìm hiểu thêm.';
  }
}

abstract class QuizService {
  List<QuizQuestion> questions(Artifact artifact);
}

class MockQuizService implements QuizService {
  @override
  List<QuizQuestion> questions(Artifact a) => [
    QuizQuestion(
      question: a.quizPrompt,
      options: switch (a.id) {
        'artifact_1' => [
          'Văn hóa Đông Sơn',
          'Văn hóa Óc Eo',
          'Văn hóa Sa Huỳnh',
        ],
        'artifact_2' => ['Triều Lý', 'Triều Nguyễn', 'Triều Trần'],
        _ => ['Thế kỷ XVIII', 'Thế kỷ XIX', 'Thế kỷ XX'],
      },
      correctIndex: switch (a.id) {
        'artifact_1' => 0,
        'artifact_2' => 1,
        _ => 2,
      },
      explanation: a.summary,
    ),
    const QuizQuestion(
      question: 'Vì sao chúng ta cần tìm hiểu hiện vật?',
      options: [
        'Chỉ dùng để trang trí',
        'Giúp tìm hiểu đời sống và lịch sử',
        'Không mang thông tin lịch sử',
      ],
      correctIndex: 1,
      explanation:
          'Hiện vật lưu giữ dấu vết về văn hóa, con người và xã hội trong quá khứ.',
    ),
  ];
}

abstract class TourService {
  Future<List<Artifact>> plan(
    String museumId,
    int duration,
    Set<String> interests,
  );
}

abstract class PaymentService {
  Future<bool> pay({required bool simulateSuccess});
}

abstract class PremiumCatalog {
  List<PremiumOffer> get offers;
}

class BackendCatalogService implements CatalogService {
  List<Museum> _museums = [];
  List<Artifact> _artifacts = [];
  @override
  List<Museum> get museums => _museums;
  @override
  List<Artifact> get artifacts => _artifacts;
  @override
  List<Artifact> inMuseum(String id) =>
      artifacts.where((a) => a.museumId == id).toList();
  @override
  String museumName(String id) =>
      museums.where((m) => m.id == id).firstOrNull?.name ??
      'Chưa có thông tin bảo tàng';
  @override
  Future<void> load() async {
    _museums = [];
    _artifacts = [];
    final results = await Future.wait([
      BackendApi.list('museums'),
      BackendApi.list('artifacts'),
    ]);
    _museums = results[0].map(Museum.fromBackendJson).toList();
    _artifacts = results[1].map(Artifact.fromBackendJson).toList();
  }
}

class BackendTourService implements TourService {
  @override
  Future<List<Artifact>> plan(
    String museumId,
    int duration,
    Set<String> interests,
  ) async {
    if (int.tryParse(museumId) == null)
      throw const FormatException('Hãy chọn bảo tàng.');
    final tours = await BackendApi.list('tours?museumId=$museumId');
    final suitable =
        tours.where((t) => (t['estimatedMinutes'] as num) <= duration).toList()
          ..sort(
            (a, b) => (b['estimatedMinutes'] as num).compareTo(
              a['estimatedMinutes'] as num,
            ),
          );
    if (suitable.isEmpty) return [];
    final items = (suitable.first['items'] as List).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['orderNo'] as int).compareTo(b['orderNo'] as int));
    final stops = <Artifact>[];
    for (final item in items) {
      final row = await BackendApi.request('artifacts/${item['artifactId']}');
      stops.add(Artifact.fromBackendJson(row as Map<String, dynamic>));
    }
    return stops;
  }
}

class AppServices {
  AppServices._();
  static late AuthService auth;
  static CatalogService catalog = BackendCatalogService();
  static RecognitionService recognition = MockRecognitionService(catalog);
  static AiGuideService guide = MockAiGuideService();
  static QuizService quiz = MockQuizService();
  static TourService tours = BackendTourService();
}
