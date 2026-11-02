// Manual browser fixture: Vite /tests/indoorCanvas.html. No API calls or persisted data.
import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';
import MapCanvas from '../src/components/indoor_maps/MapCanvas';
import '../src/components/indoor_maps/indoorMaps.css';

const image = 'data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="500"><rect width="1000" height="500" fill="#faf3e5"/><path d="M0 250H1000M500 0V500" stroke="#b9ab91"/></svg>');
function Fixture() {
  const [tool, setTool] = useState('marker');
  const [selected, setSelected] = useState(null);
  const [connections, setConnections] = useState(0);
  const [map, setMap] = useState({ imageWidth: 1000, imageHeight: 500, nodes: [{ id: 'node', label: 'Điểm dẫn đường', x: .65, y: .5 }], markers: [{ id: 'artifact', label: 'Hiện vật có QR', x: .25, y: .5 }], edges: [] });
  return <main className="indoor-page" style={{ maxWidth: 1000, margin: 'auto', fontFamily: 'sans-serif' }}>
    <h1>Kiểm thử thao tác sơ đồ — dữ liệu tạm</h1>
    <p>Kéo hiện vật khi đang bật Thêm điểm; kéo điểm dẫn đường khi bật Nối điểm phải không tạo kết nối. Thử nút giữa chuột và Ctrl + lăn chuột trên sơ đồ.</p>
    <div className="indoor-row">{[['marker', 'Thêm điểm'], ['connect', 'Nối điểm'], ['', 'Thoát công cụ']].map(([value, label]) => <button key={value} aria-pressed={tool === value} onClick={() => setTool(value)}>{label}</button>)}</div>
    <MapCanvas document={map} imageUrl={image} tool={tool} selected={selected}
      onSelect={(kind, id, connect = true) => { setSelected({ kind, id }); if (connect && tool === 'connect') setConnections(n => n + 1); }}
      onPlace={point => setMap(prev => ({ ...prev, markers: [...prev.markers, { id: crypto.randomUUID(), label: 'Mới', ...point }] }))}
      onMove={(kind, id, point) => setMap(prev => ({ ...prev, [kind]: prev[kind].map(item => item.id === id ? { ...item, ...point } : item) }))} />
    <output aria-label="Kết quả kiểm thử">{JSON.stringify({ markers: map.markers.map(m => ({ x: m.x, y: m.y })), nodes: map.nodes.map(n => ({ x: n.x, y: n.y })), connections })}</output>
  </main>;
}
createRoot(document.getElementById('root')).render(<Fixture />);
