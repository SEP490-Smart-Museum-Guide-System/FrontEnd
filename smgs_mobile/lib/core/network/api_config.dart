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
  static String artifactScanUrl(String code) => '$baseUrl/artifacts/scan/${Uri.encodeComponent(code)}';
  static String publishedContentUrl(dynamic artifactId, {String lang = 'vi'}) =>
      '$baseUrl/artifacts/$artifactId/contents/published?languageCode=$lang';
}
