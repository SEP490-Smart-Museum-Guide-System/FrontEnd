import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../data/mock/mock_artifacts.dart';
import '../../models/museum.dart';
import '../artifact/artifact_discovery_screen.dart';
import '../explore/explore_screen.dart';
import '../tours/tours_screen.dart';
import '../profile/services_screen.dart';

class MuseumDetailScreen extends StatelessWidget {
  const MuseumDetailScreen({super.key, required this.museum, this.heroTag});
  final Museum museum;
  final Object? heroTag;
  @override
  Widget build(BuildContext context) {
    final artifacts = mockArtifacts
        .where((a) => a.museumId == museum.id)
        .toList();
    return StoryScaffold(
      title: museum.name,
      heroTag: heroTag,
      photo: MuseumPhoto(museumId: museum.id, height: 300),
      children: [
        Text(
          museum.id == 'museum_national'
              ? 'Ảnh: Alistair Morrenger · Wikimedia Commons'
              : 'Ảnh: Ecow · Wikimedia Commons',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 22),
        Eyebrow(museum.category),
        const SizedBox(height: 10),
        Text(
          museum.name,
          style: AppTextStyles.display.copyWith(color: AppColors.deepBurgundy),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(museum.location, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
        const Divider(),
        Text(museum.shortIntro, style: AppTextStyles.bodyLarge),
        const SizedBox(height: 18),
        Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: AppColors.deepBurgundy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giờ tham quan tham khảo',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      museum.openingHours,
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vui lòng xác nhận lịch mở cửa với bảo tàng trước chuyến đi.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Khám phá hiện vật',
          icon: Icons.explore_outlined,
          onPressed: () => openPage(
            context,
            ArtifactDiscoveryScreen(museum: museum, artifact: artifacts.first),
          ),
        ),
        const SectionHeading('Câu chuyện bảo tàng'),
        ScrollReveal(
          child: Text(museum.description, style: AppTextStyles.bodyLarge),
        ),
        SectionHeading(
          'Hiện vật tiêu biểu',
          action: 'Xem tất cả',
          onTap: () => openPage(
            context,
            ExploreScreen(standalone: true, museumId: museum.id),
          ),
        ),
        ...artifacts.map((a) => ScrollReveal(child: ArtifactCard(artifact: a))),
        const SectionHeading('Chuẩn bị chuyến tham quan'),
        ActionTile(
          title: 'Hành trình dành cho bạn',
          subtitle: 'Chọn thời gian và sở thích để bắt đầu.',
          icon: Icons.route_outlined,
          onTap: () => openPage(
            context,
            ToursScreen(standalone: true, museumId: museum.id),
          ),
        ),
        ActionTile(
          title: 'Dịch vụ số',
          subtitle: 'Tìm hiểu các tiện ích đồng hành.',
          icon: Icons.headphones_outlined,
          onTap: () =>
              openPage(context, ServicesScreen(museumName: museum.name)),
        ),
      ],
    );
  }
}
