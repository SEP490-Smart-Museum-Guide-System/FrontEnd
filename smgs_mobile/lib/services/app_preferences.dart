import 'package:flutter/foundation.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final instance = AppPreferences._();
  bool reducedMotion = false, largeText = false;
  void setReducedMotion(bool value) {
    reducedMotion = value;
    notifyListeners();
  }

  void setLargeText(bool value) {
    largeText = value;
    notifyListeners();
  }
}
