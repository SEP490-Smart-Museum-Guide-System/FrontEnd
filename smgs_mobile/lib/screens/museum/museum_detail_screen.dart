import 'package:flutter/material.dart';

import '../../models/museum.dart';
import '../../core/network/api_config.dart';
import '../../services/discovery_api_service.dart';
import '../../services/token_manager.dart';
import '../../widgets/museum_ui.dart';
import '../artifact/artifact_qr_scanner.dart';
import '../../widgets/exploration_map_button.dart';
import 'visitor_directory_screen.dart';

const _burgundy = Color(0xff6d3032);
const _paper = Color(0xfffaf7f2);
const _label = TextStyle(
  fontFamily: AppTextStyles.sansFamily,
  color: _burgundy,
  fontWeight: FontWeight.w700,
  fontSize: 11,
  letterSpacing: .8,
);

class MuseumDetailScreen extends StatefulWidget {
  const MuseumDetailScreen({
    super.key,
    required this.museum,
    this.heroTag,
    this.loadMuseum = DiscoveryApiService.fetchMuseumDetail,
    this.loadHighlights = DiscoveryApiService.fetchMuseumHighlights,
  });

  final Museum museum;
  final Object? heroTag;
  final Future<Museum> Function(String) loadMuseum;
  final Future<MuseumHighlights> Function(String) loadHighlights;

  @override
  State<MuseumDetailScreen> createState() => _MuseumDetailScreenState();
}

class _MuseumDetailScreenState extends State<MuseumDetailScreen> {
  late Museum _museum;
  MuseumHighlights? _highlights;
  bool _detailFailed = false;
  bool _highlightsFailed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(MuseumDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.museum.id != oldWidget.museum.id) _initialize();
  }

  void _initialize() {
    _museum = widget.museum;
    _highlights = null;
    _detailFailed = false;
    _highlightsFailed = false;
    if (int.tryParse(_museum.id) != null) {
      _loadMuseum();
      _loadHighlights();
    }
  }

  Future<void> _loadMuseum() async {
    final id = widget.museum.id;
    try {
      final detail = await widget.loadMuseum(id);
      if (mounted && widget.museum.id == id) {
        setState(() => _museum = detail);
      }
    } catch (_) {
      if (mounted && widget.museum.id == id) {
        setState(() => _detailFailed = true);
      }
    }
  }

  Future<void> _loadHighlights() async {
    final id = widget.museum.id;
    try {
      final highlights = await widget.loadHighlights(id);
      if (mounted && widget.museum.id == id) {
        setState(() => _highlights = highlights);
      }
    } catch (_) {
      if (mounted && widget.museum.id == id) {
        setState(() => _highlightsFailed = true);
      }
    }
  }

  void _retry() {
    if (_detailFailed) {
      setState(() => _detailFailed = false);
      _loadMuseum();
    }
    if (_highlightsFailed) {
      setState(() => _highlightsFailed = false);
      _loadHighlights();
    }
  }

  Future<void> _explore() async {
    final id = int.tryParse(_museum.id);
    if (id == null || id <= 0) return;
    await MuseumExploration.instance.select(id);
    if (!mounted) return;
    openPage(context, const ArtifactQrScanner(direct: true, standalone: true));
  }

  @override
  Widget build(BuildContext context) {
    final museumId = int.tryParse(_museum.id);
    final top =
        _highlights?.topArtifacts.take(3).toList() ??
        <MuseumHighlightArtifact>[];
    final hours = _museum.openingHours.trim();
    // The backend stores a free-form schedule, often with days in parentheses.
    final schedule = RegExp(r'^([^()]+?)\s*\(([^()]+)\)$').firstMatch(hours);
    final intro = _museum.description.trim().isEmpty
        ? _museum.shortIntro
        : _museum.description;
    final height = (MediaQuery.sizeOf(context).width * .785 + 24)
        .clamp(240.0, 380.0)
        .toDouble();
    final photo = MuseumPhoto(
      museumId: _museum.id,
      imageUrl: _museum.imageUrl,
      height: height,
    );

    return Scaffold(
      backgroundColor: _paper,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                widget.heroTag == null
                    ? photo
                    : Hero(tag: widget.heroTag!, child: photo),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _paper,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 38,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xffded5c9),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 6,
                  child: SafeArea(
                    bottom: false,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: BackButton(color: _burgundy),
                    ),
                  ),
                ),
              ],
            ),
            SafeArea(
              top: false,
              bottom: false,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 660),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BẢO TÀNG', style: _label),
                    const SizedBox(height: 5),
                    Text(
                      _museum.name,
                      style: AppTextStyles.pageTitle.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.22,
                      ),
                    ),
                    if (_museum.location.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: _burgundy,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _museum.location,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _Stat(
                              icon: Icons.schedule_outlined,
                              label: 'GIỜ THAM KHẢO',
                              value:
                                  schedule?.group(1)?.trim() ??
                                  (hours.isEmpty
                                      ? 'Chưa có thông tin giờ mở cửa'
                                      : hours),
                              subtitle: schedule?.group(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Stat(
                              icon: Icons.museum_outlined,
                              label: 'HIỆN VẬT QR',
                              value:
                                  _highlights?.qrArtifactCount.toString() ??
                                  '—',
                              subtitle: 'Có hướng dẫn QR',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_detailFailed || _highlightsFailed)
                      TextButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử tải lại thông tin'),
                      ),
                    const SizedBox(height: 24),
                    const Text('GIỚI THIỆU', style: _label),
                    const SizedBox(height: 8),
                    Text(
                      intro.trim().isEmpty
                          ? 'Chưa có thông tin giới thiệu.'
                          : intro,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (top.isNotEmpty) ...[
                      const SectionHeading('Hiện vật được quan tâm nhất'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final artifact in top) ...[
                            if (artifact != top.first)
                              const SizedBox(width: 10),
                            Expanded(child: _Highlight(artifact: artifact)),
                          ],
                          for (var i = top.length; i < 3; i++) ...[
                            const SizedBox(width: 10),
                            const Spacer(),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Material(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _burgundy,
                        foregroundColor: Colors.white,
                        textStyle: AppTextStyles.buttonText,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _explore,
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text(
                        'Bắt đầu khám phá',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Mở bản đồ bảo tàng',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: _burgundy,
                    ),
                    onPressed: museumId == null
                        ? null
                        : () => openPage(
                            context,
                            VisitorDirectoryScreen(
                              museumId: museumId,
                              museumName: _museum.name,
                            ),
                          ),
                    icon: const Icon(Icons.map_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });
  final IconData icon;
  final String label, value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: _burgundy),
            const SizedBox(width: 4),
            Expanded(child: Text(label, style: _label.copyWith(fontSize: 10))),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption),
      ],
    ),
  );
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.artifact});
  final MuseumHighlightArtifact artifact;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.softSand,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.secondaryText),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: artifact.imageUrl.isEmpty
                ? placeholder
                : Image.network(
                    artifact.imageUrl,
                    headers:
                        artifact.imageUrl.startsWith(
                              '${ApiConfig.baseUrl}/artifacts/',
                            ) &&
                            TokenManager.hasToken
                        ? {'Authorization': 'Bearer ${TokenManager.token}'}
                        : null,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          artifact.name,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
      ],
    );
  }
}
