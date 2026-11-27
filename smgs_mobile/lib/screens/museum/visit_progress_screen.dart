import 'package:flutter/material.dart';
import '../../widgets/earned_badges.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/visitor_experience_api.dart';
import '../../services/app_services.dart';
import '../artifact/artifact_qr_scanner.dart';
import 'visitor_directory_screen.dart';
import '../profile/profile_screen.dart';

String _formatDate(dynamic value) {
  if (value == null) return '';
  final str = value.toString();
  final dt = DateTime.tryParse(str);
  if (dt != null) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$h:$m · $d/$mo/${local.year}';
  }
  return str;
}

class VisitProgressScreen extends StatefulWidget {
  const VisitProgressScreen({super.key, required this.visitId});
  final int visitId;
  @override
  State<VisitProgressScreen> createState() => _VisitProgressScreenState();
}

class _VisitProgressScreenState extends State<VisitProgressScreen> {
  bool _busy = false;
  String? _error;
  void _openMap(Map<String, dynamic> visit) {
    openPage(
      context,
      VisitorDirectoryScreen(
        museumId: visit['museumId'] as int,
        museumName: AppServices.catalog.museumName(
          visit['museumId'].toString(),
        ),
        visitId: widget.visitId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MuseumPage(
    back: true,
    title: l10n.isEn ? 'Trip Progress' : 'Tiến độ chuyến đi',
    eyebrow: l10n.isEn ? 'Live Tracking' : 'Theo dõi trực tiếp',
    children: [
      if (_error != null) Notice(_error!),
      BackendPanel(
        resourceKey: 'visit-progress:${widget.visitId}',
        load: () async {
          final results = await Future.wait([
            VisitorExperienceApi.getVisit(widget.visitId).then((v) => v ?? {}),
            VisitorExperienceApi.progress(widget.visitId),
          ]);
          final visitMap = Map<String, dynamic>.from(results[0]);
          final progressMap = Map<String, dynamic>.from(results[1]);
          final tourId = (progressMap['tourId'] ?? visitMap['tourId']) as int?;
          if (tourId != null) {
            try {
              final tour = await BackendApi.request('tours/$tourId');
              if (tour is Map && tour['title'] != null) {
                visitMap['_resolvedTourTitle'] = tour['title'].toString();
                if (tour['description'] != null) {
                  visitMap['_resolvedTourDesc'] = tour['description'].toString();
                }
              }
            } catch (_) {}
          }
          return [visitMap, progressMap];
        },
        builder: (data, reload) {
          final visit = Map<String, dynamic>.from(data[0]);
          final progress = data[1] as Map<String, dynamic>;
          final stops = (progress['stops'] as List)
              .cast<Map<String, dynamic>>();
          final active = visit['status'] == 'InProgress';
          final museumName = AppServices.catalog.museumName(visit['museumId'].toString());
          final tourTitle = (visit['_resolvedTourTitle'] ?? visit['tourTitle'] ?? '').toString();
          final tourDesc = (visit['_resolvedTourDesc'] ?? '').toString();
          final visitedCount = stops.where((s) => s['lastVisitedAt'] != null).length;
          final totalCount = stops.length;
          final progressRatio = totalCount > 0 ? (visitedCount / totalCount).clamp(0.0, 1.0) : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Live Tracker Card
              Container(
                decoration: BoxDecoration(
                  color: VisitorColors.surface1,
                  borderRadius: BorderRadius.circular(VisitorRadius.xl),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFE8F5E9)
                                  : VisitorColors.surface2,
                              borderRadius: BorderRadius.circular(VisitorRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: active
                                        ? const Color(0xFF2E7D32)
                                        : AppColors.mutedGold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    active
                                        ? (l10n.isEn ? 'CURRENT VISIT' : 'ĐANG THAM QUAN')
                                        : backendStatus(
                                            visit['status'],
                                          ).toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                      color: active
                                          ? const Color(0xFF1B5E20)
                                          : AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      museumName,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 18,
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                    if (tourTitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.route_outlined,
                            size: 15,
                            color: AppColors.deepBurgundy,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tourTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (tourDesc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: VisitorColors.surface2,
                            borderRadius: BorderRadius.circular(VisitorRadius.md),
                          ),
                          child: Text(
                            tourDesc,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 4),
                    if (visit['personalizedTourId'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 13,
                              color: AppColors.mutedGold,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                l10n.isEn ? 'Personal journey · Stop order saved' : 'Hành trình cá nhân · Thứ tự điểm dừng đã được lưu',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      l10n.isEn ? 'Started: ${_formatDate(visit['startedAt'])}' : 'Bắt đầu: ${_formatDate(visit['startedAt'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (totalCount > 0) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.isEn ? 'Progress: $visitedCount / $totalCount exhibits' : 'Tiến độ: $visitedCount / $totalCount hiện vật',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progressRatio * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepBurgundy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(VisitorRadius.full),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 6,
                          backgroundColor: VisitorColors.surface2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.deepBurgundy,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.deepBurgundy,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: reload,
                        icon: const Icon(Icons.refresh, size: 14),
                        label: Text(l10n.isEn ? 'Refresh progress' : 'Cập nhật tiến độ', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // Thẻ Đặc quyền Hành trình & Đổi quà lưu niệm tại quầy
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(VisitorRadius.xl),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xFFB45309)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.isEn
                                ? 'Tour Rewards & Souvenir Redemption'
                                : 'Đặc quyền Hành trình & Đổi quà lưu niệm',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.isEn
                          ? 'Scan each tour stop QR to earn points & unlock Quizzes. Complete 100% of stops to earn +30 bonus points & a Heritage Badge for vouchers or counter souvenirs.'
                          : 'Quét QR từng trạm trong tour để tích điểm & mở khóa Quiz. Hoàn thành đủ các trạm nhận ngay +30 điểm thưởng & Huy hiệu để đổi Voucher hoặc Quà lưu niệm tại quầy.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.deepBurgundy,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => showCounterSouvenirPass(context),
                        icon: const Icon(Icons.redeem_rounded, size: 15),
                        label: Text(
                          l10n.isEn ? 'View Counter Souvenir Pass' : 'Xem phiếu đổi quà tại quầy',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              SectionHeading(l10n.isEn ? 'Itinerary Stops' : 'Danh sách điểm dừng'),
              const SizedBox(height: 8),

              if (stops.isEmpty)
                Notice(
                  l10n.isEn
                      ? 'Self-guided visit. Scan QR at exhibits to record your discoveries.'
                      : 'Lượt tham quan tự do. Quét QR tại hiện vật để ghi nhận khám phá.',
                )
              else
                for (var i = 0; i < stops.length; i++) ...[
                  () {
                    final stop = stops[i];
                    final isVisited = stop['lastVisitedAt'] != null;
                    final isNextTarget = active && !isVisited && (i == 0 || stops[i - 1]['lastVisitedAt'] != null);
                    final artifactName = AppServices.catalog.artifacts
                            .where((a) => a.id == stop['artifactId'].toString())
                            .firstOrNull
                            ?.name ??
                        (l10n.isEn ? 'Artifact #${stop['artifactId']}' : 'Hiện vật #${stop['artifactId']}');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VisitorColors.surface1,
                        borderRadius: BorderRadius.circular(VisitorRadius.lg),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isVisited
                                  ? const Color(0xFFE8F5E9)
                                  : (isNextTarget
                                      ? AppColors.deepBurgundy
                                      : VisitorColors.surface2),
                            ),
                            child: Center(
                              child: isVisited
                                  ? Icon(Icons.check, size: 18, color: Colors.green.shade800)
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isNextTarget
                                            ? Colors.white
                                            : AppColors.darkBrown,
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
                                    color: isVisited ? AppColors.darkBrown : null,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      isVisited ? Icons.access_time_filled : Icons.access_time,
                                      size: 13,
                                      color: isVisited ? Colors.green.shade700 : AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        isVisited
                                            ? (l10n.isEn ? 'Explored · ${_formatDate(stop['lastVisitedAt'])}' : 'Đã khám phá · ${_formatDate(stop['lastVisitedAt'])}')
                                            : (isNextTarget
                                                ? (l10n.isEn ? 'Next suggested stop' : 'Điểm dừng kế tiếp theo gợi ý')
                                                : (l10n.isEn ? 'Not scanned yet' : 'Chưa ghi nhận quét')),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isVisited || isNextTarget ? FontWeight.w600 : FontWeight.normal,
                                          color: isVisited
                                              ? Colors.green.shade800
                                              : (isNextTarget
                                                  ? AppColors.deepBurgundy
                                                  : AppColors.secondaryText),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }(),
                ],

              const SizedBox(height: 16),

              if (active) ...[
                PrimaryButton(
                  label: l10n.isEn ? 'Scan QR to Record' : 'Quét QR để ghi nhận',
                  icon: Icons.qr_code_scanner,
                  onPressed: _busy
                      ? null
                      : () {
                          VisitorSession.activeVisit = visit;
                          openPage(
                            context,
                            ArtifactQrScanner(visitId: widget.visitId),
                          );
                          reload();
                        },
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: l10n.isEn ? 'Directions on Museum Map' : 'Chỉ đường trên sơ đồ bảo tàng',
                  icon: Icons.map_outlined,
                  onPressed: () => _openMap(visit),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: _busy ? (l10n.isEn ? 'Ending…' : 'Đang hoàn tất…') : (l10n.isEn ? 'End Visit' : 'Kết thúc chuyến tham quan'),
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.isEn ? 'End this visit?' : 'Kết thúc chuyến tham quan?'),
                              content: Text(
                                l10n.isEn
                                    ? 'The system will check tour completion conditions.'
                                    : 'Hệ thống sẽ kiểm tra điều kiện hoàn thành của tuyến tham quan.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.isEn ? 'Continue Visit' : 'Tiếp tục tham quan'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l10n.isEn ? 'End Visit' : 'Kết thúc'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true || !mounted) return;
                          setState(() {
                            _busy = true;
                            _error = null;
                          });
                          try {
                            final rewards = await BackendApi.request(
                              'visits/${widget.visitId}/complete',
                              method: 'POST',
                              body: {},
                            );
                            if (mounted) showExplorationRewards(context, rewards);
                            if (VisitorSession.activeVisit?['id'] ==
                                widget.visitId) {
                              VisitorSession.clear();
                            }
                            reload();
                          } catch (e) {
                            if (mounted) setState(() => _error = e.toString());
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
              ],
              if (visit['status'] == 'Completed')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: PrimaryButton(
                    label: visit['hasFeedback'] == true
                        ? (l10n.isEn ? 'View / Edit Feedback' : 'Xem / chỉnh sửa đánh giá')
                        : (l10n.isEn ? 'Rate this Visit' : 'Đánh giá chuyến tham quan'),
                    icon: Icons.star_rate_rounded,
                    onPressed: () async {
                      await openVisitFeedback(context, visit);
                      reload();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ],
    );
  }
}
