import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/core/network/api_config.dart';

void main() {
  test('museum uploads use the API host configured on the phone', () {
    final previousHost = ApiConfig.customHost;
    addTearDown(() => ApiConfig.customHost = previousHost);
    ApiConfig.customHost = 'http://192.168.1.20:5169';
    const path = '/api/museums/7/image/cover.png';
    for (final url in [path, 'http://127.0.0.1:5173$path']) {
      expect(ApiConfig.mediaUrl(url), 'http://192.168.1.20:5169$path');
    }
    const external = 'https://cdn.example.com/museum.png';
    expect(ApiConfig.mediaUrl(external), external);
  });
}
