import '../../widgets/earned_badges.dart';
import '../../services/visitor_experience_api.dart';
import '../../services/artifact_scan_service.dart';
import 'dart:typed_data';
import 'dart:async';
import '../../services/museum_presence_api.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/indoor_map.dart';
import '../../models/artifact.dart';
import '../../services/discovery_api_service.dart';
import '../../widgets/artifact_photo.dart';
import '../../services/indoor_map_api_service.dart';
import '../../widgets/museum_ui.dart';

class VisitorIndoorMapScreen extends StatefulWidget {
  const VisitorIndoorMapScreen({
    super.key,
    required this.mapId,
    this.museumName = 'Bảo tàng',
    this.visitId,
    this.directory,
    this.targetArtifactId,
  });

  final Map<String, dynamic>? directory;
  final dynamic mapId;
  final String museumName;
  final int? visitId;
  final int? targetArtifactId;

  @override
  State<VisitorIndoorMapScreen> createState() => _VisitorIndoorMapScreenState();
}

class _VisitorIndoorMapScreenState extends State<VisitorIndoorMapScreen> {
  final TransformationController _transformController =
      TransformationController();

  late dynamic _currentMapId;
  PublishedIndoorMap? _map;
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _errorMessage;
  String? _routeError;
  int _routeRequest = 0;
  int _mapRequest = 0;
  ScanRequest? _scanRequest;
  DateTime? _confirmedAt;
  DateTime? _locationScanAt;
  Map<String, dynamic>? _lastPosition;
  bool _manualStart = false;
  Timer? _positionTimer;

  // Navigation state
  String? _fromNodeId;
  IndoorMarker? _startMarker;

  IndoorMarker? _selectedDestination;
  List<Map<String, dynamic>> _routeSegments = [];
  int _segmentIndex = 0;
  int? _journeyTargetMapId;
  IndoorMarker? _journeyDestination;
  List<String> _routeNodeIds = [];
  bool _accessibleOnly = false;

