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
    SharedPreferences.setMockInitialValues({
      GameTutorialOverlay.prefKeyFor('guest'): true,
    });
    AppServices.catalog = HomeCatalog(mockMuseums);
    AppServices.auth = MockAuthService();
  });
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    homeTest('compact home fits $width with enlarged Vietnamese text', (
      tester,
    ) async {
      await screenSize(tester, Size(width, 844));
      await tester.pumpWidget(host(HomeScreen(onExplore: () {}), scale: 1.3));
      await tester.pumpAndSettle();
      expect(find.text(mockMuseums.first.name), findsOneWidget);
      expect(find.text('Khám phá thêm'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  homeTest(
    'published title and slides replace the default cover',
    (tester) async {
      var explores = 0;
      await tester.pumpWidget(host(HomeScreen(onExplore: () => explores++)));
      await tester.pumpAndSettle();
      expect(find.text('Bảo tàng của chúng ta'), findsOneWidget);
      expect(find.text('Mặt tiền'), findsOneWidget);
      await tester.tap(find.byTooltip('Ảnh 2'));
      await tester.pumpAndSettle();
      expect(find.text('Sảnh chính'), findsOneWidget);
      await tester.tap(find.text('Khám phá thêm'));
      expect(explores, 1);
    },
    request: (_) async => response({
      'title': 'Bảo tàng của chúng ta',
      'slides': [
        {'name': 'front.jpg', 'caption': 'Mặt tiền'},
        {'name': 'hall.jpg', 'caption': 'Sảnh chính'},
      ],
    }),
  );

  late Completer<http.Response> coverResponse;
  homeTest('pending configuration does not display a fallback photo', (
    tester,
  ) async {
    coverResponse = Completer<http.Response>();
    await tester.pumpWidget(host(HomeScreen(onExplore: () {})));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    coverResponse.complete(response({'title': '', 'slides': []}));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  }, request: (_) => coverResponse.future);

  homeTest('unavailable configuration falls back to the museum cover', (
    tester,
  ) async {
    await tester.pumpWidget(host(HomeScreen(onExplore: () {})));
    await tester.pumpAndSettle();
    expect(find.text(mockMuseums.first.name), findsOneWidget);
    expect(find.byTooltip('Ảnh 1'), findsNothing);
  }, request: (_) async => response({}, 503));

  homeTest('every first-time tutorial target still exists', (tester) async {
    await tester.pumpWidget(host(HomeScreen(onExplore: () {})));
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
      expect(
        tester.getBottomRight(find.text('Khám phá thêm')).dy,
        lessThan(tester.getTopLeft(tab).dy),
      );

      expect(tester.takeException(), isNull);
    });
  }

  homeTest(
    'first-time home tutorial fits 320px with large text through every step',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
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
          home: Scaffold(body: HomeScreen(onExplore: () {})),
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
}
