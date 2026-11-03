import 'package:flutter/material.dart';

import '../../data/mock/mock_artifacts.dart';
import '../../services/app_services.dart';
import '../../widgets/collection_cards.dart';
import '../../widgets/museum_ui.dart';
import '../artifact/quiz_screen.dart';
import '../explore/explore_screen.dart';
import '../tours/tours_screen.dart';

class HomeThemes extends StatelessWidget {
  const HomeThemes({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final theme in [
        (
          number: 'I',
          title: 'Dấu tích ngàn năm',
          caption: 'Khảo cổ · Từ những vòng hoa văn',
          category: 'Khảo cổ',
          icon: Icons.blur_circular,
        ),
        (
          number: 'II',
          title: 'Chuyện chốn cung đình',
          caption: 'Cung đình · Dấu ấn một triều đại',
          category: 'Cung đình',
          icon: Icons.workspace_premium_outlined,
        ),
        (
          number: 'III',
          title: 'Ký ức trên trang giấy',
          caption: 'Tư liệu · Lịch sử qua từng con chữ',
          category: 'Tư liệu',
          icon: Icons.auto_stories_outlined,
        ),
      ])
        ScrollReveal(
          child: HoverLift(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => openPage(
                    context,
                    ExploreScreen(
                      standalone: true,
                      artifactCategory: theme.category,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              Icon(
                                theme.icon,
                                color: AppColors.deepBurgundy,
                                size: 30,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                theme.number,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.mutedGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theme.title,
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(theme.caption, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.north_east,
                          size: 20,
                          color: AppColors.deepBurgundy,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class HomeRouteCard extends StatelessWidget {
  const HomeRouteCard({super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hành trình từ bảo tàng', style: AppTextStyles.cardTitle),
        const SizedBox(height: 12),
        const Text(
          'Chọn bảo tàng và thời gian để tìm các hành trình đã xuất bản.',
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Tìm hành trình',
          onPressed: () =>
              openPage(context, const ToursScreen(standalone: true)),
        ),
      ],
    ),
  );
}

class HomeMuseumStory extends StatelessWidget {
  const HomeMuseumStory({super.key});
  @override
  Widget build(BuildContext context) {
    final museums = AppServices.catalog.museums;
    if (museums.length < 2)
      return const Notice(
        'Các bảo tàng khác sẽ xuất hiện khi được công khai trên hệ thống.',
      );
    return MuseumCard(museum: museums[1]);
  }
}

class HomeQuizCard extends StatelessWidget {
  const HomeQuizCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFECE0C9),
      border: Border.all(color: AppColors.mutedGold),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: Eyebrow('Một chút thử tài')),
            SizedBox(width: 12),
            HeritageSeal(size: 52),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Nhìn một hiện vật.\nNhớ một câu chuyện.',
          style: AppTextStyles.cardTitle.copyWith(
            color: AppColors.deepBurgundy,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Hai câu hỏi nhỏ về trống đồng và ý nghĩa của di sản. Bạn đã sẵn sàng?',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Thử tài cùng trống đồng',
          icon: Icons.auto_awesome_outlined,
          onPressed: () =>
              openPage(context, QuizScreen(artifact: mockArtifacts.first)),
        ),
      ],
    ),
  );
}

class HomeVisitGuide extends StatelessWidget {
  const HomeVisitGuide({super.key});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final tip in [
          (
            title: 'Chuẩn bị một chuyến đi',
            icon: Icons.event_note_outlined,
            text:
                'Chọn bảo tàng, dành một khoảng thời gian thong thả và xem trước những hiện vật bạn quan tâm. Kiểm tra giờ mở cửa, giá vé và quy định mới nhất với bảo tàng trước khi đến.',
          ),
          (
            title: 'Tham quan theo cách của bạn',
            icon: Icons.headphones_outlined,
            text:
                'Bạn có thể đọc câu chuyện của từng hiện vật, lưu lại điều mình yêu thích hoặc chọn một hành trình có sẵn. Dừng lâu hơn ở nơi khiến bạn tò mò, không cần đi vội.',
          ),
          (
            title: 'Để di sản còn mãi',
            icon: Icons.volunteer_activism_outlined,
            text:
                'Giữ khoảng cách với hiện vật, trò chuyện vừa đủ nghe và làm theo hướng dẫn tại phòng trưng bày. Chỉ chụp ảnh ở khu vực được cho phép.',
          ),
        ])
          ExpansionTile(
            key: PageStorageKey(tip.title),
            leading: Icon(tip.icon, color: AppColors.deepBurgundy, size: 23),
            title: Text(
              tip.title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            iconColor: AppColors.deepBurgundy,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            children: [Text(tip.text, style: AppTextStyles.bodyMedium)],
          ),
      ],
    ),
  );
}
