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
import '../profile/services_screen.dart';
import '../../services/backend_api.dart';

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
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _admissionOffers = [];

  String _formatPrice(dynamic amount) {
    if (amount == null) return '0 đ';
    if (amount is num) {
      return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
    }
    final parsed = double.tryParse(amount.toString());
    if (parsed != null) {
      return '${parsed.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
    }
    return '$amount đ';
  }

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
    _products = [];
    _admissionOffers = [];
    if (int.tryParse(_museum.id) != null) {
      _loadMuseum();
      _loadHighlights();
      _loadAdmissionOffers();
      _loadProducts();
    }
  }

  Future<void> _loadAdmissionOffers() async {
    final id = widget.museum.id;
    try {
      final res = await BackendApi.request('commerce/museums/$id/admission-offers');
      if (mounted && widget.museum.id == id && res is List) {
        setState(() {
          _admissionOffers = res.cast<Map<String, dynamic>>().where((p) => p['isActive'] == true).toList();
        });
      }
    } catch (_) {
      // Gracefully ignore if admission offers unavailable
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

  Future<void> _loadProducts() async {
    final id = widget.museum.id;
    try {
      final res = await BackendApi.request('commerce/museums/$id/products');
      if (mounted && widget.museum.id == id && res is List) {
        setState(() {
          _products = res.cast<Map<String, dynamic>>().where((p) => p['isActive'] == true).toList();
        });
      }
    } catch (_) {
      // Gracefully ignore if commerce is unavailable
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
                    if (_admissionOffers.isNotEmpty || _products.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.isEn ? 'PASSES & DIGITAL SERVICES' : 'VÉ & GÓI DỊCH VỤ SỐ', style: _label),
                          if (_products.length + _admissionOffers.length > 2)
                            GestureDetector(
                              onTap: () => openPage(
                                context,
                                ServicesScreen(
                                  museumId: _museum.id,
                                  museumName: _museum.name,
                                ),
                              ),
                              child: Text(
                                l10n.isEn ? 'View all' : 'Xem tất cả',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _burgundy,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_admissionOffers.isNotEmpty) ...[
                        for (final a in _admissionOffers.take(1)) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBF7),
                              borderRadius: BorderRadius.circular(VisitorRadius.xl),
                              border: Border.all(color: AppColors.mutedGold, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: _burgundy.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _burgundy.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _burgundy.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        '🎟️ Vé vào cổng',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _burgundy,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatPrice(a['price']),
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: _burgundy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  a['name']?.toString() ?? 'Vé tham quan bảo tàng',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.serifFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bao gồm quyền vào cửa · Tùy chọn mua kèm gói thuyết minh AI khi đặt vé',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _burgundy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(VisitorRadius.md),
                                      ),
                                    ),
                                    icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                                    label: const Text('Đặt vé vào cổng ngay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    onPressed: () => openPage(
                                      context,
                                      ServicesScreen(
                                        museumId: _museum.id,
                                        museumName: _museum.name,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        for (final p in _products.take(2)) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(VisitorRadius.xl),
                              border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.45)),
                              boxShadow: [
                                BoxShadow(
                                  color: _burgundy.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.mutedGold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.mutedGold),
                                      ),
                                      child: const Text(
                                        'Tư liệu số & Thuyết minh',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _burgundy,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatPrice(p['price']),
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: _burgundy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p['name']?.toString() ?? 'Gói dịch vụ',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.serifFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Áp dụng: ${p['seats'] ?? 1} người · Thời hạn: ${p['validityHours'] ?? 24}h sau thanh toán',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _burgundy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(VisitorRadius.md),
                                      ),
                                    ),
                                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                                    label: const Text('Đặt mua gói này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    onPressed: () => openPage(
                                      context,
                                      ServiceCheckoutScreen(
                                        museumId: _museum.id,
                                        product: p,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
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
                    tooltip: l10n.isEn ? 'Buy passes and services' : 'Vé & Dịch vụ số',
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
                            ServicesScreen(
                              museumId: museumId.toString(),
                              museumName: _museum.name,
                            ),
                          ),
                    icon: const Icon(Icons.confirmation_number_outlined),
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
