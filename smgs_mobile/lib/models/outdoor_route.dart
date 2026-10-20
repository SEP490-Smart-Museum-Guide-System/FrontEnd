class OutdoorRoutePreview {
  final dynamic museumId;
  final double destinationLat;
  final double destinationLng;
  final String travelMode;
  final int distanceMeters;
  final double durationSeconds;
  final String encodedPolyline;
  final String? warning;

  const OutdoorRoutePreview({
    required this.museumId,
    required this.destinationLat,
    required this.destinationLng,
    required this.travelMode,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    this.warning,
  });

  String get distanceKmString {
    final km = distanceMeters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  String get durationMinutesString {
    final mins = (durationSeconds / 60.0).round();
    return '$mins phút';
  }

  factory OutdoorRoutePreview.fromJson(Map<String, dynamic> json) {
    final dest = json['destination'] as Map<String, dynamic>? ?? {};
    return OutdoorRoutePreview(
      museumId: json['museumId'],
      destinationLat: (dest['latitude'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (dest['longitude'] as num?)?.toDouble() ?? 0.0,
      travelMode: json['travelMode'] as String? ?? 'DRIVE',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      encodedPolyline: json['encodedPolyline'] as String? ?? '',
      warning: json['warning'] as String?,
    );
  }
}
