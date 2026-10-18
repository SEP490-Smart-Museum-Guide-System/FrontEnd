import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../artifact/artifact_detail_screen.dart';
import '../artifact/qr_scan_screen.dart';

class IndoorGuidanceScreen extends StatelessWidget {
  const IndoorGuidanceScreen({
    super.key,
    required this.currentArtifact,
    required this.nextArtifact,
  });

  final Artifact currentArtifact;
  final Artifact nextArtifact;

  @override
  Widget build(BuildContext context) {
    return MuseumPage(
      back: true,
      title: 'Chỉ đường trong bảo tàng',
      eyebrow: 'Hành trình di chuyển',
      subtitle: 'Từ điểm gần nhất tới hiện vật kế tiếp',
      children: [
        // Panel thông tin lộ trình xuất phát và đích đến
        Panel(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.deepBurgundy,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.antiqueIvory,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐIỂM XÁC ĐỊNH GẦN NHẤT (VỊ TRÍ CỦA BẠN)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepBurgundy,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentArtifact.name,
                          style: AppTextStyles.cardTitle,
                        ),
                        Text(
                          currentArtifact.location,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
                child: Container(
                  width: 2,
                  height: 28,
                  color: AppColors.mutedGold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mutedGold,
                      border: Border.all(color: AppColors.deepBurgundy, width: 2),
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: AppColors.deepBurgundy,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐIỂM ĐẾN TIẾP THEO',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepBurgundy,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextArtifact.name,
                          style: AppTextStyles.cardTitle,
                        ),
                        Text(
                          nextArtifact.location,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sơ đồ mô phỏng lối đi giữa 2 hiện vật
        const SectionHeading('Sơ đồ định vị tĩnh'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(
                  painter: _IndoorPathPainter(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 20,
                        top: 45,
                        child: _MapNode(label: 'Điểm 1\n(Hiện tại)', isCurrent: true),
                      ),
                      Positioned(
                        right: 20,
                        top: 45,
                        child: _MapNode(label: 'Điểm 2\n(Kế tiếp)', isCurrent: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.deepBurgundy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hệ thống không theo dõi vị trí liên tục. Vị trí sẽ được cập nhật lại khi bạn quét QR hoặc nhận diện ảnh tại điểm đến tiếp theo.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Hướng dẫn từng bước
        const SectionHeading('Chỉ dẫn từng bước di chuyển'),
        _StepItem(
          stepNumber: 1,
          title: 'Xuất phát từ ${currentArtifact.name}',
          description: 'Từ tủ kính trưng bày hiện tại, quay về hướng sảnh chính hành lang.',
          icon: Icons.straight_outlined,
        ),
        _StepItem(
          stepNumber: 2,
          title: 'Di chuyển qua cửa vòm nối',
          description: 'Đi dọc hành lang khoảng 15-20 mét hướng về khu trưng bày ${nextArtifact.category}.',
          icon: Icons.turn_right_outlined,
        ),
        _StepItem(
          stepNumber: 3,
          title: 'Điểm đến: ${nextArtifact.name}',
          description: 'Hiện vật nằm ở vị trí bục trưng bày tại ${nextArtifact.location}. Quét tem mã QR gắn trên tủ kính để mở thuyết minh.',
          icon: Icons.pin_drop_outlined,
          isLast: true,
        ),
        const SizedBox(height: 24),

        // Các nút hành động chính
        PrimaryButton(
          label: 'Đã tới nơi · Quét mã QR hiện vật này',
          icon: Icons.qr_code_scanner,
          onPressed: () => openPage(
            context,
            const QRScanScreen(),
          ),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Xem trước thông tin hiện vật kế tiếp',
          icon: Icons.visibility_outlined,
          onPressed: () => openPage(
            context,
            ArtifactDetailScreen(
              artifact: nextArtifact,
              museumName: 'Bảo tàng Lịch sử Quốc gia',
            ),
          ),
        ),
      ],
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({required this.label, required this.isCurrent});
  final String label;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.deepBurgundy : AppColors.card,
        border: Border.all(color: isCurrent ? AppColors.mutedGold : AppColors.deepBurgundy, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          color: isCurrent ? AppColors.antiqueIvory : AppColors.darkBrown,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    this.isLast = false,
  });

  final int stepNumber;
  final String title, description;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLast ? AppColors.deepBurgundy : AppColors.card,
                border: Border.all(color: AppColors.deepBurgundy),
              ),
              child: Text(
                '$stepNumber',
                style: AppTextStyles.caption.copyWith(
                  color: isLast ? AppColors.antiqueIvory : AppColors.deepBurgundy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.deepBurgundy),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IndoorPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final room1 = Rect.fromLTWH(10, 15, size.width * 0.4, size.height - 30);
    final room2 = Rect.fromLTWH(size.width * 0.55, 15, size.width * 0.4, size.height - 30);

    canvas.drawRRect(RRect.fromRectAndRadius(room1, const Radius.circular(8)), Paint()..color = AppColors.antiqueIvory);
    canvas.drawRRect(RRect.fromRectAndRadius(room1, const Radius.circular(8)), borderPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(room2, const Radius.circular(8)), Paint()..color = AppColors.antiqueIvory);
    canvas.drawRRect(RRect.fromRectAndRadius(room2, const Radius.circular(8)), borderPaint);

    // Đường đi dải chấm nét đứt
    final pathPaint = Paint()
      ..color = AppColors.deepBurgundy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(room1.centerRight.dx - 10, room1.centerRight.dy)
      ..lineTo(room2.centerLeft.dx + 10, room2.centerLeft.dy);

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
