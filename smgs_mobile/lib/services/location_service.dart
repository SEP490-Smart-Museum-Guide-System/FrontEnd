import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class UserLocationResult {
  final double latitude;
  final double longitude;
  final bool isMockOrFallback;
  final String? errorMessage;

  const UserLocationResult({
    required this.latitude,
    required this.longitude,
    this.isMockOrFallback = false,
    this.errorMessage,
  });
}

class LocationService {
  // Tọa độ mặc định tại trung tâm TP.HCM (Quận 1) dùng khi không cấp GPS hoặc chạy máy ảo
  static const double defaultLat = 10.7769;
  static const double defaultLng = 106.7009;

  /// Xin quyền và lấy tọa độ GPS của thiết bị
  static Future<UserLocationResult> getCurrentUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const UserLocationResult(
          latitude: defaultLat,
          longitude: defaultLng,
          isMockOrFallback: true,
          errorMessage: 'Dịch vụ định vị GPS trên thiết bị chưa được bật.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const UserLocationResult(
            latitude: defaultLat,
            longitude: defaultLng,
            isMockOrFallback: true,
            errorMessage: 'Bạn đã từ chối cấp quyền truy cập vị trí.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const UserLocationResult(
          latitude: defaultLat,
          longitude: defaultLng,
          isMockOrFallback: true,
          errorMessage: 'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return UserLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isMockOrFallback: false,
      );
    } catch (e) {
      return UserLocationResult(
        latitude: defaultLat,
        longitude: defaultLng,
        isMockOrFallback: true,
        errorMessage: 'Không thể lấy tọa độ thực tế: $e',
      );
    }
  }

  /// Tính khoảng cách Haversine đường thẳng giữa 2 tọa độ (đơn vị: km)
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }
}
