import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/screens/auth/auth_screen.dart';
import 'widget_test.dart' show host, screenSize;

void main() {
  for (final size in [const Size(1440, 1000), const Size(390, 844)]) {
    testWidgets('visitor login fits $size and shows a bundled museum photo', (
      tester,
    ) async {
      await screenSize(tester, size);
      await tester.pumpWidget(host(const AuthScreen()));
      await tester.pumpAndSettle();
      final email = find.widgetWithText(TextFormField, 'Email');
      expect(tester.getSize(email).width, lessThanOrEqualTo(480));
      expect(
        find.image(const AssetImage('assets/images/national-museum-web.jpg')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
