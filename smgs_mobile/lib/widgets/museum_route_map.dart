import 'package:flutter/material.dart';

import '../models/artifact.dart';
import 'museum_ui.dart';

class MuseumRouteMap extends StatelessWidget {
  const MuseumRouteMap({
    super.key,
    required this.stops,
    required this.current,
    this.visited = const [],
    this.skipped = const [],
  });
  final List<Artifact> stops;
  final int current;
  final List<String> visited, skipped;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Sơ đồ hành trình mẫu'),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _FloorPlan(stops.length, current),
            child: Row(
              children: [
                for (var i = 0; i < stops.length; i++)
                  Expanded(
                    child: Center(
                      child: Semantics(
                        label:
                            'Điểm ${i + 1}: ${stops[i].name}${i == current ? ', hiện tại' : ''}',
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == current
                                ? AppColors.deepBurgundy
                                : AppColors.antiqueIvory,
                            border: Border.all(color: AppColors.deepBurgundy),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.buttonText.copyWith(
                              color: i == current
                                  ? AppColors.antiqueIvory
                                  : AppColors.deepBurgundy,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < stops.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${i + 1}. ${stops[i].location}${visited.contains(stops[i].id)
                  ? ' · Đã ghé'
                  : skipped.contains(stops[i].id)
                  ? ' · Đã bỏ qua'
                  : i == current
                  ? ' · Điểm hiện tại'
                  : ''}',
              style: AppTextStyles.bodyMedium,
            ),
          ),
      ],
    ),
  );
}

class _FloorPlan extends CustomPainter {
  _FloorPlan(this.count, this.current);
  final int count, current;
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < count; i++) {
      final width = size.width / count;
      final room = Rect.fromLTWH(
        i * width + 6,
        12,
        width - 12,
        size.height - 24,
      );
      canvas.drawRect(room, Paint()..color = AppColors.antiqueIvory);
      canvas.drawRect(room, border);
      canvas.drawRect(
        Rect.fromLTWH(room.left + 10, room.top + 10, room.width - 20, 15),
        Paint()..color = AppColors.border,
      );
    }
    if (count > 1) {
      canvas.drawLine(
        Offset(size.width / count / 2, size.height / 2),
        Offset(size.width - size.width / count / 2, size.height / 2),
        Paint()
          ..color = AppColors.mutedGold
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloorPlan old) =>
      old.count != count || old.current != current;
}
