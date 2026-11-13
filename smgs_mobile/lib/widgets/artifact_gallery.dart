import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Photos from the artifact API, ordered by the museum. No generated images.
class ArtifactGallery extends StatefulWidget {
  const ArtifactGallery({
    super.key,
    required this.photos,
    required this.name,
    this.height = 300,
    this.fullscreen = false,
    this.initialIndex = 0,
  });
  final List<String> photos;
  final String name;
  final double height;
  final bool fullscreen;
  final int initialIndex;
  @override
  State<ArtifactGallery> createState() => _ArtifactGalleryState();
}

class _ArtifactGalleryState extends State<ArtifactGallery> {
  late final PageController _controller;
  late int _index;
  @override
  void initState() {
    super.initState();
    _index = widget.photos.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant ArtifactGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos.join('|') != widget.photos.join('|')) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final page = (_index + delta).clamp(0, widget.photos.length - 1);
    _controller.animateToPage(
      page,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _open() => showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: const Color(0xff211d1b),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng ảnh',
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ArtifactGallery(
                photos: widget.photos,
                name: widget.name,
                fullscreen: true,
                initialIndex: _index,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chụm hai ngón để phóng to · Vuốt để đổi ảnh',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _image(String url, int index) {
    final label =
        '${widget.name}, ảnh ${index + 1} trên ${widget.photos.length}';
    Widget error(BuildContext context, Object error, StackTrace? stack) =>
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.grey),
              SizedBox(height: 8),
              Text('Chưa tải được ảnh', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
    final image = Uri.tryParse(url)?.hasScheme == true
        ? Image.network(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            semanticLabel: label,
            errorBuilder: error,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
          )
        : Image.asset(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            semanticLabel: label,
            errorBuilder: error,
          );
    return widget.fullscreen
        ? InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(child: image),
          )
        : Semantics(
            button: true,
            label: 'Mở ảnh ${index + 1}',
            child: InkWell(onTap: _open, child: image),
          );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('Chưa có ảnh hiện vật')),
      );
    }
    final body = Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (_, index) => _image(widget.photos[index], index),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '${_index + 1} / ${widget.photos.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          Positioned(
            left: 8,
            bottom: 12,
            child: IconButton.filled(
              tooltip: 'Ảnh trước',
              onPressed: _index > 0 ? () => _move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 12,
            child: IconButton.filled(
              tooltip: 'Ảnh tiếp theo',
              onPressed: _index < widget.photos.length - 1
                  ? () => _move(1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ],
        if (!widget.fullscreen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Chạm để phóng to',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return widget.fullscreen
        ? body
        : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: widget.height,
              color: AppColors.card,
              child: body,
            ),
          );
  }
}
