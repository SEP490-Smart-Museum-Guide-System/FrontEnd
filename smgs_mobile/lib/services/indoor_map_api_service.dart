import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../models/indoor_map.dart';
import 'token_manager.dart';
import 'artifact_scan_service.dart';

class QrLocationResult {
  final IndoorMarker marker;
  final String startNodeId;
  final String artifactName;

  const QrLocationResult({
    required this.marker,
    required this.startNodeId,
    required this.artifactName,
  });
}

class IndoorMapApiService {
  static Future<PublishedIndoorMap> fetchPublishedMap(dynamic mapId) async {
    final url = Uri.parse(ApiConfig.publishedIndoorMapUrl(mapId));
    final response = await http
        .get(url, headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
      if (response.statusCode == 404) {
        throw Exception('Sơ đồ này chưa được xuất bản hoặc không tồn tại.');
      }
      throw Exception('Lỗi tải sơ đồ xuất bản (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
    return PublishedIndoorMap.fromJson(data as Map<String, dynamic>);
  }

  static Future<Uint8List> fetchMapImageBytes(dynamic mapId, String imageKey) async {
    final url = Uri.parse(ApiConfig.publishedIndoorMapImageUrl(mapId, imageKey));
    final response = await http
        .get(url, headers: TokenManager.authHeaders)
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Không tải được ảnh sơ đồ (${response.statusCode})');
    }

    return response.bodyBytes;
  }

  /// Parse QR code, call scan endpoint, match marker & linked start node (Section 6.1 & 6.2)
  static Future<QrLocationResult> resolveQrToLocation({
    required String rawQr,
    required PublishedIndoorMap map,
  }) async {
    final trimmed = rawQr.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Mã QR trống.');
    }

    // Extract qrCode from URI if it's a full URL
    String extractedCode = trimmed;
    try {
      final uri = Uri.parse(trimmed);
      if (uri.hasScheme && uri.pathSegments.isNotEmpty) {
        // e.g. /api/artifacts/scan/{qrCode}
        final scanIdx = uri.pathSegments.indexOf('scan');
        if (scanIdx != -1 && scanIdx < uri.pathSegments.length - 1) {
          extractedCode = uri.pathSegments[scanIdx + 1];
        } else {
          extractedCode = uri.pathSegments.last;
        }
      }
    } catch (_) {
      // not a uri, keep raw string
    }

    if (extractedCode.isEmpty) {
      throw const FormatException('Mã QR không thuộc hệ thống bảo tàng.');
    }

    // Call real scan endpoint
    final data = await ArtifactScanService.scan(extractedCode);
    final artifactId = (data['id'] as num?)?.toInt();
    final museumId = (data['museumId'] as num?)?.toInt();
    final artifactName = data['name']?.toString() ?? 'Hiện vật';

    if (artifactId == null) {
      throw const FormatException('Hiện vật không tìm thấy hoặc mã QR không hợp lệ.');
    }

    // Verify museum match if available
    if (museumId != null && map.museumId != 0 && museumId != map.museumId) {
      throw FormatException('Hiện vật "$artifactName" thuộc bảo tàng khác, không có trên sơ đồ này.');
    }

    // Look for matching active marker with linked nodeId
    final matchingMarkers = map.markers.where((m) =>
      m.type == 'artifact' &&
      m.isActive &&
      m.artifactId == artifactId &&
      m.nodeId != null &&
      m.nodeId!.isNotEmpty
    ).toList();

    if (matchingMarkers.isEmpty) {
      // Check if artifact is mapped but inactive or without linked node
      final unlinked = map.markers.any((m) => m.artifactId == artifactId);
      if (unlinked) {
        throw FormatException('Hiện vật "$artifactName" chưa được liên kết vị trí lối đi trên sơ đồ.');
      }
      throw FormatException('Hiện vật "$artifactName" chưa có vị trí trên sơ đồ này.');
    }

    final matched = matchingMarkers.first;
    return QrLocationResult(
      marker: matched,
      startNodeId: matched.nodeId!,
      artifactName: artifactName,
    );
  }
}
