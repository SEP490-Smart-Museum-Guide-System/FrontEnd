import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';

class TokenManager {
  static const _keySession = 'smgs_auth_session';
  static AuthSession? _session;
  static AuthSession? get session =>
      _session?.isExpired == false ? _session : null;
  static String? get token => session?.accessToken;
  static bool get hasToken => session != null;

  static Future<void> init() async {
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.get(_keySession);
    if (stored != null) {
      try {
        _session = AuthSession.fromJson(
          jsonDecode(stored as String) as Map<String, dynamic>,
        );
      } catch (_) {
        await prefs.remove(_keySession);
      }
    }
    // Legacy sessions have no expiry/role; require a fresh API login.
    for (final key in [
      'smgs_jwt_token',
      'smgs_user_email',
      'smgs_user_full_name',
      'smgs_user_role',
    ]) {
      await prefs.remove(key);
    }
  }

  static Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_keySession, jsonEncode(session.toJson()))) {
      throw Exception('Không lưu được phiên đăng nhập. Vui lòng thử lại.');
    }
    _session = session;
  }

  static Future<void> clearSession() async {
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
  }

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
