import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/services/location_service.dart';
import 'package:smgs_mobile/services/automatic_location_service.dart';
import 'package:smgs_mobile/widgets/automatic_location_host.dart';
import 'package:smgs_mobile/services/museum_presence_api.dart';
import 'package:smgs_mobile/services/visitor_experience_api.dart';
import 'package:smgs_mobile/widgets/museum_arrival_panel.dart';
import 'package:smgs_mobile/screens/museum/visitor_indoor_map_screen.dart';
import 'support/fake_location_stream.dart';
import 'visitor_directory_test.dart' show mapJson, nodeA, nodeB;
import 'widget_test.dart' show host, screenSize;

http.Response reply(Object data, {int status = 200}) => http.Response(
  jsonEncode(status == 200 ? {'data': data} : {'message': data}),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, dynamic> location({bool fresh = true}) => {
  'museumId': 7,
  'status': fresh ? 'confirmed' : 'last_known',
  'source': 'checkpoint_qr',
  'isFresh': fresh,
  'confirmedAt': DateTime.now()
      .toUtc()
      .subtract(Duration(minutes: fresh ? 0 : 6))
      .toIso8601String(),
  'mapId': 5,
  'mapRevision': 3,
  'markerId': 'start',
  'nodeId': nodeA,
  'label': 'Cổng chính',
  'floorName': 'Tầng 1',
  'galleryName': 'Phòng gốm',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.environment['SMGS_PRESENCE_SCREENSHOT'] != null) {
      for (final family in ['NotoSans', 'NotoSerif']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  late GeolocatorPlatform previous;
  late StreamingLocation gps;
  late AutomaticLocationService tracking;
  Widget arrival() => AutomaticLocationHost(
    service: tracking,
    child: MuseumArrivalPanel(
      museumId: 7,
      museumName: 'Bảo tàng thử',
      locationService: tracking,
    ),
  );
  setUp(() {
    previous = GeolocatorPlatform.instance;
    gps = StreamingLocation();
    tracking = AutomaticLocationService(fetchMuseums: (_) async => []);
    GeolocatorPlatform.instance = gps;
    VisitorSession.clear();
  });
  tearDown(() async {
    tracking.dispose();
    await gps.close();
    GeolocatorPlatform.instance = previous;
    VisitorSession.clear();
  });
  test(
    'GPS assessment sends accuracy, capture time and mock/cache flags; missing metadata never confirms',
    () async {
      var calls = 0;
      await http.runWithClient(
        () async {
          final missing = await MuseumPresenceApi.assess(
            7,
            const UserLocationResult(latitude: 0, longitude: 0),
          );
          expect(missing['status'], 'uncertain');
          expect(calls, 0);
          final time = DateTime.now().toUtc();
          await MuseumPresenceApi.assess(
            7,
            UserLocationResult(
              latitude: 1,
              longitude: 2,
              accuracyMeters: 25,
              capturedAt: time,
              isLastKnown: true,
              isMocked: true,
            ),
          );
        },
        () => MockClient((request) async {
          calls++;
          expect(
            request.url.path,
            endsWith('/museums/7/presence/gps-assessment'),
          );
          final body = jsonDecode(request.body);
          expect(body['accuracyMeters'], 25);
          expect(body['isLastKnown'], true);
          expect(body['isMocked'], true);
          expect(DateTime.parse(body['capturedAt']).isUtc, true);
          return reply({'status': 'uncertain'});
        }),
      );
      expect(calls, 1);
    },
  );
  test(
    'checkpoint scan uses scoped endpoint and preserves retry ID; denial is never shown as success',
    () async {
      const code = 'smgs:location:v1:5:3:11111111111141118111111111111111';
      await http.runWithClient(
        () async {
          expect(MuseumPresenceApi.isCheckpoint(code), true);
          await expectLater(
            MuseumPresenceApi.scan(
              code,
              museumId: 7,
              visitId: 12,
              requestId: 'same-request',
            ),
            throwsException,
          );
        },
        () => MockClient((request) async {
          expect(
            request.url.path,
            endsWith('/museums/7/presence/checkpoints/scan'),
          );
          expect(jsonDecode(request.body), {
            'code': code,
            'requestId': 'same-request',
            'visitId': 12,
          });
          return reply('QR không thuộc bảo tàng này.', status: 404);
        }),
      );
    },
  );
  testWidgets('nearby GPS remains a hint and does not mark arrival confirmed', (
    tester,
  ) async {
    gps.permission = LocationPermission.whileInUse;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await screenSize(tester, const Size(360, 800));
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          host(
            RepaintBoundary(
              key: const ValueKey('presence-preview'),
              child: arrival(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Bạn đang ở gần bảo tàng'), findsOneWidget);
        expect(find.text('Đã xác nhận qua QR'), findsNothing);
        expect(find.text('Quét QR xác nhận'), findsOneWidget);
        expect(find.text('Kiểm tra GPS'), findsNothing);
        expect(tester.takeException(), isNull);
        final output = Platform.environment['SMGS_PRESENCE_SCREENSHOT'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('presence-preview')),
          );
          await tester.runAsync(() async {
            final picture = await boundary.toImage(pixelRatio: 2);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(output).writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      },
      () => MockClient(
        (request) async => request.url.path.endsWith('/gps-assessment')
            ? reply({
                'status': 'nearby',
                'message': 'Quét QR tại cổng/phòng để xác nhận.',
              })
            : reply({'status': 'unknown'}),
      ),
    );
  });
  testWidgets(
    'persisted room/floor survives reopening; denied GPS does not block QR confirmation',
    (tester) async {
      gps.permission = LocationPermission.deniedForever;
      await screenSize(tester, const Size(320, 800));
      await http.runWithClient(() async {
        await tester.pumpWidget(host(arrival()));
        await tester.pumpAndSettle();
        expect(find.text('Đã xác nhận qua QR'), findsOneWidget);
        expect(find.textContaining('Phòng gốm'), findsOneWidget);
        expect(find.textContaining('Tầng 1'), findsOneWidget);
        expect(gps.positionRequests, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }, () => MockClient((_) async => reply(location())));
    },
  );
  testWidgets('old confirmation is labelled stale and requests a new scan', (
    tester,
  ) async {
    gps.permission = LocationPermission.deniedForever;
    await http.runWithClient(() async {
      await tester.pumpWidget(host(arrival()));
      await tester.pumpAndSettle();
      expect(find.text('Vị trí xác nhận đã cũ'), findsOneWidget);
      expect(find.text('Đã xác nhận qua QR'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((_) async => reply(location(fresh: false))));
  });
  testWidgets(
    'background refresh does not request GPS and resumes only in foreground',
    (tester) async {
      gps.permission = LocationPermission.whileInUse;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(host(arrival()));
          await tester.pumpAndSettle();
          expect(gps.positionRequests, 0);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(gps.positionRequests, 1);
          await tester.pumpWidget(const SizedBox());
        },
        () => MockClient(
          (request) async => reply(
            request.url.path.endsWith('/gps-assessment')
                ? {'status': 'nearby', 'message': 'Quét QR để xác nhận.'}
                : {'status': 'unknown'},
          ),
        ),
      );
    },
  );
  testWidgets(
    'indoor routing uses authenticated checkpoint anchor rather than caller supplied coordinates',
    (tester) async {
      var routed = false;
      await screenSize(tester, const Size(400, 900));
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(
              const VisitorIndoorMapScreen(
                mapId: 5,
                visitId: 12,
                targetArtifactId: 11,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(routed, true);
          expect(
            find.textContaining('Vừa xác nhận: Cổng chính'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/published')) {
            return reply({
              ...mapJson(),
              'imageKey': null,
              'markers': [
                {...(mapJson()['markers'] as List)[0], 'label': 'Cổng chính'},
                (mapJson()['markers'] as List)[1],
              ],
            });
          }
          if (request.url.path.endsWith('/route')) {
            routed = true;
            final body = jsonDecode(request.body);
            expect(body['visitId'], 12);
            expect(body['artifactId'], 11);
            expect(body.containsKey('fromNodeId'), false);
            return reply({
              'mapId': 5,
              'revision': 3,
              'route': {
                'nodeIds': [nodeA, nodeB],
                'cost': 1,
              },
            });
          }
          return reply(location());
        }),
      );
    },
  );
}
