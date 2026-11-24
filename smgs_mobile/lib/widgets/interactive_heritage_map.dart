import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';
import 'vietmap_surface_native.dart'
    if (dart.library.html) 'vietmap_surface_web.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/visitor_tokens.dart';
import '../core/theme/visitor_colors.dart';
import '../models/museum.dart';

class InteractiveHeritageMap extends StatefulWidget {
  const InteractiveHeritageMap({
    super.key,
    required this.museums,
    required this.selectedMuseumId,
    required this.onMuseumSelected,
    this.userLocation,
    this.followUser = false,
    this.centerOnGps = true,
    this.polylinePoints = const [],
    this.placeLocation,
    this.placeName,
  });
  final List<Museum> museums;
  final String? selectedMuseumId;
  final ValueChanged<Museum> onMuseumSelected;
  final bool followUser;
  final bool centerOnGps;
  final LatLng? userLocation;
  final List<LatLng> polylinePoints;
  final LatLng? placeLocation;
  final String? placeName;

  @override
  State<InteractiveHeritageMap> createState() => _InteractiveHeritageMapState();
}

class _InteractiveHeritageMapState extends State<InteractiveHeritageMap> {
  final _controller = MapController();
  bool _ready = false;
  bool _located = false, _panned = false;
  static final _vietnam = LatLngBounds(
    const LatLng(8.1, 102),
    const LatLng(23.5, 110),
  );
  LatLng? get _initialGps {
    final point = widget.userLocation;
    return widget.centerOnGps && point != null && _vietnam.contains(point)
        ? point
        : null;
  }

  late List<List<Object>> _pins = _markerCoordinates();
  List<List<Object>> _markerCoordinates() => [
    if (widget.polylinePoints.isNotEmpty)
      [
        'origin',
        widget.polylinePoints.first.longitude,
        widget.polylinePoints.first.latitude,
      ],
    if (widget.placeLocation case final point?)
      ['place', point.longitude, point.latitude],
    for (final m in widget.museums.where((m) => m.hasCoordinates))
      [
        m.id == widget.selectedMuseumId ? 'selected' : 'museum',
        m.longitude!,
        m.latitude!,
      ],
    if (widget.userLocation case final point?)
      ['gps', point.longitude, point.latitude],
  ];
  late List<List<double>> _line = _coordinates();
  List<List<double>> _coordinates() => [
    for (final p in widget.polylinePoints) [p.longitude, p.latitude],
  ];
  static const _styleUrl = String.fromEnvironment(
    'VIETMAP_STYLE_URL',
    defaultValue:
        'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=4d927bcaf4aca07b98f530f42fee2ec188d67d3324ba5341',
  );
  bool _fallback = false;
  Timer? _renderDeadline;
  @override
  void initState() {
    super.initState();
    _renderDeadline = Timer(
      const Duration(seconds: 18),
      () => _mapStatus('error'),
    );
  }

  void _mapStatus(String status) {
    if (!mounted) return;
    _renderDeadline?.cancel();
    if (status == 'error' && !_fallback) setState(() => _fallback = true);
  }

