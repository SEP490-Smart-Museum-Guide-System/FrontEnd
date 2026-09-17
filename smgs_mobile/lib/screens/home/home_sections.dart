import 'package:flutter/material.dart';

import '../../data/mock/mock_artifacts.dart';
import '../../data/mock/mock_museums.dart';
import '../../widgets/museum_ui.dart';
import '../artifact/quiz_screen.dart';
import '../explore/explore_screen.dart';
import '../museum/museum_detail_screen.dart';
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
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppColors.card,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.border),
              ),
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
    ],
  );
}

class HomeRouteCard extends StatelessWidget {
  const HomeRouteCard({super.key});
  @override
  Widget build(BuildContext context) {
    final stops = mockArtifacts
        .where((a) => a.museumId == mockMuseums.first.id)
        .toList();
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.deepBurgundy,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -64,
            top: -56,
            child: Opacity(
              opacity: 0.12,
              child: HeritageSeal(size: 245, light: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Hành trình tuyển chọn', light: true),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      '60',
                      style: AppTextStyles.display.copyWith(
                        fontSize: 84,
                        height: 1.05,
                        color: AppColors.lightText,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Text(
                        'phút\nchạm vào lịch sử',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.antiqueIvory,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Từ tiếng trống Đông Sơn\nđến dấu triện hoàng cung.',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.lightText,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  mockMuseums.first.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.antiqueIvory,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: AppColors.mutedGold, height: 1),
                ),
                for (final stop in stops.asMap().entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.mutedGold),
                          ),
                          child: Text(
                            '${stop.key + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            stop.value.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.antiqueIvory,
                      foregroundColor: AppColors.deepBurgundy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      textStyle: AppTextStyles.buttonText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => openPage(
                      context,
                      TourRouteScreen(
                        stops: stops,
                        duration: 60,
                        interest: 'Lịch sử',
                      ),
                    ),
                    child: const Text(
                      'Xem hành trình 60 phút',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.antiqueIvory,
                    ),
                    onPressed: () =>
                        openPage(context, const ToursScreen(standalone: true)),
                    child: const Text('Tự chọn hành trình'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeMuseumStory extends StatelessWidget {
  const HomeMuseumStory({super.key});
  @override
  Widget build(BuildContext context) {
    final museum = mockMuseums[1];
    return Material(
      color: AppColors.darkBrown,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPage(context, MuseumDetailScreen(museum: museum)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ParallaxPhoto(
                  height: 260,
                  child: MuseumPhoto(museumId: museum.id),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    color: AppColors.antiqueIvory,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: const Eyebrow('Ba Đình · Hà Nội'),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lắng nghe\nmột thời lịch sử.',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.antiqueIvory,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    museum.name,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.antiqueIvory,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Từ không gian kiến trúc đến những trang tư liệu, mỗi điểm dừng mở thêm một góc nhìn.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.antiqueIvory,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ghé Bảo tàng Hồ Chí Minh',
                          style: AppTextStyles.buttonText.copyWith(
                            color: AppColors.antiqueIvory,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.antiqueIvory,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(6),
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
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final tip in [
          (
            title: 'Chuẩn bị một chuyến đi',
            icon: Icons.event_note_outlined,
            text: 'Chọn bảo tàng, dành một khoảng thời gian thong thả và xem trước những hiện vật bạn quan tâm. Kiểm tra giờ mở cửa, giá vé và quy định mới nhất với bảo tàng trước khi đến.',
          ),
          (
            title: 'Tham quan theo cách của bạn',
            icon: Icons.headphones_outlined,
            text: 'Bạn có thể đọc câu chuyện của từng hiện vật, lưu lại điều mình yêu thích hoặc chọn một hành trình có sẵn. Dừng lâu hơn ở nơi khiến bạn tò mò, không cần đi vội.',
          ),
          (
            title: 'Để di sản còn mãi',
            icon: Icons.volunteer_activism_outlined,
            text: 'Giữ khoảng cách với hiện vật, trò chuyện vừa đủ nghe và làm theo hướng dẫn tại phòng trưng bày. Chỉ chụp ảnh ở khu vực được cho phép.',
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
