import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'visitor_experience_api.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final instance = AppPreferences._();

  static const _keyLanguage = 'smgs_pref_language';
  static const _keyReducedMotion = 'smgs_pref_reduced_motion';
  static const _keyLargeText = 'smgs_pref_large_text';

  bool reducedMotion = false;
  bool largeText = false;
  String language = 'vi';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_keyLanguage);
      if (savedLang != null && savedLang.isNotEmpty) {
        language = savedLang;
      } else {
        // Tự động nhận diện locale thiết bị: nếu ngôn ngữ hệ thống là Tiếng Anh hoặc quốc tế, đặt mặc định 'en'
        final systemLocale = PlatformDispatcher.instance.locale;
        language = systemLocale.languageCode.toLowerCase() == 'en' ? 'en' : 'vi';
      }
      reducedMotion = prefs.getBool(_keyReducedMotion) ?? false;
      largeText = prefs.getBool(_keyLargeText) ?? false;
      notifyListeners();
    } catch (_) {
      // Fallback silently to defaults if storage is unavailable.
    }
  }

  void setLanguage(String value, {bool syncRemote = true}) {
    if (language == value) return;
    language = value;
    notifyListeners();
    SharedPreferences.getInstance().then((p) {
      p.setString(_keyLanguage, value);
    }).catchError((_) {});
    if (syncRemote) {
      VisitorExperienceApi.updateUserLanguage(value).catchError((_) => false);
    }
  }

  /// Nạp ngôn ngữ người dùng đã lưu trên server khi đăng nhập (GET /api/me/language)
  Future<void> syncRemoteLanguage() async {
    final remoteLang = await VisitorExperienceApi.getUserLanguage();
    if (remoteLang != null && remoteLang.isNotEmpty && remoteLang != language) {
      setLanguage(remoteLang, syncRemote: false);
    }
  }

  void setReducedMotion(bool value) {
    if (reducedMotion == value) return;
    reducedMotion = value;
    notifyListeners();
    SharedPreferences.getInstance().then((p) {
      p.setBool(_keyReducedMotion, value);
    }).catchError((_) {});
  }

  void setLargeText(bool value) {
    if (largeText == value) return;
    largeText = value;
    notifyListeners();
    SharedPreferences.getInstance().then((p) {
      p.setBool(_keyLargeText, value);
    }).catchError((_) {});
  }
}
