import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/screens/home/home_screen.dart';

void main() {
  testWidgets('visitor can change slides and open Explore', (tester) async {
    var explored = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisitorHomeCarousel(
            title: 'Bảo tàng',
            slides: const [
              (imageUrl: '', caption: 'Mặt tiền', title: 'Kiến trúc'),
              (imageUrl: '', caption: 'Sảnh chính', title: 'Không gian'),
            ],
            exploreLabel: 'Khám phá thêm',
            onExplore: () => explored = true,
          ),
        ),
      ),
    );

    expect(find.text('Mặt tiền'), findsOneWidget);
    expect(find.text('Kiến trúc'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Sảnh chính'), findsOneWidget);
    expect(find.text('Không gian'), findsOneWidget);
    expect(find.text('Kiến trúc'), findsNothing);
    await tester.tap(find.text('Khám phá thêm'));
    expect(explored, isTrue);
  });
}
