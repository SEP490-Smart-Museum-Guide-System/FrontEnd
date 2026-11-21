import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/core/network/api_config.dart';
import 'package:smgs_mobile/models/auth_session.dart';
import 'package:smgs_mobile/services/token_manager.dart';
import 'package:smgs_mobile/services/vision_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Vision sends the visitor JWT to BE and unwraps its response', () async {
    SharedPreferences.setMockInitialValues({});
    await TokenManager.saveSession(
      AuthSession(
        accessToken: 'visitor-test-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        email: 'visitor@example.test',
        fullName: 'Test visitor',
        role: 'Visitor',
      ),
    );
    final previousHost = ApiConfig.customHost;
    ApiConfig.customHost = 'https://backend.example.test';
    addTearDown(() async {
      ApiConfig.customHost = previousHost;
      await TokenManager.clearSession();
    });
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.headers['Authorization'], 'Bearer visitor-test-token');
      expect(request.headers.containsKey('X-Service-Key'), isFalse);
      if (request.method == 'GET') {
        expect(
          request.url.toString(),
          'https://backend.example.test/api/vision/health',
        );
        return http.Response(
          '{"data":{"status":"ok","model_ready":true,"reference_images":2}}',
          200,
        );
      }
      expect(
        request.url.toString(),
        'https://backend.example.test/api/vision/recognitions?top_k=3&museum_id=7',
      );
      expect(
        request.headers['Content-Type'],
        startsWith('multipart/form-data; boundary='),
      );
      expect(request.body, contains('name="image"'));
      return http.Response(
        '{"data":{"matched":false,"artifactId":null,"requiresConfirmation":true,"candidates":[{"artifactId":3,"similarity":0.8}]}}',
        200,
      );
    });
    await http.runWithClient(() async {
      expect((await VisionApiService.checkHealth())['reference_images'], 2);
      final result = await VisionApiService.recognizeArtifact(
        Uint8List.fromList([1, 2, 3]),
        museumId: 7,
      );
      expect(result.matched, isFalse);
      expect(result.topCandidates.single.artifactId, 3);
    }, () => client);
    expect(calls, 2);
  });
  test(
    'Ambiguous Vision result retains canonical candidates and their similarity',
    () {
      final result = VisionMatchResult.fromJson({
        'matched': false,
        'artifactId': null,
        'requiresConfirmation': true,
        'similarity': 0.88,
        'margin': 0.01,
        'candidates': [
          {'artifactId': 7, 'similarity': 0.88},
          {'artifactId': 9, 'similarity': 0.87},
        ],
      });
      expect(result.matched, isFalse);
      expect(result.requiresConfirmation, isTrue);
      expect(result.artifactId, isNull);
      expect(result.topCandidates.map((c) => c.artifactId), [7, 9]);
      expect(result.topCandidates.first.score, 0.88);
    },
  );
}
