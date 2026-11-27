import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/core/theme/app_theme.dart';
import 'package:smgs_mobile/core/theme/visitor_colors.dart';
import 'package:smgs_mobile/models/experience.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/navigation/main_navigation.dart';
import 'package:smgs_mobile/screens/home/home_screen.dart';
import 'package:smgs_mobile/screens/scan/scan_screen.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'support/api_widgets.dart';
import 'support/fake_services.dart';
import 'widget_test.dart' show screenSize, tapText;

class _CoverCatalog extends MockCatalogService {
  @override
  List<Museum> get museums => super.museums
      .map(
        (museum) =>
            museum.copyWith(imageUrl: 'assets/images/national-museum-web.jpg'),
      )
      .toList();
}

void main() {
  setUp(() {
    AppServices.catalog = _CoverCatalog();
    AppServices.auth = MockAuthService(
      initialUser: const VisitorUser(
        name: 'Khách',
        email: 'visitor@test.invalid',
      ),
    );
  });
  for (final width in [360.0, 390.0, 430.0]) {
    apiTestWidgets(
      'photo home and bottom navigation preserve 5 tabs at $width',
      (tester) async {
        await screenSize(tester, Size(width, 844));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const MainNavigation(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(VisitorHomeCarousel), findsOneWidget);
        expect(
          tester.getRect(find.byType(VisitorHomeCarousel)),
          Rect.fromLTWH(0, 0, width, 844),
        );
        final rail = find.byKey(const ValueKey('visitor-bottom-nav'));
        expect(tester.getTopLeft(rail).dx, 0);
        expect(tester.getBottomRight(rail).dx, width);
        final initialSize = tester.getSize(rail);
        double? labelTop;
        for (var index = 0; index < 5; index++) {
          final tab = find.byKey(ValueKey('visitor-tab:$index'));
          expect(
            tester.getSize(tab).width,
            closeTo(initialSize.width / 5, .01),
          );
          final label = find.descendant(of: tab, matching: find.byType(Text));
          labelTop ??= tester.getTopLeft(label).dy;
          expect(tester.getTopLeft(label).dy, closeTo(labelTop, .01));
          final icon = find.descendant(of: tab, matching: find.byType(Icon));
          expect(tester.widget<Icon>(icon).size, 22);
        }
        for (var i = 0; i < 5; i++) {
          final item = find.byKey(ValueKey('visitor-tab:$i'));
          await tester.tap(item);
          await tester.pumpAndSettle();
          expect(tester.widget<Semantics>(item).properties.selected, isTrue);
          expect(tester.getSize(rail), initialSize);
          if (i == 2) expect(find.byType(ScanScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(
          Theme.of(
            tester.element(find.byType(MainNavigation)),
          ).scaffoldBackgroundColor,
          VisitorColors.background,
        );
        await tapText(tester, 'Trang chủ');
        expect(
          tester.getBottomRight(find.text('Khám phá thêm')).dy,
          lessThan(tester.getTopLeft(rail).dy),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        await tester.tap(find.text('Khám phá thêm'));
        await tester.pumpAndSettle();
        final explore = find.byKey(const ValueKey('visitor-tab:1'));
        expect(tester.widget<Semantics>(explore).properties.selected, isTrue);
      },
    );
  }
  apiTestWidgets('cancelling a scan press leaves the current tab selected', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainNavigation()),
    );
    await tester.pumpAndSettle();
    final rail = find.byKey(const ValueKey('visitor-bottom-nav'));
    final size = tester.getSize(rail);
    final scan = find.byKey(const ValueKey('visitor-tab:2'));
    final gesture = await tester.startGesture(tester.getCenter(scan));
    await tester.pump();
    expect(tester.getSize(rail), size);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('visitor-tab:0')))
          .properties
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
