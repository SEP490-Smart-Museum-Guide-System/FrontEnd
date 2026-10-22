import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/museum.dart';
import '../models/outdoor_route.dart';
import '../services/discovery_api_service.dart';
import '../services/location_service.dart';
import 'interactive_heritage_map.dart';

class RoutePreviewSheet extends StatefulWidget {
  const RoutePreviewSheet({
    super.key,
    required this.museum,
    this.onRouteLoaded,
  });
  final Museum museum;
  final ValueChanged<OutdoorRoutePreview>? onRouteLoaded;

  static Future<void> show(
    BuildContext context, {
    required Museum museum,
    ValueChanged<OutdoorRoutePreview>? onRouteLoaded,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        RoutePreviewSheet(museum: museum, onRouteLoaded: onRouteLoaded),
  );

  @override
  State<RoutePreviewSheet> createState() => _RoutePreviewSheetState();
}

class _RoutePreviewSheetState extends State<RoutePreviewSheet> {
  bool _loading = true, _opening = false;
  String? _error;
  OutdoorRoutePreview? _route;
  UserLocationResult? _origin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _route = null;
      _origin = null;
    });
    try {
      if (!widget.museum.hasCoordinates) {
        throw Exception('Bảo tàng chưa có tọa độ hợp lệ.');
      }
      final origin = await LocationService.getCurrentUserLocation();
      if (!mounted) return;
      setState(() => _origin = origin);
      final route = await DiscoveryApiService.fetchOutdoorRoute(
        museumId: widget.museum.id,
        originLat: origin.latitude,
        originLng: origin.longitude,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _loading = false;
      });
      widget.onRouteLoaded?.call(route);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e'.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    setState(() => _opening = true);
    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${widget.museum.latitude},${widget.museum.longitude}',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
    try {
      var opened = false;
      try {
        opened = await launchUrl(
          url,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (_) {
        /* Fall back to the system browser. */
      }
      if (!opened) {
        opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      if (!opened) throw Exception('Không thể mở Google Maps trên thiết bị.');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể mở Google Maps. Vui lòng kiểm tra trình duyệt.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.86,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(widget.museum.name),
          subtitle: Text(widget.museum.location),
          trailing: IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(
          child: InteractiveHeritageMap(
            museums: [widget.museum],
            selectedMuseumId: widget.museum.id,
            onMuseumSelected: (_) {},
            userLocation: _origin == null
                ? null
                : LatLng(_origin!.latitude, _origin!.longitude),
            polylinePoints: _route?.routePoints ?? const [],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_loading)
          Text(
            _origin == null ? 'Đang lấy vị trí GPS…' : 'Đang tính tuyến đường…',
          ),
        if (_origin?.isLastKnown == true)
          const Text('Dùng vị trí gần nhất trong 2 phút, sai số tối đa 100 m.'),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ô tô · Xem trước tuyến đường trên OpenStreetMap'),
                if (_route != null) ...[
                  Text(
                    '${_route!.distanceKmString} · ${_route!.durationMinutesString}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.deepBurgundy,
                    ),
                  ),
                  const Text(
                    'Ước tính từ OSRM tại thời điểm yêu cầu, không theo dõi vị trí liên tục.',
                  ),
                ],
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.deepBurgundy),
                  ),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Thử lại xem đường đi'),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: !widget.museum.hasCoordinates || _opening
                      ? null
                      : _openGoogleMaps,
                  icon: const Icon(Icons.near_me),
                  label: const Text('Chỉ đường bằng Google Maps'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
