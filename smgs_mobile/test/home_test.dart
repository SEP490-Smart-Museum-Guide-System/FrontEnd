import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/navigation/main_navigation.dart';
import 'package:smgs_mobile/core/theme/app_theme.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/screens/home/home_screen.dart';
import 'package:smgs_mobile/screens/museum/museum_detail_screen.dart';
import 'package:smgs_mobile/screens/museum/visit_progress_screen.dart';
import 'package:smgs_mobile/screens/profile/my_museum_screen.dart';
import 'package:smgs_mobile/widgets/game_tutorial_overlay.dart';
import 'support/fake_services.dart';
import 'support/mock_museums.dart';
import 'widget_test.dart' show host, screenSize;

class HomeCatalog extends MockCatalogService {
  HomeCatalog(this.rows);
  final List<Museum> rows;
  @override
  List<Museum> get museums => rows;
}

http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode({'data': data, 'message': 'Unavailable'}),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void homeTest(
  String name,
  Future<void> Function(WidgetTester) body, {
  Future<http.Response> Function(http.Request)? request,
}) {
  testWidgets(
    name,
    (tester) => http.runWithClient(
      () => body(tester),
      () => MockClient(request ?? (_) async => response([])),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppServices.catalog = HomeCatalog(mockMuseums);
    AppServices.auth = MockAuthService();
  });
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    homeTest('compact home fits $width with enlarged Vietnamese text', (
      tester,
    ) async {
      await screenSize(tester, Size(width, 844));
      await tester.pumpWidget(
        host(HomeScreen(onExplore: () {}, onScan: () {}), scale: 1.3),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mỗi hiện vật,\nmột câu chuyện'), findsOneWidget);
      for (final title in [
        'Bảo tàng nổi bật',
        'Bắt đầu hành trình khám phá',
        'Bảo tàng cá nhân',
      ]) {
        await reveal(tester, find.text(title));
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Về đầu trang'), findsNothing);
      expect(find.text('Thử tài cùng trống đồng'), findsNothing);
      expect(find.text('Chuyện chốn cung đình'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .maxScrollExtent,
        lessThan(2300),
      );
    });
  }
  homeTest('scan and discovery keep navigation callbacks', (tester) async {
    var scans = 0, explores = 0;
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      host(HomeScreen(onExplore: () => explores++, onScan: () => scans++)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giải mã một hiện vật'));
    expect(scans, 1);
    await reveal(tester, find.text('Xem tất cả'));
    await tester.tap(find.text('Xem tất cả'));
    expect(explores, 1);
    await reveal(tester, find.text('Khám phá bảo tàng'));
    await tester.tap(find.text('Khám phá bảo tàng'));
    expect(explores, 2);
  });
  homeTest(
    'one museum is not duplicated and opens its existing detail screen',
    (tester) async {
      AppServices.catalog = HomeCatalog([mockMuseums.first]);
      await tester.pumpWidget(
        host(HomeScreen(onExplore: () {}, onScan: () {})),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey('home-museum:${mockMuseums.first.id}'));
      await reveal(tester, card);
      expect(find.text(mockMuseums.first.name), findsOneWidget);
      expect(find.text(mockMuseums.first.description), findsNothing);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MuseumDetailScreen>(find.byType(MuseumDetailScreen))
            .museum
            .id,
        mockMuseums.first.id,
      );
      expect(tester.takeException(), isNull);
    },
  );
  var museumVisitRequests = 0;
  homeTest(
    'returning from museum details refreshes the current visit',
    (tester) async {
      AppServices.catalog = HomeCatalog([mockMuseums.first]);
      await tester.pumpWidget(
        host(HomeScreen(onExplore: () {}, onScan: () {})),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey('home-museum:${mockMuseums.first.id}'));
      await reveal(tester, card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(museumVisitRequests, 2);
      expect(find.text('Tiếp tục hành trình'), findsOneWidget);
    },
    request: (r) async => r.url.path == '/api/visits/me'
        ? response(
            museumVisitRequests++ == 0
                ? []
                : [
                    {'id': 42, 'museumId': mockMuseums.first.id},
                  ],
          )
        : response({}, 503),
  );

  homeTest('empty catalog does not invent museum cards', (tester) async {
    AppServices.catalog = HomeCatalog([]);
    await tester.pumpWidget(host(HomeScreen(onExplore: () {}, onScan: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Bảo tàng nổi bật'), findsNothing);
    await reveal(tester, find.text('Bắt đầu hành trình khám phá'));
    expect(find.text('Tiếp tục hành trình'), findsNothing);
  });
  homeTest(
    'active visit opens API visit id without invented progress',
    (tester) async {
      await tester.pumpWidget(
        host(HomeScreen(onExplore: () {}, onScan: () {})),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Tiếp tục hành trình'));
      expect(find.text('Bắt đầu hành trình khám phá'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Đã khám phá 1 / 2 hiện vật'), findsOneWidget);
      await reveal(tester, find.text('Xem tiến độ'));
      await tester.tap(find.text('Xem tiến độ'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VisitProgressScreen>(find.byType(VisitProgressScreen))
            .visitId,
        42,
      );
    },
    request: (r) async => r.url.path == '/api/visits/me'
        ? response([
            {
              'id': 42,
              'museumId': mockMuseums.first.id,
              'status': 'InProgress',
            },
          ])
        : r.url.path == '/api/visits/42/progress'
        ? response({
            'stops': [
              {'artifactId': 1, 'lastVisitedAt': '2026-11-19T01:00:00Z'},
              {'artifactId': 2, 'lastVisitedAt': null},
            ],
          })
        : response({}, 503),
  );
  var retryRequests = 0;
  homeTest(
    'visit API errors can retry without a false empty state',
    (tester) async {
      await tester.pumpWidget(
        host(HomeScreen(onExplore: () {}, onScan: () {})),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Chưa tải được hành trình'));
      expect(find.text('Tiếp tục hành trình'), findsNothing);
      expect(find.text('Bắt đầu hành trình khám phá'), findsNothing);
      await reveal(tester, find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được hành trình'), findsNothing);
      expect(find.text('Bắt đầu hành trình khám phá'), findsOneWidget);
    },
    request: (_) async =>
        retryRequests++ == 0 ? response({}, 503) : response([]),
  );
  homeTest('personal collection opens its existing screen', (tester) async {
    await tester.pumpWidget(host(HomeScreen(onExplore: () {}, onScan: () {})));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Bảo tàng cá nhân'));
    await tester.tap(find.text('Bảo tàng cá nhân'));
    await tester.pumpAndSettle();
    expect(find.byType(MyMuseumScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  homeTest('every first-time tutorial target still exists', (tester) async {
    await tester.pumpWidget(host(HomeScreen(onExplore: () {}, onScan: () {})));
    await tester.pumpAndSettle();
    for (final step in HomeScreenTour.getSteps()) {
      expect(step.targetKey.currentContext, isNotNull, reason: step.title);
    }
  });
  for (final size in [const Size(360, 800), const Size(430, 932)]) {
    homeTest('navigation respects display cutouts and bottom inset at $size', (
      tester,
    ) async {
      await screenSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 59, bottom: 34),
              viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
              textScaler: const TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const MainNavigation(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byTooltip('Cẩm nang tham quan')).dy,
        greaterThanOrEqualTo(59),
      );
      final tab = find.text('Trang chủ');
      expect(
        tester.getBottomRight(tab).dy,
        lessThanOrEqualTo(size.height - 34),
      );
      await reveal(tester, find.text('Bảo tàng cá nhân'));
      expect(
        tester.getBottomRight(find.text('Bảo tàng cá nhân')).dy,
        lessThan(tester.getTopLeft(tab).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }

  homeTest(
    'first-time home tutorial fits 320px with large text through every step',
    (tester) async {
      await screenSize(tester, const Size(320, 640));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: HomeScreen(onExplore: () {}, onScan: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      HomeScreenTour.start(tester.element(find.byType(HomeScreen)));
      await tester.pumpAndSettle();
      for (var i = 0; i < HomeScreenTour.getSteps().length; i++) {
        expect(tester.takeException(), isNull, reason: 'Tutorial step $i');
        final button = find.text(
          i == HomeScreenTour.getSteps().length - 1 ? 'Hoàn thành' : 'Tiếp tục',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }
      expect(find.byType(GameTutorialOverlay), findsNothing);
    },
  );

  homeTest(
    'tutorial has no repeating animations when reduced motion is enabled',
    (tester) async {
      final target = GlobalKey();
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox(key: target, width: 200, height: 80),
                GameTutorialOverlay(
                  steps: [
                    TutorialQuestStep(
                      targetKey: target,
                      questBadge: 'Cẩm nang',
                      title: 'Tham quan',
                      description: 'Hướng dẫn',
                      icon: Icons.menu_book_outlined,
                    ),
                  ],
                  onComplete: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  late Completer<http.Response> waiting;
  homeTest('loading does not fabricate visit state', (tester) async {
    waiting = Completer<http.Response>();
    await tester.pumpWidget(host(HomeScreen(onExplore: () {}, onScan: () {})));
    await tester.pump();
    expect(find.byKey(const ValueKey('home-visit-loading')), findsOneWidget);
    expect(find.text('Bắt đầu hành trình khám phá'), findsNothing);
    waiting.complete(response([]));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-visit-loading')), findsNothing);
  }, request: (_) => waiting.future);
}
