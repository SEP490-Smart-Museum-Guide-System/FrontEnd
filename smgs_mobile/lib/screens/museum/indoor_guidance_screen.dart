import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../services/app_services.dart';
import '../artifact/artifact_detail_screen.dart';
import '../artifact/qr_scan_screen.dart';
import 'visitor_directory_screen.dart';

class IndoorGuidanceScreen extends StatelessWidget {
  const IndoorGuidanceScreen({
    super.key,
    required this.currentArtifact,
    required this.nextArtifact,
  });

  final Artifact currentArtifact, nextArtifact;

  @override
  Widget build(BuildContext context) {
    final museumName = AppServices.catalog.museumName(nextArtifact.museumId);
    final hasValidMuseumId = int.tryParse(nextArtifact.museumId) != null;

    return MuseumPage(
      back: true,
      title: 'Chỉ đường nội khu',
      children: [
        const Eyebrow('LỘ TRÌNH THAM QUAN BẢO TÀNG'),
        const SizedBox(height: 8),
        Text('Điểm dừng tiếp theo', style: AppTextStyles.pageTitle),
        const SizedBox(height: 6),
        Text(
          'Hướng dẫn di chuyển từ vị trí hiện tại đến hiện vật kế tiếp trong tuyến hành trình của bạn.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkBrown.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 20),

        // Waypoint Transition Journey Card
        Container(
          decoration: BoxDecoration(
            color: VisitorColors.surface1,
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
          ),
          child: Column(
            children: [
              // Current Station (Start)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VisitorColors.surfaceGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VỊ TRÍ HIỆN TẠI',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBrown.withOpacity(0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentArtifact.name,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          if (currentArtifact.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.room_outlined,
                                  size: 14,
                                  color: AppColors.darkBrown.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    currentArtifact.location,
                                    style: AppTextStyles.caption.copyWith(
                                      color:
                                          AppColors.darkBrown.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Transit connector track
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      height: 36,
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.mutedGold.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: VisitorColors.surface2,
                        borderRadius: BorderRadius.circular(VisitorRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk_rounded,
                            size: 14,
                            color: AppColors.deepBurgundy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Di chuyển sang chặng tiếp theo',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepBurgundy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Next Station (Destination)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.deepBurgundy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        size: 20,
                        color: Colors.white,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: VisitorColors.surfaceBrand,
                                  borderRadius: BorderRadius.circular(VisitorRadius.xs),
                                ),
                                child: Text(
                                  'ĐÍCH ĐẾN KẾ TIẾP',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepBurgundy,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextArtifact.name,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: VisitorColors.surface2,
                              borderRadius: BorderRadius.circular(VisitorRadius.xs),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.meeting_room_outlined,
                                  size: 14,
                                  color: AppColors.deepBurgundy,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    nextArtifact.location.isNotEmpty
                                        ? nextArtifact.location
                                        : 'Vị trí trưng bày chính',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkBrown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (nextArtifact.imageUrl.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(VisitorRadius.md),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: VisitorColors.surface2,
                          child: Image.network(
                            nextArtifact.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.museum_outlined,
                              size: 28,
                              color: AppColors.deepBurgundy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action navigation & scanning buttons
        if (hasValidMuseumId)
          PrimaryButton(
            label: 'Xem phòng & chỉ đường trên sơ đồ',
            icon: Icons.map_outlined,
            onPressed: () => openPage(
              context,
              VisitorDirectoryScreen(
                museumId: int.parse(nextArtifact.museumId),
                initialArtifactId: int.tryParse(nextArtifact.id),
                museumName: museumName,
              ),
            ),
          )
        else
          const Notice('Hiện vật mẫu chưa có vị trí trong bảo tàng thực tế.'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Quét mã QR',
                icon: Icons.qr_code_scanner,
                onPressed: () => openPage(context, const QRScanScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryButton(
                label: 'Xem chi tiết',
                icon: Icons.info_outline_rounded,
                onPressed: () => openPage(
                  context,
                  ArtifactDetailScreen(
                    artifact: nextArtifact,
                    museumName: museumName,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
