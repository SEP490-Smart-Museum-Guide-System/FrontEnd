import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/network/api_config.dart';
import '../../models/indoor_map.dart';
import '../../services/indoor_map_api_service.dart';
import '../../widgets/museum_ui.dart';

class VisitorIndoorMapScreen extends StatefulWidget {
  const VisitorIndoorMapScreen({
    super.key,
    required this.mapId,
    this.museumName = 'Bảo tàng',
  });

  final dynamic mapId;
  final String museumName;

  @override
  State<VisitorIndoorMapScreen> createState() => _VisitorIndoorMapScreenState();
}

class _VisitorIndoorMapScreenState extends State<VisitorIndoorMapScreen> {
  final TransformationController _transformController = TransformationController();
  final TextEditingController _searchController = TextEditingController();

  late dynamic _currentMapId;
  PublishedIndoorMap? _map;
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _errorMessage;

  // Navigation state
  String? _fromNodeId;
  IndoorMarker? _startMarker;
  String? _startArtifactName;
  IndoorMarker? _selectedDestination;
  List<String> _routeNodeIds = [];
  bool _accessibleOnly = false;
  String _searchQuery = '';

  // QR Camera modal
  bool _showQrScanner = false;
  bool _isProcessingScan = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _currentMapId = widget.mapId;
    _loadPublishedMap();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _searchController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadPublishedMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mapData = await IndoorMapApiService.fetchPublishedMap(_currentMapId);
      Uint8List? imgBytes;
      if (mapData.imageKey != null && mapData.imageKey!.isNotEmpty) {
        try {
          imgBytes = await IndoorMapApiService.fetchMapImageBytes(_currentMapId, mapData.imageKey!);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _map = mapData;
        _imageBytes = imgBytes;
        _isLoading = false;
        _fromNodeId = null;
        _startMarker = null;
        _startArtifactName = null;
        _selectedDestination = null;
        _routeNodeIds = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showChangeMapDialog() {
    final controller = TextEditingController(text: _currentMapId.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chọn sơ đồ tầng (Map ID)', style: TextStyle(color: AppColors.deepBurgundy, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập ID sơ đồ đã xuất bản cần tải:', style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: 1',
                prefixIcon: Icon(Icons.layers_outlined, color: AppColors.deepBurgundy),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.darkBrown)),
          ),
          ElevatedButton(
            onPressed: () {
              final newId = int.tryParse(controller.text.trim());
              if (newId != null && newId > 0) {
                Navigator.pop(ctx);
                setState(() {
                  _currentMapId = newId;
                });
                _loadPublishedMap();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
            child: const Text('Tải sơ đồ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _recalculateRoute() {
    if (_map == null || _fromNodeId == null || _selectedDestination == null || _selectedDestination!.nodeId == null) {
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

  void _selectDestination(IndoorMarker marker) {
    setState(() {
      _selectedDestination = marker;
    });
    _recalculateRoute();
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
      ..translate(targetX, targetY)
      ..scale(targetScale);
  }

  Future<void> _handleQrDetected(String rawCode) async {
    if (_isProcessingScan || _map == null) return;
    setState(() {
      _isProcessingScan = true;
    });

    try {
      final result = await IndoorMapApiService.resolveQrToLocation(
        rawQr: rawCode,
        map: _map!,
      );

      if (!mounted) return;
      setState(() {
        _fromNodeId = result.startNodeId;
        _startMarker = result.marker;
        _startArtifactName = result.artifactName;
        _showQrScanner = false;
        _isProcessingScan = false;
      });

      _centerOnCoordinates(result.marker.x, result.marker.y);
      _recalculateRoute();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xác định vị trí tại: ${result.artifactName}'),
          backgroundColor: AppColors.deepBurgundy,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingScan = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('FormatException: ', '').replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _map?.markers.where((m) =>
      m.isActive &&
      m.isDestination &&
      (_searchQuery.isEmpty || m.label.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        elevation: 0,
        leading: const BackButton(color: AppColors.deepBurgundy),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _map?.name ?? 'Sơ đồ bảo tàng',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepBurgundy),
            ),
            Text(
              widget.museumName,
              style: const TextStyle(fontSize: 11, color: AppColors.darkBrown),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined, color: AppColors.deepBurgundy),
            tooltip: 'Đổi sơ đồ tầng',
            onPressed: _showChangeMapDialog,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.deepBurgundy),
            tooltip: 'Quét QR xác định vị trí',
            onPressed: () => setState(() {
              _showQrScanner = true;
              _scannerController = MobileScannerController();
            }),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepBurgundy))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.deepBurgundy),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPublishedMap,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
                      child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
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
                    minScale: 0.4,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(300),
                    child: Center(
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

                                  // Clickable Markers Overlay
                                  ..._map!.markers.where((m) => m.isActive).map((marker) {
                                    final px = marker.x * _map!.imageWidth;
                                    final py = marker.y * _map!.imageHeight;
                                    final isSelected = _selectedDestination?.id == marker.id;
                                    final isStart = _startMarker?.id == marker.id;

                                    return Positioned(
                                      left: px - 18,
                                      top: py - 18,
                                      child: GestureDetector(
                                        onTap: () => _selectDestination(marker),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isStart
                                                ? const Color(0xFF2563EB)
                                                : isSelected
                                                ? const Color(0xFF227C64)
                                                : const Color(0xFF873C32),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: isSelected || isStart ? 3 : 2,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            marker.type == 'artifact'
                                                ? Icons.museum_outlined
                                                : Icons.place,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),

                // 2. Floating Action Controls (Fit view, My Location, QR Scan)
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'qr_scan_btn',
                        backgroundColor: const Color(0xFF7B3B31),
                        tooltip: 'Quét QR xác định vị trí',
                        onPressed: () => setState(() {
                          _showQrScanner = true;
                          _scannerController = MobileScannerController();
                        }),
                        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      if (_fromNodeId != null && _startMarker != null)
                        FloatingActionButton.small(
                          heroTag: 'my_loc_btn',
                          backgroundColor: const Color(0xFF2563EB),
                          tooltip: 'Vị trí của bạn',
                          onPressed: () => _centerOnCoordinates(_startMarker!.x, _startMarker!.y),
                          child: const Icon(Icons.my_location, color: Colors.white),
                        ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'fit_view_btn',
                        backgroundColor: Colors.white,
                        tooltip: 'Vừa khung nhìn',
                        onPressed: () {
                          _transformController.value = Matrix4.identity();
                        },
                        child: const Icon(Icons.crop_free, color: AppColors.darkBrown),
                      ),
                    ],
                  ),
                ),

                // 3. Location Status Banner
                Positioned(
                  left: 16,
                  right: 80,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _fromNodeId != null ? Icons.check_circle : Icons.info_outline,
                          size: 18,
                          color: _fromNodeId != null ? const Color(0xFF227C64) : const Color(0xFF873C32),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startArtifactName != null
                                ? 'Đang ở: $_startArtifactName'
                                : 'Chưa có vị trí. Hãy quét QR cạnh hiện vật.',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E232B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Draggable Bottom Sheet for Destinations & Navigation Info
                DraggableScrollableSheet(
                  initialChildSize: 0.28,
                  minChildSize: 0.12,
                  maxChildSize: 0.65,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Sheet grab handle
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Selected Destination Card if active
                          if (_selectedDestination != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEADCC8)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedDestination!.label,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF800020),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                        onPressed: () => setState(() {
                                          _selectedDestination = null;
                                          _routeNodeIds = [];
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Status message on route
                                  if (_fromNodeId == null)
                                    const Text(
                                      '👉 Nhấn nút Quét QR góc trên để chọn điểm xuất phát gần bạn.',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF873C32)),
                                    )
                                  else if (_fromNodeId == _selectedDestination!.nodeId)
                                    const Text(
                                      '📍 Bạn đang ở điểm tiếp cận địa điểm này.',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF227C64)),
                                    )
                                  else if (_routeNodeIds.isEmpty)
                                    const Text(
                                      'Không tìm thấy đường đi (có thể do đường một chiều hoặc lối đi xe lăn bị ngắt).',
                                      style: TextStyle(fontSize: 12, color: Colors.red),
                                    )
                                  else
                                    Text(
                                      'Đã tìm thấy lộ trình qua ${_routeNodeIds.length} điểm rẽ hành lang.',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF227C64)),
                                    ),

                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // Wheelchair filter toggle
                                      FilterChip(
                                        label: const Text('Xe lăn', style: TextStyle(fontSize: 11)),
                                        avatar: const Icon(Icons.accessible, size: 14),
                                        selected: _accessibleOnly,
                                        onSelected: (val) {
                                          setState(() => _accessibleOnly = val);
                                          _recalculateRoute();
                                        },
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        onPressed: _fromNodeId != null ? _recalculateRoute : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF7B3B31),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.navigation, size: 16),
                                        label: const Text('Chỉ đường', style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Search Bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Tìm hiện vật, phòng trưng bày...',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF8F5EE),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                          const SizedBox(height: 12),

                          // Destinations List
                          const Text(
                            'Điểm đến trên sơ đồ:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E232B)),
                          ),
                          const SizedBox(height: 8),
                          if (destinations.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('Không có địa điểm phù hợp.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          for (final marker in destinations)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: marker.type == 'artifact'
                                    ? const Color(0xFF873C32).withValues(alpha: 0.15)
                                    : const Color(0xFF2563EB).withValues(alpha: 0.15),
                                child: Icon(
                                  marker.type == 'artifact' ? Icons.museum : Icons.place,
                                  size: 14,
                                  color: marker.type == 'artifact' ? const Color(0xFF873C32) : const Color(0xFF2563EB),
                                ),
                              ),
                              title: Text(marker.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                marker.type == 'artifact' ? 'Hiện vật' : 'Tiện ích / Phòng',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                              onTap: () {
                                _selectDestination(marker);
                                _centerOnCoordinates(marker.x, marker.y);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),

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
                                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
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
                                border: Border.all(color: const Color(0xFFC5A059), width: 3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          // Close button
                          Positioned(
                            left: 16,
                            top: 40,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 28),
                              onPressed: () => setState(() {
                                _showQrScanner = false;
                                _scannerController?.dispose();
                              }),
                            ),
                          ),
                          // Torch button
                          Positioned(
                            right: 16,
                            top: 40,
                            child: IconButton(
                              icon: const Icon(Icons.flash_on, color: Colors.white, size: 28),
                              onPressed: () => _scannerController?.toggleTorch(),
                            ),
                          ),
                          // Instruction text
                          Positioned(
                            bottom: 60,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Quét tem mã QR gắn cạnh hiện vật tại tủ trưng bày để xác định điểm xuất phát.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                          if (_isProcessingScan)
                            const Center(
                              child: CircularProgressIndicator(color: Color(0xFFC5A059)),
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

    // 1. Draw subtle background corridors (edges)
    final edgePaint = Paint()
      ..color = const Color(0xFF800020).withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final edge in map.edges) {
      final u = nodeMap[edge.fromNodeId];
      final v = nodeMap[edge.toNodeId];
      if (u == null || v == null) continue;

      canvas.drawLine(
        Offset(u.x * map.imageWidth, u.y * map.imageHeight),
        Offset(v.x * map.imageWidth, v.y * map.imageHeight),
        edgePaint,
      );
    }

    // 2. Draw Dijkstra Route in Bold Green
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
    return oldDelegate.routeNodeIds != routeNodeIds ||
           oldDelegate.startNodeId != startNodeId ||
           oldDelegate.destinationMarker != destinationMarker;
  }
}
