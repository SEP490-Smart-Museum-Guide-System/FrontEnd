import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get defaultHost {
    if (kIsWeb) {
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
}
