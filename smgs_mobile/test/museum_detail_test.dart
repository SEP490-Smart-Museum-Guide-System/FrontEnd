import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/widgets/exploration_map_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/screens/artifact/artifact_qr_scanner.dart';
import 'package:smgs_mobile/screens/museum/visitor_directory_screen.dart';
import 'package:smgs_mobile/screens/museum/museum_detail_screen.dart';
import 'package:smgs_mobile/services/discovery_api_service.dart';

import 'support/mock_museums.dart';
import 'widget_test.dart' show host, screenSize;

void main() {
  testWidgets('exploration map button renders above the Navigator', (
    tester,
  ) async {
    final exploration = MuseumExploration.instance;
    final navigation = ExplorationNavigator();
    addTearDown(() => exploration.select(null));
    await exploration.select(7);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [navigation],
        builder: (context, child) => Stack(
          children: [
            child!,
            Positioned.fill(
              child: ExplorationMapButton(navigation: navigation),
            ),
          ],
        ),
        home: const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
    navigation.navigator!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'QRScanScreen'),
        builder: (_) => const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    navigation.navigator!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'ArtifactQrScanner'),
        builder: (_) => const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byIcon(Icons.map_outlined);
    expect(button, findsOneWidget);
    final start = tester.getCenter(button);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-24, 30));
    await tester.pump();
    expect(find.byIcon(Icons.close), findsOneWidget);
    final target = tester.getCenter(find.byIcon(Icons.close));
    await gesture.moveTo(target);
    await tester.pump();
    expect(
      (tester.getCenter(button) - target).distance,
      lessThan(44),
      reason: 'Button at ${tester.getCenter(button)}, target at $target',
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(button, findsNothing);
    expect(exploration.museumId, isNull);
  });

  test('exploration restores per Visitor and ends independently', () async {
    SharedPreferences.setMockInitialValues({});
    final first = MuseumExploration();
    await first.restore('visitor@example.test');
    await first.select(7);
    await first.select(8);
    final reopened = MuseumExploration();
    await reopened.restore('visitor@example.test');
    expect(reopened.museumId, 8);
    await reopened.restore('other@example.test');
    expect(reopened.museumId, isNull);
    await reopened.restore('visitor@example.test');
    await reopened.select(null);
    await first.restore('visitor@example.test');
    expect(first.museumId, isNull);
  });
  for (final width in [360.0, 375.0, 390.0, 430.0]) {
    testWidgets('museum detail and direct scanner fit at ${width}px', (
      tester,
    ) async {
      await screenSize(tester, Size(width, 760));
      final museum = mockMuseums.first.copyWith(
        id: '7',
        name: 'Bảo tàng Lịch sử và Văn hóa các dân tộc Việt Nam',
        description: List.filled(6, mockMuseums.first.description).join('\n'),
        openingHours: '08:00 - 17:00 (Thứ Ba - Chủ Nhật)',
      );
      await tester.pumpWidget(
        host(
          MuseumDetailScreen(
            museum: museum,
            loadMuseum: (id) async {
              expect(id, '7');
              return museum;
            },
            loadHighlights: (id) async {
              expect(id, '7');
              return const MuseumHighlights(12, [
                MuseumHighlightArtifact('Trống đồng Đông Sơn', ''),
                MuseumHighlightArtifact('Bình gốm hoa lam', ''),
                MuseumHighlightArtifact('Tượng đất nung', ''),
              ]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(museum.name), findsOneWidget);
      expect(find.text('HIỆN VẬT QR'), findsOneWidget);
      expect(find.text('Chưa xác định vị trí của bạn'), findsNothing);
      final last = find.text('Tượng đất nung');
      await tester.scrollUntilVisible(
        last,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      final button = find.text('Bắt đầu khám phá');
      expect(
        tester.getBottomLeft(last).dy,
        lessThan(tester.getTopLeft(button).dy),
      );
      if (width == 390) {
        await tester.tap(find.byTooltip('Mở bản đồ bảo tàng'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<VisitorDirectoryScreen>(
                find.byType(VisitorDirectoryScreen),
              )
              .museumId,
          7,
        );
      }
      if (width != 390) {
        await tester.tap(button);
        await tester.pumpAndSettle();
        final scanner = tester.widget<ArtifactQrScanner>(
          find.byType(ArtifactQrScanner),
        );
        expect(scanner.direct && scanner.standalone, isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
