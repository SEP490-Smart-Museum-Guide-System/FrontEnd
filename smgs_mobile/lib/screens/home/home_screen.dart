import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/experience.dart';
import '../../models/museum.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import '../../services/visitor_experience_api.dart';
import '../../widgets/game_tutorial_overlay.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/visitor_handbook_sheet.dart';
import '../../widgets/automatic_arrival_card.dart';
import '../museum/museum_detail_screen.dart';
import '../museum/visit_progress_screen.dart';
import '../profile/my_museum_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onExplore, required this.onScan});
  final VoidCallback onExplore, onScan;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _visits = _loadVisits();

  Future<List<Map<String, dynamic>>> _loadVisits() {
    final future = BackendApi.list('visits/me?status=InProgress');
    // FutureBuilder subscribes next frame; retain even immediate failures for its error UI.
    future.ignore();
    return future;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  Future<void> _checkOnboarding() async {
    final user = AppServices.auth.user;
    if (user == null || user.role != UserRole.visitor) return;
    final show = await GameTutorialOverlay.shouldShow(user.email);
    if (show && mounted) HomeScreenTour.start(context);
  }

  void _reloadVisits() {
    setState(() {
      _visits = _loadVisits();
    });
  }

  Future<void> _openVisit(int id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => VisitProgressScreen(visitId: id)),
    );
    if (mounted) _reloadVisits();
  }

  Future<void> _openMuseum(Museum museum) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => MuseumDetailScreen(museum: museum)),
    );
    if (mounted) _reloadVisits();
  }

  @override
  Widget build(BuildContext context) {
    final museums = AppServices.catalog.museums;
    final l10n = context.l10n;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: VisitorColors.burgundy,
          onPrimary: VisitorColors.background,
          surface: VisitorColors.background,
          onSurface: VisitorColors.text,
          outline: VisitorColors.border,
        ),
        iconTheme: const IconThemeData(color: VisitorColors.text),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: VisitorColors.burgundy,
            minimumSize: const Size(48, 48),
            textStyle: AppTextStyles.buttonText.copyWith(
              color: VisitorColors.burgundy,
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: VisitorColors.burgundy,
          linearTrackColor: VisitorColors.border,
        ),
      ),
      child: ColoredBox(
        key: const ValueKey('home-white-surface'),
        color: VisitorColors.background,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                key: const PageStorageKey('home-discovery'),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                      child: Row(
                        children: [
                          const HeritageSeal(size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SMGS',
                                  style: AppTextStyles.sectionTitle.copyWith(
                                    fontSize: 22,
                                    color: VisitorColors.text,
                                  ),
                                ),
                                Text(
                                  l10n.isEn ? 'Discover Vietnamese Heritage' : 'Khám phá di sản Việt',
                                  style: AppTextStyles.caption.copyWith(
                                    color: VisitorColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: HomeScreenTour.handbookBtnKey,
                            tooltip: l10n.isEn ? 'Handbook' : 'Cẩm nang tham quan',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(
                              Icons.menu_book_outlined,
                              size: 24,
                            ),
                            onPressed: () => VisitorHandbookSheet.show(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AutomaticArrivalCard(),
                          _DiscoveryHero(museum: museums.firstOrNull),
                          const SizedBox(height: 24),
                          Material(
                            key: HomeScreenTour.scanCardKey,
                            color: VisitorColors.burgundy,
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: widget.onScan,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.qr_code_scanner,
                                      color: VisitorColors.background,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.isEn ? 'Decode an Artifact' : 'Giải mã một hiện vật',
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                                  color:
                                                      VisitorColors.background,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.4,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.isEn
                                                ? 'Scan QR code to reveal the story behind the artifact'
                                                : 'Quét mã QR để khám phá câu chuyện phía sau hiện vật',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color:
                                                      VisitorColors.background,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  l10n.isEn ? 'Scan Artifact' : 'Quét hiện vật',
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: VisitorColors
                                                            .background,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward,
                                                size: 18,
                                                color: VisitorColors.background,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Column(
                            key: HomeScreenTour.museumSectionKey,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (museums.isNotEmpty) ...[
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  children: [
                                    Text(
                                      l10n.isEn ? 'Featured Museums' : 'Bảo tàng nổi bật',
                                      style: AppTextStyles.sectionTitle
                                          .copyWith(
                                            color: VisitorColors.text,
                                            fontSize: 22,
                                          ),
                                    ),
                                    TextButton(
                                      onPressed: widget.onExplore,
                                      child: Text(l10n.isEn ? 'See all' : 'Xem tất cả'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = museums.length == 1
                                        ? constraints.maxWidth
                                        : constraints.maxWidth * .86;
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (
                                            var i = 0;
                                            i < museums.length;
                                            i++
                                          ) ...[
                                            if (i > 0)
                                              const SizedBox(width: 16),
                                            SizedBox(
                                              width: width,
                                              child: _MuseumPreview(
                                                museum: museums[i],
                                                onTap: () =>
                                                    _openMuseum(museums[i]),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 28),
                              ],
                            ],
                          ),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _visits,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return Semantics(
                                  label: l10n.isEn ? 'Loading journey' : 'Đang tải hành trình',
                                  child: Container(
                                    key: const ValueKey('home-visit-loading'),
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: VisitorColors.surface2,
                                      borderRadius: BorderRadius.circular(VisitorRadius.xl),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      l10n.isEn ? 'Loading journey…' : 'Đang tải hành trình…',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: VisitorColors.secondaryText,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.isEn ? 'Unable to load journey' : 'Chưa tải được hành trình',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: VisitorColors.text,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _reloadVisits,
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: Text(l10n.isEn ? 'Retry' : 'Thử lại'),
                                    ),
                                  ],
                                );
                              }
                              final visit = snapshot.data!.firstOrNull;
                              return _JourneyCard(
                                visit: visit,
                                onPressed: visit == null
                                    ? widget.onExplore
                                    : () => _openVisit(visit['id'] as int),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Material(
                            key: HomeScreenTour.collectionKey,
                            color: VisitorColors.surface1,
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () =>
                                  openPage(context, const MyMuseumScreen()),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.collections_bookmark_outlined,
                                      size: 24,
                                      color: VisitorColors.burgundy,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.isEn ? 'My Museums' : 'Bảo tàng cá nhân',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: VisitorColors.text,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.isEn
                                                ? 'Preserve artifacts you have discovered'
                                                : 'Lưu giữ những hiện vật bạn đã khám phá',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: VisitorColors
                                                      .secondaryText,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 20,
                                      color: VisitorColors.secondaryText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({this.museum});
  final Museum? museum;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(VisitorRadius.xxl),
          child: AspectRatio(
            aspectRatio: 1.8,
            child: museum != null && museum!.imageUrl.isNotEmpty
                ? MuseumPhoto(
                    museumId: museum!.id,
                    imageUrl: museum!.imageUrl,
                    placeholderColor: VisitorColors.secondaryBackground,
                  )
                : Image.asset(
                    'assets/images/national-museum-web.jpg',
                    fit: BoxFit.cover,
                    semanticLabel: 'Kiến trúc Bảo tàng Lịch sử Quốc gia',
                    errorBuilder: (_, _, _) => const HeritageArt(height: 180),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.isEn ? 'Every artifact,\na story to tell' : 'Mỗi hiện vật,\nmột câu chuyện',
          style: AppTextStyles.display.copyWith(
            color: VisitorColors.text,
            fontSize: 28,
            height: 1.3,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.isEn
              ? 'Explore Vietnamese history and culture in your own way'
              : 'Khám phá lịch sử và văn hóa Việt Nam theo cách của bạn',
          style: AppTextStyles.bodySmall.copyWith(
            color: VisitorColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _MuseumPreview extends StatelessWidget {
  const _MuseumPreview({required this.museum, required this.onTap});
  final Museum museum;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    key: ValueKey('home-museum:${museum.id}'),
    color: VisitorColors.surface1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VisitorRadius.xl),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MuseumPhoto(
            museumId: museum.id,
            imageUrl: museum.imageUrl,
            placeholderColor: VisitorColors.secondaryBackground,
            height: 160,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  museum.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: VisitorColors.text,
                    fontSize: 20,
                  ),
                ),
                if (museum.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: VisitorColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          museum.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: VisitorColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.visit, required this.onPressed});
  final Map<String, dynamic>? visit;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                size: 20,
                color: VisitorColors.burgundy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visit == null
                      ? (l10n.isEn ? 'Your Journey' : 'Hành trình của bạn')
                      : (l10n.isEn ? 'Visiting now' : 'Đang tham quan'),
                  style: AppTextStyles.caption.copyWith(
                    color: VisitorColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            visit == null
                ? (l10n.isEn ? 'Start exploration journey' : 'Bắt đầu hành trình khám phá')
                : (l10n.isEn ? 'Continue journey' : 'Tiếp tục hành trình'),
            style: AppTextStyles.sectionTitle.copyWith(
              color: VisitorColors.text,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            visit == null
                ? (l10n.isEn
                    ? 'Pick a museum and start your personal tour'
                    : 'Chọn một bảo tàng và bắt đầu chuyến đi theo cách của bạn')
                : AppServices.catalog.museumName(visit!['museumId'].toString()),
            style: AppTextStyles.bodySmall.copyWith(
              color: VisitorColors.secondaryText,
            ),
          ),
          if (visit != null) ...[
            const SizedBox(height: 12),
            _VisitProgress(key: ObjectKey(visit), visitId: visit!['id'] as int),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onPressed,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(
              visit == null
                  ? (l10n.isEn ? 'Explore museums' : 'Khám phá bảo tàng')
                  : (l10n.isEn ? 'View progress' : 'Xem tiến độ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitProgress extends StatefulWidget {
  const _VisitProgress({super.key, required this.visitId});
  final int visitId;
  @override
  State<_VisitProgress> createState() => _VisitProgressState();
}

class _VisitProgressState extends State<_VisitProgress> {
  late final _progress = VisitorExperienceApi.progress(widget.visitId);
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<Map<String, dynamic>>(
      future: _progress,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final stops = (snapshot.data!['stops'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        if (stops.isEmpty) return const SizedBox.shrink();
        final visited = stops
            .where((stop) => stop['lastVisitedAt'] != null)
            .length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.isEn
                  ? 'Explored $visited / ${stops.length} artifacts'
                  : 'Đã khám phá $visited / ${stops.length} hiện vật',
              style: AppTextStyles.caption.copyWith(
                color: VisitorColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: visited / stops.length,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
              semanticsLabel: l10n.isEn ? 'Exploration progress' : 'Tiến độ khám phá hiện vật',
            ),
          ],
        );
      },
    );
  }
}
