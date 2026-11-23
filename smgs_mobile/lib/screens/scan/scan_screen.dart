import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../widgets/museum_ui.dart';
import '../artifact/artifact_qr_scanner.dart';
import '../artifact/qr_scan_screen.dart';
import '../explore/explore_screen.dart';
import '../../widgets/game_tutorial_overlay.dart';
import '../../services/app_services.dart';
import '../../models/experience.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.standalone = false});
  final bool standalone;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTour());
  }

  Future<void> _checkTour() async {
    final user = AppServices.auth.user;
    if (user != null && user.role == UserRole.visitor) {
      final shouldShow = await GameTutorialOverlay.shouldShow(
        user.email,
        'scan',
      );
      if (shouldShow && mounted) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          ScanScreenTour.start(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop =
        widget.standalone || (ModalRoute.of(context)?.canPop ?? false);
    return MuseumPage(
      back: canPop,
      title: l10n.isEn ? 'Uncover stories\nbefore your eyes.' : 'Mở câu chuyện\ntrước mắt bạn.',
      eyebrow: l10n.isEn ? 'Artifact Recognition' : 'Nhận diện hiện vật',
      subtitle: l10n.isEn ? 'Choose how you want to explore.' : 'Chọn cách bạn muốn khám phá.',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const HeritageArt(kind: 'artifact_1', height: 215),
        ),
        const SizedBox(height: 24),
        Container(
          key: ScanScreenTour.qrTileKey,
          child: ActionTile(
            title: l10n.isEn ? 'Scan Artifact QR Code' : 'Quét mã hiện vật',
            subtitle: l10n.isEn ? 'Use the code placed beside museum exhibits.' : 'Dùng mã đặt cạnh hiện vật trưng bày.',
            icon: Icons.qr_code_scanner,
            onTap: () =>
                openPage(context, const ArtifactQrScanner(direct: true)),
          ),
        ),
        Container(
          key: ScanScreenTour.aiVisionTileKey,
          child: ActionTile(
            title: l10n.isEn ? 'AI Visual Recognition' : 'Nhận diện qua hình ảnh',
            subtitle: l10n.isEn ? 'Identify artifacts through your camera angle.' : 'Tìm hiểu hiện vật qua góc nhìn của bạn.',
            icon: Icons.camera_alt_outlined,
            onTap: () =>
                openPage(context, const QRScanScreen(recognition: true)),
          ),
        ),
        Container(
          key: ScanScreenTour.collectionTileKey,
          child: ActionTile(
            title: l10n.isEn ? 'Browse Collection' : 'Tra cứu bộ sưu tập',
            subtitle: l10n.isEn ? 'Search artifacts by name and category.' : 'Tìm hiện vật theo tên và chủ đề.',
            icon: Icons.view_list_outlined,
            onTap: () =>
                openPage(context, const ExploreScreen(standalone: true)),
          ),
        ),
        const SizedBox(height: 10),
        Notice(
          l10n.isEn
              ? 'You can browse the collection without camera permissions.'
              : 'Bạn có thể tra cứu bộ sưu tập mà không cần cấp quyền máy ảnh.',
        ),
      ],
    );
  }
}
