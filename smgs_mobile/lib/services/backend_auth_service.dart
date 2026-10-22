import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../models/auth_session.dart';
import '../models/experience.dart';
import 'app_services.dart';
import 'token_manager.dart';

class BackendAuthService extends AuthService {
  BackendAuthService() {
    final saved = TokenManager.session;
    if (saved != null && saved.role == 'Visitor') {
      _user = saved.user;
      _scheduleExpiry(saved);
    }
  }
  VisitorUser? _user;
  Timer? _expiryTimer;
  @override
  VisitorUser? get user => _user;

  @override
  Future<void> login(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ email và mật khẩu.');
    }
    return _authenticate(ApiConfig.loginUrl, {
      'email': email.trim(),
      'password': password,
    });
  }

  @override
  Future<void> register(String name, String email, String password) {
    if (name.trim().isEmpty || email.trim().isEmpty || password.length < 6) {
      throw Exception(
        'Vui lòng nhập họ tên, email và mật khẩu tối thiểu 6 ký tự.',
      );
    }
    return _authenticate(ApiConfig.registerUrl, {
      'fullName': name.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  Future<void> _authenticate(String url, Map<String, String> payload) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Máy chủ phản hồi quá chậm. Vui lòng thử lại.');
    } on http.ClientException {
      throw Exception(
        'Không kết nối được máy chủ. Vui lòng kiểm tra mạng và địa chỉ API.',
      );
    }
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      /* A proxy may return HTML on failure. */
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body?['message'] is String
            ? body!['message']
            : 'Không thể xác thực (${response.statusCode}). Vui lòng thử lại.',
      );
    }
    if (body?['data'] is! Map<String, dynamic>) {
      throw const FormatException('Phản hồi xác thực từ máy chủ không hợp lệ.');
    }
    final session = AuthSession.fromJson(body!['data'] as Map<String, dynamic>);
    if (session.role != 'Visitor') {
      throw Exception(
        'Tài khoản nhân viên và quản trị viên vui lòng đăng nhập cổng nghiệp vụ web.',
      );
    }
    await TokenManager.saveSession(session);
    _user = session.user;
    _scheduleExpiry(session);
    notifyListeners();
  }

  void _scheduleExpiry(AuthSession session) {
    _expiryTimer?.cancel();
    _expiryTimer = Timer(
      session.expiresAt.difference(DateTime.now().toUtc()),
      logout,
    );
  }

  @override
  Future<void> recover(String email) async {
    throw Exception(
      'Chức năng khôi phục mật khẩu chưa được hỗ trợ. Vui lòng liên hệ hỗ trợ.',
    );
  }

  @override
  Future<void> logout() async {
    _expiryTimer?.cancel();
    _user = null;
    final clearing = TokenManager.clearSession();
    notifyListeners();
    await clearing;
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
