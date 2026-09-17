import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../data/mock/mock_artifacts.dart';
import '../../data/mock/mock_museums.dart';
import '../explore/explore_screen.dart';
import 'artifact_detail_screen.dart';

class QRScanScreen extends StatelessWidget {
  const QRScanScreen({
    super.key,
    this.recognition = false,
    this.museumId = 'museum_national',
  });
  final bool recognition;
  final String museumId;
  @override
  Widget build(BuildContext context) {
    final artifact = mockArtifacts.firstWhere((a) => a.museumId == museumId);
    return MuseumPage(
      back: true,
      title: recognition ? 'Nhận diện hiện vật' : 'Quét mã hiện vật',
      eyebrow: 'Khám phá tại bảo tàng',
      subtitle: recognition
          ? 'Đặt hiện vật ở giữa khung hình.'
          : 'Hướng máy ảnh vào mã đặt cạnh hiện vật.',
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.darkBrown,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.mutedGold, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    recognition
                        ? Icons.camera_alt_outlined
                        : Icons.qr_code_scanner,
                    size: 64,
                    color: AppColors.antiqueIvory,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Khung xem trước',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.antiqueIvory,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Notice(
          'Máy ảnh chưa được kết nối trong bản trải nghiệm này. Bạn có thể xem hiện vật mẫu hoặc tra cứu danh sách.',
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Xem hiện vật mẫu',
          icon: Icons.arrow_forward,
          onPressed: () => openPage(
            context,
            ArtifactDetailScreen(
              artifact: artifact,
              museumName: mockMuseums.firstWhere((m) => m.id == museumId).name,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Tra cứu danh sách',
          icon: Icons.search_outlined,
          onPressed: () => openPage(
            context,
            ExploreScreen(standalone: true, museumId: museumId),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
      ],
    );
  }
}
