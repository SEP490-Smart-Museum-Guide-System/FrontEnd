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
    'QR floor opens first; buildings scope floors and switching clears selection',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      final catalog = directory();
      final maps = catalog['maps'] as List;
      catalog['maps'] = [
        ...maps,
        {
          'id': 6,
          'floorId': 6,
          'name': 'Sơ đồ tầng 2',
          'floorName': 'Tầng 2',
          'buildingName': 'Nhà A',
        },
        {
          'id': 7,
          'floorId': 9,
          'name': 'Sơ đồ sảnh',
          'floorName': 'Sảnh',
          'buildingName': 'Nhà B',
        },
      ];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const VisitorDirectoryScreen(museumId: 7)),
          );
          await frames(tester);
          expect(find.text('Tầng 2 · Nhà A ▾'), findsOneWidget);
          await tester.tap(find.text('1'));
          await frames(tester);
          expect(find.text('Tầng 1 · Nhà A ▾'), findsOneWidget);
          await tester.tap(find.byTooltip('Trống đồng'));
          await frames(tester);
          expect(find.text('Chỉ đường'), findsOneWidget);
          await screenSize(tester, const Size(844, 390));
          await frames(tester);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Chọn tòa nhà'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Nhà B').last);
          await tester.pumpAndSettle();
          expect(find.text('Sảnh · Nhà B ▾'), findsOneWidget);
          expect(find.text('Chỉ đường'), findsNothing);
          expect(find.text('2'), findsNothing);
        },
        () => MockClient((req) async {
          if (req.url.path.endsWith('visitor-directory')) return data(catalog);
          if (req.url.path.endsWith('/presence')) {
            return data({'isFresh': true, 'mapId': 6});
          }
          if (req.url.path.endsWith('/published')) {
            return data({
              ...mapJson(),
              'id': int.parse(req.url.pathSegments.reversed.elementAt(1)),
              'imageKey': null,
            });
          }
          return data({});
        }),
      );
    },
  );
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
          expect(find.byType(VisitorIndoorMapScreen), findsOneWidget);
          expect(find.text('Tìm hiện vật & chỉ đường'), findsNothing);
          expect(find.text('Trống đồng'), findsWidgets);
          expect(requests, contains('/api/indoor-maps/5/published'));
          for (final width in [360.0, 375.0, 390.0, 430.0]) {
            await screenSize(tester, Size(width, 800));
            await frames(tester);
            expect(
              find.byTooltip('Quét QR xác định vị trí').hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
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
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const VisitorDirectoryScreen(museumId: 7), scale: 1.3),
          );
          await frames(tester);
          await tester.tap(find.byTooltip('Tìm hiện vật hoặc phòng'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'Bình gốm');
          await frames(tester);
          await tester.tap(find.widgetWithText(ListTile, 'Bình gốm'));
          await tester.pumpAndSettle();
          expect(
            find.text('Chưa có điểm liên kết trên sơ đồ đã xuất bản.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
        () => MockClient((req) async {
          if (req.url.path.endsWith('/published')) {
            return data({...mapJson(), 'imageKey': null});
          }
          if (req.url.path.endsWith('visitor-directory')) {
            return data(directory());
          }
          return data({});
        }),
      );
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
          await tester.tap(retry);
          await frames(tester);
          expect(find.text('Bảo tàng chưa xuất bản sơ đồ.'), findsOneWidget);
          expect(calls, 2);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('{"message":"Chưa tải được danh mục"}', 503)
              : data({...directory(), 'maps': []});
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
