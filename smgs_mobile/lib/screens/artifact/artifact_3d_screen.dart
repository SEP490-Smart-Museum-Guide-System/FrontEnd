import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/artifact.dart';
import '../../widgets/museum_ui.dart';

class Artifact3DScreen extends StatefulWidget {
  const Artifact3DScreen({super.key, required this.artifact});

  final Artifact artifact;

  @override
  State<Artifact3DScreen> createState() => _Artifact3DScreenState();
}

class _Artifact3DScreenState extends State<Artifact3DScreen> {
  double _angle = -0.18;
  double _zoom = 1;

  void _reset() => setState(() {
    _angle = -0.18;
    _zoom = 1;
  });

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Quan sát từng\nđường nét.',
    eyebrow: 'Mô hình hiện vật 3D',
    subtitle: widget.artifact.name,
    children: [
      Container(
        height: 390,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.darkBrown,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mutedGold),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -60,
              top: -54,
              child: Opacity(
                opacity: 0.12,
                child: HeritageSeal(size: 230, light: true),
              ),
            ),
            Center(
              child: GestureDetector(
                onHorizontalDragUpdate: (details) => setState(
                  () => _angle =
                      (_angle + details.delta.dx / 180) % (math.pi * 2),
                ),
                child: Transform.scale(
                  scale: _zoom,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(_angle),
                    child: Container(
                      width: 235,
                      height: 255,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueIvory,
                        borderRadius: BorderRadius.circular(120),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 28,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ngoc-lu-web.jpg',
                          fit: BoxFit.cover,
                          semanticLabel:
                              'Mô phỏng mô hình ba chiều ${widget.artifact.name}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kéo ngang để xoay',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.antiqueIvory,
                      ),
                    ),
                  ),
                  Text(
                    '${(_zoom * 100).round()}%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Thu nhỏ',
            onPressed: _zoom <= 0.8 ? null : () => setState(() => _zoom -= 0.1),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Slider(
              value: _zoom,
              min: 0.8,
              max: 1.35,
              divisions: 11,
              label: '${(_zoom * 100).round()}%',
              onChanged: (value) => setState(() => _zoom = value),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Phóng to',
            onPressed: _zoom >= 1.35
                ? null
                : () => setState(() => _zoom += 0.1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Đặt lại góc nhìn',
        icon: Icons.refresh,
        onPressed: _reset,
      ),
      const SizedBox(height: 18),
      const Notice(
        'Đây là bản mô phỏng giao diện xem 3D. Mô hình 3D thật sẽ được tải từ dữ liệu hiện vật đã xuất bản.',
        icon: Icons.view_in_ar_outlined,
      ),
    ],
  );
}
