import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class HeritagePaper extends StatelessWidget {
  const HeritagePaper({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PaperPainter(), child: child);
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.antiqueIvory,
    );
    final ink = Paint()
      ..color = AppColors.mutedGold.withAlpha(14)
      ..strokeWidth = 0.5;
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ink);
    }
    final grain = Paint()..color = AppColors.darkBrown.withAlpha(9);
    final random = math.Random(17);
    for (var i = 0; i < size.width * size.height / 90; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.45,
        grain,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 4),
      Paint()..color = AppColors.deepBurgundy,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeritageSeal extends StatelessWidget {
  const HeritageSeal({super.key, this.size = 76, this.light = false});
  final double size;
  final bool light;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SealPainter(light)),
    ),
  );
}

class _SealPainter extends CustomPainter {
  _SealPainter(this.light);
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final color = light ? AppColors.antiqueIvory : AppColors.deepBurgundy;
    final ink = Paint()
      ..color = color
      ..strokeWidth = 0.85
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, r, ink);
    canvas.drawCircle(Offset.zero, r - 4, ink);
    canvas.drawCircle(Offset.zero, r * 0.66, ink);
    for (var i = 0; i < 36; i++) {
      final angle = i * math.pi * 2 / 36;
      canvas.drawCircle(
        Offset(math.cos(angle) * (r - 8), math.sin(angle) * (r - 8)),
        0.75,
        Paint()..color = color,
      );
    }
    final star = Path();
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final radius = i.isEven ? r * 0.52 : r * 0.24;
      if (i == 0) {
        star.moveTo(math.cos(angle) * radius, math.sin(angle) * radius);
      } else {
        star.lineTo(math.cos(angle) * radius, math.sin(angle) * radius);
      }
    }
    canvas.drawPath(star..close(), Paint()..color = color.withAlpha(190));
    canvas.drawCircle(
      Offset.zero,
      r * 0.14,
      Paint()..color = AppColors.mutedGold,
    );
  }

  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) =>
      light != oldDelegate.light;
}

class ChapterHeading extends StatelessWidget {
  const ChapterHeading({
    super.key,
    required this.number,
    required this.title,
    this.action,
    this.onTap,
  });
  final String number, title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 16),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              number,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.deepBurgundy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.deepBurgundy,
                ),
              ),
            ),
            if (action != null)
              TextButton(
                onPressed: onTap,
                child: Text(
                  action!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.deepBurgundy,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(width: 36, height: 2, color: AppColors.deepBurgundy),
            const Expanded(child: Divider(height: 1, thickness: 1)),
          ],
        ),
      ],
    ),
  );
}

class MuseumPhoto extends StatelessWidget {
  const MuseumPhoto({super.key, required this.museumId, this.height = 220});
  final String museumId;
  final double height;
  @override
  Widget build(BuildContext context) => Image.asset(
    museumId == 'museum_national'
        ? 'assets/images/national-museum-web.jpg'
        : 'assets/images/ho-chi-minh-museum-web.jpg',
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    alignment: const Alignment(0, 0.35),
    semanticLabel: museumId == 'museum_national'
        ? 'Kiến trúc Bảo tàng Lịch sử Quốc gia tại Hà Nội'
        : 'Bảo tàng Hồ Chí Minh tại Hà Nội',
    errorBuilder: (context, error, stack) => Container(
      height: height,
      color: AppColors.border,
      alignment: Alignment.center,
      child: const Icon(
        Icons.account_balance_outlined,
        size: 48,
        color: AppColors.deepBurgundy,
      ),
    ),
  );
}
