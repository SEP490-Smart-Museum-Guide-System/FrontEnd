import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';
import '../artifact/daily_quiz_screen.dart';
import '../artifact/artifact_detail_screen.dart';
import '../../models/artifact.dart';

String _formatExpDate(dynamic raw) {
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

class ExperienceHistoryScreen extends StatelessWidget {
  const ExperienceHistoryScreen({super.key, required this.kind});
  final String kind;
  String get path => kind == 'quiz'
      ? 'quiz-attempts/me'
      : kind == 'points'
      ? 'gamification/me/transactions'
      : 'recognitions/me';

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: kind == 'quiz'
        ? 'Lịch sử thử tài'
        : kind == 'points'
        ? 'Sổ điểm của bạn'
        : 'Lịch sử quét hiện vật',
    eyebrow: kind == 'quiz'
        ? 'Thử thách kiến thức'
        : kind == 'points'
        ? 'Điểm thưởng di sản'
        : 'Khảo cứu di sản',
    subtitle: kind == 'quiz'
        ? 'Xem lại kết quả các bộ câu hỏi và độ chính xác của bạn.'
        : kind == 'points'
        ? 'Biến động điểm tích lũy từ các hoạt động tham quan và thử thách.'
        : 'Danh mục các hiện vật bạn đã quét mã QR và tìm hiểu.',
    children: [
      BackendPanel(
        resourceKey: path,
        load: () => BackendApi.list(path),
        builder: (data, reload) {
          final rows = (data as List).cast<Map<String, dynamic>>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    kind == 'points'
                        ? 'LỊCH SỬ BIẾN ĐỘNG'
                        : kind == 'quiz'
                            ? 'LƯỢT LÀM BÀI'
                            : 'HIỆN VẬT ĐÃ MỞ',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Tải lại', style: TextStyle(fontSize: 12.5)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.deepBurgundy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (rows.isEmpty)
                EmptyState(
                  title: kind == 'points'
                      ? 'Chưa có biến động điểm'
                      : kind == 'quiz'
                          ? 'Chưa tham gia thử tài'
                          : 'Chưa quét hiện vật nào',
                  message: kind == 'points'
                      ? 'Hoàn thành các hoạt động tại bảo tàng để nhận điểm thưởng.'
                      : kind == 'quiz'
                          ? 'Hãy tham gia Quiz trong ngày để kiểm tra kiến thức và nhận quà.'
                          : 'Quét mã QR tại các tủ trưng bày để mở câu chuyện hiện vật.',
                  icon: kind == 'points'
                      ? Icons.toll_outlined
                      : kind == 'quiz'
                          ? Icons.quiz_outlined
                          : Icons.qr_code_scanner_rounded,
                ),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: kind == 'points'
                      ? _buildPointsCard(row)
                      : _buildInteractiveCard(context, row, reload),
                ),
            ],
          );
        },
      ),
    ],
  );

  Widget _buildPointsCard(Map<String, dynamic> row) {
    final points = (row['points'] as num?) ?? 0;
    final isPositive = points >= 0;

    return Container(
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPositive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isPositive ? Icons.add_rounded : Icons.remove_rounded,
                  color: isPositive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['reason']?.toString() ?? 'Tích lũy điểm',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatExpDate(row['createdAt']),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}$points điểm',
              style: TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? const Color(0xFF2E7D32)
                    : AppColors.deepBurgundy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCard(
    BuildContext context,
    Map<String, dynamic> row,
    VoidCallback reload,
  ) {
    final isQuiz = kind == 'quiz';
    final title = isQuiz
        ? 'Bộ câu hỏi #${row['quizId']}'
        : AppServices.catalog.artifacts
              .where((a) => a.id == row['artifactId'].toString())
              .firstOrNull
              ?.name ??
          'Hiện vật #${row['artifactId']}';

    final subtitle = isQuiz
        ? '${row['correctCount']}/${row['totalQuestions']} câu đúng · ${backendStatus(row['status'])}'
        : _formatExpDate(row['recognizedAt']);

    return Container(
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
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
          borderRadius: BorderRadius.circular(VisitorRadius.xl),
          onTap: () async {
            try {
              if (isQuiz) {
                final result = Map<String, dynamic>.from(
                  await BackendApi.request('quiz-attempts/${row['id']}'),
                );
                if (context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BackendQuizAttemptScreen(attempt: result),
                    ),
                  );
                }
              } else {
                final result = Map<String, dynamic>.from(
                  await BackendApi.request('artifacts/${row['artifactId']}'),
                );
                if (context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ArtifactDetailScreen(
                        artifact: Artifact.fromBackendJson(result),
                        museumName: AppServices.catalog.museumName(
                          result['museumId'].toString(),
                        ),
                      ),
                    ),
                  );
                }
              }
              reload();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.antiqueIvory,
                    borderRadius: BorderRadius.circular(VisitorRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Icon(
                      isQuiz ? Icons.quiz_outlined : Icons.qr_code_scanner_rounded,
                      color: AppColors.deepBurgundy,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isQuiz) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueIvory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${row['score']}/100 đ',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
