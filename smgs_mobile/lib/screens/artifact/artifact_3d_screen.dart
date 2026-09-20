import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/artifact.dart';
import '../../widgets/museum_ui.dart';

class Artifact3DScreen extends StatefulWidget {
  const Artifact3DScreen({super.key, required this.artifact});

  final Artifact artifact;

  @override
  State<Artifact3DScreen> createState() => _Artifact3DScreenState();
}

class _Artifact3DScreenState extends State<Artifact3DScreen> {
  int _resetKey = 0;
  bool _autoRotate = true;

  bool get _isTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  void _reset() => setState(() {
    _resetKey++;
    _autoRotate = true;
  });

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Quan sát từng\nđường nét.',
    eyebrow: 'Mô hình hiện vật 3D',
    subtitle: widget.artifact.name,
    children: [
      Container(
        height: 420,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.darkBrown,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mutedGold.withOpacity(0.5)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
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
              child: SizedBox(
                height: 380,
                width: double.infinity,
                child: _isTest
                    ? Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Mô hình 3D ${widget.artifact.name}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.antiqueIvory,
                          ),
                        ),
                      )
                    : ModelViewer(
                        key: ValueKey('model_viewer_$_resetKey'),
                        src: 'assets/models/trong_dong_dong_son.glb',
                        alt: 'Mô hình 3D ${widget.artifact.name}',
                        ar: true,
                        autoRotate: _autoRotate,
                        autoRotateDelay: 1000,
                        rotationPerSecond: '25deg',
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                        shadowIntensity: 1.0,
                        shadowSoftness: 0.8,
                        exposure: 1.05,
                      ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: AppColors.mutedGold,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kéo ngang để xoay',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.antiqueIvory,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _autoRotate = !_autoRotate),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _autoRotate
                            ? AppColors.mutedGold.withOpacity(0.2)
                            : Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _autoRotate
                              ? AppColors.mutedGold
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _autoRotate ? Icons.play_arrow : Icons.pause,
                            size: 14,
                            color: AppColors.mutedGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _autoRotate ? 'Tự xoay' : 'Tạm dừng',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Đặt lại góc nhìn',
              icon: Icons.refresh,
              onPressed: _reset,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Notice(
        'Mô hình 3D thực của ${widget.artifact.name}. Bạn có thể kéo thả để xoay 360°, cuộn để phóng to chi tiết hoa văn.',
        icon: Icons.view_in_ar_outlined,
      ),
    ],
  );
}
