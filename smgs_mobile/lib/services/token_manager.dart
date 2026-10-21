import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _keyToken = 'smgs_jwt_token';
  static const String _keyEmail = 'smgs_user_email';
  static const String _keyFullName = 'smgs_user_full_name';
  static const String _keyRole = 'smgs_user_role';

  static String? _cachedToken;
  static String? _cachedEmail;
  static String? _cachedFullName;

  static String? get token => _cachedToken;
  static String? get email => _cachedEmail;
  static String? get fullName => _cachedFullName;

  static bool get hasToken => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Nạp token từ SharedPreferences khi khởi động ứng dụng
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_keyToken);
    _cachedEmail = prefs.getString(_keyEmail);
    _cachedFullName = prefs.getString(_keyFullName);
  }

  /// Lưu Token và thông tin tài khoản sau khi đăng nhập/đăng ký thành công
  static Future<void> saveSession({
    required String token,
    required String email,
    required String fullName,
    String? role,
  }) async {
    _cachedToken = token;
    _cachedEmail = email;
    _cachedFullName = fullName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyFullName, fullName);
    if (role != null) {
      await prefs.setString(_keyRole, role);
    }
  }

  /// Xóa phiên đăng nhập (Đăng xuất hoặc khi token hết hạn 401)
  static Future<void> clearSession() async {
    _cachedToken = null;
    _cachedEmail = null;
    _cachedFullName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyRole);
  }

  /// Trả về Headers mặc định kèm JWT Token (nếu có)
  static Map<String, String> get authHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (hasToken) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }
    return headers;
  }
}
