import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';
import '../../services/visitor_experience_api.dart';
import '../museum/visit_progress_screen.dart';

class PublishedToursScreen extends StatelessWidget {
  const PublishedToursScreen({
    super.key,
    required this.museumId,
    this.maxMinutes,
  });
  final int museumId;
  final int? maxMinutes;

  @override
  Widget build(BuildContext context) {
    final museumName = AppServices.catalog.museumName(museumId.toString());

    return MuseumPage(
      back: true,
      title: 'Các tuyến tham quan',
      subtitle: museumName,
      children: [
        const Eyebrow('TUYẾN KHÁM PHÁ CHỦ ĐỀ'),
        const SizedBox(height: 6),
        Text('Tuyến tham quan có sẵn', style: AppTextStyles.pageTitle),
        if (maxMinutes != null) ...[
          const SizedBox(height: 6),
          Text(
            'Lọc theo thời lượng tối đa $maxMinutes phút',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.deepBurgundy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        BackendPanel(
          resourceKey: 'published-tours:$museumId:$maxMinutes',
          load: () => BackendApi.list('tours?museumId=$museumId'),
          builder: (data, reload) {
            final rows = (data as List)
                .cast<Map<String, dynamic>>()
                .where(
                  (t) =>
                      maxMinutes == null ||
                      (t['estimatedMinutes'] as num) <= maxMinutes!,
                )
                .toList();
            return Column(
              children: [
                if (rows.isEmpty)
                  const Notice('Chưa có tuyến đã xuất bản phù hợp.')
                else
                  for (final tour in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => openPage(
                          context,
                          PublishedTourDetailScreen(tourId: tour['id'] as int),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.deepBurgundy,
                                  borderRadius: BorderRadius.circular(10),
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
                                              '${tour['estimatedMinutes']} phút',
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
                                              '${(tour['items'] as List).length} điểm dừng',
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
        ),
        if (maxMinutes != null)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () =>
                  openPage(context, PublishedToursScreen(museumId: museumId)),
              child: const Text('Xem tất cả tuyến tham quan'),
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

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Tuyến tham quan',
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
                  borderRadius: BorderRadius.circular(16),
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
                            borderRadius: BorderRadius.circular(12),
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
                                'TUYẾN TIÊU BIỂU',
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
                              '${tour['estimatedMinutes']} phút',
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
              const SectionHeading('Lộ trình các điểm dừng'),
              const SizedBox(height: 12),

              // Connected Timeline
              for (var i = 0; i < items.length; i++) ...[
                () {
                  final item = items[i];
                  final artifact = AppServices.catalog.artifacts
                      .where((a) => a.id == item['artifactId'].toString())
                      .firstOrNull;
                  final artifactName =
                      artifact?.name ?? 'Hiện vật #${item['artifactId']}';
                  final location = artifact?.location ?? '';
                  final isLast = i == items.length - 1;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.antiqueIvory,
                                  child: Image.network(
                                    artifact!.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
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
                                'Di chuyển sang điểm tiếp theo',
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
                label: _busy ? 'Đang bắt đầu…' : 'Bắt đầu chuyến tham quan',
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
            ],
          );
        },
      ),
    ],
  );
}
