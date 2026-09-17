import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Original vector illustrations, deliberately distinct from collection photos.
class HeritageArt extends StatelessWidget {
  const HeritageArt({super.key, this.kind = 'museum', this.height = 200});
  final String kind;
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
    label: kind == 'museum'
        ? 'Minh họa kiến trúc bảo tàng'
        : 'Minh họa hiện vật',
    image: true,
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _HeritagePainter(kind)),
    ),
  );
}

class _HeritagePainter extends CustomPainter {
  _HeritagePainter(this.kind);
  final String kind;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 440, size.height / 240);
    final bg = Paint()..color = const Color(0xFFE6D8C1);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 440, 240), bg);
    final line = Paint()
      ..color = AppColors.mutedGold.withAlpha(95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var y = 8.0; y < 240; y += 9) {
      canvas.drawLine(
        Offset(0, y),
        Offset(440, y),
        line..color = AppColors.mutedGold.withAlpha(12),
      );
    }
    final ink = Paint()..color = AppColors.darkBrown;
    final gold = Paint()..color = AppColors.mutedGold;
    final paper = Paint()..color = AppColors.antiqueIvory;
    if (kind == 'museum') {
      canvas.drawCircle(
        const Offset(332, 68),
        37,
        gold..color = AppColors.mutedGold.withAlpha(55),
      );
      line.color = AppColors.darkBrown.withAlpha(38);
      for (var x = 26.0; x < 430; x += 40) {
        canvas.drawLine(Offset(x, 213), Offset(x, 228), line);
      }
      // Stepped roof and central pavilion inspired by Vietnamese museum architecture.
      canvas.drawRect(const Rect.fromLTWH(55, 126, 330, 77), paper);
      canvas.drawRect(const Rect.fromLTWH(159, 93, 122, 110), paper);
      for (var i = 0; i < 3; i++) {
        final top = 63.0 + i * 14;
        final half = 46.0 + i * 18;
        final path = Path()
          ..moveTo(220 - half - 14, top + 15)
          ..quadraticBezierTo(220 - half, top + 14, 220 - half + 10, top)
          ..lineTo(220 + half - 10, top)
          ..quadraticBezierTo(220 + half, top + 14, 220 + half + 14, top + 15)
          ..close();
        canvas.drawPath(path, ink..color = AppColors.deepBurgundy);
        canvas.drawLine(
          Offset(220 - half, top + 18),
          Offset(220 + half, top + 18),
          line..color = AppColors.mutedGold,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(40, 130)
          ..lineTo(70, 106)
          ..lineTo(158, 106)
          ..lineTo(158, 130)
          ..close(),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(282, 130)
          ..lineTo(282, 106)
          ..lineTo(370, 106)
          ..lineTo(400, 130)
          ..close(),
        ink,
      );
      for (var x = 69.0; x < 382; x += 27) {
        if (x > 155 && x < 280) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(x, 145, 14, 34),
          ink..color = AppColors.darkBrown.withAlpha(170),
        );
        canvas.drawLine(
          Offset(x + 7, 145),
          Offset(x + 7, 179),
          line..color = AppColors.mutedGold,
        );
        canvas.drawRect(
          Rect.fromLTWH(x - 4, 136, 3, 64),
          gold..color = AppColors.mutedGold.withAlpha(120),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(176, 115, 88, 15),
        ink..color = AppColors.deepBurgundy,
      );
      for (var x = 181.0; x < 260; x += 23) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, 145, 18, 58),
            topLeft: const Radius.circular(9),
            topRight: const Radius.circular(9),
          ),
          ink..color = AppColors.darkBrown,
        );
      }
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(
          Rect.fromLTWH(147 - i * 10.0, 203 + i * 5.0, 146 + i * 20.0, 3),
          gold..color = AppColors.mutedGold.withAlpha(180),
        );
      }
      canvas.drawLine(
        const Offset(22, 222),
        const Offset(418, 222),
        line..color = AppColors.darkBrown.withAlpha(100),
      );
      for (final x in [27.0, 413.0]) {
        canvas.drawLine(Offset(x, 215), Offset(x, 130), line..strokeWidth = 2);
        for (var i = 0; i < 5; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x + (i.isEven ? -7 : 7), 144 + i * 12.0),
              width: 24,
              height: 11,
            ),
            gold..color = AppColors.mutedGold.withAlpha(100),
          );
        }
      }
    } else if (kind == 'artifact_2') {
      canvas.drawOval(
        const Rect.fromLTWH(122, 198, 196, 14),
        gold..color = AppColors.darkBrown.withAlpha(25),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(144, 153, 152, 43),
          const Radius.circular(3),
        ),
        gold..color = AppColors.mutedGold,
      );
      canvas.drawRect(
        const Rect.fromLTWH(157, 143, 126, 14),
        ink..color = AppColors.deepBurgundy,
      );
      final dragon = Path()
        ..moveTo(178, 143)
        ..cubicTo(158, 97, 209, 62, 231, 98)
        ..cubicTo(238, 110, 214, 119, 216, 133)
        ..lineTo(266, 143)
        ..lineTo(260, 125)
        ..cubicTo(282, 93, 264, 58, 244, 49)
        ..lineTo(234, 69)
        ..cubicTo(193, 38, 146, 98, 165, 141)
        ..close();
      canvas.drawPath(dragon, gold);
      canvas.drawPath(
        dragon,
        line
          ..color = AppColors.darkBrown.withAlpha(120)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        const Offset(252, 76),
        3,
        ink..color = AppColors.darkBrown,
      );
      for (var x = 155.0; x < 290; x += 12) {
        canvas.drawLine(
          Offset(x, 165),
          Offset(x, 184),
          line..color = AppColors.darkBrown.withAlpha(70),
        );
      }
    } else if (kind == 'artifact_3') {
      canvas.save();
      canvas.translate(220, 120);
      canvas.rotate(-0.09);
      canvas.drawRect(
        const Rect.fromLTWH(-78, -91, 166, 189),
        gold..color = AppColors.mutedGold.withAlpha(80),
      );
      canvas.drawRect(const Rect.fromLTWH(-86, -98, 166, 189), paper);
      canvas.drawRect(
        const Rect.fromLTWH(-70, -81, 134, 23),
        ink..color = AppColors.deepBurgundy,
      );
      for (var y = -43.0; y < 76; y += 9) {
        for (var x = -70.0; x < 55; x += 48) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + 36, y),
            line
              ..color = AppColors.darkBrown.withAlpha(100)
              ..strokeWidth = 1,
          );
        }
      }
      canvas.restore();
    } else {
      canvas.translate(220, 120);
      canvas.drawCircle(
        Offset.zero,
        103,
        ink..color = AppColors.darkBrown.withAlpha(15),
      );
      canvas.drawCircle(Offset.zero, 97, gold..color = AppColors.mutedGold);
      canvas.drawCircle(Offset.zero, 91, ink..color = AppColors.darkBrown);
      for (final r in [88.0, 83.0, 76.0, 70.0, 53.0, 48.0, 32.0]) {
        canvas.drawCircle(
          Offset.zero,
          r,
          line
            ..color = AppColors.mutedGold
            ..strokeWidth = 1.2,
        );
      }
      for (var i = 0; i < 48; i++) {
        final a = i * math.pi * 2 / 48;
        canvas.drawLine(
          Offset(math.cos(a) * 77, math.sin(a) * 77),
          Offset(math.cos(a) * 82, math.sin(a) * 82),
          line,
        );
        canvas.drawCircle(
          Offset(math.cos(a) * 87, math.sin(a) * 87),
          0.8,
          gold,
        );
      }
      for (var i = 0; i < 12; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 6);
        canvas.drawPath(
          Path()
            ..moveTo(55, -5)
            ..lineTo(67, -10)
            ..lineTo(64, 0)
            ..lineTo(58, 4)
            ..lineTo(64, 9),
          line..strokeWidth = 1.6,
        );
        canvas.restore();
      }
      final star = Path();
      for (var i = 0; i < 28; i++) {
        final a = i * math.pi / 14 - math.pi / 2;
        final r = i.isEven ? 30.0 : 12.0;
        if (i == 0) {
          star.moveTo(math.cos(a) * r, math.sin(a) * r);
        } else {
          star.lineTo(math.cos(a) * r, math.sin(a) * r);
        }
      }
      canvas.drawPath(star..close(), gold);
      for (var i = 0; i < 28; i++) {
        final a = i * math.pi / 14;
        canvas.drawCircle(
          Offset(math.cos(a) * 41, math.sin(a) * 41),
          1.4,
          gold,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeritagePainter oldDelegate) =>
      oldDelegate.kind != kind;
}
