import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smgs_mobile/models/artifact.dart';
import 'package:smgs_mobile/services/tts_api_service.dart';
import 'package:smgs_mobile/widgets/narration_player.dart';
import 'widget_test.dart' show host, screenSize;

Uint8List wave() {
  final bytes = Uint8List(46);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  bytes.setRange(8, 12, ascii.encode('WAVE'));
  return bytes;
}

class FakeAudio extends AudioplayersPlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final calls = <String>[];
  final events = <String, StreamController<AudioEvent>>{};
  Uint8List? bytes;
  String? mime;
  int position = 0;
  @override
  Future<void> create(String id) async {
    calls.add('create');
    events[id] = StreamController.broadcast();
  }

  @override
  Stream<AudioEvent> getEventStream(String id) => events[id]!.stream;
  @override
  Future<void> setSourceBytes(
    String id,
    Uint8List data, {
    String? mimeType,
  }) async {
    calls.add('source');
    bytes = data;
    mime = mimeType;
    events[id]!.add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
    events[id]!.add(
      const AudioEvent(
        eventType: AudioEventType.duration,
        duration: Duration(seconds: 20),
      ),
    );
  }

  @override
  Future<void> setReleaseMode(String id, ReleaseMode mode) async {
    calls.add('releaseMode');
  }

  @override
  Future<void> setPlaybackRate(String id, double rate) async {
    calls.add('rate:$rate');
  }

  @override
  Future<void> resume(String id) async {
    calls.add('resume');
  }

  @override
  Future<void> pause(String id) async {
    calls.add('pause');
  }

  @override
  Future<void> seek(String id, Duration value) async {
    position = value.inMilliseconds;
    calls.add('seek:$position');
    events[id]!.add(const AudioEvent(eventType: AudioEventType.seekComplete));
  }

  @override
  Future<int?> getCurrentPosition(String id) async => position;
  @override
  Future<int?> getDuration(String id) async => 20000;
  @override
  Future<void> stop(String id) async {
    calls.add('stop');
  }

  @override
  Future<void> release(String id) async {
    calls.add('release');
  }

  @override
  Future<void> dispose(String id) async {
    calls.add('dispose');
    await events.remove(id)?.close();
  }
}

