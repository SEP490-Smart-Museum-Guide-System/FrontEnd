import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../models/city.dart';
import '../models/museum.dart';
import '../models/outdoor_route.dart';
import 'location_service.dart';
import 'token_manager.dart';

class DiscoveryApiService {
  /// Lấy danh mục 34 tỉnh/thành phố từ Backend (chuẩn QĐ 19/2025/QĐ-TTg)
  static Future<List<CityItem>> fetchCities() async {
    try {
      final uri = Uri.parse(ApiConfig.citiesUrl);
      final response = await http
          .get(uri, headers: TokenManager.authHeaders)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        final List items = body['data'] as List? ?? [];
        return items.map((e) => CityItem.fromJson(e)).toList();
      }
    } catch (_) {
      // Bỏ qua lỗi mạng
    }

    // Danh mục tiêu biểu fallback nếu có sự cố
    return const [
      CityItem(code: '79', name: 'TP. Hồ Chí Minh'),
      CityItem(code: '01', name: 'TP. Hà Nội'),
      CityItem(code: '48', name: 'TP. Đà Nẵng'),
      CityItem(code: '31', name: 'TP. Hải Phòng'),
      CityItem(code: '92', name: 'TP. Cần Thơ'),
      CityItem(code: '46', name: 'Thừa Thiên Huế'),
      CityItem(code: '49', name: 'Quảng Nam'),
      CityItem(code: '77', name: 'Bà Rịa - Vũng Tàu'),
      CityItem(code: '68', name: 'Lâm Đồng'),
      CityItem(code: '56', name: 'Khánh Hòa'),
    ];
  }

  /// Lấy danh sách bảo tàng theo bộ lọc, tìm kiếm và khoảng cách từ Backend
  static Future<List<Museum>> fetchMuseums({
    String? keyword,
    String? cityCode,
    double? latitude,
    double? longitude,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (cityCode != null && cityCode.isNotEmpty) 'cityCode': cityCode,
      if (latitude != null && longitude != null) ...{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
    };

    final uri = Uri.parse(ApiConfig.museumsUrl).replace(queryParameters: queryParams);
    final response = await http
        .get(uri, headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body);
      final List items = body['data']?['items'] as List? ?? [];
      return items.map((e) => Museum.fromBackendJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    } else {
      final body = json.decode(response.body);
      final msg = body['message'] as String? ?? 'Không thể tải danh sách bảo tàng (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Lấy chi tiết bảo tàng từ Backend theo ID
  static Future<Museum> fetchMuseumDetail(dynamic id) async {
    final uri = Uri.parse(ApiConfig.museumDetailUrl(id));
    final response = await http
        .get(uri, headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body);
      return Museum.fromBackendJson(body['data']);
    } else if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    } else {
      throw Exception('Không tìm thấy thông tin bảo tàng (${response.statusCode})');
    }
  }

  /// Gọi API Outdoor Navigation để lấy cự ly, thời gian và encoded polyline từ Backend
  static Future<OutdoorRoutePreview> fetchOutdoorRoute({
    required dynamic museumId,
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'DRIVE',
  }) async {
    final uri = Uri.parse(ApiConfig.outdoorRoutesUrl);
    final response = await http
        .post(
          uri,
          headers: TokenManager.authHeaders,
          body: json.encode({
            'museumId': int.tryParse(museumId.toString()) ?? 1,
            'origin': {'latitude': originLat, 'longitude': originLng},
            'travelMode': travelMode,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body);
      if (body['data'] != null) {
        return OutdoorRoutePreview.fromJson(body['data']);
      }
    }

    // Nếu Google Routes API chưa có key hợp lệ hoặc lỗi, fallback tính cự ly mượt mà
    final distanceKm = LocationService.calculateDistanceKm(
      lat1: originLat,
      lon1: originLng,
      lat2: destinationLat,
      lon2: destinationLng,
    );
    final distanceMeters = (distanceKm * 1000).round();
    final speedKmH = travelMode == 'WALK' ? 4.5 : (travelMode == 'TWO_WHEELER' ? 24.0 : 28.0);
    final durationSeconds = (distanceKm / speedKmH) * 3600;

    return OutdoorRoutePreview(
      museumId: museumId,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      travelMode: travelMode,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      encodedPolyline: '',
      warning: travelMode != 'DRIVE'
          ? 'Tuyến xe máy / đi bộ có thể qua đường hẹp hoặc cấm một chiều. Hãy quan sát thực địa.'
          : null,
    );
  }
}
