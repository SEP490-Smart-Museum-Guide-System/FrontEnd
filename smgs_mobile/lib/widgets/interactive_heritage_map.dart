import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/museum.dart';

class InteractiveHeritageMap extends StatefulWidget {
  const InteractiveHeritageMap({
    super.key,
    required this.museums,
    required this.selectedMuseumId,
    required this.onMuseumSelected,
    this.userLocation,
    this.polylinePoints = const [],
    this.placeLocation,
    this.placeName,
  });
  final List<Museum> museums;
  final String? selectedMuseumId;
  final ValueChanged<Museum> onMuseumSelected;
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
  bool _tileError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveHeritageMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeLocation != widget.placeLocation ||
        oldWidget.museums != widget.museums ||
        oldWidget.polylinePoints != widget.polylinePoints ||
        oldWidget.selectedMuseumId != widget.selectedMuseumId ||
        oldWidget.userLocation != widget.userLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit();
      });
    }
  }

  void _fit() {
    if (!_ready) return;
    final selected = widget.museums.where(
      (m) => m.id == widget.selectedMuseumId && m.hasCoordinates,
    );
    final points = widget.placeLocation != null
        ? [widget.placeLocation!]
        : widget.polylinePoints.isNotEmpty
        ? widget.polylinePoints
        : selected.isNotEmpty
        ? [LatLng(selected.first.latitude!, selected.first.longitude!)]
        : widget.museums
              .where((m) => m.hasCoordinates)
              .map((m) => LatLng(m.latitude!, m.longitude!))
              .toList();
    if (points.isEmpty) return;
    if (points.every((p) => p == points.first)) {
      _controller.move(points.first, 14);
    } else {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(36),
          maxZoom: 16,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: const LatLng(16.2, 106.3),
          initialZoom: 5,
          onMapReady: () {
            _ready = true;
            _fit();
          },
        ),
        children: [
          TileLayer(
            urlTemplate: const String.fromEnvironment(
              'OSM_TILE_URL',
              defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            userAgentPackageName: 'com.smgs.museum_guide',
            panBuffer: 0,
            errorTileCallback: (tile, error, stack) {
              if (!_tileError && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _tileError = true);
                });
              }
            },
          ),
          if (widget.polylinePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.polylinePoints,
                  strokeWidth: 5,
                  color: AppColors.deepBurgundy,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
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
          Align(
            alignment: Alignment.bottomRight,
            child: ColoredBox(
              color: Colors.white,
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 11, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      if (_tileError)
        Positioned(
          top: 4,
          left: 8,
          right: 8,
          child: Material(
            color: Colors.white,
            child: ListTile(
              dense: true,
              title: const Text(
                'Không tải được một số ô bản đồ. Kiểm tra kết nối mạng.',
              ),
              trailing: IconButton(
                tooltip: 'Đóng',
                onPressed: () => setState(() => _tileError = false),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ),
    ],
  );
}
