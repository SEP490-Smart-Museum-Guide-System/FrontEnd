import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      language = prefs.getString(_keyLanguage) ?? 'vi';
      reducedMotion = prefs.getBool(_keyReducedMotion) ?? false;
      largeText = prefs.getBool(_keyLargeText) ?? false;
      notifyListeners();
    } catch (_) {
      // Fallback silently to defaults if storage is unavailable.
    }
  }

  void setLanguage(String value) {
    if (language == value) return;
    language = value;
    notifyListeners();
    SharedPreferences.getInstance().then((p) {
      p.setString(_keyLanguage, value);
    }).catchError((_) {});
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
