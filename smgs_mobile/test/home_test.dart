import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/screens/home/home_screen.dart';
import 'package:smgs_mobile/screens/explore/explore_screen.dart';
import 'package:smgs_mobile/screens/tours/tours_screen.dart';
import 'package:smgs_mobile/screens/artifact/quiz_screen.dart';

import 'widget_test.dart' show host, screenSize;

Future<void> reach(WidgetTester tester, String title) async {
  final scroll = find.byType(Scrollable).first;
  for (var i = 0; i < 45; i++) {
    final target = find.text(title);
    if (target.evaluate().isNotEmpty) {
      final y = tester.getCenter(target.last).dy;
      if (y > 90 && y < tester.view.physicalSize.height - 40) return;
    }
    await tester.drag(scroll, const Offset(0, -380));
    await tester.pumpAndSettle();
  }
  fail('Could not reach $title');
}

void main() {
  testWidgets('Every home chapter fits a narrow screen with enlarged text', (
    tester,
  ) async {
    await screenSize(tester, const Size(320, 640));
    await tester.pumpWidget(
      host(HomeScreen(onExplore: () {}, onScan: () {}), scale: 1.3),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final scroll = find.byType(Scrollable).first;
    var reachedEnd = false;
    for (var i = 0; i < 45; i++) {
      final footer = find.text('Về đầu trang').hitTestable();
      if (footer.evaluate().isNotEmpty) {
        reachedEnd = true;
        break;
      }
      await tester.drag(scroll, const Offset(0, -380));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Home scroll step $i');
    }
    expect(reachedEnd, isTrue);
    final position = tester.state<ScrollableState>(scroll).position;
    expect(position.maxScrollExtent, greaterThan(3500));
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('home-reading-progress')),
          )
          .value,
      greaterThan(0.9),
    );
    await tester.tap(find.text('Về đầu trang'));
    await tester.pumpAndSettle();
    expect(position.pixels, 0);
    expect(find.text('Chạm vào\nmiền ký ức.').hitTestable(), findsOneWidget);
  });

  testWidgets('Home themes, itinerary, quiz and visitor guide are connected', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(host(HomeScreen(onExplore: () {}, onScan: () {})));
    await tester.pumpAndSettle();
    await reach(tester, 'Chuyện chốn cung đình');
    await tester.tap(find.text('Chuyện chốn cung đình'));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    final selected = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Cung đình'),
    );
    expect(selected.selected, isTrue);
    expect(find.text('1 hiện vật được tìm thấy'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await reach(tester, 'Xem hành trình 60 phút');
    await tester.tap(find.text('Xem hành trình 60 phút'));
    await tester.pumpAndSettle();
    final route = tester.widget<TourRouteScreen>(find.byType(TourRouteScreen));
    expect(route.duration, 60);
    expect(route.stops, hasLength(2));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await reach(tester, 'Thử tài cùng trống đồng');
    await tester.tap(find.text('Thử tài cùng trống đồng'));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await reach(tester, 'Chuẩn bị một chuyến đi');
    await tester.tap(find.text('Chuẩn bị một chuyến đi'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Kiểm tra giờ mở cửa').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
