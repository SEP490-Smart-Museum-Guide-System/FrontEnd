import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/screens/museum/visitor_directory_screen.dart';
import 'package:smgs_mobile/screens/museum/visitor_indoor_map_screen.dart';
import 'widget_test.dart' show host, screenSize;

const nodeA = '11111111-1111-4111-8111-111111111111';
const nodeB = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> mapJson() => {
  'id': 5,
  'museumId': 7,
  'floorId': 2,
  'name': 'Sơ đồ tầng 1',
  'revision': 3,
  'imageKey': 'floor.png',
  'imageWidth': 600,
  'imageHeight': 400,
  'nodes': [
    {'id': nodeA, 'label': 'Điểm đầu', 'x': 0.1, 'y': 0.2},
    {'id': nodeB, 'label': 'Điểm đích', 'x': 0.7, 'y': 0.6},
  ],
  'markers': [
    {
      'id': 'start',
      'label': 'Hiện vật đầu',
      'artifactId': 10,
      'nodeId': nodeA,
      'x': 0.1,
      'y': 0.2,
      'isActive': true,
      'isDestination': true,
    },
    {
      'id': 'target',
      'label': 'Trống đồng',
      'artifactId': 11,
      'nodeId': nodeB,
      'x': 0.7,
      'y': 0.6,
      'isActive': true,
      'isDestination': true,
    },
  ],
  'edges': [
    {
      'id': 'edge',
      'fromNodeId': nodeA,
      'toNodeId': nodeB,
      'bidirectional': true,
      'isAccessible': true,
    },
  ],
};
Map<String, dynamic> directory() => {
  'museumId': 7,
  'museumName': 'Bảo tàng thử',
  'galleries': [
    {
      'id': 3,
      'name': 'Phòng Đông Sơn',
      'floorId': 2,
      'floorName': 'Tầng 1',
      'levelNo': 1,
      'buildingName': 'Nhà A',
    },
    {
      'id': 4,
      'name': 'Phòng Gốm',
      'floorId': 6,
      'floorName': 'Tầng 2',
      'levelNo': 2,
      'buildingName': 'Nhà A',
    },
  ],
  'maps': [
    {'id': 5, 'name': 'Sơ đồ tầng 1', 'floorId': 2},
  ],
  'artifacts': [
    {
      'id': 11,
      'name': 'Trống đồng',
      'galleryId': 3,
      'galleryName': 'Phòng Đông Sơn',
      'floorId': 2,
      'floorName': 'Tầng 1',
      'buildingName': 'Nhà A',
      'maps': [
        {'id': 5, 'name': 'Sơ đồ tầng 1'},
      ],
    },
    {
      'id': 12,
      'name': 'Bình gốm',
      'galleryId': 4,
      'galleryName': 'Phòng Gốm',
      'floorId': 6,
      'floorName': 'Tầng 2',
      'buildingName': 'Nhà A',
      'maps': [],
    },
  ],
};
http.Response data(dynamic value) => http.Response(
  jsonEncode({'data': value}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder get pageScroll => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
    )
    .first;

void main() {
  testWidgets(
    'Directory shows the actual room and opens the actual published map with the chosen destination',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      final requests = <String>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(
              const VisitorDirectoryScreen(
                museumId: 7,
                museumName: 'Bảo tàng thử',
                initialArtifactId: 11,
              ),
            ),
          );
          await frames(tester);
          final button = find.text('Chỉ đường · Sơ đồ tầng 1');
          await tester.scrollUntilVisible(button, 250, scrollable: pageScroll);
          await tester.pumpAndSettle();
          expect(find.text('Phòng Đông Sơn · Tầng 1 · Nhà A'), findsOneWidget);
          await tester.tap(button);
          await frames(tester);
          final screen = tester.widget<VisitorIndoorMapScreen>(
            find.byType(VisitorIndoorMapScreen),
          );
          expect(screen.mapId, 5);
          expect(screen.targetArtifactId, 11);
          expect(requests, contains('/api/indoor-maps/5/published'));
          expect(find.text('Trống đồng'), findsWidgets);
          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Hiện vật đầu').last);
          await frames(tester);
          expect(
            find.text('Đã tìm thấy lộ trình qua 2 điểm rẽ hành lang.'),
            findsOneWidget,
          );
          final viewer = tester.widget<InteractiveViewer>(
            find.byType(InteractiveViewer),
          );
          expect(
            viewer.transformationController!.value.entry(0, 0),
            lessThan(1),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await frames(tester);
        },
        () => MockClient((request) async {
          requests.add(request.url.path);
          if (request.url.path.endsWith('visitor-directory')) {
            return data(directory());
          }
          if (request.url.path.endsWith('/published')) return data(mapJson());
          return http.Response.bytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
            ),
            200,
            headers: {'content-type': 'image/png'},
          );
        }),
      );
    },
  );
  testWidgets(
    'Directory filters rooms and artifacts at 320px with enlarged text; missing map stays explicit',
    (tester) async {
      await screenSize(tester, const Size(320, 700));
      await http.runWithClient(() async {
        await tester.pumpWidget(
          host(const VisitorDirectoryScreen(museumId: 7), scale: 1.3),
        );
        await frames(tester);
        await tester.enterText(find.byType(TextField), 'Bình gốm');
        await frames(tester);
        final item = find.text('Bình gốm', findRichText: false).last;
        await tester.scrollUntilVisible(item, 250, scrollable: pageScroll);
        await tester.pumpAndSettle();
        expect(item, findsOneWidget);
        expect(find.text('Trống đồng'), findsNothing);
        expect(find.text('Phòng Gốm · Tầng 2 · Nhà A'), findsOneWidget);
        expect(
          find.text(
            'Hiện vật chưa được liên kết với điểm đến trên sơ đồ đã xuất bản.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }, () => MockClient((_) async => data(directory())));
    },
  );
  testWidgets(
    'Directory retries API errors without substituting sample rooms or maps',
    (tester) async {
      var calls = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const VisitorDirectoryScreen(museumId: 7)),
          );
          await frames(tester);
          final retry = find.text('Thử lại');
          await tester.scrollUntilVisible(retry, 250, scrollable: pageScroll);
          await tester.pumpAndSettle();
          await tester.tap(retry);
          await frames(tester);
          final item = find.text('Trống đồng');
          await tester.scrollUntilVisible(item, 250, scrollable: pageScroll);
          await tester.pumpAndSettle();
          expect(item, findsOneWidget);
          expect(calls, 2);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('{"message":"Chưa tải được danh mục"}', 503)
              : data(directory());
        }),
      );
    },
  );
  testWidgets(
    'Map image failure shows a retry state instead of a blank floor plan',
    (tester) async {
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const VisitorIndoorMapScreen(mapId: 5, targetArtifactId: 11)),
          );
          await frames(tester);
          expect(
            find.textContaining('Chưa tải được ảnh sơ đồ'),
            findsOneWidget,
          );
          expect(find.text('Thử lại'), findsOneWidget);
          expect(find.byType(InteractiveViewer), findsNothing);
          expect(tester.takeException(), isNull);
        },
        () => MockClient(
          (request) async => request.url.path.endsWith('/published')
              ? data(mapJson())
              : http.Response('', 503),
        ),
      );
    },
  );
}
