import 'package:flutter/material.dart';

import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/visitor_experience_api.dart';
import '../../services/museum_presence_api.dart';
import 'visitor_indoor_map_screen.dart';

class VisitorDirectoryScreen extends StatefulWidget {
  const VisitorDirectoryScreen({
    super.key,
    required this.museumId,
    this.museumName = 'Bảo tàng',
    this.initialArtifactId,
    this.initialMapId,
    this.visitId,
  });
  final int museumId;
  final String museumName;
  final int? initialArtifactId, initialMapId, visitId;
  @override
  State<VisitorDirectoryScreen> createState() => _VisitorDirectoryScreenState();
}

class _VisitorDirectoryScreenState extends State<VisitorDirectoryScreen> {
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

  Future<dynamic> _loadDirectory() async {
    final directory = Map<String, dynamic>.from(
      await BackendApi.request('museums/${widget.museumId}/visitor-directory'),
    );
    final rooms = (directory['galleries'] as List).cast<Map>();
    final maps =
        (directory['maps'] as List).map((m) {
          final room = rooms
              .where((r) => r['floorId'] == m['floorId'])
              .firstOrNull;
          return <String, dynamic>{
            ...Map<String, dynamic>.from(m),
            'buildingName': m['buildingName'] ?? room?['buildingName'],
            'floorName': m['floorName'] ?? room?['floorName'],
            'levelNo': room?['levelNo'],
          };
        }).toList()..sort((a, b) {
          final building = (a['buildingName'] ?? '').toString().compareTo(
            (b['buildingName'] ?? '').toString(),
          );
          return building != 0
              ? building
              : ((a['levelNo'] as int?) ?? 999).compareTo(
                  (b['levelNo'] as int?) ?? 999,
                );
        });
    directory['maps'] = maps;
    if (maps.isEmpty) return directory;
    final target = (directory['artifacts'] as List)
        .where((a) => a['id'] == widget.initialArtifactId)
        .firstOrNull;
    dynamic preferred =
        widget.initialMapId ?? (target?['maps'] as List?)?.firstOrNull?['id'];
    if (preferred == null) {
      try {
        final presence = await MuseumPresenceApi.current(
          widget.museumId,
          visitId: _visitId,
        );
        preferred =
            presence['mapId'] ??
            maps
                .where((m) => m['floorId'] == presence['floorId'])
                .firstOrNull?['id'];
      } catch (_) {
        /* Location is optional for browsing. */
      }
    }
    directory['initialMap'] =
        maps.where((m) => m['id'] == preferred).firstOrNull ?? maps.first;
    return directory;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BackendPanel(
      resourceKey: 'directory:${widget.museumId}',
      load: _loadDirectory,
      builder: (raw, reload) {
        final directory = Map<String, dynamic>.from(raw);
        final map = directory['initialMap'];
        if (map == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sơ đồ bảo tàng')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bảo tàng chưa xuất bản sơ đồ.'),
                  TextButton(onPressed: reload, child: const Text('Tải lại')),
                ],
              ),
            ),
          );
        }
        return VisitorIndoorMapScreen(
          mapId: map['id'],
          directory: directory,
          museumName: directory['museumName'] ?? widget.museumName,
          visitId: _visitId,
          targetArtifactId: widget.initialArtifactId,
        );
      },
    ),
  );
}
