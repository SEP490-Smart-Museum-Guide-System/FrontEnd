import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../models/museum.dart';
import '../explore/explore_screen.dart';
import 'qr_scan_screen.dart';

class ArtifactDiscoveryScreen extends StatelessWidget {
  const ArtifactDiscoveryScreen({
    super.key,
    required this.museum,
    required this.artifact,
  });
  final Museum museum;
  final Artifact artifact;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Bắt đầu khám phá',
    eyebrow: 'Câu chuyện hiện vật',
    subtitle: museum.name,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HeritageArt(kind: artifact.id, height: 215),
      ),
      const SizedBox(height: 24),
      ActionTile(
        title: 'Quét mã hiện vật',
        subtitle: 'Mở thông tin từ mã bên cạnh hiện vật.',
        icon: Icons.qr_code_scanner,
        onTap: () => openPage(context, QRScanScreen(museumId: museum.id)),
      ),
      ActionTile(
        title: 'Nhận diện qua hình ảnh',
        subtitle: 'Khám phá bằng máy ảnh của bạn.',
        icon: Icons.camera_alt_outlined,
        onTap: () => openPage(
          context,
          QRScanScreen(recognition: true, museumId: museum.id),
        ),
      ),
      ActionTile(
        title: 'Xem danh sách hiện vật',
        subtitle: 'Duyệt bộ sưu tập của bảo tàng.',
        icon: Icons.view_list_outlined,
        onTap: () => openPage(
          context,
          ExploreScreen(standalone: true, museumId: museum.id),
        ),
      ),
    ],
  );
}
