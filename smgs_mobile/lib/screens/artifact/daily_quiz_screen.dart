import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../data/visit_store.dart';
import '../../data/mock/mock_artifacts.dart';
import '../../models/artifact.dart';
import 'quiz_screen.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  String _filter = 'all'; // 'all', 'pending', 'completed'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VisitStore.instance,
      builder: (context, _) {
        final store = VisitStore.instance;
        final scannedIds = store.todayScannedArtifactIds;
        final allArtifacts = scannedIds
            .map((id) => mockArtifacts.firstWhere((a) => a.id == id, orElse: () => mockArtifacts.first))
            .toSet()
            .toList();

        final pendingArtifacts = allArtifacts.where((a) => !store.quizScores.containsKey(a.id)).toList();
        final completedArtifacts = allArtifacts.where((a) => store.quizScores.containsKey(a.id)).toList();

        final displayedArtifacts = switch (_filter) {
          'pending' => pendingArtifacts,
          'completed' => completedArtifacts,
          _ => allArtifacts,
        };

        final now = DateTime.now();
        final dateStr = 'Hôm nay, ngày ${now.day} tháng ${now.month}';

        return MuseumPage(
          back: true,
          title: 'Quiz tích lũy trong ngày',
          eyebrow: 'Di sản & Thử thách trí tuệ',
          subtitle: dateStr,
          children: [
            // Thẻ tóm tắt tiến độ với phong cách Hoàng gia
            Panel(
              gold: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HeritageSeal(size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SỔ TÍCH LŨY CÂU HỎI TRONG NGÀY',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepBurgundy,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Các hiện vật bạn đã quét QR hoặc nhận diện AI thành công trong ngày sẽ tự động được lưu câu đố tại đây. Bạn có thể thong thả làm bài vào cuối ngày để tích điểm đổi huy hiệu.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueIvory,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBadge(
                          value: '${allArtifacts.length}',
                          label: 'Hiện vật mở quiz',
                          color: AppColors.deepBurgundy,
                        ),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _StatBadge(
                          value: '${pendingArtifacts.length}',
                          label: 'Chưa hoàn thành',
                          color: AppColors.mutedGold,
                        ),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _StatBadge(
                          value: '${completedArtifacts.length}',
                          label: 'Đã hoàn thành',
                          color: const Color(0xFF2E6B3E),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bộ lọc trạng thái
            Row(
              children: [
                _FilterChip(
                  label: 'Tất cả (${allArtifacts.length})',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Chưa làm (${pendingArtifacts.length})',
                  selected: _filter == 'pending',
                  onTap: () => setState(() => _filter = 'pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Đã xong (${completedArtifacts.length})',
                  selected: _filter == 'completed',
                  onTap: () => setState(() => _filter = 'completed'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Danh sách các hiện vật
            if (displayedArtifacts.isEmpty)
              Panel(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.hourglass_empty_outlined,
                        size: 48,
                        color: AppColors.mutedGold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filter == 'completed'
                            ? 'Bạn chưa hoàn thành câu đố nào hôm nay.'
                            : _filter == 'pending'
                            ? 'Tuyệt vời! Bạn đã hoàn thành tất cả các quiz tích lũy.'
                            : 'Chưa có hiện vật nào được quét trong ngày.',
                        style: AppTextStyles.cardTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hãy quét mã QR hoặc chụp ảnh hiện vật tại các phòng trưng bày để mở khóa câu đố mới.',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final artifact in displayedArtifacts)
                _DailyQuizCard(
                  artifact: artifact,
                  isCompleted: store.quizScores.containsKey(artifact.id),
                  score: store.quizScores[artifact.id],
                  onStartQuiz: () => openPage(
                    context,
                    QuizScreen(artifact: artifact),
                  ),
                ),

            const SizedBox(height: 24),
            const Notice(
              'Gợi ý: Trả lời đúng mỗi câu hỏi giúp bạn tích lũy +10 điểm kinh nghiệm để vinh danh trên bảng xếp hạng di sản.',
              icon: Icons.lightbulb_outline,
            ),
          ],
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.display.copyWith(
            fontSize: 22,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.deepBurgundy : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.deepBurgundy : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? AppColors.antiqueIvory : AppColors.darkBrown,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyQuizCard extends StatelessWidget {
  const _DailyQuizCard({
    required this.artifact,
    required this.isCompleted,
    this.score,
    required this.onStartQuiz,
  });

  final Artifact artifact;
  final bool isCompleted;
  final int? score;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCompleted ? const Color(0xFF2E6B3E).withValues(alpha: 0.4) : AppColors.border,
            width: isCompleted ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: artifact.id == 'artifact_1'
                          ? Image.asset(
                              'assets/images/ngoc-lu-web.jpg',
                              fit: BoxFit.cover,
                            )
                          : HeritageArt(kind: artifact.id, height: 72),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFFEAF5ED)
                                    : AppColors.mutedGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCompleted ? 'ĐÃ LÀM' : 'ĐANG CHỜ BẠN',
                                style: AppTextStyles.caption.copyWith(
                                  color: isCompleted
                                      ? const Color(0xFF2E6B3E)
                                      : AppColors.deepBurgundy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isCompleted ? 'Đạt ${score ?? 0}/2 câu' : '+20 điểm',
                              style: AppTextStyles.caption.copyWith(
                                color: isCompleted
                                    ? const Color(0xFF2E6B3E)
                                    : AppColors.deepBurgundy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          artifact.name,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.deepBurgundy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${artifact.period} · ${artifact.location}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2 câu hỏi trắc nghiệm',
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                  ),
                  if (isCompleted)
                    TextButton.icon(
                      onPressed: onStartQuiz,
                      icon: const Icon(Icons.refresh, size: 16, color: AppColors.deepBurgundy),
                      label: Text(
                        'Làm lại câu khác',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.deepBurgundy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: onStartQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBurgundy,
                        foregroundColor: AppColors.antiqueIvory,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text(
                        'Làm bài ngay',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
