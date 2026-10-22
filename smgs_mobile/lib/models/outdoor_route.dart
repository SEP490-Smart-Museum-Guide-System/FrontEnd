import 'package:latlong2/latlong.dart';

class OutdoorRoutePreview {
  const OutdoorRoutePreview({
    required this.museumId,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.routePoints,
  });
  final int museumId;
  final LatLng destination;
  final double distanceMeters, durationSeconds;
  final List<LatLng> routePoints;
  String get distanceKmString =>
      '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  String get durationMinutesString => '${(durationSeconds / 60).ceil()} phút';

  static LatLng parsePoint(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num).toDouble();
    final lon = (json['longitude'] as num).toDouble();
    if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
      throw const FormatException('Tọa độ tuyến đường không hợp lệ.');
    }
    return LatLng(lat, lon);
  }

  factory OutdoorRoutePreview.fromJson(Map<String, dynamic> json) {
    final points = (json['routePoints'] as List)
        .map((p) => parsePoint(Map<String, dynamic>.from(p as Map)))
        .toList();
    final distance = (json['distanceMeters'] as num).toDouble();
    final duration = (json['durationSeconds'] as num).toDouble();
    if (json['travelMode'] != 'DRIVE' ||
        points.length < 2 ||
        !distance.isFinite ||
        !duration.isFinite ||
        distance < 0 ||
        duration < 0) {
      throw const FormatException('Dữ liệu tuyến đường không hợp lệ.');
    }
    return OutdoorRoutePreview(
      museumId: json['museumId'] as int,
      destination: parsePoint(
        Map<String, dynamic>.from(json['destination'] as Map),
      ),
      distanceMeters: distance,
      durationSeconds: duration,
      routePoints: points,
    );
  }
}
