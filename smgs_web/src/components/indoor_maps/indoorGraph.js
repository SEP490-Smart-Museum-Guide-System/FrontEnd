export const nodeTypes = { corridor: 'Hành lang', intersection: 'Ngã rẽ', door: 'Cửa phòng', entrance: 'Lối vào', stair: 'Cầu thang', elevator: 'Thang máy' };
export const markerTypes = { artifact: 'Hiện vật (có QR)', gallery: 'Phòng trưng bày', entrance: 'Lối vào', exit: 'Lối ra', restroom: 'Nhà vệ sinh', information: 'Quầy thông tin', stair: 'Cầu thang', elevator: 'Thang máy' };

export function zoomAt(view, factor, anchor) {
  const scale = Math.min(8, Math.max(0.5, view.scale * factor));
  const ratio = view.scale / scale;
  return { scale, x: anchor.x - (anchor.x - view.x) * ratio, y: anchor.y - (anchor.y - view.y) * ratio };
}

export function normalizePoint(x, y, width, height) {
  return { x: Math.max(0, Math.min(1, x / width)), y: Math.max(0, Math.min(1, y / height)) };
}

export function removeObject(draft, kind, id) {
  if (kind !== 'nodes') return { ...draft, [kind]: draft[kind].filter(item => item.id !== id) };
  return {
    ...draft,
    nodes: draft.nodes.filter(node => node.id !== id),
    edges: draft.edges.filter(edge => edge.fromNodeId !== id && edge.toNodeId !== id),
    markers: draft.markers.map(marker => marker.nodeId === id ? { ...marker, nodeId: null } : marker),
  };
}

export function hasOverlappingEdge(edges, from, to, bidirectional = true) {
  return edges.some(edge => (edge.fromNodeId === from && edge.toNodeId === to) ||
    (edge.fromNodeId === to && edge.toNodeId === from && (edge.bidirectional || bidirectional)));
}
