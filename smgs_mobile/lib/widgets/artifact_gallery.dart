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
    this.cover = false,
    this.onModel,
  });
  final List<String> photos;
  final String name;
  final double height;
  final bool fullscreen;
  final int initialIndex;
  final bool cover;
  final VoidCallback? onModel;

  static void open(
    BuildContext context, {
    required List<String> photos,
    required String name,
    int initialIndex = 0,
    VoidCallback? onModel,
  }) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: const Color(0xff151210),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Đóng ảnh',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onModel != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        onModel();
                      },
                      child: const Text('3D'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ArtifactGallery(
                photos: photos,
                name: name,
                fullscreen: true,
                initialIndex: initialIndex,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Text(
                name == 'Trống đồng Ngọc Lũ'
                    ? 'Ảnh: VuThiAnh, Wikimedia Commons\nChụm hai ngón để phóng to'
                    : 'Chụm hai ngón để phóng to',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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

  void _open() => ArtifactGallery.open(
    context,
    photos: widget.photos,
    name: widget.name,
    initialIndex: _index,
    onModel: widget.onModel,
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
            fit: widget.cover ? BoxFit.cover : BoxFit.contain,
            width: double.infinity,
            semanticLabel: label,
            errorBuilder: error,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
          )
        : Image.asset(
            url,
            fit: widget.cover ? BoxFit.cover : BoxFit.contain,
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chưa có ảnh hiện vật'),
              if (widget.onModel != null)
                TextButton.icon(
                  onPressed: widget.onModel,
                  icon: const Icon(Icons.view_in_ar_outlined),
                  label: const Text('Xem 3D'),
                ),
            ],
          ),
        ),
      );
    }
    final galleryButtonStyle = FilledButton.styleFrom(
      shape: const StadiumBorder(),
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    const galleryIconSize = 15.0;
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
        if (widget.fullscreen && widget.photos.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: AppColors.antiqueIvory,
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Ảnh trước',
                      onPressed: _index > 0 ? () => _move(-1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'ẢNH ${_index + 1} / ${widget.photos.length}',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ảnh tiếp theo',
                      onPressed: _index < widget.photos.length - 1
                          ? () => _move(1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (!widget.fullscreen)
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonalIcon(
                          style: galleryButtonStyle.copyWith(
                            backgroundColor: const WidgetStatePropertyAll(
                              Color(0xff6d3032),
                            ),
                            foregroundColor: const WidgetStatePropertyAll(
                              Colors.white,
                            ),
                          ),
                          onPressed: _open,
                          icon: const Icon(
                            Icons.image_outlined,
                            size: galleryIconSize,
                          ),
                          label: Text(
                            widget.photos.length > 1
                                ? 'Ảnh ${_index + 1}/${widget.photos.length}'
                                : 'Ảnh',
                          ),
                        ),
                        if (widget.onModel != null) ...[
                          const SizedBox(width: 4),
                          FilledButton.tonalIcon(
                            style: galleryButtonStyle.copyWith(
                              backgroundColor: const WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              foregroundColor: const WidgetStatePropertyAll(
                                Color(0xff292929),
                              ),
                            ),
                            onPressed: widget.onModel,
                            icon: const Icon(
                              Icons.view_in_ar_outlined,
                              size: galleryIconSize,
                            ),
                            label: const Text('Xem 3D'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                IconButton.filledTonal(
                  tooltip: 'Mở ảnh toàn màn hình',
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: _open,
                  icon: const Icon(Icons.fullscreen),
                ),
              ],
            ),
          ),
      ],
    );
    return widget.fullscreen || widget.cover
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
