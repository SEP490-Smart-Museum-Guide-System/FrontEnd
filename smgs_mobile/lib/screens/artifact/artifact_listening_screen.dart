import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/artifact.dart';
import '../../widgets/artifact_gallery.dart';
import '../../widgets/narration_player.dart';
import '../../widgets/sketchfab_viewer.dart';

enum ListeningAction { quiz, ask }

class ArtifactListeningScreen extends StatefulWidget {
  const ArtifactListeningScreen({
    super.key,
    required this.artifact,
    required this.photos,
    required this.description,
    required this.narration,
    this.audioUrl,
    this.modelUrl,
  });

  final Artifact artifact;
  final List<String> photos;
  final String description;
  final String narration;
  final String? audioUrl;
  final String? modelUrl;

  @override
  State<ArtifactListeningScreen> createState() =>
      _ArtifactListeningScreenState();
}

class _ArtifactListeningScreenState extends State<ArtifactListeningScreen> {
  static const _cream = Color(0xFFFFEEE0);
  final _player = GlobalKey<NarrationPlayerState>();

  void _leave([ListeningAction? action]) {
    _player.currentState?.stopPlayback();
    Navigator.of(context).pop(action);
  }

  Widget _artwork(BoxFit fit) {
    const placeholder = Center(
      child: Icon(Icons.museum_outlined, color: _cream, size: 64),
    );
    final photo = widget.photos.firstOrNull;
    if (photo == null) return placeholder;
    return Uri.tryParse(photo)?.hasScheme == true
        ? Image.network(photo, fit: fit, errorBuilder: (_, _, _) => placeholder)
        : Image.asset(photo, fit: fit, errorBuilder: (_, _, _) => placeholder);
  }

  Widget _display() {
    final model = widget.modelUrl;
    if (model == null) return _artwork(BoxFit.contain);
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return Center(
        child: Text(
          'Mô hình 3D ${widget.artifact.name}',
          style: const TextStyle(color: _cream),
        ),
      );
    }
    final uri = Uri.parse(model);
    if (uri.host == 'sketchfab.com' && uri.path.endsWith('/embed')) {
      return SketchfabViewer(
        url: uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'autostart': '1',
                'autospin': '0.25',
              },
            )
            .toString(),
      );
    }
    return ModelViewer(
      src: model,
      alt: 'Mô hình 3D ${widget.artifact.name}',
      autoRotate: true,
      autoRotateDelay: 0,
      rotationPerSecond: '25deg',
      cameraControls: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _readDetails() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .82,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          children: [
            Text(
              widget.artifact.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              widget.description.trim().isNotEmpty
                  ? widget.description
                  : widget.narration,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _action(String label, IconData icon, VoidCallback? onPressed) =>
      Expanded(
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF432B24),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 5),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF231813),
    body: Stack(
      fit: StackFit.expand,
      children: [
        if (widget.photos.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: _artwork(BoxFit.cover),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x9C38251A), Color(0xF21B110E)],
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          onPressed: _leave,
                          color: _cream,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Expanded(
                          child: Text(
                            'Thuyết minh',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _cream,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _readDetails,
                          style: TextButton.styleFrom(foregroundColor: _cream),
                          child: const Text('Chi tiết'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: NarrationPlayer(
                          key: _player,
                          text: widget.narration,
                          audioUrl: widget.audioUrl,
                          presentation: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height:
                                    (MediaQuery.sizeOf(context).height * .40)
                                        .clamp(170.0, 410.0),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: const Color(0x55231710),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: _display(),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.artifact.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: _cream,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (widget.artifact.exhibition.trim().isNotEmpty)
                                Text(
                                  widget.artifact.exhibition,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: _cream),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: const Color(0xFFFFFAF3),
                      borderRadius: BorderRadius.circular(24),
                      child: Row(
                        children: [
                          _action(
                            'Xem ảnh',
                            Icons.image_outlined,
                            widget.photos.isEmpty
                                ? null
                                : () => ArtifactGallery.open(
                                    context,
                                    photos: widget.photos,
                                    name: widget.artifact.name,
                                  ),
                          ),
                          _action(
                            'Đọc lời',
                            Icons.article_outlined,
                            _readDetails,
                          ),
                          _action(
                            'Làm quiz',
                            Icons.quiz_outlined,
                            () => _leave(ListeningAction.quiz),
                          ),
                          _action(
                            'Hỏi',
                            Icons.chat_bubble_outline,
                            () => _leave(ListeningAction.ask),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
