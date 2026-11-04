import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/models/experience.dart';
import 'package:smgs_mobile/models/artifact.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/data/mock/mock_artifacts.dart';
import 'mock_museums.dart';

class MockAuthService extends AuthService {
  MockAuthService({VisitorUser? initialUser}) : _user = initialUser;

  VisitorUser? _user;
  final _accounts = <String, ({String name, String password, UserRole role})>{
    'khach@smgs.vn': (
      name: 'Minh An',
      password: 'smgs123',
      role: UserRole.visitor,
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
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}

class MockCatalogService extends CatalogService {
  @override
  List<Museum> get museums => mockMuseums;
  @override
  List<Artifact> get artifacts => mockArtifacts;
  @override
  List<Artifact> inMuseum(String id) =>
      artifacts.where((a) => a.museumId == id).toList();
}

class MockTourService implements TourService {
  MockTourService(this.catalog);
  final CatalogService catalog;
  @override
  Future<List<Artifact>> plan(
    String museumId,
    int duration,
    Set<String> interests,
  ) async {
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

class MockPaymentService implements PaymentService {
  @override
  Future<bool> pay({required bool simulateSuccess}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return simulateSuccess;
  }
}

class MockPremiumCatalog implements PremiumCatalog {
  @override
  List<PremiumOffer> get offers => const [
    PremiumOffer(
      id: 'ticket',
      name: 'Vé vào cửa bảo tàng',
      description: 'Vé tham quan theo ngày tại bảo tàng đã chọn.',
      price: 50000,
      kind: DigitalServiceKind.exhibition,
    ),
    PremiumOffer(
      id: 'digital-guide',
      name: 'Hướng dẫn số',
      description:
          'Thuyết minh, trợ lý AI và nội dung số trong ngày tham quan.',
      price: 20000,
      kind: DigitalServiceKind.narration,
    ),
    PremiumOffer(
      id: 'combo',
      name: 'Vé + Hướng dẫn số',
      description: 'Một gói gồm vé vào cửa và toàn bộ quyền Hướng dẫn số.',
      price: 65000,
      kind: DigitalServiceKind.guide,
    ),
  ];
}
