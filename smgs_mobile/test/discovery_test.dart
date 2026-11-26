import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smgs_mobile/widgets/interactive_heritage_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/models/outdoor_route.dart';
import 'package:smgs_mobile/services/discovery_api_service.dart';
import 'package:smgs_mobile/services/location_service.dart';
import 'package:smgs_mobile/screens/explore/museum_discovery_map_screen.dart';
import 'package:smgs_mobile/widgets/route_preview_sheet.dart';
import 'widget_test.dart' show host, screenSize;

Map<String, dynamic> museumJson([int id = 7]) => {
  'id': id,
  'name': 'Bảo tàng $id',
  'address': 'Địa chỉ',
  'latitude': 10.7769,
  'longitude': 106.7009,
  'cityCode': '79',
  'isActive': true,
};
Map<String, dynamic> routeJson() => {
  'museumId': 7,
  'destination': {'latitude': 10.7769, 'longitude': 106.7009},
  'travelMode': 'DRIVE',
  'steps': [
    {'pointIndex': 0, 'sign': -2, 'text': 'Rẽ trái vào Nguyễn Huệ'},
  ],
  'distanceMeters': 3500.5,
  'durationSeconds': 720.25,
  'routePoints': [
    {'latitude': 10.7626, 'longitude': 106.6824},
    {'latitude': 10.7769, 'longitude': 106.7009},
  ],
};
http.Response dataResponse(Object data) => http.Response(
  jsonEncode({'statusCode': 200, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
http.Response museumPage({
  List<int> ids = const [7],
  int page = 1,
  int totalPages = 1,
  int totalCount = 1,
}) => dataResponse({
  'items': ids.map(museumJson).toList(),
  'page': page,
  'pageSize': 20,
  'totalCount': totalCount,
  'totalPages': totalPages,
});

class FakeLocation extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  bool enabled = true;
  int positionRequests = 0;
  bool timeout = false;
  Position? recent;
  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => recent;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    if (timeout) throw TimeoutException('GPS');
    return Position(
      latitude: 10.7626,
      longitude: 106.6824,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeLocation location;
  late GeolocatorPlatform previousLocation;
  late Directory cacheDirectory;
  late BuiltInMapCachingProvider cache;
  setUpAll(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('smgs_map_test_');
    cache = BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: cacheDirectory.path,
      readOnly: true,
    );
    await cache.getTile('test-initialisation');
  });
  tearDownAll(() async {
    await cache.destroy(deleteCache: true);
    await cacheDirectory.delete();
  });
  setUp(() {
    previousLocation = GeolocatorPlatform.instance;
    location = FakeLocation();
    GeolocatorPlatform.instance = location;
  });
  tearDown(() {
    GeolocatorPlatform.instance = previousLocation;
  });

  test(
    'Route DTO preserves lat/lon and rejects invalid geometry and modes',
    () {
      final route = OutdoorRoutePreview.fromJson(routeJson());
      expect(route.routePoints.first.latitude, 10.7626);
      expect(route.routePoints.first.longitude, 106.6824);
      expect(route.distanceMeters, 3500.5);
      expect(route.durationMinutesString, '13 phút');
      expect(
        () => OutdoorRoutePreview.fromJson({...routeJson(), 'routePoints': []}),
        throwsFormatException,
      );
      expect(
        () => OutdoorRoutePreview.fromJson({
          ...routeJson(),
          'travelMode': 'WALK',
        }),
        throwsFormatException,
      );
      expect(
        () => OutdoorRoutePreview.parsePoint({'latitude': 91, 'longitude': 0}),
        throwsFormatException,
      );
      expect(
        Museum.fromBackendJson({
          ...museumJson(),
          'latitude': null,
        }).hasCoordinates,
        isFalse,
      );
      expect(
        Museum.fromBackendJson({
          ...museumJson(),
          'latitude': 0,
          'longitude': 0,
        }).hasCoordinates,
        isTrue,
      );
    },
  );

  test(
    'Discovery API preserves filters and pagination; route only sends DB ID and origin',
    () async {
      await http.runWithClient(
        () async {
          final page = await DiscoveryApiService.fetchMuseumPage(
            keyword: '  Test ',
            cityCode: '79',
            latitude: 10.7626,
            longitude: 106.6824,
            sortBy: 'distance',
            page: 2,
          );
          expect(page.page, 2);
          expect(page.totalPages, 3);
          expect(page.items.single.id, '7');
          final cities = await DiscoveryApiService.fetchCities();
          expect(cities.single.code, '79');
          final route = await DiscoveryApiService.fetchOutdoorRoute(
            museumId: '7',
            originLat: 10.7626,
            originLng: 106.6824,
          );
          expect(route.distanceMeters, 3500.5);
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/cities')) {
            return dataResponse([
              {'code': '79', 'name': 'Hồ Chí Minh'},
            ]);
          }
          if (request.method == 'POST') {
            final body = jsonDecode(request.body) as Map;
            expect(body['museumId'], 7);
            expect(body['travelMode'], 'DRIVE');
            expect(body.containsKey('destination'), isFalse);
            return dataResponse(routeJson());
          }
          expect(request.url.queryParameters['keyword'], 'Test');
          expect(request.url.queryParameters['cityCode'], '79');
          expect(request.url.queryParameters['sortBy'], 'distance');
          expect(request.url.queryParameters['page'], '2');
          return museumPage(page: 2, totalPages: 3, totalCount: 41);
        }),
      );
    },
  );

  test(
    'Failed routes and city requests never manufacture successful data',
    () async {
      for (final status in [401, 422, 429, 502, 504]) {
        await http.runWithClient(
          () async {
            await expectLater(
              DiscoveryApiService.fetchOutdoorRoute(
                museumId: '7',
                originLat: 10,
                originLng: 106,
              ),
              throwsException,
            );
            await expectLater(
              DiscoveryApiService.fetchCities(),
              throwsException,
            );
          },
          () => MockClient(
            (_) async => http.Response('<html>unavailable</html>', status),
          ),
        );
      }
      expect(
        () => DiscoveryApiService.decodeResponse(http.Response('[]', 200)),
        throwsFormatException,
      );
    },
  );

  test('GPS denied/disabled has no fabricated location', () async {
    await expectLater(
      LocationService.getCurrentUserLocation(),
      throwsException,
    );
    expect(location.positionRequests, 0);
    location.permission = LocationPermission.deniedForever;
    await expectLater(
      LocationService.getCurrentUserLocation(),
      throwsException,
    );
    location.enabled = false;
    await expectLater(
      LocationService.getCurrentUserLocation(),
      throwsException,
    );
    location.enabled = true;
    location.permission = LocationPermission.whileInUse;
    expect((await LocationService.getCurrentUserLocation()).latitude, 10.7626);
    expect(location.positionRequests, 1);
    // Browsers without the Permissions API prompt when requesting the position.
    location.permission = LocationPermission.unableToDetermine;
    expect(
      (await LocationService.getCurrentUserLocation()).longitude,
      106.6824,
    );
    expect(location.positionRequests, 2);
  });

  test(
    'GPS timeout only accepts a fresh accurate last-known position',
    () async {
      location.permission = LocationPermission.whileInUse;
      final fresh = await location.getCurrentPosition();
      location.timeout = true;
      await expectLater(
        LocationService.getCurrentUserLocation(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('GPS'),
          ),
        ),
      );
      location.recent = fresh;
      expect(
        (await LocationService.getCurrentUserLocation()).isLastKnown,
        isTrue,
      );
      location.recent = Position.fromMap({
        ...fresh.toJson(),
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 3))
            .millisecondsSinceEpoch,
      });
      await expectLater(
        LocationService.getCurrentUserLocation(),
        throwsException,
      );
      location.recent = Position.fromMap({
        ...fresh.toJson(),
        'accuracy': 500.0,
      });
      await expectLater(
        LocationService.getCurrentUserLocation(),
        throwsException,
      );
    },
  );

  testWidgets('System museum filter frames museums despite GPS updates', (
    tester,
  ) async {
    final museum = Museum.fromBackendJson(museumJson());
    Future<void> show(bool world, LatLng gps) async {
      await tester.pumpWidget(
        host(
          InteractiveHeritageMap(
            centerOnGps: world,
            userLocation: gps,
            museums: world
                ? []
                : [
                    museum,
                    Museum.fromBackendJson({
                      ...museumJson(8),
                      'latitude': 21.025,
                      'longitude': 105.84,
                    }),
                  ],
            selectedMuseumId: null,
            onMuseumSelected: (_) {},
          ),
        ),
      );
      await tester.pump();
    }

    LatLng center() => tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera
        .center;
    const gps = LatLng(21.03, 105.84);
    await show(true, gps);
    expect(center(), gps);
    await show(false, gps);
    final target = LatLng(museum.latitude!, museum.longitude!);
    expect(center(), target);
    await show(false, const LatLng(21.04, 105.85));
    expect(center(), target);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'GPS denied keeps museum search usable without reading coordinates',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      final requests = <Uri>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(host(const MuseumDiscoveryMapScreen()));
          await tester.tap(find.byType(Switch).first);
          await tester.pumpAndSettle();
          expect(find.text('Bảo tàng 8'), findsOneWidget);
          expect(location.positionRequests, 0);
          await tester.enterText(find.byType(TextField), 'Bảo tàng 8');
          await tester.pumpAndSettle();
          expect(find.text('Bảo tàng 8'), findsNWidgets(2));
          expect(
            requests
                .where((u) => u.path.endsWith('/museums'))
                .every((u) => !u.queryParameters.containsKey('latitude')),
            isTrue,
          );
          expect(find.byType(FlutterMap), findsOneWidget);
          expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
          expect(find.byType(TileLayer), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
        () => MockClient((request) async {
          requests.add(request.url);
          if (request.url.path.endsWith('/cities')) return dataResponse([]);
          if (request.url.path.endsWith('/museums'))
            return museumPage(ids: [8]);
          return http.Response('', 404);
        }),
      );
    },
  );

  testWidgets(
    'City filter loads every page and remains usable on a narrow screen',
    (tester) async {
      await screenSize(tester, const Size(320, 640));
      location.permission = LocationPermission.whileInUse;
      final requests = <Uri>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const MuseumDiscoveryMapScreen(), scale: 1.3),
          );
          await tester.tap(find.byType(Switch).first);
          await tester.pump();
          await tester.pump();
          await tester.pump();
          await tester.tap(find.byType(DropdownButton<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Hồ Chí Minh').last);
          await tester.pumpAndSettle();
          await tester.pumpAndSettle();
          final cityRequests = requests
              .where(
                (uri) =>
                    uri.path.endsWith('/museums') &&
                    uri.queryParameters.containsKey('page'),
              )
              .toList();
          expect(
            cityRequests
                .sublist(cityRequests.length - 2)
                .map((uri) => uri.queryParameters['page']),
            ['1', '2'],
          );
          final appliedCityRequests = cityRequests.sublist(
            cityRequests.length - 2,
          );
          expect(
            appliedCityRequests.every(
              (uri) => uri.queryParameters['cityCode'] == '79',
            ),
            isTrue,
          );
          expect(
            appliedCityRequests.every(
              (uri) => !uri.queryParameters.containsKey('latitude'),
            ),
            isTrue,
          );
          await tester.tap(find.byTooltip('Bảo tàng tiếp theo'));
          await tester.pumpAndSettle();
          expect(find.byTooltip('Bảo tàng trước'), findsOneWidget);
          expect(find.byTooltip('Bảo tàng tiếp theo'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/cities')) {
            return dataResponse([
              {'code': '79', 'name': 'Hồ Chí Minh'},
            ]);
          }
          if (request.url.path.endsWith('/museums')) {
            requests.add(request.url);
            final page = int.parse(request.url.queryParameters['page']!);
            return museumPage(
              ids: [page + 6],
              page: page,
              totalPages: 2,
              totalCount: 2,
            );
          }
          return http.Response('', 404);
        }),
      );
    },
  );

  testWidgets(
    'Successful preview renders actual route points and route metrics',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      location.permission = LocationPermission.whileInUse;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(
              RoutePreviewSheet(museum: Museum.fromBackendJson(museumJson())),
            ),
          );
          await tester.pump();
          await tester.pump();
          await tester.pump();
          expect(find.text('3.5 km · 13 phút'), findsOneWidget);
          final line = tester
              .widget<PolylineLayer>(find.byType(PolylineLayer))
              .polylines
              .single;
          expect(line.points.length, 2);
          expect(line.points.first.latitude, 10.7626);
          final camera = MapController.of(
            tester.element(find.byType(PolylineLayer)),
          ).camera;
          expect(line.points.every(camera.visibleBounds.contains), isTrue);
          final start = find.text('Bắt đầu chỉ đường');
          await tester.ensureVisible(start);
          await tester.tap(start);
          await tester.pump();
          expect(find.text('Dừng chỉ đường'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
        () => MockClient(
          (request) async => request.method == 'POST'
              ? dataResponse(routeJson())
              : http.Response('', 404),
        ),
      );
    },
  );

  testWidgets('Route errors allow retry in app', (tester) async {
    await screenSize(tester, const Size(320, 640));
    location.permission = LocationPermission.whileInUse;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          host(
            RoutePreviewSheet(museum: Museum.fromBackendJson(museumJson())),
            scale: 1.3,
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.textContaining('Không thể tải dữ liệu'), findsOneWidget);
        expect(find.byType(PolylineLayer), findsNothing);
        expect(find.text('Thử lại xem đường đi'), findsOneWidget);
        final choose = find.text('Chọn điểm xuất phát');
        await tester.ensureVisible(choose);
        await tester.tap(choose);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Chợ Bến Thành');
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pump();
        await tester.tap(find.widgetWithText(ListTile, 'Chợ Bến Thành'));
        await tester.pumpAndSettle();
        expect(find.byType(PolylineLayer), findsOneWidget);
        expect(find.text('Xuất phát từ Chợ Bến Thành'), findsOneWidget);
        await tester.tap(find.text('Bắt đầu chỉ đường'));
        await tester.pumpAndSettle();
        expect(find.text('Rẽ trái vào Nguyễn Huệ'), findsOneWidget);
        expect(find.text('Dẫn đường từ vị trí GPS của tôi'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('/places')) {
          return dataResponse([
            {
              'name': 'Chợ Bến Thành',
              'address': 'TP.HCM',
              'latitude': 10.772,
              'longitude': 106.698,
            },
          ]);
        }
        if (request.method == 'POST' &&
            jsonDecode(request.body)['origin']['latitude'] == 10.772) {
          return dataResponse(routeJson());
        }
        return http.Response('', 502);
      }),
    );
  });
}
