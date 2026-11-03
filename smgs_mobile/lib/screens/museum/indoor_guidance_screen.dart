import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../services/app_services.dart';
import '../artifact/artifact_detail_screen.dart';
import '../artifact/qr_scan_screen.dart';

class IndoorGuidanceScreen extends StatelessWidget {
  const IndoorGuidanceScreen({
    super.key,
    required this.currentArtifact,
    required this.nextArtifact,
  });
  final Artifact currentArtifact, nextArtifact;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Hiện vật kế tiếp',
    children: [
      Text('Đang xem: ${currentArtifact.name}', style: AppTextStyles.bodyLarge),
      const SizedBox(height: 16),
      Text(nextArtifact.name, style: AppTextStyles.cardTitle),
      Text(nextArtifact.location),
      const SizedBox(height: 16),
      const Notice(
        'Chưa có sơ đồ đường đi được liên kết với hành trình này. Hãy xem biển chỉ dẫn hoặc hỏi nhân viên bảo tàng.',
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Quét mã QR hiện vật',
        icon: Icons.qr_code_scanner,
        onPressed: () => openPage(context, const QRScanScreen()),
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Xem thông tin hiện vật',
        onPressed: () => openPage(
          context,
          ArtifactDetailScreen(
            artifact: nextArtifact,
            museumName: AppServices.catalog.museumName(nextArtifact.museumId),
          ),
        ),
      ),
    ],
  );
}
