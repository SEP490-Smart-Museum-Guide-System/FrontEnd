import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme/app_colors.dart';
import '../models/museum.dart';

class InteractiveHeritageMap extends StatelessWidget {
  final List<Museum> museums;
  final String? selectedMuseumId;
  final ValueChanged<Museum> onMuseumSelected;
  final LatLng? userLocation;
  final List<LatLng> polylinePoints;

  const InteractiveHeritageMap({
    super.key,
    required this.museums,
    required this.selectedMuseumId,
    required this.onMuseumSelected,
    this.userLocation,
    this.polylinePoints = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (museums.isEmpty) {
      return Container(
        color: AppColors.antiqueIvory,
        alignment: Alignment.center,
        child: const Text('Chưa có dữ liệu bảo tàng hiển thị trên bản đồ.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Calculate bounding box
        double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
        final allPoints = <LatLng>[];
        for (final m in museums) {
          if (m.latitude != 0.0 && m.longitude != 0.0) {
            allPoints.add(LatLng(m.latitude, m.longitude));
          }
        }
        if (userLocation != null) allPoints.add(userLocation!);
        allPoints.addAll(polylinePoints);

        if (allPoints.isEmpty) {
          allPoints.add(const LatLng(10.7769, 106.7009));
        }

        for (final p in allPoints) {
          minLat = math.min(minLat, p.latitude);
          maxLat = math.max(maxLat, p.latitude);
          minLng = math.min(minLng, p.longitude);
          maxLng = math.max(maxLng, p.longitude);
        }

        // Add padding & calculate usable viewport area between top search bar and bottom carousel
        final latSpan = math.max(0.04, (maxLat - minLat) * 1.3);
        final lngSpan = math.max(0.04, (maxLng - minLng) * 1.3);
        final centerLat = (minLat + maxLat) / 2;
        final centerLng = (minLng + maxLng) / 2;

        const topPadding = 130.0;
        const bottomPadding = 240.0;
        final usableHeight = math.max(120.0, size.height - topPadding - bottomPadding);
        const horizontalPadding = 40.0;
        final usableWidth = math.max(120.0, size.width - horizontalPadding * 2);

        Offset toOffset(LatLng latLng) {
          final x = horizontalPadding +
              (((latLng.longitude - (centerLng - lngSpan / 2)) / lngSpan) * usableWidth);
          // Invert Y for screen coordinates (north is up)
          final y = topPadding +
              (usableHeight - (((latLng.latitude - (centerLat - latSpan / 2)) / latSpan) * usableHeight));
          return Offset(x, y);
        }

        return Container(
          color: AppColors.antiqueIvory,
          child: Stack(
            children: [
              // Heritage Canvas Background
              CustomPaint(
                size: size,
                painter: _HeritageCanvasPainter(
                  polylinePoints: polylinePoints.map(toOffset).toList(),
                ),
              ),

              // User Location Marker
              if (userLocation != null) ...[
                Positioned(
                  left: toOffset(userLocation!).dx - 14,
                  top: toOffset(userLocation!).dy - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Museum Markers
              for (final museum in museums) ...[
                if (museum.latitude != 0.0 && museum.longitude != 0.0) ...[
                  Builder(
                    builder: (context) {
                      final pos = toOffset(LatLng(museum.latitude, museum.longitude));
                      final isSelected = museum.id == selectedMuseumId;
                      return Positioned(
                        left: pos.dx - 20,
                        top: pos.dy - 38,
                        child: GestureDetector(
                          onTap: () => onMuseumSelected(museum),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.all(isSelected ? 8 : 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.imperialGold : AppColors.deepBurgundy,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected ? AppColors.imperialGold : AppColors.deepBurgundy)
                                          .withOpacity(0.4),
                                      blurRadius: isSelected ? 10 : 4,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.account_balance,
                                  color: isSelected ? AppColors.charcoalBrown : Colors.white,
                                  size: isSelected ? 20 : 15,
                                ),
                              ),
                              // Marker pointer triangle
                              CustomPaint(
                                size: const Size(8, 6),
                                painter: _TrianglePainter(
                                  color: isSelected ? AppColors.imperialGold : AppColors.deepBurgundy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],

              // Map status badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.antiqueIvory.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.parchmentBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.imperialGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Heritage Map Mode',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoalBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeritageCanvasPainter extends CustomPainter {
  final List<Offset> polylinePoints;

  _HeritageCanvasPainter({required this.polylinePoints});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.parchmentBorder.withOpacity(0.4)
      ..strokeWidth = 1.0;

    // Draw grid
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Polyline if available
    if (polylinePoints.length > 1) {
      final polylineShadow = Paint()
        ..color = AppColors.deepBurgundy.withOpacity(0.2)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final polylinePaint = Paint()
        ..color = AppColors.deepBurgundy
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(polylinePoints.first.dx, polylinePoints.first.dy);
      for (int i = 1; i < polylinePoints.length; i++) {
        path.lineTo(polylinePoints[i].dx, polylinePoints[i].dy);
      }

      canvas.drawPath(path, polylineShadow);
      canvas.drawPath(path, polylinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeritageCanvasPainter oldDelegate) => true;
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => false;
}
