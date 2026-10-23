import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../models/artifact.dart';
import '../models/city.dart';
import '../models/museum.dart';
import '../models/outdoor_route.dart';
import 'token_manager.dart';

class MuseumDiscoveryPage {
  const MuseumDiscoveryPage(
    this.items,
    this.page,
    this.totalPages,
    this.totalCount,
  );
  final List<Museum> items;
  final int page, totalPages, totalCount;
}

class DiscoveryApiService {
  static Map<String, dynamic> decodeResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      /* A proxy may return HTML rather than JSON. */
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body?['message'] ??
            (response.statusCode == 429
                ? 'Dịch vụ đang bận. Vui lòng thử lại sau.'
                : 'Không thể tải dữ liệu (${response.statusCode}).'),
      );
    }
    if (body == null || body['data'] == null) {
      throw const FormatException('Phản hồi máy chủ không hợp lệ.');
    }
    return body;
  }

  static Future<List<CityItem>> fetchCities() async {
    final response = await http
        .get(Uri.parse(ApiConfig.citiesUrl), headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 10));
    final items = decodeResponse(response)['data'] as List;
    return items
        .map((e) => CityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<MuseumDiscoveryPage> fetchMuseumPage({
    String? keyword,
    String? cityCode,
    double? latitude,
    double? longitude,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(ApiConfig.museumsUrl).replace(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        if (cityCode != null && cityCode.isNotEmpty) 'cityCode': cityCode,
        if (latitude != null && longitude != null) ...{
          'latitude': '$latitude',
          'longitude': '$longitude',
        },
        'sortBy': ?sortBy,
      },
    );
    final response = await http
        .get(uri, headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 10));
    final data = decodeResponse(response)['data'] as Map<String, dynamic>;
    return MuseumDiscoveryPage(
      (data['items'] as List)
          .map((e) => Museum.fromBackendJson(e as Map<String, dynamic>))
          .toList(),
      data['page'] as int,
      data['totalPages'] as int,
      data['totalCount'] as int,
    );
  }

  // Existing list callers keep their List<Museum> contract.
  static Future<List<Museum>> fetchMuseums({
    String? keyword,
    String? cityCode,
    double? latitude,
    double? longitude,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async => (await fetchMuseumPage(
    keyword: keyword,
    cityCode: cityCode,
    latitude: latitude,
    longitude: longitude,
    sortBy: sortBy,
    page: page,
    pageSize: pageSize,
  )).items;

  static Future<Museum> fetchMuseumDetail(String id) async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.museumDetailUrl(id)),
          headers: TokenManager.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    return Museum.fromBackendJson(
      decodeResponse(response)['data'] as Map<String, dynamic>,
    );
  }

  static Future<OutdoorRoutePreview> fetchOutdoorRoute({
    required String museumId,
    required double originLat,
    required double originLng,
  }) async {
    final id = int.tryParse(museumId);
    if (id == null || id <= 0) {
      throw const FormatException('Mã bảo tàng không hợp lệ.');
    }
    final response = await http
        .post(
          Uri.parse(ApiConfig.outdoorRoutesUrl),
          headers: {
            ...TokenManager.authHeaders,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'museumId': id,
            'origin': {'latitude': originLat, 'longitude': originLng},
            'travelMode': 'DRIVE',
          }),
        )
        .timeout(const Duration(seconds: 15));
    return OutdoorRoutePreview.fromJson(
      decodeResponse(response)['data'] as Map<String, dynamic>,
    );
  }

  static Future<List<Artifact>> fetchArtifacts({
    int? museumId,
    String? keyword,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (museumId != null) 'museumId': '$museumId',
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
    };
    final uri = Uri.parse(ApiConfig.artifactsUrl).replace(queryParameters: query);
    final response = await http
        .get(uri, headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 10));
    final data = decodeResponse(response)['data'] as Map<String, dynamic>;
    final items = data['items'] as List;
    return items
        .map((e) => Artifact.fromBackendJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> fetchArtifactDetail(dynamic id) async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.artifactDetailUrl(id)),
          headers: TokenManager.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    return decodeResponse(response)['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchPublishedContent(
    dynamic artifactId, {
    String languageCode = 'vi',
  }) async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.publishedContentUrl(artifactId, lang: languageCode)),
          headers: TokenManager.authHeaders,
        )
        .timeout(const Duration(seconds: 10));
    return decodeResponse(response)['data'] as Map<String, dynamic>;
  }
}