class FakeGlobalAudio extends GlobalAudioplayersPlatformInterface {
  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> init() async {}
  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> listen(WidgetTester tester) async {
  final button = find.text('Nghe thuyết minh âm thanh');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await flush(tester);
}

void main() {
  late FakeAudio platform;
  setUp(() {
    platform = FakeAudio();
    AudioplayersPlatformInterface.instance = platform;
    GlobalAudioplayersPlatformInterface.instance = FakeGlobalAudio();
  });

  testWidgets(
    'WAV reaches real player API; playback events drive pause, seek, speed and replay',
    (tester) async {
      var requests = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const NarrationPlayer(text: 'audio controls test')),
          );
          await listen(tester);
          expect(platform.bytes, wave());
          expect(platform.mime, 'audio/wav');
          expect(find.text('Tạm dừng thuyết minh'), findsOneWidget);
          platform.position = 5000;
          await flush(tester);
          expect(find.text('0:05 / 0:20'), findsOneWidget);
          await tester.tap(find.text('Tạm dừng thuyết minh'));
          await flush(tester);
          expect(platform.calls, contains('pause'));
          await tester.tap(find.text('1.25x'));
          await flush(tester);
          expect(platform.calls, contains('rate:1.25'));
          expect(requests, 1);
          tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(15000);
          await flush(tester);
          expect(platform.calls, contains('seek:15000'));
          await listen(tester);
          platform.events.values.single.add(
            const AudioEvent(eventType: AudioEventType.complete),
          );
          await flush(tester);
          expect(find.text('Nghe lại thuyết minh'), findsOneWidget);
          await tester.tap(find.text('Nghe lại thuyết minh'));
          await flush(tester);
          expect(platform.calls, contains('seek:0'));
          expect(requests, 1);
          await tester.pumpWidget(const SizedBox());
          await flush(tester);
          expect(platform.calls, contains('stop'));
          expect(platform.calls, contains('release'));
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          requests++;
          expect(jsonDecode(request.body)['speed'], 1.0);
          return http.Response.bytes(
            wave(),
            200,
            headers: {'content-type': 'audio/wav'},
          );
        }),
      );
    },
  );

  testWidgets(
    'Failed synthesis retries without claiming playback; HTML is rejected',
    (tester) async {
      var requests = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const NarrationPlayer(text: 'retry bad WAV test')),
          );
          await listen(tester);
          expect(platform.calls, isEmpty);
          expect(find.textContaining('Chưa tải được âm thanh'), findsOneWidget);
          await listen(tester);
          expect(platform.calls, isEmpty);
          await listen(tester);
          expect(platform.calls, contains('resume'));
          expect(requests, 3);
          await tester.pumpWidget(const SizedBox());
          await flush(tester);
        },
        () => MockClient((_) async {
          requests++;
          if (requests == 1) return http.Response('unavailable', 503);
          if (requests == 2) {
            return http.Response(
              '<html>wrong route</html>',
              200,
              headers: {'content-type': 'text/html'},
            );
          }
          return http.Response.bytes(
            wave(),
            200,
            headers: {'content-type': 'audio/wav'},
          );
        }),
      );
    },
  );

  testWidgets(
    'Late synthesis cannot start audio after content changes or screen closes',
    (tester) async {
      final pending = Completer<http.Response>();
      var requests = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(const NarrationPlayer(text: 'old pending text')),
          );
          await tester.tap(find.text('Nghe thuyết minh âm thanh'));
          await flush(tester);
          await tester.pumpWidget(
            host(const NarrationPlayer(text: 'new pending text')),
          );
          pending.complete(http.Response.bytes(wave(), 200));
          await flush(tester);
          expect(platform.calls, isEmpty);
          expect(requests, 1);
          await listen(tester);
          expect(requests, 2);
          expect(platform.calls, contains('resume'));
          await tester.pumpWidget(const SizedBox());
          await flush(tester);
          expect(platform.calls, contains('stop'));
          expect(platform.calls, contains('release'));
          expect(tester.takeException(), isNull);
        },
        () => MockClient((_) async {
          requests++;
          return requests == 1
              ? pending.future
              : http.Response.bytes(wave(), 200);
        }),
      );
    },
  );

  testWidgets(
    'Published recording is preferred and never invokes speech synthesis',
    (tester) async {
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            host(
              const NarrationPlayer(
                text: 'curated text',
                audioUrl: 'https://cdn.example.test/recording.wav',
              ),
            ),
          );
          await listen(tester);
          expect(platform.calls, contains('resume'));
          await tester.pumpWidget(const SizedBox());
          await flush(tester);
        },
        () => MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/recording.wav');
          expect(request.headers.containsKey('authorization'), isFalse);
          return http.Response.bytes(
            wave(),
            200,
            headers: {'content-type': 'audio/wav'},
          );
        }),
      );
    },
  );

  testWidgets(
    'Narration screen uses published BE narration, not the catalog placeholder',
    (tester) async {
      await screenSize(tester, const Size(800, 2000));
      var synthesis = '';
      final artifact = Artifact.fromBackendJson({
        'id': 17,
        'name': 'Hiện vật thật',
        'museumId': 1,
      });
      await http.runWithClient(
        () async {
          await tester.pumpWidget(host(NarrationScreen(artifact: artifact)));
          await flush(tester);
          expect(find.text('Kịch bản đã xuất bản.'), findsOneWidget);
          expect(find.textContaining('Bạn có thể hỏi Trợ lý AI'), findsNothing);
          await listen(tester);
          expect(synthesis, 'Kịch bản đã xuất bản.');
          await tester.pumpWidget(const SizedBox());
          await flush(tester);
        },
        () => MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'data': {
                  'narrationText': 'Kịch bản đã xuất bản.',
                  'description': 'Nội dung mô tả',
                  'audioUrl': null,
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          synthesis = jsonDecode(request.body)['text'] as String;
          return http.Response.bytes(wave(), 200);
        }),
      );
    },
  );

  test(
    'Published audio download rejects HTML and sends no credentials to external storage',
    () async {
      await http.runWithClient(
        () async {
          await expectLater(
            TtsApiService.fetchPublishedAudio(
              'https://cdn.example.test/no-audio',
            ),
            throwsFormatException,
          );
        },
        () => MockClient((request) async {
          expect(request.headers.containsKey('authorization'), isFalse);
          return http.Response(
            '<html>login</html>',
            200,
            headers: {'content-type': 'text/html'},
          );
        }),
      );
    },
  );
}
