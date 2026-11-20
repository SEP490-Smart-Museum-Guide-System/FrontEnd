import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Tiến độ chuyến đi',
    eyebrow: 'Theo dõi trực tiếp',
    children: [
      if (_error != null) Notice(_error!),
      BackendPanel(
        resourceKey: 'visit-progress:${widget.visitId}',
        load: () => Future.wait([
          BackendApi.request('visits/${widget.visitId}'),
          VisitorExperienceApi.progress(widget.visitId),
        ]),
        builder: (data, reload) {
          final visit = Map<String, dynamic>.from(data[0]);
          final progress = data[1] as Map<String, dynamic>;
          final stops = (progress['stops'] as List)
              .cast<Map<String, dynamic>>();
          final active = visit['status'] == 'InProgress';
          final museumName = AppServices.catalog.museumName(visit['museumId'].toString());
          final visitedCount = stops.where((s) => s['lastVisitedAt'] != null).length;
          final totalCount = stops.length;
          final progressRatio = totalCount > 0 ? (visitedCount / totalCount).clamp(0.0, 1.0) : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Live Tracker Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBrown.withValues(alpha: 0.05),
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
                                  : AppColors.softSand,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF81C784)
                                    : AppColors.border,
                                width: 0.8,
                              ),
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
                                        ? 'ĐANG THAM QUAN'
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
                        const SizedBox(width: 8),
                        Text(
                          '#${widget.visitId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedGold,
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
                                'Hành trình cá nhân · Thứ tự điểm dừng đã được lưu',
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
                      'Bắt đầu: ${_formatDate(visit['startedAt'])}',
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
                              'Tiến độ: $visitedCount / $totalCount hiện vật',
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
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 6,
                          backgroundColor: AppColors.softSand,
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
                        label: const Text('Cập nhật tiến độ', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const SectionHeading('Danh sách điểm dừng'),
              const SizedBox(height: 8),

              if (stops.isEmpty)
                const Notice(
                  'Lượt tham quan tự do. Quét QR tại hiện vật để ghi nhận khám phá.',
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
                        'Hiện vật #${stop['artifactId']}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isNextTarget
                              ? AppColors.mutedGold
                              : (isVisited ? Colors.green.shade300 : AppColors.border),
                          width: isNextTarget ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isVisited
                                  ? Colors.green.shade100
                                  : (isNextTarget
                                      ? AppColors.deepBurgundy
                                      : AppColors.antiqueIvory),
                              border: Border.all(
                                color: isVisited
                                    ? Colors.green.shade700
                                    : (isNextTarget
                                        ? AppColors.mutedGold
                                        : AppColors.border),
                                width: 1.5,
                              ),
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
                                            ? AppColors.antiqueIvory
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
                                            ? 'Đã khám phá · ${_formatDate(stop['lastVisitedAt'])}'
                                            : (isNextTarget
                                                ? 'Điểm dừng kế tiếp theo gợi ý'
                                                : 'Chưa ghi nhận quét'),
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
                  label: 'Quét QR để ghi nhận',
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
                  label: 'Chỉ đường trên sơ đồ bảo tàng',
                  icon: Icons.map_outlined,
                  onPressed: () => _openMap(visit),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: _busy ? 'Đang hoàn tất…' : 'Kết thúc chuyến tham quan',
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Kết thúc chuyến tham quan?'),
                              content: const Text(
                                'Hệ thống sẽ kiểm tra điều kiện hoàn thành của tuyến tham quan.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Tiếp tục tham quan'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Kết thúc'),
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
                            await BackendApi.request(
                              'visits/${widget.visitId}/complete',
                              method: 'POST',
                              body: {},
                            );
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
                        ? 'Xem / chỉnh sửa đánh giá'
                        : 'Đánh giá chuyến tham quan',
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
