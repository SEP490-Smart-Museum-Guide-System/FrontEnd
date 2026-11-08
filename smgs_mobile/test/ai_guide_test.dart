import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/models/artifact.dart';
import 'package:smgs_mobile/models/experience.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/screens/ai_guide/ai_guide_screen.dart';
import 'support/fake_services.dart';
import 'widget_test.dart' show host, screenSize, tapText;

final artifact = Artifact.fromBackendJson({
  'id': 17,
  'museumId': 1,
  'name': 'Bình gốm đã xuất bản',
});
http.Response reply({int id = 17, bool supported = true, int status = 200}) =>
    http.Response(
      jsonEncode({
        if (status == 200)
          'data': {
            'artifactId': id,
            'answer': supported
                ? 'Bình gốm dùng để đựng nước.'
                : 'Nội dung đã xuất bản chưa đủ thông tin.',
            'supported': supported,
            'sources': supported
                ? [
                    {
                      'contentVersionId': 91,
                      'versionNo': 2,
                      'title': 'Bình đựng nước',
                      'languageCode': 'vi',
                    },
                  ]
                : [],
          },
        if (status != 200)
          'message': status == 403
              ? 'Cần pass còn hiệu lực.'
              : 'Trợ lý chưa được kết nối dịch vụ AI.',
      }),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<void> settle(WidgetTester tester) async {
  // HTTP mocks resolve in real microtasks; no live API or model calls are made.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 10)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppServices.guide = BackendAiGuideService();
    AppServices.auth = MockAuthService(
      initialUser: const VisitorUser(name: 'An', email: 'an@example.test'),
    );
  });

  test(
    'Guide API posts only question/history to BE and validates artifact/source',
    () async {
      await http.runWithClient(
        () async {
          final result = await AppServices.guide.answer(
            artifact,
            ' Bình dùng làm gì? ',
            history: const [
              GuideTurn('user', 'Đây là gì?'),
              GuideTurn('assistant', 'Bình gốm.'),
            ],
          );
          expect(result.text, 'Bình gốm dùng để đựng nước.');
          expect(result.sources.single.contentVersionId, 91);
        },
        () => MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/artifacts/17/guide/messages');
          expect(
            request.headers.keys.any(
              (k) => k.contains('api-key') || k.contains('service-key'),
            ),
            isFalse,
          );
          final data = jsonDecode(request.body) as Map;
          expect(data.keys, unorderedEquals(['question', 'history']));
          expect(data['question'], 'Bình dùng làm gì?');
          expect((data['history'] as List).length, 2);
          return reply();
        }),
      );
      await http.runWithClient(() async {
        await expectLater(
          AppServices.guide.answer(artifact, 'Hỏi'),
          throwsFormatException,
        );
      }, () => MockClient((_) async => reply(id: 18)));
    },
  );

  test(
    'Premium/model failures stay errors; unsupported answers have no invented source',
    () async {
      for (final code in [403, 503]) {
        await http.runWithClient(() async {
          await expectLater(
            AppServices.guide.answer(artifact, 'Hỏi'),
            throwsException,
          );
        }, () => MockClient((_) async => reply(status: code)));
      }
      await http.runWithClient(() async {
        final result = await AppServices.guide.answer(artifact, 'Ai tìm thấy?');
        expect(result.supported, isFalse);
        expect(result.sources, isEmpty);
      }, () => MockClient((_) async => reply(supported: false)));
    },
  );

  testWidgets(
    'Visitor asks follow-ups, sees source, listens and starts fresh',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      final bodies = <Map>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(host(AiGuideScreen(artifact: artifact)));
          await tapText(tester, 'Hiện vật này có ý nghĩa gì?');
          await settle(tester);
          expect(find.text('Bình gốm dùng để đựng nước.'), findsOneWidget);
          expect(find.text('Bình đựng nước · Phiên bản 2'), findsOneWidget);
          expect(find.text('Đọc và nghe câu trả lời'), findsOneWidget);
          expect(bodies.first['history'], isEmpty);
          await tester.enterText(find.byType(TextField), 'Nó dùng làm gì?');
          await tester.tap(find.byTooltip('Gửi câu hỏi'));
          await settle(tester);
          expect((bodies.last['history'] as List).length, 2);
          await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
          await tester.pumpAndSettle();
          expect(find.text('Bình gốm dùng để đựng nước.'), findsNothing);
          await tapText(tester, 'Hiện vật này có ý nghĩa gì?');
          await settle(tester);
          expect(bodies.last['history'], isEmpty);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          bodies.add(jsonDecode(request.body) as Map);
          return reply();
        }),
      );
    },
  );

  testWidgets(
    'Provider failure can retry without duplicating a question or narrating an error',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      var calls = 0;
      await http.runWithClient(() async {
        await tester.pumpWidget(host(AiGuideScreen(artifact: artifact)));
        await tapText(tester, 'Hiện vật thuộc thời kỳ nào?');
        await settle(tester);
        expect(find.textContaining('Trợ lý chưa được kết nối'), findsOneWidget);
        expect(find.text('Đọc và nghe câu trả lời'), findsNothing);
        await tapText(tester, 'Thử lại câu hỏi');
        await settle(tester);
        // One suggestion plus one visitor bubble; retry does not add another bubble.
        expect(find.text('Hiện vật thuộc thời kỳ nào?'), findsNWidgets(2));
        expect(find.text('Bình gốm dùng để đựng nước.'), findsOneWidget);
        expect(calls, 2);
      }, () => MockClient((_) async => reply(status: ++calls == 1 ? 503 : 200)));
    },
  );

  testWidgets('Logout drops chat and ignores an in-flight answer', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    final pending = Completer<http.Response>();
    await http.runWithClient(() async {
      await tester.pumpWidget(host(AiGuideScreen(artifact: artifact)));
      await tester.ensureVisible(find.text('Hiện vật này có ý nghĩa gì?'));
      await tester.tap(find.text('Hiện vật này có ý nghĩa gì?'));
      await tester.pump();
      await AppServices.auth.logout();
      await tester.pump();
      pending.complete(reply());
      await settle(tester);
      expect(find.text('Bình gốm dùng để đựng nước.'), findsNothing);
      expect(find.text('Đọc và nghe câu trả lời'), findsNothing);
    }, () => MockClient((_) => pending.future));
  });
}
