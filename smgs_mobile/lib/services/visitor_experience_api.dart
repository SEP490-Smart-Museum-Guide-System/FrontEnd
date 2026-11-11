import 'dart:math';
import 'artifact_scan_service.dart';
import 'backend_api.dart';

class VisitorSession {
  static Map<String, dynamic>? activeVisit;
  static void clear() => activeVisit = null;
}

class ScanRequest {
  ScanRequest(String input, {this.visitId})
    : code = ArtifactScanService.extractCode(input),
      requestId = uuid();
  final String code, requestId;
  final int? visitId;
  static String uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final text = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${text.substring(0, 8)}-${text.substring(8, 12)}-${text.substring(12, 16)}-${text.substring(16, 20)}-${text.substring(20)}';
  }

  Future<Map<String, dynamic>> record() async {
    final result = await BackendApi.request(
      'recognitions/qr',
      method: 'POST',
      body: {'qrCode': code, 'visitId': visitId, 'requestId': requestId},
    );
    return Map<String, dynamic>.from(result);
  }
}

class VisitorExperienceApi {
  static Future<Map<String, dynamic>> startVisit(
    int museumId, {
    int? tourId,
    String? personalizedTourId,
  }) async {
    final data = Map<String, dynamic>.from(
      await BackendApi.request(
        'visits',
        method: 'POST',
        body: {
          'museumId': museumId,
          'tourId': tourId,
          'personalizedTourId': ?personalizedTourId,
        },
      ),
    );
    VisitorSession.activeVisit = data;
    return data;
  }

  static Future<Map<String, dynamic>> progress(int visitId) async =>
      Map<String, dynamic>.from(
        await BackendApi.request('visits/$visitId/progress'),
      );
  static Future<Map<String, dynamic>> location(int visitId) async =>
      Map<String, dynamic>.from(
        await BackendApi.request(
          'visitor-navigation/location?visitId=$visitId',
        ),
      );
  static Future<Map<String, dynamic>> route(
    int visitId,
    int mapId, {
    int? artifactId,
    bool accessible = false,
  }) async => Map<String, dynamic>.from(
    await BackendApi.request(
      'visitor-navigation/route?visitId=$visitId&mapId=$mapId&accessibleOnly=$accessible${artifactId == null ? '' : '&artifactId=$artifactId'}',
    ),
  );
}