  @override
  void dispose() {
    _renderDeadline?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveHeritageMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userLocation != widget.userLocation ||
        oldWidget.placeLocation != widget.placeLocation ||
        oldWidget.selectedMuseumId != widget.selectedMuseumId ||
        !listEquals(oldWidget.museums, widget.museums) ||
        oldWidget.polylinePoints != widget.polylinePoints) {
      _pins = _markerCoordinates();
    }
    final modeChanged = oldWidget.centerOnGps != widget.centerOnGps;
    if (modeChanged) {
      _located = false;
      _panned = false;
    }
    if (oldWidget.polylinePoints != widget.polylinePoints)
      _line = _coordinates();
    if (!_located &&
        !_panned &&
        _initialGps != null &&
        _ready &&
        widget.polylinePoints.isEmpty &&
        widget.placeLocation == null &&
        widget.selectedMuseumId == null) {
      _located = true;
      _controller.move(_initialGps!, 15);
    }
    if (widget.followUser && widget.userLocation != null && _ready) {
      _controller.move(widget.userLocation!, 16);
      return;
    }
    if (modeChanged ||
        oldWidget.followUser != widget.followUser ||
        oldWidget.placeLocation != widget.placeLocation ||
        !listEquals(oldWidget.museums, widget.museums) ||
        oldWidget.polylinePoints != widget.polylinePoints ||
        oldWidget.selectedMuseumId != widget.selectedMuseumId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit();
      });
    }
  }

  void _fit() {
    if (!_ready) return;
    if (widget.centerOnGps &&
        widget.polylinePoints.isEmpty &&
        widget.placeLocation == null &&
        widget.selectedMuseumId == null &&
        (_located || _panned || _initialGps != null)) {
      if (!_located && !_panned && _initialGps != null) {
        _located = true;
        _controller.move(_initialGps!, 15);
      }
      return;
    }
    final selected = widget.museums.where(
      (m) => m.id == widget.selectedMuseumId && m.hasCoordinates,
    );
    final points = widget.polylinePoints.isNotEmpty
        ? widget.polylinePoints
        : widget.placeLocation != null
        ? [widget.placeLocation!]
        : selected.isNotEmpty
        ? [LatLng(selected.first.latitude!, selected.first.longitude!)]
        : widget.museums
              .where((m) => m.hasCoordinates)
              .map((m) => LatLng(m.latitude!, m.longitude!))
              .toList();
    if (points.isEmpty) return;
    if (points.every((p) => p == points.first)) {
      _controller.move(points.first, 14);
      return;
    }
    final fit = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: EdgeInsets.all(
        !widget.centerOnGps && widget.polylinePoints.isEmpty ? 24 : 36,
      ),
      maxZoom: 16,
    );
    const cityZoom = 11.0;
    if (!widget.centerOnGps &&
        widget.polylinePoints.isEmpty &&
        widget.placeLocation == null &&
        selected.isEmpty &&
        fit.fit(_controller.camera).zoom < cityZoom) {
      _controller.move(points.first, cityZoom);
      return;
    }
    _controller.fitCamera(fit);
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: _initialGps ?? const LatLng(16.2, 106.3),
          initialCameraFit: _initialGps == null
              ? CameraFit.bounds(bounds: _vietnam)
              : null,
          cameraConstraint: CameraConstraint.containCenter(bounds: _vietnam),
          minZoom: 4,
          onPositionChanged: (_, gesture) {
            if (gesture) _panned = true;
          },
          initialZoom: _initialGps == null ? 5 : 15,
          onMapReady: () {
            _ready = true;
            _fit();
          },
        ),
        children: [
          if (_fallback)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              tileBounds: _vietnam,
              userAgentPackageName: 'com.smgs.museum_guide',
            )
          else
            Builder(
              builder: (context) {
                final camera = MapCamera.of(context);
                return VietMapSurface(
                  [
                    camera.center.longitude,
                    camera.center.latitude,
                    camera.zoom,
                    camera.rotation,
                    _styleUrl,
                  ],
                  _line,
                  _pins,
                  _mapStatus,
                );
              },
            ),
          if (_fallback && widget.polylinePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.polylinePoints,
                  strokeWidth: 5,
                  color: AppColors.deepBurgundy,
                ),
              ],
            ),
          // Flutter keeps the accessible tap targets; VietMap paints the visible markers.
          Opacity(
            opacity: _fallback ? 1 : 0,
            alwaysIncludeSemantics: true,
            child: MarkerLayer(
              markers: [
                if (_fallback && widget.polylinePoints.isNotEmpty)
                  Marker(
                    point: widget.polylinePoints.first,
                    child: const Icon(Icons.trip_origin, color: Colors.green),
                  ),
                if (widget.placeLocation != null)
                  Marker(
                    point: widget.placeLocation!,
                    width: 48,
                    height: 48,
                    child: Tooltip(
                      message: widget.placeName ?? 'Địa điểm',
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),
                  ),
                for (final museum in widget.museums.where(
                  (m) => m.hasCoordinates,
                ))
                  Marker(
                    point: LatLng(museum.latitude!, museum.longitude!),
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: museum.name,
                      onPressed: () => widget.onMuseumSelected(museum),
                      icon: Icon(
                        Icons.location_on,
                        size: 40,
                        color: museum.id == widget.selectedMuseumId
                            ? AppColors.imperialGold
                            : AppColors.deepBurgundy,
                      ),
                    ),
                  ),
                if (widget.userLocation != null)
                  Marker(
                    point: widget.userLocation!,
                    width: 30,
                    height: 30,
                    child: const Tooltip(
                      message: 'Vị trí của bạn',
                      child: Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(VisitorRadius.xs),
              ),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse(
                    _fallback
                        ? 'https://www.openstreetmap.org/copyright'
                        : 'https://maps.vietmap.vn',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    _fallback ? '© OpenStreetMap contributors' : '© VIETMAP',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
