import 'package:flutter/material.dart';
import '../models/artifact.dart';
import 'museum_ui.dart';

// Ordered itinerary only. Spatial directions require a published indoor map.
class MuseumRouteMap extends StatelessWidget {
  const MuseumRouteMap({
    super.key,
    required this.stops,
    required this.current,
    this.visited = const [],
    this.skipped = const [],
  });
  final List<Artifact> stops;
  final int current;
  final List<String> visited, skipped;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Thứ tự các điểm dừng'),
        const SizedBox(height: 12),
        for (var i = 0; i < stops.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(stops[i].name),
            subtitle: Text(
              '${stops[i].location} · ${visited.contains(stops[i].id)
                  ? 'Đã xem trong phiên'
                  : skipped.contains(stops[i].id)
                  ? 'Đã bỏ qua'
                  : i == current
                  ? 'Đang chọn'
                  : 'Chưa xem'}',
            ),
          ),
      ],
    ),
  );
}
