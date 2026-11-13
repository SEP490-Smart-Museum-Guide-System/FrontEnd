import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/models/artifact.dart';
import 'package:smgs_mobile/widgets/artifact_gallery.dart';

void main() {
  test(
    'backend image list preserves all photos, ignores audio, sorts and removes duplicates',
    () {
      final artifact = Artifact.fromBackendJson({
        'id': 7,
        'media': [
          {
            'mediaType': 'image',
            'fileUrl': 'https://example.com/b.jpg',
            'sortOrder': 2,
          },
          {'mediaType': 'audio', 'fileUrl': 'https://example.com/voice.mp3'},
          {
            'mediaType': 'image',
            'fileUrl': 'https://example.com/a.jpg',
            'sortOrder': 1,
          },
          {
            'mediaType': 'image',
            'fileUrl': 'https://example.com/a.jpg',
            'sortOrder': 3,
          },
        ],
      });
      expect(artifact.photos, [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
      ]);
      expect(artifact.imageUrl, artifact.photos.first);
    },
  );
  testWidgets('visitor changes photos and opens fullscreen at selected photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArtifactGallery(
            photos: [
              'assets/images/ngoc-lu-web.jpg',
              'assets/images/ngoc-lu-web.jpg',
            ],
            name: 'Hiện vật',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Ảnh tiếp theo'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsWidgets);
    expect(find.text('2 / 2'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Đóng ảnh'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
