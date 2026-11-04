import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/visitor_experience_api.dart';
import '../artifact/artifact_qr_scanner.dart';
import 'visitor_indoor_map_screen.dart';

class VisitorDirectoryScreen extends StatefulWidget {
  const VisitorDirectoryScreen({
    super.key,
    required this.museumId,
    this.museumName = 'Bảo tàng',
    this.initialArtifactId,
    this.visitId,
  });
  final int museumId;
  final String museumName;
  final int? initialArtifactId, visitId;
  @override
  State<VisitorDirectoryScreen> createState() => _VisitorDirectoryScreenState();
}

class _VisitorDirectoryScreenState extends State<VisitorDirectoryScreen> {
  String _query = '';
  int? _floor, _gallery;
  int? get _visitId {
    if (widget.visitId != null) return widget.visitId;
    final active = VisitorSession.activeVisit;
    if (active == null ||
        active['museumId'] != widget.museumId ||
        active['status'] != 'InProgress') {
      return null;
    }
    return (active['id'] as num?)?.toInt();
  }

  List<Map<String, dynamic>> _rows(dynamic value) => (value as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  String _location(Map<String, dynamic> a) => [
    a['galleryName'],
    a['floorName'],
    a['buildingName'],
  ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
  void _openMap(Map<String, dynamic> map, {int? artifactId}) => openPage(
    context,
    VisitorIndoorMapScreen(
      mapId: map['id'],
      museumName: widget.museumName,
      visitId: _visitId,
      targetArtifactId: artifactId,
    ),
  );

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Tìm hiện vật & chỉ đường',
    subtitle: widget.museumName,
    children: [
      const Notice(
        'Xem hiện vật nằm ở phòng và tầng nào. Quét QR tại vị trí đang đứng để tìm đường trên sơ đồ.',
      ),
      const SizedBox(height: 16),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Tìm hiện vật hoặc phòng trưng bày',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Quét QR xác định vị trí',
        icon: Icons.qr_code_scanner,
        onPressed: () =>
            openPage(context, ArtifactQrScanner(visitId: _visitId)),
      ),
      const SizedBox(height: 16),
      BackendPanel(
        resourceKey: 'visitor-directory:${widget.museumId}',
        load: () =>
            BackendApi.request('museums/${widget.museumId}/visitor-directory'),
        builder: (data, reload) {
          final directory = Map<String, dynamic>.from(data as Map);
          final rooms = _rows(directory['galleries']);
          final maps = _rows(directory['maps']);
          final artifacts = _rows(directory['artifacts']);
          final floors = <int, String>{};
          for (final room in rooms) {
            floors[room['floorId'] as int] =
                '${room['buildingName']} · ${room['floorName'] ?? 'Tầng ${room['levelNo']}'}';
          }
          final floor = floors.containsKey(_floor) ? _floor : null;
          final availableRooms = rooms
              .where((r) => floor == null || r['floorId'] == floor)
              .toList();
          final gallery = availableRooms.any((r) => r['id'] == _gallery)
              ? _gallery
              : null;
          final filtered =
              artifacts
                  .where(
                    (a) =>
                        (floor == null || a['floorId'] == floor) &&
                        (gallery == null || a['galleryId'] == gallery) &&
                        '${a['name']} ${_location(a)}'.toLowerCase().contains(
                          _query,
                        ),
                  )
                  .toList()
                ..sort((a, b) {
                  final priority = (a['id'] == widget.initialArtifactId ? 0 : 1)
                      .compareTo(b['id'] == widget.initialArtifactId ? 0 : 1);
                  return priority != 0
                      ? priority
                      : a['name'].toString().compareTo(b['name'].toString());
                });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: reload,
                child: const Text('Cập nhật vị trí & sơ đồ'),
              ),
              if (floors.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  key: ValueKey('floor:$floor'),
                  initialValue: floor,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tòa nhà / tầng',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tất cả tầng'),
                    ),
                    ...floors.entries.map(
                      (f) => DropdownMenuItem(
                        value: f.key,
                        child: Text(
                          f.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _floor = value;
                    _gallery = null;
                  }),
                ),
                const SizedBox(height: 12),
              ],
              if (availableRooms.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  key: ValueKey('gallery:$floor:$gallery'),
                  initialValue: gallery,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Phòng trưng bày',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tất cả phòng'),
                    ),
                    ...availableRooms.map(
                      (r) => DropdownMenuItem<int>(
                        value: r['id'] as int,
                        child: Text(
                          r['name'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _gallery = value),
                ),
                const SizedBox(height: 12),
              ],
              SectionHeading('Hiện vật · ${filtered.length}'),
              if (filtered.isEmpty)
                const Notice(
                  'Chưa có hiện vật phù hợp. Thử đổi từ khóa hoặc bộ lọc.',
                ),
              for (final artifact in filtered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Panel(
                    gold: artifact['id'] == widget.initialArtifactId,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          artifact['name'].toString(),
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _location(artifact).isEmpty
                              ? 'Bảo tàng chưa cập nhật phòng trưng bày.'
                              : _location(artifact),
                        ),
                        const SizedBox(height: 12),
                        if (_rows(artifact['maps']).isEmpty)
                          const Notice(
                            'Hiện vật chưa được liên kết với điểm đến trên sơ đồ đã xuất bản.',
                          )
                        else
                          for (final map in _rows(artifact['maps']))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SecondaryButton(
                                label: 'Chỉ đường · ${map['name']}',
                                icon: Icons.directions_walk,
                                onPressed: () => _openMap(
                                  map,
                                  artifactId: artifact['id'] as int,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              const SectionHeading('Sơ đồ đã xuất bản'),
              if (maps.isEmpty)
                const Notice(
                  'Bảo tàng chưa xuất bản sơ đồ. Sơ đồ nháp của nhân viên chưa hiển thị cho khách.',
                ),
              for (final map in maps)
                ActionTile(
                  title: map['name'].toString(),
                  subtitle: [
                    map['buildingName'],
                    map['floorName'],
                  ].whereType<String>().join(' · '),
                  icon: Icons.map_outlined,
                  onTap: () => _openMap(map),
                ),
            ],
          );
        },
      ),
    ],
  );
}
