import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/city.dart';
import '../models/museum.dart';
import '../models/outdoor_route.dart';
import '../data/mock/mock_museums.dart';
import 'location_service.dart';

class DiscoveryApiService {
  // Thay đổi IP này cho phù hợp với máy chủ Backend của bạn (10.0.2.2 cho Android Emulator, localhost cho iOS/Web)
  static String baseUrl = 'http://10.0.2.2:5000';
  static String? authToken;

  /// Lấy danh mục 34 tỉnh/thành phố theo quy chuẩn hành chính mới
  static Future<List<CityItem>> fetchCities() async {
    try {
      final uri = Uri.parse('$baseUrl/api/museums/cities');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List items = body['data'] as List? ?? [];
        return items.map((e) => CityItem.fromJson(e)).toList();
      }
    } catch (_) {
      // Fallback khi chưa kết nối backend trực tiếp
    }

    // Danh mục tiêu biểu theo QĐ 19/2025/QĐ-TTg
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

  /// Lấy danh sách bảo tàng theo bộ lọc, tìm kiếm và khoảng cách
  static Future<List<Museum>> fetchMuseums({
    String? keyword,
    String? cityCode,
    double? latitude,
    double? longitude,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
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

      final uri = Uri.parse('$baseUrl/api/museums').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List items = body['data']?['items'] as List? ?? [];
        return items.map((e) => Museum.fromBackendJson(e)).toList();
      }
    } catch (_) {
      // Khi offline hoặc chưa chạy BE, dùng dữ liệu mẫu chất lượng cao
    }

    return _getFilteredMockMuseums(
      keyword: keyword,
      cityCode: cityCode,
      userLat: latitude,
      userLng: longitude,
      sortByDistance: sortBy == 'distance',
    );
  }

  /// Lọc và tính khoảng cách trên danh sách bảo tàng sẵn có trong app
  static List<Museum> _getFilteredMockMuseums({
    String? keyword,
    String? cityCode,
    double? userLat,
    double? userLng,
    bool sortByDistance = false,
  }) {
    var list = mockMuseums.map((m) {
      double? dist;
      if (userLat != null && userLng != null && m.latitude != 0.0) {
        dist = LocationService.calculateDistanceKm(
          lat1: userLat,
          lon1: userLng,
          lat2: m.latitude,
          lon2: m.longitude,
        );
      }
      // Gán mã tỉnh mẫu nếu chưa có
      final code = m.location.toLowerCase().contains('hồ chí minh') || m.location.toLowerCase().contains('hcm')
          ? '79'
          : '01';
      return m.copyWith(distanceKm: dist, cityCode: code);
    }).toList();

    if (keyword != null && keyword.trim().isNotEmpty) {
      final term = keyword.trim().toLowerCase();
      list = list.where((m) => m.name.toLowerCase().contains(term) || m.location.toLowerCase().contains(term)).toList();
    }

    if (cityCode != null && cityCode.isNotEmpty) {
      list = list.where((m) => m.cityCode == cityCode).toList();
    }

    if (sortByDistance && userLat != null && userLng != null) {
      list.sort((a, b) => (a.distanceKm ?? 99999).compareTo(b.distanceKm ?? 99999));
    }

    return list;
  }

  /// Gọi API Outdoor Navigation để lấy cự ly, thời gian và encoded polyline
  static Future<OutdoorRoutePreview> fetchOutdoorRoute({
    required dynamic museumId,
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String travelMode = 'DRIVE',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/navigation/outdoor/routes');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'museumId': int.tryParse(museumId.toString()) ?? 1,
          'origin': {'latitude': originLat, 'longitude': originLng},
          'travelMode': travelMode,
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null) {
          return OutdoorRoutePreview.fromJson(body['data']);
        }
      }
    } catch (_) {
      // Backend chưa có Google Routes key hoặc mất kết nối
    }

    // Mô phỏng lộ trình mượt mà (Mock Fallback Route)
    final distanceKm = LocationService.calculateDistanceKm(
      lat1: originLat,
      lon1: originLng,
      lat2: destinationLat,
      lon2: destinationLng,
    );

    final distanceMeters = (distanceKm * 1000).round();
    // Vận tốc ước lượng: Ô tô: 30km/h, Xe máy: 25km/h, Đi bộ: 4km/h
    final speedKmH = travelMode == 'WALK' ? 4.5 : (travelMode == 'TWO_WHEELER' ? 24.0 : 28.0);
    final durationSeconds = (distanceKm / speedKmH) * 3600;

    return OutdoorRoutePreview(
      museumId: museumId,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      travelMode: travelMode,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      encodedPolyline: '', // Sẽ được vẽ bằng interpolation thông minh nếu chuỗi rỗng
      warning: travelMode != 'DRIVE'
          ? 'Tuyến đi xe máy / đi bộ có thể bao gồm hẻm nhỏ hoặc đường cấm xe một chiều. Hãy quan sát thực địa.'
          : null,
    );
  }
}
