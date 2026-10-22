import 'dart:async';
import 'package:geolocator/geolocator.dart';

class UserLocationResult {
  const UserLocationResult({
    required this.latitude,
    required this.longitude,
    this.isLastKnown = false,
  });
  final double latitude, longitude;
  final bool isLastKnown;
}

class LocationService {
  static Future<UserLocationResult> getCurrentUserLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Vui lòng bật dịch vụ định vị GPS.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đã bị khóa. Vui lòng cấp quyền trong Cài đặt.',
      );
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse &&
        permission != LocationPermission.unableToDetermine) {
      throw Exception(
        'Chưa có quyền vị trí. Bạn vẫn có thể tìm kiếm và lọc tỉnh/thành.',
      );
    }
    Position position;
    var isLastKnown = false;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } on TimeoutException {
      Position? recent;
      try {
        recent = await Geolocator.getLastKnownPosition().timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {
        /* Last-known location is unavailable on some platforms. */
      }
      final age = recent == null
          ? null
          : DateTime.now().difference(recent.timestamp);
      if (recent == null ||
          age!.isNegative ||
          age > const Duration(minutes: 2) ||
          !recent.accuracy.isFinite ||
          recent.accuracy < 0 ||
          recent.accuracy > 100) {
        throw Exception(
          'Chưa lấy được vị trí GPS. Hãy bật Độ chính xác vị trí, ra nơi thoáng rồi nhấn Thử lại. Bạn vẫn có thể mở Google Maps.',
        );
      }
      position = recent;
      isLastKnown = true;
    }
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude.abs() > 90 ||
        position.longitude.abs() > 180) {
      throw Exception('Vị trí GPS không hợp lệ. Vui lòng thử lại.');
    }
    return UserLocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      isLastKnown: isLastKnown,
    );
  }
}
