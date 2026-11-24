import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class OutdoorRoutePreview {
  const OutdoorRoutePreview({
    required this.museumId,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.routePoints,
    this.steps = const [],
  });
  final int museumId;
  final LatLng destination;
  final double distanceMeters, durationSeconds;
  final List<LatLng> routePoints;
  final List<RouteStep> steps;

  ({int segment, double meters}) match(LatLng fix) {
    final scale = math.cos(fix.latitude * math.pi / 180);
    var best = double.infinity;
    var segment = 0;
    for (var i = 0; i + 1 < routePoints.length; i++) {
      final a = routePoints[i], b = routePoints[i + 1];
      final x = (a.longitude - fix.longitude) * scale;
      final y = a.latitude - fix.latitude;
      final dx = (b.longitude - a.longitude) * scale;
      final dy = b.latitude - a.latitude;
      final length = dx * dx + dy * dy;
      final t = length == 0 ? 0 : (-(x * dx + y * dy) / length).clamp(0, 1);
      final distance = math.pow(x + t * dx, 2) + math.pow(y + t * dy, 2);
      if (distance < best) {
        best = distance.toDouble();
        segment = i;
      }
    }
    return (segment: segment, meters: math.sqrt(best) * 111320);
  }

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
      steps: [
        for (final step in json['steps'] ?? const [])
          RouteStep(
            step['pointIndex'] as int,
            step['sign'] as int,
            step['text'] as String,
          ),
      ],
    );
  }
}

class RouteStep {
  const RouteStep(this.index, this.sign, this.street);
  final int index, sign;
  final String street;
  String get label {
    final action = switch (sign) {
      -3 => 'Rẽ gắt sang trái',
      -2 => 'Rẽ trái',
      -1 => 'Chếch trái',
      1 => 'Chếch phải',
      2 => 'Rẽ phải',
      3 => 'Rẽ gắt sang phải',
      4 => 'Đến điểm đích',
      6 => 'Vào vòng xuyến',
      -8 || 8 => 'Quay đầu',
      _ => 'Tiếp tục',
    };
    return street.isEmpty ? action : street;
  }
}
