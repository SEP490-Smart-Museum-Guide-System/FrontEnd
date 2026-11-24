import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../models/museum.dart';
import '../models/map_place.dart';
import '../models/outdoor_route.dart';
import '../services/discovery_api_service.dart';
import '../services/location_service.dart';
import '../services/automatic_location_service.dart';
import 'interactive_heritage_map.dart';
import 'museum_arrival_panel.dart';
import 'place_search_field.dart';

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
  bool _loading = true, _navigating = false;
  String? _error, _guidance;
  DateTime? _lastReroute;
  OutdoorRoutePreview? _route;
  UserLocationResult? _origin;
  MapPlace? _from;

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
      _updateGuidance();
    }
  }

  void _updateGuidance() {
    final route = _route, fix = _origin;
    if (!_navigating || route == null || fix == null || _loading) return;
    final position = LatLng(fix.latitude, fix.longitude);
    final match = route.match(position);
    if (const Distance()(position, route.routePoints.last) < 25) {
      setState(() {
        _guidance = 'Bạn đã đến nơi';
        _navigating = false;
      });
    } else if (match.meters > 65) {
      final now = DateTime.now();
      if (_lastReroute == null ||
          now.difference(_lastReroute!).inSeconds >= 15) {
        _lastReroute = now;
        _load();
      }
    } else {
      final next = route.steps
          .where((step) => step.index > match.segment)
          .firstOrNull;
      setState(
        () => _guidance = next?.label ?? 'Tiếp tục theo tuyến trên bản đồ',
      );
    }
  }

  @override
  void dispose() {
    _location.removeListener(_locationChanged);
    super.dispose();
  }

  Future<void> _openDirections() async {
    final route = _route;
    if (route == null) return;
    if (_from != null) {
      final useGps = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Chỉ đường từng bước'),
              subtitle: Text('Từ ${_from!.name}'),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (route.steps.isEmpty)
                    const ListTile(
                      title: Text('Tuyến này chưa có hướng dẫn từng bước.'),
                    ),
                  for (final step in route.steps.asMap().entries)
                    ListTile(
                      leading: Text('${step.key + 1}'),
                      title: Text(step.value.label),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(sheet, true),
                icon: const Icon(Icons.my_location),
                label: const Text('Dẫn đường từ vị trí GPS của tôi'),
              ),
            ),
          ],
        ),
      );
      if (!mounted || useGps != true) return;
      setState(() => _from = null);
      await _load();
      if (!mounted || _route == null) return;
    }
    setState(() {
      _navigating = !_navigating;
      _guidance = _navigating ? 'Đang xác định vị trí…' : null;
    });
    _updateGuidance();
  }

  Future<void> _chooseOrigin() async {
    final selected = await showDialog<MapPlace>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Chọn điểm xuất phát'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: PlaceSearchField(
              onSelected: (place) {
                if (place != null) Navigator.pop(dialog, place);
              },
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _from = selected;
      _guidance = null;
      _navigating = false;
    });
    await _load();
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
      final from = _from;
      final origin = from != null
          ? null
          : _location.hasFreshLocation
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
        originLat: from?.latitude ?? origin!.latitude,
        originLng: from?.longitude ?? origin!.longitude,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _loading = false;
      });
      widget.onRouteLoaded?.call(route);
      _updateGuidance();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e'.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
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
            followUser: _navigating,
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
            _from == null && _origin == null
                ? 'Đang lấy vị trí GPS…'
                : 'Đang tính tuyến đường…',
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
                const Text('Ô tô · Tuyến đường VietMap'),
                if (_from != null) Text('Xuất phát từ ${_from!.name}'),
                if (!_loading && !_navigating)
                  TextButton(
                    onPressed: _chooseOrigin,
                    child: const Text('Chọn điểm xuất phát'),
                  ),
                if (_from != null && !_loading)
                  TextButton(
                    onPressed: () {
                      setState(() => _from = null);
                      _load();
                    },
                    child: const Text('Dùng vị trí GPS của tôi'),
                  ),
                if (_route != null) ...[
                  Text(
                    '${_route!.distanceKmString} · ${_route!.durationMinutesString}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.deepBurgundy,
                    ),
                  ),
                  if (_guidance != null) Text(_guidance!),
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
              ],
            ),
          ),
        ),
        if (_route != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: FilledButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.navigation),
                label: Text(
                  _navigating ? 'Dừng chỉ đường' : 'Bắt đầu chỉ đường',
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
