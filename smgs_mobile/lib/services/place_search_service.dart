import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../models/map_place.dart';
import 'discovery_api_service.dart';

class PlaceSearchService {
  static Future<List<MapPlace>> search(String query) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/places',
    ).replace(queryParameters: {'q': query.trim()});
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    final data = DiscoveryApiService.decodeResponse(response)['data'] as List;
    return data
        .map((e) => MapPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
