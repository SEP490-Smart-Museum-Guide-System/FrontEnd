import '../museum/visit_progress_screen.dart';
import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../models/experience.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import 'profile_screen.dart';

String _formatHistoryDate(dynamic raw) {
  if (raw == null) return '';
  final dt = DateTime.tryParse(raw.toString());
  if (dt == null) return raw.toString();
  final local = dt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute · $day/$month/${local.year}';
}

Widget _buildVisitStatusPill(dynamic rawStatus) {
  final s = rawStatus?.toString().toLowerCase() ?? '';
  final bool isInProgress = s == 'inprogress' || s == 'active';
  final bool isCompleted = s == 'completed';

  final label = isInProgress
      ? 'Đang diễn ra'
      : isCompleted
          ? 'Đã hoàn thành'
          : s == 'cancelled'
              ? 'Đã hủy'
              : (rawStatus?.toString() ?? 'Chưa rõ');

  final bg = isInProgress
      ? const Color(0xFFE8F5E9)
      : isCompleted
          ? AppColors.antiqueIvory
          : Colors.grey.shade100;

  final fg = isInProgress
      ? const Color(0xFF2E7D32)
      : isCompleted
          ? AppColors.deepBurgundy
          : AppColors.secondaryText;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: fg.withValues(alpha: 0.3),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: AppTextStyles.sansFamily,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: fg,
      ),
    ),
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _visits = BackendApi.list(
    'visits/me',
  );
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Lịch sử tham quan',
    eyebrow: 'Hành trình di sản',
    subtitle: 'Nhật ký các lượt ghé thăm và trải nghiệm bảo tàng của bạn.',
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'CÁC CHUYẾN ĐI GẦN ĐÂY',
              style: TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => setState(() => _visits = BackendApi.list('visits/me')),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tải lại', style: TextStyle(fontSize: 12.5)),
            style: TextButton.styleFrom(foregroundColor: AppColors.deepBurgundy),
          ),
        ],
      ),
      const SizedBox(height: 6),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _visits,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          if (snapshot.data!.isEmpty) {
            return const EmptyState(
              title: 'Chưa có lượt tham quan',
              message:
                  'Bắt đầu lượt tham quan từ trang bảo tàng để lưu lịch sử.',
              icon: Icons.history_edu_outlined,
            );
          }
          return Column(
            children: snapshot.data!
                .map(
                  (v) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => openPage(
                          context,
                          VisitDetailScreen(
                            visit: VisitRecord(
                              id: v['id'].toString(),
                              museumId: v['museumId'].toString(),
                              date: DateTime.tryParse(v['startedAt'].toString()) ?? DateTime.now(),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.antiqueIvory,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.museum_outlined,
                                    size: 22,
                                    color: AppColors.deepBurgundy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppServices.catalog.museumName(
                                        v['museumId'].toString(),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.sansFamily,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkBrown,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatHistoryDate(v['startedAt']),
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.sansFamily,
                                        fontSize: 12,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildVisitStatusPill(v['status']),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class VisitDetailScreen extends StatefulWidget {
  const VisitDetailScreen({super.key, required this.visit});
  final VisitRecord visit;
  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  late Future<dynamic> _data = BackendApi.request('visits/${widget.visit.id}');
  String? _error;
  bool _busy = false;
  Future<void> _complete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BackendApi.request(
        'visits/${widget.visit.id}/complete',
        method: 'POST',
        body: {},
      );
      if (mounted) {
        setState(() => _data = BackendApi.request('visits/${widget.visit.id}'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Chi tiết lượt tham quan',
    eyebrow: 'Nhật ký di sản',
    subtitle: AppServices.catalog.museumName(widget.visit.museumId),
    children: [
      if (_error != null) Notice(_error!),
      FutureBuilder<dynamic>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          final v = snapshot.data as Map<String, dynamic>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin chuyến đi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'TRẠNG THÁI CHUYẾN ĐI',
                            style: TextStyle(
                              fontFamily: AppTextStyles.sansFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildVisitStatusPill(v['status']),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.login_rounded,
                      label: 'Bắt đầu',
                      value: _formatHistoryDate(v['startedAt']),
                    ),
                    if (v['completedAt'] != null) ...[
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        icon: Icons.logout_rounded,
                        label: 'Kết thúc',
                        value: _formatHistoryDate(v['completedAt']),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Nút Xem tiến độ & bản đồ
              OutlinedButton.icon(
                onPressed: () => openPage(
                  context,
                  VisitProgressScreen(visitId: int.parse(widget.visit.id)),
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text(
                  'Xem tiến độ & dẫn đường bảo tàng',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deepBurgundy,
                  side: const BorderSide(color: AppColors.deepBurgundy),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (v['status'] == 'InProgress') ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: _busy ? 'Đang gửi…' : 'Kết thúc lượt tham quan',
                  onPressed: _busy ? null : _complete,
                ),
              ],
              if (v['status'] == 'Completed') ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: v['hasFeedback'] == true
                      ? 'Xem / chỉnh sửa đánh giá'
                      : 'Đánh giá lượt tham quan',
                  onPressed: () async {
                    await openVisitFeedback(context, v);
                    if (mounted) {
                      setState(
                        () => _data = BackendApi.request(
                          'visits/${widget.visit.id}',
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    ],
  );

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedGold),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: AppTextStyles.sansFamily,
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AppTextStyles.sansFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
        ),
      ],
    );
  }
}
