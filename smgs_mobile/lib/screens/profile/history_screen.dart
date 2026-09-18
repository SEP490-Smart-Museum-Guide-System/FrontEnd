import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../data/visit_store.dart';
import '../../models/experience.dart';
import '../../services/app_services.dart';
import '../explore/explore_screen.dart';
import 'profile_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: VisitStore.instance,
    builder: (context, _) {
      final visits = [...VisitStore.instance.history]
        ..sort((a, b) => b.date.compareTo(a.date));
      final dates = visits.map((v) => vietnameseDate(v.date)).toSet();
      return MuseumPage(
        back: true,
        title: 'Lịch sử khám phá',
        eyebrow: 'Những ngày cùng di sản',
        children: [
          if (visits.isEmpty) ...[
            const EmptyState(
              title: 'Chuyến đi đầu tiên đang chờ',
              message: 'Khám phá một hiện vật để bắt đầu ghi lại hành trình của bạn.',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Khám phá bảo tàng',
              icon: Icons.explore_outlined,
              onPressed: () =>
                  openPage(context, const ExploreScreen(standalone: true)),
            ),
          ],
          for (final day in dates) ...[
            SectionHeading(day),
            for (final visit in visits.where(
              (v) => vietnameseDate(v.date) == day,
            ))
              ActionTile(
                title: AppServices.catalog.museums
                    .firstWhere((m) => m.id == visit.museumId)
                    .name,
                subtitle:
                    '${visit.artifactIds.length} hiện vật · ${visit.tours.where((t) => t.completed).length} hành trình hoàn thành · ${visit.quizzes.length} lượt thử tài',
                icon: Icons.auto_stories_outlined,
                onTap: () => openPage(context, VisitDetailScreen(visit: visit)),
              ),
          ],
        ],
      );
    },
  );
}

class VisitDetailScreen extends StatelessWidget {
  const VisitDetailScreen({super.key, required this.visit});
  final VisitRecord visit;
  @override
  Widget build(BuildContext context) {
    final museum = AppServices.catalog.museums.firstWhere(
      (m) => m.id == visit.museumId,
    );
    return MuseumPage(
      back: true,
      title: 'Một ngày ở bảo tàng',
      eyebrow: vietnameseDate(visit.date),
      subtitle: museum.name,
      children: [
        MuseumPhoto(museumId: museum.id, height: 185),
        const SectionHeading('Hiện vật đã xem'),
        if (visit.artifactIds.isEmpty)
          const Text(
            'Bạn chưa mở chi tiết hiện vật trong ngày này.',
            style: AppTextStyles.bodyMedium,
          ),
        ...AppServices.catalog.artifacts
            .where((a) => visit.artifactIds.contains(a.id))
            .map((a) => ArtifactCard(artifact: a)),
        const SectionHeading('Hành trình'),
        if (visit.tours.isEmpty)
          const Text(
            'Chưa có hành trình trong ngày này.',
            style: AppTextStyles.bodyMedium,
          ),
        for (final tour in visit.tours)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Text(
                '${tour.completed ? 'Đã hoàn thành' : 'Kết thúc sớm'}\nĐã ghé ${tour.visitedIds.length} điểm · Bỏ qua ${tour.skippedIds.length} điểm',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        const SectionHeading('Kết quả thử tài'),
        if (visit.quizzes.isEmpty)
          const Text(
            'Chưa có lượt thử tài trong ngày này.',
            style: AppTextStyles.bodyMedium,
          ),
        for (final quiz in visit.quizzes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Text(
                '${AppServices.catalog.artifacts.firstWhere((a) => a.id == quiz.artifactId).name}\n${quiz.correct}/${quiz.total} câu đúng · ${quiz.points} điểm',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Góp ý chuyến tham quan',
          icon: Icons.rate_review_outlined,
          onPressed: () => openPage(
            context,
            FeedbackScreen(
              targetType: 'visit',
              targetId: visit.id,
              targetName: '${museum.name} · ${vietnameseDate(visit.date)}',
            ),
          ),
        ),
      ],
    );
  }
}
