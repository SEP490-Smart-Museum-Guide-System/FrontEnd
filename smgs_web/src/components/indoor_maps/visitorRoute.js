export function visitorRoute(map, from, to, accessible) {
  const nodes = new Map(map.nodes.map(n => [n.id, n]));
  if (!nodes.has(from) || !nodes.has(to)) return null;
  const pending = new Set(nodes.keys()), distances = new Map([[from, 0]]), previous = new Map();
  const adjacency = new Map(map.nodes.map(n => [n.id, []]));
  for (const e of map.edges) {
    if (accessible && !e.isAccessible) continue;
    if (!nodes.has(e.fromNodeId) || !nodes.has(e.toNodeId)) continue;
    adjacency.get(e.fromNodeId).push(e.toNodeId);
    if (e.bidirectional) adjacency.get(e.toNodeId).push(e.fromNodeId);
  }
  while (pending.size) {
    let current, best = Infinity;
    for (const id of pending) if ((distances.get(id) ?? Infinity) < best) { current = id; best = distances.get(id); }
    if (current === undefined) return null;
    if (current === to) {
      const path = [to];
      while (path[0] !== from) path.unshift(previous.get(path[0]));
      return path.map(id => nodes.get(id));
    }
    pending.delete(current);
    for (const next of adjacency.get(current)) {
      const a = nodes.get(current), b = nodes.get(next);
      const cost = best + Math.hypot((a.x - b.x) * map.imageWidth, (a.y - b.y) * map.imageHeight);
      if (cost < (distances.get(next) ?? Infinity)) { distances.set(next, cost); previous.set(next, current); }
    }
  }
  return null;
}
