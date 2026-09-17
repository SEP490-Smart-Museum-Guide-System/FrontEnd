import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../artifact/qr_scan_screen.dart';
import '../explore/explore_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});
  @override
  Widget build(BuildContext context) => MuseumPage(
    title: 'Mở câu chuyện\ntrước mắt bạn.',
    eyebrow: 'Nhận diện hiện vật',
    subtitle: 'Chọn cách bạn muốn khám phá.',
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: const HeritageArt(kind: 'artifact_1', height: 215),
      ),
      const SizedBox(height: 24),
      ActionTile(
        title: 'Quét mã hiện vật',
        subtitle: 'Dùng mã đặt cạnh hiện vật trưng bày.',
        icon: Icons.qr_code_scanner,
        onTap: () => openPage(context, const QRScanScreen()),
      ),
      ActionTile(
        title: 'Nhận diện qua hình ảnh',
        subtitle: 'Tìm hiểu hiện vật qua góc nhìn của bạn.',
        icon: Icons.camera_alt_outlined,
        onTap: () => openPage(context, const QRScanScreen(recognition: true)),
      ),
      ActionTile(
        title: 'Tra cứu bộ sưu tập',
        subtitle: 'Tìm hiện vật theo tên và chủ đề.',
        icon: Icons.view_list_outlined,
        onTap: () => openPage(
          context,
          const ExploreScreen(standalone: true, museumId: 'museum_national'),
        ),
      ),
      const SizedBox(height: 10),
      const Notice(
        'Bạn có thể tra cứu bộ sưu tập mà không cần cấp quyền máy ảnh.',
      ),
    ],
  );
}
