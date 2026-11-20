import 'backend_api.dart';
import 'location_service.dart';
import 'visitor_experience_api.dart';

class MuseumPresenceApi {
  static bool isCheckpoint(String value) =>
      value.trim().startsWith('smgs:location:');
  static Future<Map<String, dynamic>> current(
    int museumId, {
    int? visitId,
    int? mapId,
  }) async => Map<String, dynamic>.from(
    await BackendApi.request(
      'museums/$museumId/presence?${Uri(queryParameters: {if (visitId != null) 'visitId': '$visitId', if (mapId != null) 'mapId': '$mapId'}).query}',
    ),
  );
  static Future<Map<String, dynamic>> assess(
    int museumId,
    UserLocationResult location,
  ) async {
    if (!location.accuracyMeters.isFinite || location.capturedAt == null) {
      return {
        'status': 'uncertain',
        'message':
            'GPS chưa có độ chính xác hoặc thời gian hợp lệ. Hãy quét QR.',
      };
    }
    return Map<String, dynamic>.from(
      await BackendApi.request(
        'museums/$museumId/presence/gps-assessment',
        method: 'POST',
        body: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracyMeters': location.accuracyMeters,
          'capturedAt': location.capturedAt!.toUtc().toIso8601String(),
          'isLastKnown': location.isLastKnown,
          'isMocked': location.isMocked,
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> scan(
    String code, {
    int? museumId,
    int? visitId,
    String? requestId,
  }) async => Map<String, dynamic>.from(
    await BackendApi.request(
      museumId == null
          ? 'museum-presence/checkpoints/scan'
          : 'museums/$museumId/presence/checkpoints/scan',
      method: 'POST',
      body: {
        'code': code.trim(),
        'requestId': requestId ?? ScanRequest.uuid(),
        'visitId': visitId,
      },
    ),
  );
  static Future<Map<String, dynamic>> route(
    int museumId,
    int mapId, {
    int? visitId,
    int? artifactId,
    String? targetNodeId,
    bool accessible = false,
  }) async => Map<String, dynamic>.from(
    await BackendApi.request(
      'museums/$museumId/presence/route',
      method: 'POST',
      body: {
        'mapId': mapId,
        'visitId': visitId,
        'artifactId': artifactId,
        'targetNodeId': targetNodeId,
        'accessibleOnly': accessible,
      },
    ),
  );
}
