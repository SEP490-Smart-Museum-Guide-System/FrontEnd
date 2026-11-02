import React, { useEffect, useRef, useState } from 'react';
import { normalizePoint, zoomAt } from './indoorGraph';

export default function MapCanvas({ document, imageUrl, tool, selected, onSelect, onPlace, onMove, route, disabled }) {
  const svg = useRef(null);
  const drag = useRef(null);
  const [view, setView] = useState({ x: 0, y: 0, scale: 1 });
  const width = document.imageWidth || 1000, height = document.imageHeight || 700;
  useEffect(() => {
    const canvas = svg.current;
    function wheel(event) {
      if (!event.ctrlKey || disabled || !imageUrl) return;
      // A non-passive listener prevents browser zoom only while the pointer is on the canvas.
      event.preventDefault();
      if (drag.current) return;
      const matrix = canvas.getScreenCTM();
      if (!matrix) return;
      const anchor = new DOMPoint(event.clientX, event.clientY).matrixTransform(matrix.inverse());
      const delta = event.deltaY * (event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? canvas.clientHeight : 1);
      setView(v => zoomAt(v, Math.exp(-Math.max(-1000, Math.min(1000, delta)) * 0.002), anchor));
    }
    canvas.addEventListener('wheel', wheel, { passive: false });
    return () => canvas.removeEventListener('wheel', wheel);
  }, [disabled, imageUrl]);
  function position(event) {
    const matrix = svg.current.getScreenCTM();
    if (!matrix) return null;
    return new DOMPoint(event.clientX, event.clientY).matrixTransform(matrix.inverse());
  }
  function down(event, kind, item) {
    if (disabled || !imageUrl || ![0, 1].includes(event.button) || drag.current) return;
    event.preventDefault();
    event.stopPropagation();
    const p = position(event);
    if (!p) return;
    if (event.button === 1 || (tool === 'pan' && !item) || (!tool && !item)) {
      const matrix = svg.current.getScreenCTM();
      drag.current = { pointerId: event.pointerId, pan: true, clientX: event.clientX, clientY: event.clientY, view, pixelsPerUnit: matrix.a };
    } else if (item) {
      onSelect(kind, item.id, false);
      drag.current = { pointerId: event.pointerId, kind, id: item.id, start: p, x: item.x, y: item.y, clientX: event.clientX, clientY: event.clientY, moved: false };
    } else if (tool !== 'connect' && p.x >= 0 && p.y >= 0 && p.x <= width && p.y <= height) {
      onPlace(normalizePoint(p.x, p.y, width, height));
    }
    svg.current.setPointerCapture(event.pointerId);
  }
  function move(event) {
    if (!drag.current || disabled || drag.current.pointerId !== event.pointerId) return;
    const current = drag.current;
    if (current.pan) {
      setView({ ...current.view, x: current.view.x - (event.clientX - current.clientX) / current.pixelsPerUnit, y: current.view.y - (event.clientY - current.clientY) / current.pixelsPerUnit });
    } else {
      if (!current.moved && Math.hypot(event.clientX - current.clientX, event.clientY - current.clientY) < 4) return;
      current.moved = true;
      const p = position(event);
      if (p && current.kind !== 'edges') onMove(current.kind, current.id, normalizePoint(current.x * width + p.x - current.start.x, current.y * height + p.y - current.start.y, width, height));
    }
  }
  function up(event) {
    const current = drag.current;
    if (current?.pointerId !== event.pointerId) return;
    drag.current = null;
    if (!disabled && !current.pan && !current.moved && tool === 'connect') onSelect(current.kind, current.id);
    if (svg.current.hasPointerCapture(event.pointerId)) svg.current.releasePointerCapture(event.pointerId);
  }
  function zoom(factor) {
    if (!drag.current) setView(v => zoomAt(v, factor, { x: v.x + width / v.scale / 2, y: v.y + height / v.scale / 2 }));
  }
  const radius = Math.max(width, height) / 100;
  const nodes = new Map(document.nodes.map(node => [node.id, node]));
  const routePairs = new Set((route?.nodeIds || []).slice(1).flatMap((id, i) => [`${route.nodeIds[i]}:${id}`, `${id}:${route.nodeIds[i]}`]));
  return <div>
    <div className="indoor-row">
      <button type="button" onClick={() => zoom(1.25)}>Phóng to</button>
      <button type="button" onClick={() => zoom(0.8)}>Thu nhỏ</button>
      <button type="button" onClick={() => setView({ x: 0, y: 0, scale: 1 })}>Vừa khung</button>
      <span>{Math.round(view.scale * 100)}%</span>
    </div>
    <svg ref={svg} className="indoor-canvas" viewBox={`${view.x} ${view.y} ${width / view.scale} ${height / view.scale}`}
      aria-label="Sơ đồ bảo tàng. Chọn điểm trong danh sách thuộc tính để chỉnh sửa bằng bàn phím."
      onAuxClick={e => { if (e.button === 1) e.preventDefault(); }}
      onPointerDown={e => down(e)} onPointerMove={move} onPointerUp={up}
      onPointerCancel={() => { drag.current = null; }} onLostPointerCapture={() => { drag.current = null; }}>
      {imageUrl && <image href={imageUrl} width={width} height={height} />}
      {document.edges.map(edge => {
        const a = nodes.get(edge.fromNodeId), b = nodes.get(edge.toNodeId);
        if (!a || !b) return null;
        const highlighted = routePairs.has(`${a.id}:${b.id}`);
        const active = selected?.id === edge.id;
        return <g key={edge.id} onPointerDown={e => down(e, 'edges', edge)}>
          <line x1={a.x * width} y1={a.y * height} x2={b.x * width} y2={b.y * height} stroke="transparent" strokeWidth={radius * 2} />
          <line x1={a.x * width} y1={a.y * height} x2={b.x * width} y2={b.y * height} stroke={active ? '#f59e0b' : highlighted ? '#16a34a' : '#2563eb'} strokeWidth={radius / 3} strokeDasharray={edge.isAccessible ? undefined : `${radius} ${radius / 2}`} />
          {!edge.bidirectional && <text x={(a.x + b.x) * width / 2} y={(a.y + b.y) * height / 2} fontSize={radius * 2} fill="#172554" transform={`rotate(${Math.atan2((b.y - a.y) * height, (b.x - a.x) * width) * 180 / Math.PI}, ${(a.x + b.x) * width / 2}, ${(a.y + b.y) * height / 2})`}>➤</text>}
        </g>;
      })}
      {['nodes', 'markers'].flatMap(kind => document[kind].map(item => <g key={item.id} onPointerDown={e => down(e, kind, item)}>
        <circle cx={item.x * width} cy={item.y * height} r={radius * (kind === 'markers' ? 1.15 : 0.7)}
          fill={kind === 'markers' ? '#9f1239' : '#1d4ed8'} stroke={selected?.id === item.id ? '#fbbf24' : 'white'} strokeWidth={radius / 3} />
        <text x={item.x * width + radius} y={item.y * height - radius} fontSize={radius * 1.5} stroke="white" strokeWidth={radius / 5} paintOrder="stroke" fill="#17202a">{item.label}</text>
      </g>))}
    </svg>
    <p className="indoor-hint">Giữ chuột trái trên điểm để kéo trực tiếp. Giữ nút giữa chuột (nút lăn) để kéo bản đồ; Ctrl + lăn chuột để thu/phóng tại vị trí con trỏ.</p>
    <p className="indoor-hint">Xanh: điểm dẫn đường · Đỏ: điểm đánh dấu · Xanh lá: tuyến thử. Đường nét đứt không dành cho xe lăn. Nhân viên chịu trách nhiệm tránh tường và khu vực cấm.</p>
  </div>;
}
