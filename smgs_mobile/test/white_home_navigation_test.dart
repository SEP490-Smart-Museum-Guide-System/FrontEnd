import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/core/theme/app_theme.dart';
import 'package:smgs_mobile/models/experience.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/navigation/main_navigation.dart';
import 'package:smgs_mobile/screens/home/home_screen.dart';
import 'package:smgs_mobile/screens/scan/scan_screen.dart';
import 'package:smgs_mobile/widgets/heritage_decoration.dart';
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
      'white home and floating navigation preserve 5 tabs at $width',
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
        final surface = find.byKey(const ValueKey('home-white-surface'));
        expect(tester.widget<ColoredBox>(surface).color, Colors.white);
        expect(
          tester
              .widget<Text>(find.text('Mỗi hiện vật,\nmột câu chuyện'))
              .style!
              .color,
          const Color(0xFF292929),
        );
        for (final photo in tester.widgetList<MuseumPhoto>(
          find.descendant(of: surface, matching: find.byType(MuseumPhoto)),
        )) {
          expect(photo.placeholderColor, const Color(0xFFF7F7F5));
        }
        final rail = find.byKey(const ValueKey('visitor-bottom-nav'));
        expect(tester.getTopLeft(rail).dx, greaterThan(0));
        expect(tester.getBottomRight(rail).dx, lessThan(width));
        final initialSize = tester.getSize(rail);
        final scanButton = find.byKey(const ValueKey('visitor-scan-press'));
        expect(tester.getSize(scanButton), const Size(54, 54));
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
          final boxes = find.ancestor(
            of: icon,
            matching: find.byType(SizedBox),
          );
          expect(
            tester.widgetList<SizedBox>(boxes).any((box) => box.height == 54),
            isTrue,
          );
          if (index != 2) {
            expect(tester.widget<Icon>(icon).size, inInclusiveRange(21, 23));
          }
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
          Colors.white,
        );
        await tapText(tester, 'Trang chủ');
        final scroll = find
            .byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  axisDirectionToAxis(w.axisDirection) == Axis.vertical,
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('Bảo tàng cá nhân'),
          240,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        expect(
          tester.getBottomRight(find.text('Bảo tàng cá nhân')).dy,
          lessThan(tester.getTopLeft(rail).dy),
        );
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  }
  apiTestWidgets(
    'scan press and cancellation restore feedback without selecting another tab',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const MainNavigation()),
      );
      await tester.pumpAndSettle();
      final rail = find.byKey(const ValueKey('visitor-bottom-nav'));
      final size = tester.getSize(rail);
      final scan = find.byKey(const ValueKey('visitor-tab:2'));
      final gesture = await tester.startGesture(tester.getCenter(scan));
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('visitor-scan-press')),
            )
            .scale,
        .96,
      );
      expect(tester.getSize(rail), size);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('visitor-scan-press')),
            )
            .scale,
        1,
      );
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('visitor-tab:0')))
            .properties
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
