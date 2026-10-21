import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../models/experience.dart';
import 'app_services.dart';
import 'token_manager.dart';

class BackendAuthService extends AuthService {
  BackendAuthService() {
    // Khôi phục phiên đăng nhập nếu đã có token từ trước
    if (TokenManager.hasToken) {
      _user = VisitorUser(
        name: TokenManager.fullName ?? 'Khách tham quan',
        email: TokenManager.email ?? '',
        role: UserRole.visitor,
      );
    }
  }

  VisitorUser? _user;

  @override
  VisitorUser? get user => _user;

  @override
  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ Email và Mật khẩu.');
    }

    try {
      final uri = Uri.parse(ApiConfig.loginUrl);
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode({
              'email': cleanEmail,
              'password': cleanPass,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final token = data['accessToken'] as String? ?? '';
        final resEmail = data['email'] as String? ?? cleanEmail;
        final resFullName = data['fullName'] as String? ?? 'Khách tham quan';

        if (token.isEmpty) {
          throw Exception('Không nhận được mã xác thực (Token) từ hệ thống.');
        }

        await TokenManager.saveSession(
          token: token,
          email: resEmail,
          fullName: resFullName,
        );

        _user = VisitorUser(
          name: resFullName,
          email: resEmail,
          role: UserRole.visitor,
        );
        notifyListeners();
      } else {
        final errorMsg = body['message'] as String? ??
            'Đăng nhập không thành công (Mã lỗi: ${response.statusCode})';
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (_) {
      throw Exception(
        'Không thể kết nối tới máy chủ Backend (${ApiConfig.baseUrl}). Hãy chắc chắn máy chủ BE đang chạy.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi xử lý đăng nhập: $e');
    }
  }

  @override
  Future<void> register(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Vui lòng điền đầy đủ Họ tên, Email và Mật khẩu.');
    }

    if (cleanPass.length < 6) {
      throw Exception('Mật khẩu cần tối thiểu 6 ký tự.');
    }

    try {
      final uri = Uri.parse(ApiConfig.registerUrl);
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode({
              'fullName': cleanName,
              'email': cleanEmail,
              'password': cleanPass,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final token = data['accessToken'] as String? ?? '';
        final resEmail = data['email'] as String? ?? cleanEmail;
        final resFullName = data['fullName'] as String? ?? cleanName;

        if (token.isNotEmpty) {
          await TokenManager.saveSession(
            token: token,
            email: resEmail,
            fullName: resFullName,
          );
        }

        _user = VisitorUser(
          name: resFullName,
          email: resEmail,
          role: UserRole.visitor,
        );
        notifyListeners();
      } else {
        final errorMsg = body['message'] as String? ??
            'Đăng ký không thành công (Mã lỗi: ${response.statusCode})';
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (_) {
      throw Exception(
        'Không thể kết nối tới máy chủ Backend (${ApiConfig.baseUrl}). Hãy chắc chắn máy chủ BE đang chạy.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi xử lý đăng ký: $e');
    }
  }

  @override
  Future<void> recover(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  void logout() {
    TokenManager.clearSession();
    _user = null;
    notifyListeners();
  }
}
