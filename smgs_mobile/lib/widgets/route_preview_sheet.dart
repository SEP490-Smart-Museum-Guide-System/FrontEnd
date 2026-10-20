import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/museum.dart';
import '../models/outdoor_route.dart';
import '../services/discovery_api_service.dart';

class RoutePreviewSheet extends StatefulWidget {
  final Museum museum;
  final double userLat;
  final double userLng;
  final ValueChanged<OutdoorRoutePreview>? onRouteLoaded;

  const RoutePreviewSheet({
    super.key,
    required this.museum,
    required this.userLat,
    required this.userLng,
    this.onRouteLoaded,
  });

  static Future<void> show(
    BuildContext context, {
    required Museum museum,
    required double userLat,
    required double userLng,
    ValueChanged<OutdoorRoutePreview>? onRouteLoaded,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RoutePreviewSheet(
        museum: museum,
        userLat: userLat,
        userLng: userLng,
        onRouteLoaded: onRouteLoaded,
      ),
    );
  }

  @override
  State<RoutePreviewSheet> createState() => _RoutePreviewSheetState();
}

class _RoutePreviewSheetState extends State<RoutePreviewSheet> {
  String _travelMode = 'TWO_WHEELER'; // DRIVE, TWO_WHEELER, WALK
  bool _isLoading = true;
  OutdoorRoutePreview? _routeData;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() => _isLoading = true);
    final route = await DiscoveryApiService.fetchOutdoorRoute(
      museumId: widget.museum.id,
      originLat: widget.userLat,
      originLng: widget.userLng,
      destinationLat: widget.museum.latitude,
      destinationLng: widget.museum.longitude,
      travelMode: _travelMode,
    );

    if (mounted) {
      setState(() {
        _routeData = route;
        _isLoading = false;
      });
      widget.onRouteLoaded?.call(route);
    }
  }

  Future<void> _openExternalGoogleMaps() async {
    final destination = '${widget.museum.latitude},${widget.museum.longitude}';
    final googleTravelMode = _travelMode == 'WALK'
        ? 'walking'
        : (_travelMode == 'TWO_WHEELER' ? 'two-wheeler' : 'driving');

    // Deep link Google Maps URL
    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': '${widget.userLat},${widget.userLng}',
      'destination': destination,
      'travelmode': googleTravelMode,
      'dir_action': 'navigate',
    });

    try {
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể kích hoạt ứng dụng Google Maps.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở ứng dụng: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.antiqueIvory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.charcoalBrown.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Destination header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.deepBurgundy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.museum_outlined, color: AppColors.deepBurgundy, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.museum.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.deepBurgundy,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.museum.location,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoalBrown),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Travel mode selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.softSand,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.parchmentBorder),
            ),
            child: Row(
              children: [
                _buildModeTab('TWO_WHEELER', 'Xe máy', Icons.two_wheeler),
                _buildModeTab('DRIVE', 'Ô tô', Icons.directions_car),
                _buildModeTab('WALK', 'Đi bộ', Icons.directions_walk),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Route info card
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.deepBurgundy),
              ),
            )
          else if (_routeData != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.parchmentBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    Icons.straighten,
                    _routeData!.distanceKmString,
                    'Quãng đường dự kiến',
                  ),
                  Container(width: 1, height: 36, color: AppColors.parchmentBorder),
                  _buildMetric(
                    Icons.access_time,
                    _routeData!.durationMinutesString,
                    'Thời gian di chuyển',
                  ),
                ],
              ),
            ),

            if (_routeData!.warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD166)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFB7791F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _routeData!.warning!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF744210)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.charcoalBrown),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Xem bản đồ', style: TextStyle(color: AppColors.charcoalBrown)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBurgundy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.near_me, size: 20),
                  label: const Text(
                    'Chỉ đường Google Maps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _openExternalGoogleMaps,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, IconData icon) {
    final isSelected = _travelMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_travelMode != mode) {
            setState(() => _travelMode = mode);
            _loadRoute();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.deepBurgundy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.charcoalBrown,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.charcoalBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.imperialGold),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepBurgundy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.charcoalBrown.withOpacity(0.7)),
        ),
      ],
    );
  }
}
