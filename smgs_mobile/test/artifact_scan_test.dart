import 'package:flutter/material.dart';
import 'package:smgs_mobile/screens/artifact/artifact_qr_scanner.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/core/network/api_config.dart';
import 'package:smgs_mobile/services/artifact_scan_service.dart';

void main() {
  testWidgets('manual QR displays backend details without mock catalog', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: ArtifactQrScanner()));
        await tester.enterText(find.byType(TextField), 'qr-live');
        await tester.tap(find.text('Xem thông tin hiện vật'));
        await tester.pumpAndSettle();
        expect(find.text('Hiện vật từ API'), findsOneWidget);
        expect(find.text('Bảo tàng từ API'), findsOneWidget);
        expect(find.text('Mô tả xuất bản'), findsOneWidget);
        expect(find.text('Trống đồng Ngọc Lũ'), findsNothing);
      },
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'name': 'Hiện vật từ API',
              'museumName': 'Bảo tàng từ API',
              'contents': [
                {
                  'title': 'Câu chuyện',
                  'languageCode': 'vi',
                  'description': 'Mô tả xuất bản',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
  });
  test('accept raw codes and backend QR URLs; reject unrelated URLs', () {
    expect(ArtifactScanService.extractCode(' abc '), 'abc');
    expect(
      ArtifactScanService.extractCode(
        'https://museum.test/api/artifacts/scan/a%20b',
      ),
      'a b',
    );
    for (final input in [
      '',
      'https://other.test/page',
      'javascript:alert(1)',
      '/bad/path',
    ]) {
      expect(
        () => ArtifactScanService.extractCode(input),
        throwsFormatException,
      );
    }
  });
  test('scan uses configured API and returns published content', () async {
    await http.runWithClient(
      () async {
        final result = await ArtifactScanService.scan(
          'https://untrusted.test/api/artifacts/scan/qr-1',
        );
        expect(result['name'], 'Trống đồng');
        expect(result['contents'][0]['description'], 'Nội dung thật');
      },
      () => MockClient((request) async {
        expect(
          request.url.toString(),
          '${ApiConfig.baseUrl}/artifacts/scan/qr-1',
        );
        return http.Response(
          jsonEncode({
            'data': {
              'name': 'Trống đồng',
              'contents': [
                {'description': 'Nội dung thật'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  });
  test('not found propagates backend message', () async {
    await http.runWithClient(
      () async {
        await expectLater(
          ArtifactScanService.scan('missing'),
          throwsA(predicate((e) => e.toString().contains('Không tìm thấy'))),
        );
      },
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Không tìm thấy'}),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
  });
}
