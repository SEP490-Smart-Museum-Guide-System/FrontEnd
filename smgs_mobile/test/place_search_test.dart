import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/models/map_place.dart';
import 'package:smgs_mobile/widgets/place_search_field.dart';

void main() {
  test('place rejects invalid coordinates', () {
    expect(
      () => MapPlace.fromJson({
        'name': 'Test',
        'address': '',
        'latitude': 91,
        'longitude': 1,
      }),
      throwsFormatException,
    );
  });
  testWidgets('debounce, stale responses, select and clear', (tester) async {
    final requests = <String, Completer<List<MapPlace>>>{};
    MapPlace? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceSearchField(
            onSelected: (value) => selected = value,
            search: (q) => (requests[q] = Completer<List<MapPlace>>()).future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump(const Duration(seconds: 1));
    expect(requests, isEmpty);
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 700));
    requests['old']!.complete([const MapPlace('Old place', '', 1, 1)]);
    requests['new']!.complete([
      const MapPlace('New place', 'Address', 10, 106),
    ]);
    await tester.pump();
    expect(find.text('Old place'), findsNothing);
    await tester.tap(find.text('New place'));
    await tester.pump();
    expect(selected?.longitude, 106);
    expect(find.byType(ListTile), findsNothing);
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pump();
    expect(selected, isNull);
  });
  testWidgets('provider failure displays retry message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceSearchField(
            onSelected: (_) {},
            search: (_) async => throw Exception('offline'),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'park');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.textContaining('Không tải được gợi ý'), findsOneWidget);
  });
}
