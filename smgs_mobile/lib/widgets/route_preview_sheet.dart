import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/museum.dart';
import '../models/map_place.dart';
import '../models/outdoor_route.dart';
import '../services/discovery_api_service.dart';
import '../services/location_service.dart';
import '../services/automatic_location_service.dart';
import 'interactive_heritage_map.dart';
import 'museum_arrival_panel.dart';

class RoutePreviewSheet extends StatefulWidget {
  const RoutePreviewSheet({
    super.key,
    this.museum,
    this.place,
    this.onRouteLoaded,
  });
  final Museum? museum;
  final MapPlace? place;
  final ValueChanged<OutdoorRoutePreview>? onRouteLoaded;

  static Future<void> show(
    BuildContext context, {
    Museum? museum,
    MapPlace? place,
    ValueChanged<OutdoorRoutePreview>? onRouteLoaded,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RoutePreviewSheet(
      museum: museum,
      place: place,
      onRouteLoaded: onRouteLoaded,
    ),
  );

  @override
  State<RoutePreviewSheet> createState() => _RoutePreviewSheetState();
}

class _RoutePreviewSheetState extends State<RoutePreviewSheet> {
  final _location = AutomaticLocationService.instance;
  bool _loading = true, _opening = false;
  String? _error;
  OutdoorRoutePreview? _route;
  UserLocationResult? _origin;

  @override
  void initState() {
    super.initState();
    _location.addListener(_locationChanged);
    _load();
  }

  void _locationChanged() {
    if (mounted) {
      setState(
        () => _origin = _location.hasFreshLocation ? _location.latest : null,
      );
    }
  }

  @override
  void dispose() {
    _location.removeListener(_locationChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _route = null;
      _origin = null;
    });
    try {
      if ((widget.place == null && widget.museum?.hasCoordinates != true)) {
        throw Exception('Bảo tàng chưa có tọa độ hợp lệ.');
      }
      final origin = _location.hasFreshLocation
          ? _location.latest!
          : await LocationService.getCurrentUserLocation();
      if (!mounted) return;
      setState(() => _origin = origin);
      final route = await DiscoveryApiService.fetchOutdoorRoute(
        museumId: widget.museum?.id,
        destination: widget.place == null
            ? null
            : {
                'latitude': widget.place!.latitude,
                'longitude': widget.place!.longitude,
              },
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
      'destination':
          '${widget.place?.latitude ?? widget.museum?.latitude},${widget.place?.longitude ?? widget.museum?.longitude}',
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
          title: Text(widget.place?.name ?? widget.museum!.name),
          subtitle: Text(widget.place?.address ?? widget.museum!.location),
          trailing: IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(
          child: InteractiveHeritageMap(
            museums: [if (widget.museum != null) widget.museum!],
            placeLocation: widget.place == null
                ? null
                : LatLng(widget.place!.latitude, widget.place!.longitude),
            placeName: widget.place?.name,
            selectedMuseumId: widget.museum?.id,
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
                    'Tuyến OSRM được tính khi mở. Vị trí của bạn tự cập nhật khi đang dùng app.',
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
                if (int.tryParse(widget.museum?.id ?? '')
                    case final int museumId)
                  MuseumArrivalPanel(
                    museumId: museumId,
                    museumName: widget.museum!.name,
                  ),
                FilledButton.icon(
                  onPressed:
                      (widget.place == null &&
                              widget.museum?.hasCoordinates != true) ||
                          _opening
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
