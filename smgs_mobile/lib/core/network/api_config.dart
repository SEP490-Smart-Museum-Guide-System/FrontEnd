import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get defaultHost {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      if (Uri.base.scheme == 'https') return Uri.base.origin;
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:5169';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:5169';
    return 'http://localhost:5169';
  }

  static String customHost = '';

  static String get baseUrl {
    final host = customHost.trim().isNotEmpty ? customHost.trim() : defaultHost;
    return '$host/api';
  }

  static String mediaUrl(String? value) {
    if (value == null || value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    final museumCover = uri == null
        ? null
        : RegExp(r'/api(/museums/\d+/image/[^/]+)$').firstMatch(uri.path);
    if (museumCover != null) {
      // Older cover URLs may contain the host used by the admin during upload.
      return Uri.parse(
        '$baseUrl${museumCover.group(1)}',
      ).replace(query: uri!.hasQuery ? uri.query : null).toString();
    }
    if (value.startsWith('/')) {
      return Uri.parse(baseUrl).resolve(value).toString();
    }
    return value;
  }

  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';

  // Museum endpoints
  static String get museumsUrl => '$baseUrl/museums';
  static String museumDetailUrl(dynamic id) => '$baseUrl/museums/$id';
  static String get citiesUrl => '$baseUrl/museums/cities';

  // Navigation endpoints
  static String get outdoorRoutesUrl => '$baseUrl/navigation/outdoor/routes';

  // Artifact endpoints
  static String get artifactsUrl => '$baseUrl/artifacts';
  static String artifactDetailUrl(dynamic id) => '$baseUrl/artifacts/$id';
  static String artifactScanUrl(String code) =>
      '$baseUrl/artifacts/scan/${Uri.encodeComponent(code)}';
  static String publishedContentUrl(dynamic artifactId, {String lang = 'vi'}) =>
      '$baseUrl/artifacts/$artifactId/contents/published?languageCode=$lang';

  // Indoor Maps (Visitor)
  static String publishedIndoorMapUrl(dynamic id) =>
      '$baseUrl/indoor-maps/$id/published';
  static String publishedIndoorMapImageUrl(dynamic id, String imageKey) =>
      '$baseUrl/indoor-maps/$id/published/image?key=${Uri.encodeComponent(imageKey)}';

  // --- AI-System Services (Port 8000: TTS, Port 8001: Vision, Port 8002: 3D Scan) ---

  static String get defaultTtsHost {
    const configured = String.fromEnvironment('TTS_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      return '${Uri.base.origin}/ai-tts';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String customTtsHost = '';
  static String get ttsBaseUrl =>
      customTtsHost.trim().isNotEmpty ? customTtsHost.trim() : defaultTtsHost;
  static String get ttsSpeechUrl => '$ttsBaseUrl/api/v1/speech';
  static String get ttsHealthUrl => '$ttsBaseUrl/health';

  static String get defaultVisionHost {
    const configured = String.fromEnvironment('VISION_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:8001';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:8001';
    return 'http://localhost:8001';
  }

  static String customVisionHost = '';
  static String get visionBaseUrl => customVisionHost.trim().isNotEmpty
      ? customVisionHost.trim()
      : defaultVisionHost;
  static String get visionHealthUrl => '$visionBaseUrl/health';
  static String get visionRecognitionsUrl =>
      '$visionBaseUrl/api/v1/recognitions';
  static String visionReferencesUrl(dynamic artifactId) =>
      '$visionBaseUrl/api/v1/references?artifact_id=$artifactId';

  static String get defaultScanHost {
    const configured = String.fromEnvironment('SCAN_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:8002';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:8002';
    return 'http://localhost:8002';
  }

  static String customScanHost = '';
  static String get scanBaseUrl => customScanHost.trim().isNotEmpty
      ? customScanHost.trim()
      : defaultScanHost;
  static String get scanHealthUrl => '$scanBaseUrl/health';
  static String get scanJobsUrl => '$scanBaseUrl/api/v1/scans';
  static String scanJobStatusUrl(String jobId) =>
      '$scanBaseUrl/api/v1/scans/$jobId';
  static String scanDownloadGlbUrl(String jobId) =>
      '$scanBaseUrl/api/v1/scans/$jobId/model';
}
