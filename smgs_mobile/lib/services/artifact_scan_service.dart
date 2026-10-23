import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import 'discovery_api_service.dart';

class ArtifactScanService {
  static String extractCode(String input) {
    final value = input.trim();
    if (value.isEmpty) throw const FormatException('Vui lòng nhập mã QR.');
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      final parts = uri.pathSegments;
      if (!['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          parts.length != 4 ||
          parts[0].toLowerCase() != 'api' ||
          parts[1].toLowerCase() != 'artifacts' ||
          parts[2] != 'scan' ||
          parts[3].trim().isEmpty) {
        throw const FormatException('URL không phải mã QR hiện vật.');
      }
      return parts[3];
    }
    if (value.contains('/') || value.contains('?') || value.contains('#')) {
      throw const FormatException('Mã QR không hợp lệ.');
    }
    return value;
  }

  static Future<Map<String, dynamic>> scan(String input) async {
    final code = extractCode(input);
    // Only contact the configured backend, never the host embedded in a QR.
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/artifacts/scan/${Uri.encodeComponent(code)}',
          ),
        )
        .timeout(const Duration(seconds: 12));
    return DiscoveryApiService.decodeResponse(response)['data']
        as Map<String, dynamic>;
  }
}
