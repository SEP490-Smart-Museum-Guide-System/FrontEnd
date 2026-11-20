import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/services/automatic_location_service.dart';
import 'package:smgs_mobile/widgets/automatic_arrival_card.dart';
import 'package:smgs_mobile/widgets/automatic_location_host.dart';
import 'support/fake_location_stream.dart';
import 'discovery_test.dart' show museumJson;
import 'widget_test.dart' show host, screenSize;

Future<void> flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GeolocatorPlatform previous;
  late StreamingLocation gps;
  late AutomaticLocationService service;
  late DateTime time;
  late List<Museum> museums;
  late int lookups;
  setUp(() {
    previous = GeolocatorPlatform.instance;
    gps = StreamingLocation();
    GeolocatorPlatform.instance = gps;
    time = DateTime.now();
    gps.initial = gpsPosition(time);
    museums = [Museum.fromBackendJson(museumJson())];
    lookups = 0;
    SharedPreferences.setMockInitialValues({});
    service = AutomaticLocationService(
      now: () => time,
      fetchMuseums: (_) async {
        lookups++;
        return museums;
      },
    );
  });
  tearDown(() async {
    service.dispose();
    await gps.close();
    GeolocatorPlatform.instance = previous;
  });

  test(
    'first launch asks once, resumes/reopens without repeated permission dialog',
    () async {
      gps.permission = LocationPermission.denied;
      await service.start();
      await flush();
      expect(gps.prompts, 1);
      expect(service.hasFreshLocation, true);
      expect(gps.subscriptions, 1);
      service.pause();
      await service.start(requestPermission: false);
      expect(gps.prompts, 1);
      expect(gps.subscriptions, 2);
      gps.permission = LocationPermission.denied;
      await service.start();
      expect(gps.prompts, 1);
      expect(service.status, AutomaticLocationStatus.denied);
      expect(service.latest, isNull);
    },
  );

  test(
    'denied/deniedForever never reads GPS; settings grant recovers automatically',
    () async {
      gps.permission = LocationPermission.denied;
      gps.promptResult = LocationPermission.denied;
      await service.start();
      expect(gps.prompts, 1);
      expect(gps.positionRequests, 0);
      expect(gps.subscriptions, 0);
      await service.start(requestPermission: false);
      expect(gps.prompts, 1);
      gps.permission = LocationPermission.deniedForever;
      await service.start();
      expect(service.status, AutomaticLocationStatus.deniedForever);
      expect(gps.prompts, 1);
      gps.permission = LocationPermission.always;
      await service.start(requestPermission: false);
      await flush();
      expect(service.hasFreshLocation, true);
    },
  );

  test(
    'GPS off/on restarts automatically and pause cancels all position updates',
    () async {
      gps.enabled = false;
      await service.start();
      expect(service.status, AutomaticLocationStatus.disabled);
      expect(gps.subscriptions, 0);
      gps.enabled = true;
      gps.services.add(ServiceStatus.enabled);
      await flush();
      expect(service.hasFreshLocation, true);
      gps.enabled = false;
      gps.services.add(ServiceStatus.disabled);
      await flush();
      expect(service.latest, isNull);
      expect(service.status, AutomaticLocationStatus.disabled);
      service.pause();
      final requests = gps.positionRequests;
      gps.positions.add(gpsPosition(time));
      gps.services.add(ServiceStatus.enabled);
      await flush();
      expect(service.latest, isNull);
      expect(gps.positionRequests, requests);
    },
  );

  test(
    'arrival needs stable fresh GPS; moving outside removes it without extra API calls',
    () async {
      await service.start();
      await flush();
      expect(service.nearbyMuseum?.id, '7');
      expect(service.arrivedMuseum, isNull);
      time = time.add(const Duration(seconds: 11));
      gps.positions.add(gpsPosition(time));
      expect(service.arrivedMuseum?.id, '7');
      expect(lookups, 1);
      time = time.add(const Duration(seconds: 1));
      gps.positions.add(gpsPosition(time, latitude: 10.79));
      expect(service.arrivedMuseum, isNull);
      expect(service.nearbyMuseum, isNull);
      await flush();
    },
  );

  test(
    'mock, stale, inaccurate or overlapping museum samples never establish arrival',
    () async {
      await service.start();
      await flush();
      for (final sample in [
        gpsPosition(time, mocked: true),
        gpsPosition(time, accuracy: 200),
        gpsPosition(time.subtract(const Duration(minutes: 2))),
      ]) {
        gps.positions.add(sample);
        expect(service.arrivedMuseum, isNull);
        expect(service.hasFreshLocation, false);
      }
      museums = [
        Museum.fromBackendJson(museumJson(7)),
        Museum.fromBackendJson(museumJson(8)),
      ];
      time = time.add(const Duration(minutes: 2));
      gps.positions.add(gpsPosition(time));
      await flush();
      time = time.add(const Duration(seconds: 11));
      gps.positions.add(gpsPosition(time));
      expect(service.nearbyMuseum, isNull);
      expect(service.arrivedMuseum, isNull);
    },
  );

  test('late museum response after pause cannot restore arrival', () async {
    final response = Completer<List<Museum>>();
    final slow = AutomaticLocationService(
      now: () => time,
      fetchMuseums: (_) => response.future,
    );
    await slow.start();
    await flush();
    slow.pause();
    response.complete(museums);
    await flush();
    expect(slow.status, AutomaticLocationStatus.paused);
    expect(slow.nearbyMuseum, isNull);
    slow.dispose();
  });

  testWidgets(
    'app startup tracks without tapping; navigation keeps stream, background stops, resume restarts',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              AutomaticLocationHost(service: service, child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Màn hình khác')),
                  ),
                ),
                child: const Text('Đi tiếp'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(gps.subscriptions, 1);
      await tester.tap(find.text('Đi tiếp'));
      await tester.pumpAndSettle();
      expect(find.text('Màn hình khác'), findsOneWidget);
      expect(gps.subscriptions, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(service.latest, isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(gps.subscriptions, 2);
      expect(gps.prompts, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'first foreground after a background launch still asks permission automatically',
    (tester) async {
      gps.permission = LocationPermission.denied;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpWidget(
        host(
          AutomaticLocationHost(
            service: service,
            child: const Text('Ứng dụng'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(gps.prompts, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(gps.prompts, 1);
      expect(service.hasFreshLocation, true);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'arrival is announced once without taps and arrival card fits enlarged text',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await screenSize(tester, const Size(320, 800));
      final messenger = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: messenger,
          builder: (_, child) => AutomaticLocationHost(
            service: service,
            messengerKey: messenger,
            child: child!,
          ),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: AutomaticArrivalCard(service: service),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      time = time.add(const Duration(seconds: 11));
      gps.positions.add(gpsPosition(time));
      await tester.pumpAndSettle();
      expect(find.text('Đã đến khu vực Bảo tàng 7 theo GPS.'), findsOneWidget);
      expect(find.text('Đã đến khu vực Bảo tàng 7 (GPS).'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      time = time.add(const Duration(seconds: 1));
      gps.positions.add(gpsPosition(time));
      await tester.pumpAndSettle();
      expect(find.text('Đã đến khu vực Bảo tàng 7 theo GPS.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'denied permission keeps app content usable and recovery card fits 320px',
    (tester) async {
      gps.permission = LocationPermission.deniedForever;
      await service.start();
      await screenSize(tester, const Size(320, 800));
      await tester.pumpWidget(
        host(
          Column(
            children: [
              AutomaticArrivalCard(service: service),
              const Text('Nội dung bảo tàng'),
            ],
          ),
          scale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nội dung bảo tàng'), findsOneWidget);
      expect(find.textContaining('Cho phép vị trí'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
