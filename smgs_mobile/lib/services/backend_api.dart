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
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$path');
    final headers = {
      ...TokenManager.authHeaders,
      'Content-Type': 'application/json',
    };
    final response = await (switch (method) {
      'POST' => http.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => http.put(uri, headers: headers, body: jsonEncode(body)),
      _ => http.get(uri, headers: headers),
    }).timeout(const Duration(seconds: 15));
    return DiscoveryApiService.decodeResponse(response)['data'];
  }

  static Future<List<Map<String, dynamic>>> list(String path) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1; page <= 1000; page++) {
      final data = await request(
        '$path${path.contains('?') ? '&' : '?'}page=$page&pageSize=50',
      );
      final items = (data is List ? data : data['items']) as List;
      rows.addAll(items.cast<Map<String, dynamic>>());
      if (data is List
          ? items.length < 50
          : (items.isEmpty ||
                page >= (data['totalPages'] as int) ||
                rows.length >= (data['totalCount'] as int)))
        return rows;
    }
    throw const FormatException('Danh sách quá lớn. Hãy lọc dữ liệu.');
  }
}
