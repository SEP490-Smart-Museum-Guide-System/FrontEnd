import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/museum.dart';
import '../../core/network/api_config.dart';
import '../../services/discovery_api_service.dart';
import '../../services/token_manager.dart';
import '../../widgets/museum_ui.dart';
import '../artifact/artifact_qr_scanner.dart';
import '../../widgets/exploration_map_button.dart';
import 'visitor_directory_screen.dart';

const _burgundy = Color(0xff6d3032);
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
      // Keep the available museum information when this request fails.
    }
  }

  Future<void> _loadHighlights() async {
    final id = widget.museum.id;
    try {
      final highlights = await widget.loadHighlights(id);
      if (mounted && widget.museum.id == id) {
        setState(() => _highlights = highlights);
      }
    } catch (error) {
      debugPrint('Museum discovery request failed: $error');
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
    final l10n = context.l10n;
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                widget.heroTag == null
                    ? photo
                    : Hero(tag: widget.heroTag!, child: photo),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(VisitorRadius.xxl),
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 38,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: VisitorColors.surface2,
                            borderRadius: BorderRadius.all(Radius.circular(VisitorRadius.full)),
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
                      child: const BackButton(color: _burgundy),
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
                    Text(l10n.isEn ? 'MUSEUM' : 'BẢO TÀNG', style: _label),
                    const SizedBox(height: 5),
                    Text(
                      _museum.name,
                      style: AppTextStyles.pageTitle.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.22,
                      ),
                    ),
                    if (l10n.isEn && _museum.languageCode != null && _museum.languageCode != 'en') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: VisitorColors.surface2,
                          borderRadius: BorderRadius.circular(VisitorRadius.sm),
                          border: Border.all(color: VisitorColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: VisitorColors.secondaryText),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l10n.fallbackTranslationNote,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.sansFamily,
                                  fontSize: 12,
                                  color: VisitorColors.secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                              label: l10n.isEn ? 'OPENING HOURS' : 'GIỜ THAM KHẢO',
                              value:
                                  schedule?.group(1)?.trim() ??
                                  (hours.isEmpty
                                      ? (l10n.isEn ? 'Hours not provided' : 'Chưa có thông tin giờ mở cửa')
                                      : hours),
                              subtitle: schedule?.group(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Stat(
                              icon: Icons.museum_outlined,
                              label: l10n.isEn ? 'QR ARTIFACTS' : 'HIỆN VẬT QR',
                              value:
                                  _highlights?.qrArtifactCount.toString() ??
                                  '—',
                              subtitle: _highlights?.publicOnly == true
                                  ? (l10n.isEn ? 'Public QR guide available' : 'Có hướng dẫn QR công khai')
                                  : (l10n.isEn ? 'Has QR guide' : 'Có hướng dẫn QR'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.isEn ? 'INTRODUCTION' : 'GIỚI THIỆU', style: _label),
                    const SizedBox(height: 8),
                    Text(
                      intro.trim().isEmpty
                          ? (l10n.isEn ? 'No introduction available.' : 'Chưa có thông tin giới thiệu.')
                          : intro,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (top.isNotEmpty) ...[
                      SectionHeading(
                        l10n.isEn ? 'Most Popular Artifacts' : 'Hiện vật được quan tâm nhất',
                      ),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Material(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VisitorRadius.xl),
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
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VisitorRadius.lg),
                        ),
                      ),
                      onPressed: _explore,
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: Text(
                        l10n.startExploreCTA,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: l10n.isEn ? 'Open museum map' : 'Mở bản đồ bảo tàng',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(50, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VisitorRadius.lg),
                      ),
                      side: BorderSide.none,
                      backgroundColor: VisitorColors.surface2,
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: VisitorColors.surface1,
      borderRadius: BorderRadius.circular(VisitorRadius.xl),
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
          borderRadius: BorderRadius.circular(VisitorRadius.md),
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
            fontFamily: AppTextStyles.serifFamily,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
      ],
    );
  }
}
