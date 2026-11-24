import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/app_preferences.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';
import '../../services/visitor_experience_api.dart';
import '../museum/visit_progress_screen.dart';

class PublishedToursScreen extends StatefulWidget {
  const PublishedToursScreen({
    super.key,
    required this.museumId,
    this.maxMinutes,
  });
  final int museumId;
  final int? maxMinutes;

  @override
  State<PublishedToursScreen> createState() => _PublishedToursScreenState();
}

class _PublishedToursScreenState extends State<PublishedToursScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final museumName = AppServices.catalog.museumName(widget.museumId.toString());

    return MuseumPage(
      back: true,
      title: l10n.isEn ? 'Curated Tours' : 'Các tuyến tham quan',
      subtitle: museumName,
      children: [
        Eyebrow(l10n.isEn ? 'THEMATIC EXPLORATION ROUTES' : 'TUYẾN KHÁM PHÁ CHỦ ĐỀ'),
        const SizedBox(height: 6),
        Text(l10n.isEn ? 'Available Curated Tours' : 'Tuyến tham quan có sẵn', style: AppTextStyles.pageTitle),
        if (widget.maxMinutes != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.isEn ? 'Filtered by max duration ${widget.maxMinutes} mins' : 'Lọc theo thời lượng tối đa ${widget.maxMinutes} phút',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.deepBurgundy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Tabs: Tất cả tuyến vs Lộ trình đã lưu (WF-02 F05)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? AppColors.deepBurgundy : VisitorColors.surface2,
                    borderRadius: BorderRadius.circular(VisitorRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      l10n.isEn ? 'All Tours' : 'Tất cả tuyến',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 0 ? AppColors.antiqueIvory : AppColors.darkBrown,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? AppColors.deepBurgundy : VisitorColors.surface2,
                    borderRadius: BorderRadius.circular(VisitorRadius.md),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          size: 15,
                          color: _selectedTab == 1 ? AppColors.antiqueIvory : AppColors.darkBrown,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.isEn ? 'Saved Routes' : 'Lộ trình đã lưu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1 ? AppColors.antiqueIvory : AppColors.darkBrown,
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
        const SizedBox(height: 16),

        if (_selectedTab == 0)
        BackendPanel(
          resourceKey: 'published-tours:${widget.museumId}:${widget.maxMinutes}',
          load: () => BackendApi.list('tours?museumId=${widget.museumId}'),
          builder: (data, reload) {
            final rows = (data as List)
                .cast<Map<String, dynamic>>()
                .where(
                  (t) =>
                      widget.maxMinutes == null ||
                      (t['estimatedMinutes'] as num) <= widget.maxMinutes!,
                )
                .toList();
            return Column(
              children: [
                if (rows.isEmpty)
                  Notice(l10n.isEn ? 'No matching curated tours found.' : 'Chưa có tuyến đã xuất bản phù hợp.')
                else
                  for (final tour in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => openPage(
                          context,
                          PublishedTourDetailScreen(tourId: tour['id'] as int),
                        ),
                        borderRadius: BorderRadius.circular(VisitorRadius.xl),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: VisitorColors.surface1,
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.deepBurgundy,
                                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                                ),
                                child: const Icon(
                                  Icons.route_outlined,
                                  color: AppColors.antiqueIvory,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tour['title'] ?? '',
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 13,
                                              color: AppColors.darkBrown
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.isEn ? '${tour['estimatedMinutes']} mins' : '${tour['estimatedMinutes']} phút',
                                              style:
                                                  AppTextStyles.caption.copyWith(
                                                color: AppColors.darkBrown
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.flag_outlined,
                                              size: 13,
                                              color: AppColors.darkBrown
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.isEn ? '${(tour['items'] as List).length} stops' : '${(tour['items'] as List).length} điểm dừng',
                                              style:
                                                  AppTextStyles.caption.copyWith(
                                                color: AppColors.darkBrown
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.darkBrown.withOpacity(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        )
        else
          // Tab 1: Saved Routes (GET /api/tours/saved-routes)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: VisitorExperienceApi.getSavedRoutes(museumId: widget.museumId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ));
              }
              final saved = snapshot.data ?? [];
              if (saved.isEmpty) {
                return Column(
                  children: [
                    Notice(l10n.isEn
                        ? 'You have not saved any routes for this museum. Click "Save Route" when viewing a tour to remember.'
                        : 'Bạn chưa lưu lộ trình nào cho bảo tàng này. Khi xem chi tiết tuyến tham quan, bấm "Lưu lộ trình" để ghi nhớ.'),
                  ],
                );
              }
              return Column(
                children: [
                  for (final item in saved)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          final tourId = item['tourId'] as int?;
                          if (tourId != null) {
                            openPage(context, PublishedTourDetailScreen(tourId: tourId));
                          }
                        },
                        borderRadius: BorderRadius.circular(VisitorRadius.xl),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: VisitorColors.surface1,
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.mutedGold,
                                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                                ),
                                child: const Icon(
                                  Icons.bookmark,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? (l10n.isEn ? 'Saved Route' : 'Lộ trình đã lưu'),
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          l10n.isEn ? '${item['estimatedMinutes'] ?? item['availableMinutes']} mins' : '${item['estimatedMinutes'] ?? item['availableMinutes']} phút',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.deepBurgundy,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          l10n.isEn ? '${(item['artifactIds'] as List?)?.length ?? 0} stops' : '${(item['artifactIds'] as List?)?.length ?? 0} trạm dừng',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.darkBrown.withOpacity(0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.mutedGold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (widget.maxMinutes != null)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () =>
                  openPage(context, PublishedToursScreen(museumId: widget.museumId)),
              child: Text(l10n.isEn ? 'View all available tours' : 'Xem tất cả tuyến tham quan'),
            ),
          ),
      ],
    );
  }
}

class PublishedTourDetailScreen extends StatefulWidget {
  const PublishedTourDetailScreen({super.key, required this.tourId});
  final int tourId;
  @override
  State<PublishedTourDetailScreen> createState() =>
      _PublishedTourDetailScreenState();
}

class _PublishedTourDetailScreenState extends State<PublishedTourDetailScreen> {
  bool _busy = false;
  String? _error;
  bool _isSaved = false;
  bool _savingRoute = false;

  Future<void> _saveRoute(Map<String, dynamic> tour) async {
    setState(() => _savingRoute = true);
    try {
      final versionRes = await BackendApi.request('tours/${widget.tourId}/public-version');
      final versionId = versionRes['id'] as int;
      final minutes = tour['estimatedMinutes'] is num ? (tour['estimatedMinutes'] as num).toInt() : 60;
      await VisitorExperienceApi.saveRoute(tourVersionId: versionId, availableMinutes: minutes);
      if (mounted) {
        final isEn = AppPreferences.instance.language == 'en';
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn
                ? 'Route saved to your personal list!'
                : 'Đã lưu lộ trình này vào mục cá nhân của bạn!'),
            backgroundColor: AppColors.deepBurgundy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isEn = AppPreferences.instance.language == 'en';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Failed to save route: $e' : 'Lỗi khi lưu lộ trình: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MuseumPage(
    back: true,
    title: l10n.isEn ? 'Tour Details' : 'Tuyến tham quan',
    children: [
      if (_error != null) Notice(_error!),
      BackendPanel(
        resourceKey: 'tour:${widget.tourId}',
        load: () => BackendApi.request('tours/${widget.tourId}'),
        builder: (data, reload) {
          final tour = data as Map<String, dynamic>;
          final museumName =
              AppServices.catalog.museumName(tour['museumId'].toString());
          final items =
              (tour['items'] as List).cast<Map<String, dynamic>>().toList()
                ..sort(
                  (a, b) =>
                      (a['orderNo'] as int).compareTo(b['orderNo'] as int),
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Itinerary Header Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.deepBurgundy,
                  borderRadius: BorderRadius.circular(VisitorRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(VisitorRadius.xs),
                            border: Border.all(
                              color: AppColors.mutedGold,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 13,
                                color: AppColors.mutedGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.isEn ? 'FEATURED TOUR' : 'TUYẾN TIÊU BIỂU',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: AppColors.antiqueIvory,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tour['title'] ?? '',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 20,
                        color: AppColors.antiqueIvory,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (museumName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        museumName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.antiqueIvory.withOpacity(0.8),
                        ),
                      ),
                    ],
                    if (tour['description'] != null &&
                        (tour['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        tour['description'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.antiqueIvory.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),

                    // Metrics row
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: AppColors.mutedGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.isEn ? '${tour['estimatedMinutes']} mins' : '${tour['estimatedMinutes']} phút',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.antiqueIvory,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.museum_outlined,
                              size: 16,
                              color: AppColors.mutedGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${items.length} điểm dừng',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.antiqueIvory,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SectionHeading(l10n.isEn ? 'Tour Stops Route' : 'Lộ trình các điểm dừng'),
              const SizedBox(height: 12),

              // Connected Timeline
              for (var i = 0; i < items.length; i++) ...[
                () {
                  final item = items[i];
                  final artifact = AppServices.catalog.artifacts
                      .where((a) => a.id == item['artifactId'].toString())
                      .firstOrNull;
                  final artifactName =
                      artifact?.name ?? (l10n.isEn ? 'Artifact #${item['artifactId']}' : 'Hiện vật #${item['artifactId']}');
                  final location = artifact?.location ?? '';
                  final isLast = i == items.length - 1;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: VisitorColors.surface1,
                          borderRadius: BorderRadius.circular(VisitorRadius.lg),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.deepBurgundy,
                              ),
                              child: Center(
                                child: Text(
                                  '${item['orderNo'] ?? (i + 1)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.antiqueIvory,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artifactName,
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (location.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.room_outlined,
                                          size: 13,
                                          color: AppColors.darkBrown
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style:
                                                AppTextStyles.caption.copyWith(
                                              color: AppColors.darkBrown
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (artifact?.imageUrl.isNotEmpty == true) ...[
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(VisitorRadius.sm),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.antiqueIvory,
                                  child: Image.network(
                                    artifact!.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.museum_outlined,
                                      size: 24,
                                      color: AppColors.deepBurgundy,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(left: 28),
                                width: 2,
                                height: 24,
                                color: AppColors.mutedGold.withOpacity(0.5),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                l10n.isEn ? 'Proceed to next stop' : 'Di chuyển sang điểm tiếp theo',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.darkBrown.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }(),
              ],

              const SizedBox(height: 24),
              PrimaryButton(
                label: _busy ? (l10n.isEn ? 'Starting…' : 'Đang bắt đầu…') : (l10n.isEn ? 'Start Museum Tour' : 'Bắt đầu chuyến tham quan'),
                icon: Icons.play_arrow_rounded,
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() {
                          _busy = true;
                          _error = null;
                        });
                        try {
                          final visit = await VisitorExperienceApi.startVisit(
                            tour['museumId'] as int,
                            tourId: widget.tourId,
                          );
                          if (context.mounted) {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => VisitProgressScreen(
                                  visitId: visit['id'] as int,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) setState(() => _error = e.toString());
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: _isSaved
                    ? (l10n.isEn ? 'Saved to Your List' : 'Đã lưu vào danh sách của bạn')
                    : (_savingRoute
                        ? (l10n.isEn ? 'Saving…' : 'Đang lưu…')
                        : (l10n.isEn ? 'Save Route' : 'Lưu lộ trình này')),
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                onPressed: _isSaved || _savingRoute ? null : () => _saveRoute(tour),
              ),
            ],
          );
        },
      ),
    ],
    );
  }
}