  // QR Camera modal
  bool _showQrScanner = false;
  bool _isProcessingScan = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _currentMapId = widget.mapId;
    _loadPublishedMap();
    _positionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        if (!_manualStart &&
            _confirmedAt != null &&
            DateTime.now().toUtc().difference(_confirmedAt!.toUtc()) >
                const Duration(minutes: 5)) {
          _routeNodeIds = [];
          _fromNodeId = null;
          _routeError =
              'Vị trí đã cũ. Hãy quét QR tại vị trí đang đứng để tiếp tục chỉ đường.';
        }
      });
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _transformController.dispose();

    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadPublishedMap({
    bool showSegment = false,
    Map<String, dynamic>? scannedPosition,
  }) async {
    final segment = showSegment ? _routeSegments[_segmentIndex] : null;
    final position = scannedPosition ?? (showSegment ? _lastPosition : null);
    final loadRequest = ++_mapRequest;
    _routeRequest++;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mapData = await IndoorMapApiService.fetchPublishedMap(
        _currentMapId,
      );
      Uint8List? imgBytes;
      if (mapData.imageKey != null && mapData.imageKey!.isNotEmpty) {
        try {
          imgBytes = await IndoorMapApiService.fetchMapImageBytes(
            _currentMapId,
            mapData.imageKey!,
          );
        } catch (_) {
          throw const FormatException(
            'Chưa tải được ảnh sơ đồ. Vui lòng thử lại.',
          );
        }
      }

      if (!mounted || loadRequest != _mapRequest) return;
      if (segment != null && segment['revision'] != mapData.revision) {
        _routeSegments = [];
        _journeyDestination = null;
        _journeyTargetMapId = null;
        throw const FormatException(
          'Sơ đồ đã thay đổi. Hãy tải lại và tìm đường lại.',
        );
      }
      setState(() {
        _selectedArtifact = null;
        _map = mapData;
        _imageBytes = imgBytes;
        _isLoading = false;
        _fromNodeId = null;
        _startMarker = null;

        _manualStart = false;
        _confirmedAt = null;
        _lastPosition = null;
        final targets = widget.targetArtifactId == null
            ? <IndoorMarker>[]
            : mapData.markers
                  .where(
                    (m) =>
                        m.isActive &&
                        m.isDestination &&
                        m.artifactId == widget.targetArtifactId,
                  )
                  .toList();
        _selectedDestination = !showSegment && _journeyTargetMapId == mapData.id
            ? mapData.markers
                  .where((m) => m.isActive && m.id == _journeyDestination?.id)
                  .firstOrNull
            : (targets.length == 1 ? targets.single : null);
        if (!showSegment) _routeSegments = [];
        _routeNodeIds = [];
        _routeError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && loadRequest == _mapRequest) _fitMap();
      });
      if (segment != null) {
        setState(() {
          _applyPosition(mapData, position);
          _routeNodeIds = (segment['nodeIds'] as List).cast<String>();
        });
        return;
      }
      try {
        final location =
            position ??
            await MuseumPresenceApi.current(
              mapData.museumId,
              visitId: widget.visitId,
              mapId: mapData.id,
            );
        if (!mounted || loadRequest != _mapRequest) return;
        setState(() => _applyPosition(mapData, location));
      } catch (e) {
        if (mounted && loadRequest == _mapRequest) {
          setState(() => _routeError = e.toString());
        }
      }
    } catch (e) {
      if (!mounted || loadRequest != _mapRequest) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applyPosition(PublishedIndoorMap map, Map<String, dynamic>? location) {
    _confirmedAt = DateTime.tryParse(
      location?['confirmedAt']?.toString() ?? '',
    );
    _lastPosition = _confirmedAt == null ? null : location;
    if (!_hasFreshPosition || location?['mapId'] != map.id) return;
    _startMarker = map.markers
        .where(
          (marker) =>
              marker.isActive &&
              marker.id == location?['markerId']?.toString() &&
              marker.nodeId != null,
        )
        .firstOrNull;
    _fromNodeId = _startMarker?.nodeId;
  }

  bool get _hasFreshPosition {
    final confirmedAt = _confirmedAt;
    if (confirmedAt == null ||
        _lastPosition?['isFresh'] != true ||
        _lastPosition?['nodeId'] == null) {
      return false;
    }
    final age = DateTime.now().difference(confirmedAt);
    return !age.isNegative && age <= const Duration(minutes: 5);
  }

  bool get _hasLocationScan =>
      _hasFreshPosition &&
      (_lastPosition?['source'] == 'checkpoint_qr' ||
          _confirmedAt == _locationScanAt);
  Future<void> _startDirections() async {
    if (_manualStart || _hasLocationScan) return _recalculateRoute();
    if (!_hasFreshPosition) {
      _scan();
      return;
    }
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kiểm tra điểm xuất phát'),
        content: const Text(
          'Vị trí này được ghi nhận từ lần quét QR gần nhất. Bạn có thể đã di chuyển. Hãy quét QR tại nơi đang đứng để xác nhận vị trí trước khi chỉ đường.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Dùng vị trí gần nhất'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận lại vị trí'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice) {
      _scan();
    } else {
      await _recalculateRoute();
    }
  }

  Future<void> _recalculateRoute() async {
    final request = ++_routeRequest;
    if (!_manualStart) {
      if (_map == null || _selectedDestination == null) return;
      final target = _selectedDestination!.artifactId;
      setState(() {
        _routeNodeIds = [];
        _routeError = null;
      });
      try {
        final data = await MuseumPresenceApi.route(
          _map!.museumId,
          int.parse(_currentMapId.toString()),
          visitId: widget.visitId,
          artifactId: target,
          targetNodeId: _selectedDestination!.nodeId,
          accessible: _accessibleOnly,
        );
        if (!mounted || request != _routeRequest) return;
        if (data['segments'] case final List segments
            when segments.isNotEmpty) {
          _journeyTargetMapId = _map!.id;
          _journeyDestination = _selectedDestination;
          _routeSegments = segments.cast<Map<String, dynamic>>();
          await _openRouteSegment(0);
          return;
        }
        if (data['revision'] != _map!.revision) {
          throw const FormatException('Sơ đồ đã thay đổi. Hãy tải lại sơ đồ.');
        }
        final nodes = (data['route']['nodeIds'] as List)
            .map((id) => id.toString())
            .toList();
        setState(() {
          if (nodes.isEmpty ||
              nodes.any((id) => !_map!.nodes.any((n) => n.id == id))) {
            _routeError = 'Chưa tìm được đường đi trên sơ đồ này.';
            return;
          }
          _routeNodeIds = nodes;
          _fromNodeId = nodes.firstOrNull;
        });
      } catch (e) {
        if (mounted && request == _routeRequest) {
          setState(() => _routeError = e.toString());
        }
      }
      return;
    }
    if (_map == null ||
        _fromNodeId == null ||
        _selectedDestination == null ||
        _selectedDestination!.nodeId == null) {
      setState(() {
        _routeNodeIds = [];
      });
      return;
    }

    final targetNodeId = _selectedDestination!.nodeId!;
    if (_fromNodeId == targetNodeId) {
      setState(() {
        _routeNodeIds = [_fromNodeId!];
      });
      return;
    }

    final path = DijkstraRouter.findShortestPath(
      nodes: _map!.nodes,
      edges: _map!.edges,
      startNodeId: _fromNodeId!,
      targetNodeId: targetNodeId,
      imageWidth: _map!.imageWidth,
      imageHeight: _map!.imageHeight,
      accessibleOnly: _accessibleOnly,
    );

    setState(() {
      _routeNodeIds = path;
    });
  }

  Future<void> _openRouteSegment(int index) async {
    _segmentIndex = index;
    _currentMapId = _routeSegments[index]['mapId'];
    await _loadPublishedMap(showSegment: true);
  }

  void _selectDestination(IndoorMarker marker) {
    _journeyDestination = null;
    _journeyTargetMapId = null;
    _routeSegments = [];
    setState(() {
      _selectedArtifact = null;
      _selectedDestination = marker;
    });
    _routeRequest++;
    _routeNodeIds = [];
    _routeError = null;
  }

  List<Map> _rows(String key) =>
      (widget.directory?[key] as List? ?? []).cast<Map>();
  Map get _floor =>
      _rows('maps').where((m) => m['id'] == _currentMapId).firstOrNull ?? {};
  String _location(Map item) => [
    item['floorName'],
    item['buildingName'],
    item['galleryName'],
  ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
  Future<void> _switch(dynamic id) async {
    if (id == _currentMapId) return;
    _journeyDestination = null;
    _journeyTargetMapId = null;
    _currentMapId = id;
    await _loadPublishedMap();
  }

  void _scan() {
    _scannerController ??= MobileScannerController();
    setState(() => _showQrScanner = true);
  }

  Future<void> _search() async {
    final results = <Map>[
      for (final a in _rows('artifacts')) {...a, 'artifact': true},
      for (final g in _rows('galleries')) {...g, 'artifact': false},
      if (widget.directory == null)
        for (final m in _map!.markers.where((m) => m.isActive))
          {'id': m.id, 'name': m.label, 'marker': m},
    ];
    var query = '';
    final chosen = await showModalBottomSheet<Map>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VisitorRadius.xxl),
        ),
      ),
      builder: (sheet) => FractionallySizedBox(
        heightFactor: .78,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, refresh) {
              final matches = results
                  .where(
                    (r) => '${r['name']} ${_location(r)}'
                        .toLowerCase()
                        .contains(query),
                  )
                  .toList();
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.mutedGold.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(VisitorRadius.full),
                    ),
                  ),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm hiện vật hoặc phòng',
                    ),
                    onChanged: (v) =>
                        refresh(() => query = v.trim().toLowerCase()),
                  ),
                  Expanded(
                    child: matches.isEmpty
                        ? const Center(child: Text('Không tìm thấy kết quả.'))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (_, i) => ListTile(
                              title: Text(matches[i]['name']),
                              subtitle: Text(_location(matches[i])),
                              onTap: () => Navigator.pop(sheet, matches[i]),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final artifact = chosen['artifact'] == true;
    final linked = artifact
        ? (chosen['maps'] as List? ?? []).cast<Map>()
        : _rows(
            'maps',
          ).where((m) => m['floorId'] == chosen['floorId']).toList();
    final targetMap =
        linked.where((m) => m['id'] == _currentMapId).firstOrNull ??
        linked.firstOrNull;
    if (targetMap != null) await _switch(targetMap['id']);
    if (!mounted) return;
    final active = _map?.markers.where((m) => m.isActive) ?? <IndoorMarker>[];
    final marker =
        chosen['marker'] as IndoorMarker? ??
        (targetMap == null
            ? null
            : (artifact
                      ? active
                            .where((m) => m.artifactId == chosen['id'])
                            .firstOrNull
                      : null) ??
                  active
                      .where(
                        (m) =>
                            m.galleryId ==
                                (artifact
                                    ? chosen['galleryId']
                                    : chosen['id']) &&
                            m.galleryId != null &&
                            m.artifactId == null,
                      )
                      .firstOrNull);
    if (marker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có điểm liên kết trên sơ đồ đã xuất bản.'),
        ),
      );
      return;
    }
    _selectDestination(marker);
    if (artifact) setState(() => _selectedArtifact = chosen);
    _centerOnCoordinates(marker.x, marker.y);
  }

  final _thumbnails = <int, Future<Map<String, dynamic>>>{};
  Widget _thumbnail(int? id, {double size = 48, bool circular = false}) {
    final fallback = circular
        ? const Center(child: Icon(Icons.museum_outlined, color: Colors.white))
        : const Icon(Icons.place_outlined);
    if (id == null) return fallback;
    final photo = FutureBuilder<Map<String, dynamic>>(
      future: _thumbnails.putIfAbsent(
        id,
        () => DiscoveryApiService.fetchArtifactDetail(id),
      ),
      builder: (_, snapshot) => snapshot.hasData
          ? ArtifactPhoto(
              artifact: Artifact.fromBackendJson(snapshot.data!),
              height: size,
              fallback: fallback,
            )
          : fallback,
    );
    return SizedBox.square(
      dimension: size,
      child: circular
          ? ClipOval(child: photo)
          : ClipRRect(
              borderRadius: BorderRadius.circular(VisitorRadius.sm),
              child: photo,
            ),
    );
  }

  Widget _mapPin(
    IndoorMarker marker, {
    required bool isStart,
    required bool isSelected,
    required double size,
  }) {
    const blue = Color(0xFF155DE0);
    final hasPhoto = marker.type == 'artifact' && marker.artifactId != null;
    final outline = isStart
        ? blue
        : isSelected
        ? const Color(0xFF227C64)
        : Colors.white;
    return GestureDetector(
      onTap: () => _selectDestination(marker),
      child: Tooltip(
        message: isStart ? 'Vị trí hiện tại của bạn' : marker.label,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (hasPhoto)
                Positioned(
                  bottom: -3,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: SizedBox.square(
                      dimension: size / 5,
                      child: ColoredBox(color: outline),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isStart && !hasPhoto ? blue : AppColors.deepBurgundy,
                    border: Border.all(
                      color: isStart && !hasPhoto ? Colors.white : outline,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isStart)
                        const BoxShadow(
                          color: Color(0x66155DE0),
                          spreadRadius: 5,
                          blurRadius: 1,
                        ),
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: hasPhoto
                        ? _thumbnail(
                            marker.artifactId,
                            size: size - 6,
                            circular: true,
                          )
                        : Icon(
                            isStart ? Icons.my_location_rounded : Icons.place,
                            color: Colors.white,
                            size: size * 0.55,
                          ),
                  ),
                ),
              ),
              if (hasPhoto && isStart)
                Positioned(
                  top: -5,
                  right: -5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: size * 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map? _selectedArtifact;
  Widget _controls(IndoorMarker? position) {
    final floor = _floor;
    final maps = _rows('maps');
    final buildings = maps
        .map((m) => m['buildingName'])
        .whereType<String>()
        .toSet();
    final floors = maps
        .where((m) => m['buildingName'] == floor['buildingName'])
        .toList()
        .reversed;
    final selected = _selectedDestination;
    final artifact =
        _selectedArtifact ??
        _rows(
          'artifacts',
        ).where((a) => a['id'] == selected?.artifactId).firstOrNull;
    final room = _rows(
      'galleries',
    ).where((r) => r['id'] == selected?.galleryId).firstOrNull;
    final location = _location({
      ...floor,
      'galleryName': room?['name'],
      ...?artifact,
    });
    final floorLabel = _location(floor);
    final controls = <Widget>[
      Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.white,
          elevation: 1,
          borderRadius: BorderRadius.circular(VisitorRadius.full),
          child: buildings.length > 1
              ? PopupMenuButton<String>(
                  tooltip: 'Chọn tòa nhà',
                  onSelected: (b) => _switch(
                    maps.firstWhere((m) => m['buildingName'] == b)['id'],
                  ),
                  itemBuilder: (_) => [
                    for (final b in buildings)
                      PopupMenuItem(value: b, child: Text(b)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('$floorLabel ▾'),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Text(floorLabel.isEmpty ? _map!.name : floorLabel),
                ),
        ),
      ),
      const Spacer(),
      if (floors.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('TẦNG', style: TextStyle(fontSize: 10)),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final f in floors)
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: f['id'] == _currentMapId
                                  ? AppColors.deepBurgundy
                                  : null,
                              foregroundColor: f['id'] == _currentMapId
                                  ? Colors.white
                                  : AppColors.darkBrown,
                              minimumSize: const Size(44, 44),
                            ),
                            onPressed: () => _switch(f['id']),
                            child: Text(
                              f['levelNo']?.toString() ??
                                  f['floorName'] ??
                                  f['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_hasLocationScan)
        Card(
          color: const Color(0xFFE6EFFF),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.my_location, color: Color(0xFF1746A2)),
            title: const Text(
              'Vị trí hiện tại của bạn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1746A2),
              ),
            ),
            subtitle: Text(
              [
                _lastPosition?['floorName'],
                _lastPosition?['label'],
              ].whereType<String>().join(' · '),
            ),
          ),
        ),
      if (_routeSegments.isNotEmpty)
        Card(
          child: ListTile(
            title: Text(_routeSegments[_segmentIndex]['mapName'] as String),
            subtitle: Text(
              _segmentIndex + 1 < _routeSegments.length
                  ? 'Đi đến ${_routeSegments[_segmentIndex]['connectorLabel']} '
                        'để sang ${_routeSegments[_segmentIndex + 1]['mapName']}.'
                  : 'Đi theo tuyến đến ${_journeyDestination?.label ?? 'điểm đến'}.',
            ),
            leading: _segmentIndex > 0
                ? IconButton(
                    tooltip: 'Xem đoạn trước',
                    onPressed: () => _openRouteSegment(_segmentIndex - 1),
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            trailing: _segmentIndex + 1 < _routeSegments.length
                ? TextButton(
                    onPressed: () => _openRouteSegment(_segmentIndex + 1),
                    child: const Text('Xem đoạn tiếp'),
                  )
                : null,
          ),
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child:
                !_hasLocationScan &&
                    _routeSegments.isEmpty &&
                    position == null &&
                    selected == null
                ? Card(
                    margin: EdgeInsets.zero,
                    color: VisitorColors.surface1,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VisitorRadius.md),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.deepBurgundy,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Quét QR để biết bạn đang đứng ở đâu trên sơ đồ.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: 12),
          SizedBox.square(
            dimension: 48,
            child: FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VisitorRadius.md),
              ),
              heroTag: null,
              tooltip: 'Quét QR xác định vị trí',
              backgroundColor: AppColors.deepBurgundy,
              foregroundColor: Colors.white,
              onPressed: _scan,
              child: const Icon(Icons.qr_code_scanner, size: 23),
            ),
          ),
        ],
      ),
      if (selected != null)
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    _thumbnail(artifact?['id'] ?? selected.artifactId),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artifact?['name'] ?? selected.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium,
                          ),
                          if (location.isNotEmpty)
                            Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => setState(() {
                        _journeyDestination = null;
                        _journeyTargetMapId = null;
                        _selectedDestination = null;
                        _selectedArtifact = null;
                        _routeRequest++;
                        _routeNodeIds = [];
                        _routeError = null;
                      }),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (selected.isDestination && selected.nodeId != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _startDirections,
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Chỉ đường'),
                      ),
                      IconButton(
                        tooltip: 'Ưu tiên lối đi dễ tiếp cận',
                        isSelected: _accessibleOnly,
                        icon: const Icon(Icons.accessible),
                        onPressed: () {
                          setState(() => _accessibleOnly = !_accessibleOnly);
                          if (_routeNodeIds.isNotEmpty) _recalculateRoute();
                        },
                      ),
                    ],
                  ),
                if (_routeError != null)
                  Text(
                    _routeError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
    ];
    final horizontal =
        MediaQuery.orientationOf(context) == Orientation.landscape &&
        selected != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: horizontal
            ? Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: SingleChildScrollView(child: controls.last),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: controls.sublist(0, controls.length - 1),
                    ),
                  ),
                ],
              )
            : Column(children: controls),
      ),
    );
  }

  Size? _viewport;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    if (_viewport != size) {
      _viewport = size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMap();
      });
    }
  }

  void _fitMap() {
    if (_map == null || _map!.imageWidth <= 0 || _map!.imageHeight <= 0) return;
    final screen = MediaQuery.of(context).size;
    final height =
        (screen.height -
            kToolbarHeight -
            MediaQuery.of(context).padding.vertical) *
        0.65;
    final scale = math
        .min(screen.width / _map!.imageWidth, height / _map!.imageHeight)
        .clamp(0.02, 4.0);
    _transformController.value = Matrix4.identity()
      ..translateByDouble(
        (screen.width - _map!.imageWidth * scale) / 2,
        (height - _map!.imageHeight * scale) / 2 + 16,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _centerOnCoordinates(double normX, double normY) {
    if (_map == null) return;
    const targetScale = 1.5;
    final px = normX * _map!.imageWidth;
    final py = normY * _map!.imageHeight;

    final size = MediaQuery.of(context).size;
    final targetX = -(px * targetScale - size.width / 2);
    final targetY = -(py * targetScale - size.height / 3);

    _transformController.value = Matrix4.identity()
      ..translateByDouble(targetX, targetY, 0, 1)
      ..scaleByDouble(targetScale, targetScale, 1, 1);
  }

  void _prepareMapAfterScan(dynamic scannedMapId) {
    if (_selectedDestination != null && _routeSegments.isEmpty) {
      _journeyDestination = _selectedDestination;
      _journeyTargetMapId = _map?.id;
    }
    _currentMapId = _journeyTargetMapId ?? scannedMapId ?? _currentMapId;
  }

  Future<void> _reloadAfterScan(Map<String, dynamic> location) async {
    _locationScanAt = DateTime.tryParse(
      location['confirmedAt']?.toString() ?? '',
    );
    await _loadPublishedMap(scannedPosition: location);
    if (mounted &&
        _errorMessage == null &&
        _selectedDestination?.nodeId != null) {
      await _recalculateRoute();
    }
  }

  Future<void> _handleQrDetected(String rawCode) async {
    if (!_showQrScanner || _isProcessingScan || _map == null) return;
    setState(() {
      _isProcessingScan = true;
    });

    try {
      if (MuseumPresenceApi.isCheckpoint(rawCode)) {
        final result = await MuseumPresenceApi.scan(
          rawCode,
          museumId: _map!.museumId,
          visitId: widget.visitId,
        );
        if (!mounted) return;
        _prepareMapAfterScan(result['mapId']);
        setState(() {
          _showQrScanner = false;
          _isProcessingScan = false;
        });
        await _scannerController?.dispose();
        _scannerController = null;
        await _reloadAfterScan(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xác nhận tại ${result['label']}.')),
          );
        }
        return;
      }
      final code = ArtifactScanService.extractCode(rawCode);
      final artifact = await ArtifactScanService.scan(code);
      if (artifact['museumId'] != _map!.museumId) {
        throw const FormatException('QR thuộc bảo tàng khác.');
      }
      if (_scanRequest?.code != code ||
          _scanRequest?.visitId != widget.visitId) {
        _scanRequest = ScanRequest(code, visitId: widget.visitId);
      }
      final recognition = await _scanRequest!.record();
      _scanRequest = null;
      if (mounted) showExplorationRewards(context, recognition);
      if (!mounted) return;
      final location = await MuseumPresenceApi.current(
        _map!.museumId,
        visitId: widget.visitId,
      );
      if (!mounted) return;
      final recordedAt = DateTime.tryParse(
        recognition['recognizedAt'].toString(),
      );
      final confirmedAt = DateTime.tryParse(location['confirmedAt'].toString());
      if (recordedAt == null ||
          confirmedAt == null ||
          recordedAt.difference(confirmedAt).abs() >=
              const Duration(milliseconds: 1) ||
          location['artifactId'].toString() != artifact['id'].toString()) {
        throw const FormatException(
          'Hiện vật chưa có vị trí hợp lệ trên sơ đồ.',
        );
      }
      _prepareMapAfterScan(location['mapId']);
      setState(() {
        _showQrScanner = false;
        _isProcessingScan = false;
        _selectedDestination = null;
      });
      await _scannerController?.dispose();
      _scannerController = null;
      if (mounted) await _reloadAfterScan(location);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingScan = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst('FormatException: ', '')
                .replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _confirmedAt == null
        ? null
        : DateTime.now().toUtc().difference(_confirmedAt!.toUtc());
    final position =
        _manualStart ||
            (age != null &&
                !age.isNegative &&
                age <= const Duration(minutes: 5))
        ? _startMarker
        : null;
    final map = _map;
    final labelWidth = map?.imageWidth.clamp(0.0, 156.0).toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Center(
          child: IconButton.filledTonal(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            style: IconButton.styleFrom(
              backgroundColor: VisitorColors.surface1,
              shape: const CircleBorder(),
            ),
            onPressed: () => Navigator.maybePop(context),
            icon: const BackButtonIcon(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sơ đồ bảo tàng',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepBurgundy,
              ),
            ),
            Text(
              _lastPosition == null
                  ? widget.museumName
                  : [
                      _hasLocationScan
                          ? 'Vị trí hiện tại của bạn'
                          : 'Vị trí ghi nhận gần nhất',
                      _lastPosition?['buildingName'],
                      _lastPosition?['floorName'],
                      _lastPosition?['galleryName'],
                      DateTime.tryParse(
                        _lastPosition?['confirmedAt']?.toString() ?? '',
                      )?.toLocal().toString().split('.').first,
                    ].whereType<String>().join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.darkBrown),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: VisitorColors.surface1,
              shape: const CircleBorder(),
            ),
            tooltip: 'Tìm hiện vật hoặc phòng',
            icon: const Icon(Icons.search),
            onPressed: _map == null ? null : _search,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.deepBurgundy),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.deepBurgundy,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadPublishedMap(
                        showSegment: _routeSegments.isNotEmpty,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBurgundy,
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // 1. Interactive Canvas Map Viewport
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    minScale: 0.02,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(300),
                    child: GestureDetector(
                      onDoubleTapDown: (tap) {
                        final plan = _map;
                        if (plan == null ||
                            plan.imageWidth <= 0 ||
                            plan.imageHeight <= 0) {
                          return;
                        }
                        if (_transformController.value.entry(0, 0) >= 1.5) {
                          _fitMap();
                        } else {
                          _centerOnCoordinates(
                            tap.localPosition.dx / plan.imageWidth,
                            tap.localPosition.dy / plan.imageHeight,
                          );
                        }
                      },
                      child: _map != null
                          ? SizedBox(
                              width: _map!.imageWidth,
                              height: _map!.imageHeight,
                              child: Stack(
                                children: [
                                  // Background Image
                                  if (_imageBytes != null)
                                    Positioned.fill(
                                      child: Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.fill,
                                      ),
                                    )
                                  else
                                    Positioned.fill(
                                      child: Container(color: Colors.white),
                                    ),

                                  // Route Path Painter
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _IndoorMapPainter(
                                        map: _map!,
                                        routeNodeIds: _routeNodeIds,
                                        startNodeId: _fromNodeId,
                                        destinationMarker: _selectedDestination,
                                      ),
                                    ),
                                  ),

                                  ..._map!.markers.where((m) => m.isActive).map(
                                    (marker) {
                                      final isStart = position?.id == marker.id;
                                      final isSelected =
                                          _selectedDestination?.id == marker.id;
                                      final isArtifact =
                                          marker.type == 'artifact' &&
                                          marker.artifactId != null;
                                      final size = isArtifact
                                          ? 54.0
                                          : isStart
                                          ? 48.0
                                          : 36.0;
                                      return Positioned(
                                        left:
                                            marker.x * _map!.imageWidth -
                                            size / 2,
                                        top:
                                            marker.y * _map!.imageHeight -
                                            size / 2,
                                        child: _mapPin(
                                          marker,
                                          isStart: isStart,
                                          isSelected: isSelected,
                                          size: size,
                                        ),
                                      );
                                    },
                                  ),
                                  if (map != null)
                                    for (final marker in map.markers.where(
                                      (m) =>
                                          m.isActive &&
                                          m.type == 'artifact' &&
                                          m.id != position?.id &&
                                          m.label.trim().isNotEmpty,
                                    ))
                                      Positioned(
                                        left:
                                            (marker.x * map.imageWidth -
                                                    labelWidth / 2)
                                                .clamp(
                                                  0.0,
                                                  map.imageWidth - labelWidth,
                                                )
                                                .toDouble(),
                                        top: (marker.y * map.imageHeight + 34)
                                            .clamp(
                                              0.0,
                                              (map.imageHeight - 28).clamp(
                                                0.0,
                                                map.imageHeight,
                                              ),
                                            )
                                            .toDouble(),
                                        width: labelWidth,
                                        child: IgnorePointer(
                                          child: Center(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      VisitorRadius.xs,
                                                    ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                child: Text(
                                                  marker.label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF612D25),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  if (position != null && map != null)
                                    Positioned(
                                      left:
                                          (position.x * map.imageWidth -
                                                  labelWidth / 2)
                                              .clamp(
                                                0.0,
                                                map.imageWidth - labelWidth,
                                              )
                                              .toDouble(),
                                      top: position.y * map.imageHeight >= 75
                                          ? position.y * map.imageHeight - 75
                                          : position.y * map.imageHeight + 35,
                                      width: labelWidth,
                                      child: IgnorePointer(
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0xFF2563EB),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    VisitorRadius.xs,
                                                  ),
                                            ),
                                            child: Text(
                                              _manualStart
                                                  ? 'Điểm xuất phát chọn tay'
                                                  : 'Vừa xác nhận: ${position.label}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Color(0xFF1749A8),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),

                // 2. Floating Action Controls (Fit view, My Location, QR Scan)
                _controls(position),
                // 5. Fullscreen QR Scanner Camera Overlay
                if (_showQrScanner)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              for (final barcode in capture.barcodes) {
                                if (barcode.rawValue != null &&
                                    barcode.rawValue!.isNotEmpty) {
                                  _handleQrDetected(barcode.rawValue!);
                                  break;
                                }
                              }
                            },
                          ),
                          // Viewfinder box
                          Center(
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFC5A059),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(
                                  VisitorRadius.md,
                                ),
                              ),
                            ),
                          ),
                          // Close button
                          Positioned(
                            left: 16,
                            top: 40,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => setState(() {
                                _showQrScanner = false;
                                _scannerController?.dispose();
                                _scannerController = null;
                              }),
                            ),
                          ),
                          // Torch button
                          Positioned(
                            right: 16,
                            top: 40,
                            child: IconButton(
                              icon: const Icon(
                                Icons.flash_on,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () =>
                                  _scannerController?.toggleTorch(),
                            ),
                          ),
                          // Instruction text
                          Positioned(
                            bottom: 60,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(
                                  VisitorRadius.xs,
                                ),
                              ),
                              child: const Text(
                                'Quét mã QR tại vị trí bạn đang đứng để xác định điểm xuất phát.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          if (_isProcessingScan)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFC5A059),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// CustomPainter to render edges and Dijkstra path line
class _IndoorMapPainter extends CustomPainter {
  final PublishedIndoorMap map;
  final List<String> routeNodeIds;
  final String? startNodeId;
  final IndoorMarker? destinationMarker;

  _IndoorMapPainter({
    required this.map,
    required this.routeNodeIds,
    this.startNodeId,
    this.destinationMarker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final n in map.nodes) n.id: n};

    if (routeNodeIds.length > 1) {
      final routePaint = Paint()
        ..color = const Color(0xFF227C64)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < routeNodeIds.length; i++) {
        final node = nodeMap[routeNodeIds[i]];
        if (node == null) continue;
        final pt = Offset(node.x * map.imageWidth, node.y * map.imageHeight);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IndoorMapPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.routeNodeIds != routeNodeIds ||
        oldDelegate.startNodeId != startNodeId ||
        oldDelegate.destinationMarker != destinationMarker;
  }
}
