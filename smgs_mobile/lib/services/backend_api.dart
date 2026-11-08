import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import 'token_manager.dart';
import 'discovery_api_service.dart';

class BackendApi {
  static Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$path');
    final headers = {
      ...TokenManager.authHeaders,
      'Content-Type': 'application/json',
    };
    final response = await (switch (method) {
      'POST' => http.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => http.put(uri, headers: headers, body: jsonEncode(body)),
      'PATCH' => http.patch(uri, headers: headers, body: jsonEncode(body)),
      'DELETE' => http.delete(uri, headers: headers),
      'GET' => http.get(uri, headers: headers),
      _ => throw ArgumentError('Phương thức HTTP không hợp lệ.'),
    }).timeout(timeout);
    return DiscoveryApiService.decodeResponse(response)['data'];
  }

  static Future<List<Map<String, dynamic>>> list(String path) async {
    final rows = <Map<String, dynamic>>[];
    final pagedArray = RegExp(
      r'^(tours|recognitions/me|quiz-attempts/me|gamification/me/transactions|commerce/(orders/me|passes/me|museums/[^/]+/orders))$',
    ).hasMatch(path.split('?').first);
    for (var page = 1; page <= 1000; page++) {
      final data = await request(
        '$path${path.contains('?') ? '&' : '?'}page=$page&pageSize=50',
      );
      final items = (data is List ? data : data['items']) as List;
      rows.addAll(items.cast<Map<String, dynamic>>());
      if (data is List
          ? (!pagedArray || items.length < 50)
          : (items.isEmpty ||
                page >= (data['totalPages'] as int) ||
                rows.length >= (data['totalCount'] as int))) {
        return rows;
      }
    }
    throw const FormatException('Danh sách quá lớn. Hãy lọc dữ liệu.');
  }
}
