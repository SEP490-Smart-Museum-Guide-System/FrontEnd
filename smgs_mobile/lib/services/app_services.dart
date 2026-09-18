import 'package:flutter/foundation.dart';

import '../models/experience.dart';
import '../models/artifact.dart';
import '../models/museum.dart';
import '../data/mock/mock_artifacts.dart';
import '../data/mock/mock_museums.dart';

abstract class AuthService extends ChangeNotifier {
  VisitorUser? get user;
  Future<void> login(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<void> recover(String email);
  void guest();
  void logout();
}

class MockAuthService extends AuthService {
  VisitorUser? _user;
  final _accounts = <String, ({String name, String password, UserRole role})>{
    'khach@smgs.vn': (
      name: 'Minh An',
      password: 'smgs123',
      role: UserRole.visitor,
    ),
    'curator@smgs.vn': (
      name: 'Lê Thu Hà',
      password: 'smgs123',
      role: UserRole.curator,
    ),
    'admin@smgs.vn': (
      name: 'Quản trị SMGS',
      password: 'smgs123',
      role: UserRole.administrator,
    ),
  };
  @override
  VisitorUser? get user => _user;
  @override
  Future<void> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || account.password != password) {
      throw const FormatException(
        'Email hoặc mật khẩu chưa đúng. Hãy dùng tài khoản mẫu hoặc đăng ký trong phiên này.',
      );
    }
    _user = VisitorUser(name: account.name, email: key, role: account.role);
    notifyListeners();
  }

  @override
  Future<void> register(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const FormatException(
        'Địa chỉ này đã có tài khoản trong bản trải nghiệm.',
      );
    }
    _accounts[key] = (
      name: name.trim(),
      password: password,
      role: UserRole.visitor,
    );
    _user = VisitorUser(name: name.trim(), email: key);
    notifyListeners();
  }

  @override
  Future<void> recover(String email) =>
      Future<void>.delayed(const Duration(milliseconds: 350));
  @override
  void guest() {
    _user = const VisitorUser(
      name: 'Khách tham quan',
      email: '',
      isGuest: true,
    );
    notifyListeners();
  }

  @override
  void logout() {
    _user = null;
    notifyListeners();
  }
}

abstract class CatalogService {
  List<Museum> get museums;
  List<Artifact> get artifacts;
  List<Artifact> inMuseum(String id);
}

class MockCatalogService implements CatalogService {
  @override
  List<Museum> get museums => mockMuseums;
  @override
  List<Artifact> get artifacts => mockArtifacts;
  @override
  List<Artifact> inMuseum(String id) =>
      artifacts.where((a) => a.museumId == id).toList();
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
      explanation: 'Hiện vật lưu giữ dấu vết về văn hóa, con người và xã hội trong quá khứ.',
    ),
  ];
}

abstract class TourService {
  List<Artifact> plan(String museumId, int duration, Set<String> interests);
}

class MockTourService implements TourService {
  MockTourService(this.catalog);
  final CatalogService catalog;
  @override
  List<Artifact> plan(String museumId, int duration, Set<String> interests) {
    if (interests.isEmpty) return [];
    final stops = [...catalog.inMuseum(museumId)];
    int rank(Artifact a) =>
        (interests.contains('Nghệ thuật') && a.category == 'Cung đình') ||
            (interests.contains('Văn hóa') && a.category == 'Khảo cổ')
        ? 0
        : 1;
    stops.sort((a, b) => rank(a).compareTo(rank(b)));
    return stops.take(duration == 30 ? 1 : stops.length).toList();
  }
}

abstract class PaymentService {
  Future<bool> pay({required bool simulateSuccess});
}

class MockPaymentService implements PaymentService {
  @override
  Future<bool> pay({required bool simulateSuccess}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return simulateSuccess;
  }
}

abstract class PremiumCatalog {
  List<PremiumOffer> get offers;
}

class MockPremiumCatalog implements PremiumCatalog {
  @override
  List<PremiumOffer> get offers => const [
    PremiumOffer(
      id: 'guide',
      name: 'Hướng dẫn viên thông minh',
      description: 'Hỏi đáp theo từng hiện vật trong ngày tham quan.',
      price: 30000,
      kind: DigitalServiceKind.guide,
    ),
    PremiumOffer(
      id: 'narration',
      name: 'Thuyết minh trọn bộ',
      description: 'Nội dung thuyết minh cho các hiện vật trong bộ sưu tập.',
      price: 25000,
      kind: DigitalServiceKind.narration,
    ),
    PremiumOffer(
      id: 'tour',
      name: 'Hành trình cá nhân',
      description: 'Lộ trình theo thời gian và những điều bạn yêu thích.',
      price: 20000,
      kind: DigitalServiceKind.tour,
    ),
    PremiumOffer(
      id: 'exhibition',
      name: 'Chuyên đề mở rộng',
      description: 'Đọc thêm câu chuyện và tư liệu của các chủ đề trưng bày.',
      price: 35000,
      kind: DigitalServiceKind.exhibition,
    ),
  ];
}

class AppServices {
  AppServices._();
  static AuthService auth = MockAuthService();
  static CatalogService catalog = MockCatalogService();
  static RecognitionService recognition = MockRecognitionService(catalog);
  static AiGuideService guide = MockAiGuideService();
  static QuizService quiz = MockQuizService();
  static TourService tours = MockTourService(catalog);
  static PaymentService payment = MockPaymentService();
  static PremiumCatalog premium = MockPremiumCatalog();
}
