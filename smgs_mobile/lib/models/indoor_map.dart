import 'dart:math' as math;

class IndoorNode {
  final String id;
  final String label;
  final String type;
  final double x;
  final double y;

  const IndoorNode({
    required this.id,
    required this.label,
    required this.type,
    required this.x,
    required this.y,
  });

  factory IndoorNode.fromJson(Map<String, dynamic> json) => IndoorNode(
    id: json['id']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    type: json['type']?.toString() ?? 'corridor',
    x: (json['x'] as num?)?.toDouble() ?? 0.0,
    y: (json['y'] as num?)?.toDouble() ?? 0.0,
  );
}

class IndoorMarker {
  final String id;
  final String label;
  final String type;
  final double x;
  final double y;
  final int? artifactId;
  final int? galleryId;
  final String? nodeId;
  final bool isDestination;
  final bool isActive;

  const IndoorMarker({
    required this.id,
    required this.label,
    required this.type,
    required this.x,
    required this.y,
    this.artifactId,
    this.galleryId,
    this.nodeId,
    this.isDestination = true,
    this.isActive = true,
  });

  factory IndoorMarker.fromJson(Map<String, dynamic> json) => IndoorMarker(
    id: json['id']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    type: json['type']?.toString() ?? 'artifact',
    x: (json['x'] as num?)?.toDouble() ?? 0.0,
    y: (json['y'] as num?)?.toDouble() ?? 0.0,
    artifactId: (json['artifactId'] as num?)?.toInt(),
    galleryId: (json['galleryId'] as num?)?.toInt(),
    nodeId: json['nodeId']?.toString(),
    isDestination: json['isDestination'] == true,
    isActive: json['isActive'] == true,
  );
}

class IndoorEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final bool bidirectional;
  final bool isAccessible;

  const IndoorEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.bidirectional = true,
    this.isAccessible = true,
  });

  factory IndoorEdge.fromJson(Map<String, dynamic> json) => IndoorEdge(
    id: json['id']?.toString() ?? '',
    fromNodeId: json['fromNodeId']?.toString() ?? '',
    toNodeId: json['toNodeId']?.toString() ?? '',
    bidirectional: json['bidirectional'] == true,
    isAccessible: json['isAccessible'] == true,
  );
}

class PublishedIndoorMap {
  final dynamic id;
  final int museumId;
  final int? floorId;
  final String name;
  final int revision;
  final String? imageKey;
  final double imageWidth;
  final double imageHeight;
  final String? publishedAt;
  final List<IndoorNode> nodes;
  final List<IndoorMarker> markers;
  final List<IndoorEdge> edges;

  const PublishedIndoorMap({
    required this.id,
    required this.museumId,
    this.floorId,
    required this.name,
    required this.revision,
    this.imageKey,
    required this.imageWidth,
    required this.imageHeight,
    this.publishedAt,
    required this.nodes,
    required this.markers,
    required this.edges,
  });

  factory PublishedIndoorMap.fromJson(Map<String, dynamic> json) {
    return PublishedIndoorMap(
      id: json['id'],
      museumId: (json['museumId'] as num?)?.toInt() ?? 0,
      floorId: (json['floorId'] as num?)?.toInt(),
      name: json['name']?.toString() ?? 'Sơ đồ bảo tàng',
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      imageKey: json['imageKey']?.toString(),
      imageWidth: (json['imageWidth'] as num?)?.toDouble() ?? 1200.0,
      imageHeight: (json['imageHeight'] as num?)?.toDouble() ?? 800.0,
      publishedAt: json['publishedAt']?.toString(),
      nodes: (json['nodes'] as List?)?.map((n) => IndoorNode.fromJson(n)).toList() ?? [],
      markers: (json['markers'] as List?)?.map((m) => IndoorMarker.fromJson(m)).toList() ?? [],
      edges: (json['edges'] as List?)?.map((e) => IndoorEdge.fromJson(e)).toList() ?? [],
    );
  }
}

class _WeightedNeighbor {
  final String id;
  final double weight;
  const _WeightedNeighbor(this.id, this.weight);
}

class _NodeDist {
  final String id;
  final double dist;
  const _NodeDist(this.id, this.dist);
}

/// Dijkstra Shortest Path Router on Published Graph (Section 7.5)
class DijkstraRouter {
  static List<String> findShortestPath({
    required List<IndoorNode> nodes,
    required List<IndoorEdge> edges,
    required String startNodeId,
    required String targetNodeId,
    required double imageWidth,
    required double imageHeight,
    bool accessibleOnly = false,
  }) {
    if (startNodeId == targetNodeId) return [startNodeId];

    final nodeMap = {for (final n in nodes) n.id: n};
    if (!nodeMap.containsKey(startNodeId) || !nodeMap.containsKey(targetNodeId)) {
      return [];
    }

    // Build adjacency list with euclidean pixel distance
    final adj = <String, List<_WeightedNeighbor>>{};
    for (final node in nodes) {
      adj[node.id] = [];
    }

    for (final edge in edges) {
      if (accessibleOnly && !edge.isAccessible) continue;
      final u = nodeMap[edge.fromNodeId];
      final v = nodeMap[edge.toNodeId];
      if (u == null || v == null) continue;

      // Distance in pixels: sqrt(((x1-x2)*w)^2 + ((y1-y2)*h)^2)
      final dx = (u.x - v.x) * imageWidth;
      final dy = (u.y - v.y) * imageHeight;
      final weight = math.sqrt(dx * dx + dy * dy);

      adj[u.id]?.add(_WeightedNeighbor(v.id, weight));
      if (edge.bidirectional) {
        adj[v.id]?.add(_WeightedNeighbor(u.id, weight));
      }
    }

    final dist = <String, double>{for (final n in nodes) n.id: double.infinity};
    final prev = <String, String?>{for (final n in nodes) n.id: null};
    final visited = <String>{};

    dist[startNodeId] = 0;
    final pq = <_NodeDist>[_NodeDist(startNodeId, 0)];

    while (pq.isNotEmpty) {
      pq.sort((a, b) => a.dist.compareTo(b.dist));
      final current = pq.removeAt(0);

      if (visited.contains(current.id)) continue;
      visited.add(current.id);

      if (current.id == targetNodeId) break;

      for (final neighbor in adj[current.id] ?? []) {
        if (visited.contains(neighbor.id)) continue;
        final newDist = dist[current.id]! + neighbor.weight;
        if (newDist < dist[neighbor.id]!) {
          dist[neighbor.id] = newDist;
          prev[neighbor.id] = current.id;
          pq.add(_NodeDist(neighbor.id, newDist));
        }
      }
    }

    if (dist[targetNodeId] == double.infinity) return [];

    final path = <String>[];
    String? curr = targetNodeId;
    while (curr != null) {
      path.insert(0, curr);
      curr = prev[curr];
    }
    return path;
  }
}
