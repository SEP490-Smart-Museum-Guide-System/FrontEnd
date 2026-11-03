import React, { useEffect, useState } from 'react';
import { indoorApi } from '../../services/indoorMapApi';
import { markerTypes } from './indoorGraph';
import { visitorRoute } from './visitorRoute';
import './visitorMap.css';

export default function VisitorMap() {
  const id = new URLSearchParams(window.location.search).get('map');
  const preview = new URLSearchParams(window.location.search).get('preview') === 'draft';
  const [map, setMap] = useState(null);
  const [image, setImage] = useState('');
  const [error, setError] = useState(id ? '' : 'Hãy chọn bản đồ đã xuất bản từ bảo tàng.');
  const [from, setFrom] = useState('');
  const [selected, setSelected] = useState('');
  const [search, setSearch] = useState('');
  const [accessible, setAccessible] = useState(false);
  const [navigate, setNavigate] = useState(false);
  const [zoom, setZoom] = useState(1);
  useEffect(() => {
    if (!id) return;
    const controller = new AbortController(); let url;
    async function load() {
      try {
        const data = await indoorApi(`indoor-maps/${id}/${preview ? 'draft' : 'published'}`, { signal: controller.signal });
        const blob = await indoorApi(`indoor-maps/${id}/${preview ? '' : 'published/'}image?key=${encodeURIComponent(data.imageKey)}`, { blob: true, signal: controller.signal });
        if (controller.signal.aborted) return;
        url = URL.createObjectURL(blob); setImage(url); setMap(data);
      } catch (e) { if (!controller.signal.aborted) setError(e.message); }
    }
    load();
    return () => { controller.abort(); if (url) URL.revokeObjectURL(url); };
  }, [id, preview]);
  const markers = map?.markers.filter(m => m.isActive) || [];
  const target = markers.find(m => m.id === selected);
  const path = navigate && target ? visitorRoute(map, from, target.nodeId, accessible) : null;
  const start = map?.nodes.find(n => n.id === from);
  function choose(marker) { setSelected(marker.id); setNavigate(false); }
  return <div className="visitor-page">
    <header className="visitor-header"><a href="/">SMGS <span>· Bảo tàng số</span></a><span>Trải nghiệm khách tham quan</span></header>
    <main>
      <div className="visitor-intro"><div><span className="visitor-eyebrow">KHÁM PHÁ THEO CÁCH CỦA BẠN</span><h1>{map?.name || 'Bản đồ bảo tàng'}</h1><p>Chạm vào một hiện vật để tìm đường đến nơi trưng bày.</p></div><span className="visitor-badge">{id ? (preview ? 'Xem thử bản nháp đã lưu · Chỉ nhân viên' : 'Bản đã xuất bản') : 'Chưa chọn bản đồ'}</span></div>
      {error && <p role="alert" className="visitor-alert">{error} {preview ? 'Hãy đăng nhập tài khoản quản lý bảo tàng để xem bản nháp đã lưu.' : 'Hãy đăng nhập và mở bản đồ đã xuất bản từ trang quản lý.'}</p>}
      {!map && !error && <p role="status">Đang tải bản đồ…</p>}
      {map && <div className="visitor-layout">
        <aside className="visitor-panel"><h2>Bạn muốn khám phá gì?</h2>
          <label>Tìm hiện vật hoặc tiện ích<input value={search} onChange={e => setSearch(e.target.value)} placeholder="Nhập tên để tìm…" /></label>
          <div className="visitor-destinations">{markers.filter(m => m.label.toLocaleLowerCase('vi').includes(search.toLocaleLowerCase('vi'))).map(m => <button key={m.id} aria-pressed={selected === m.id} onClick={() => choose(m)}><span>{m.type === 'artifact' ? '◈' : '◎'}</span><div><strong>{m.label}</strong><small>{markerTypes[m.type] || 'Địa điểm'}</small></div><span>›</span></button>)}{!markers.some(m => m.label.toLocaleLowerCase('vi').includes(search.toLocaleLowerCase('vi'))) && <p>Không có địa điểm phù hợp.</p>}</div>
          <div className="visitor-location"><h3>Vị trí xuất phát</h3><label>Chọn vị trí để thử đường đi<select value={from} onChange={e => { setFrom(e.target.value); setNavigate(false); }}><option value="">Chọn vị trí hiện tại</option>{map.nodes.map(n => <option key={n.id} value={n.id}>{n.label}</option>)}</select></label><small>Mô phỏng vị trí sau khi quét QR. Chưa theo dõi vị trí trực tiếp.</small><label className="visitor-check"><input type="checkbox" checked={accessible} onChange={e => setAccessible(e.target.checked)} /> Lối đi phù hợp xe lăn</label></div>
        </aside>
        <section className="visitor-map-panel" aria-label="Bản đồ tham quan">
          <div className="visitor-map-heading"><strong>{map.floorId ? 'Sơ đồ tầng đang xem' : 'Mặt bằng bảo tàng'}</strong><div><button onClick={() => setZoom(z => Math.max(1, z - .25))} aria-label="Thu nhỏ">−</button><button onClick={() => setZoom(1)}>Vừa khung</button><button onClick={() => setZoom(z => Math.min(3, z + .25))} aria-label="Phóng to">+</button></div></div>
          <div className="visitor-map-scroll"><svg style={{ width: `${zoom * 100}%` }} viewBox={`0 0 ${map.imageWidth} ${map.imageHeight}`} aria-label="Chọn điểm đánh dấu trên sơ đồ">
            {image ? <image href={image} width={map.imageWidth} height={map.imageHeight} /> : <g><rect width="1000" height="650" fill="#f4f0e8"/><rect x="65" y="65" width="870" height="520" rx="28" fill="#e8dfcf" stroke="#c7baa4" strokeWidth="5"/>{[[100,100,280,170],[620,100,280,170],[390,80,220,120],[100,410,280,140],[620,410,280,140]].map(([x,y,w,h],i)=><rect key={i} x={x} y={y} width={w} height={h} rx="12" fill="#fbf8f1" stroke="#d3c7b3" strokeWidth="3"/>)}<text x="500" y="380" textAnchor="middle" fill="#97866e" fontSize="18" letterSpacing="4">KHÔNG GIAN TRƯNG BÀY</text></g>}
            {path && <polyline points={path.map(n => `${n.x*map.imageWidth},${n.y*map.imageHeight}`).join(' ')} fill="none" stroke="#227c64" strokeWidth={map.imageWidth/160} strokeLinejoin="round" strokeLinecap="round" />}
            {markers.map(m => <g key={m.id} role="button" tabIndex={0} aria-label={m.label} aria-pressed={selected === m.id} onClick={() => choose(m)} onKeyDown={e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); choose(m); } }} className="visitor-pin"><circle cx={m.x*map.imageWidth} cy={m.y*map.imageHeight} r={map.imageWidth/65} fill={selected === m.id ? '#227c64' : '#873c32'} stroke="white" strokeWidth={map.imageWidth/300}/><text x={m.x*map.imageWidth} y={m.y*map.imageHeight+map.imageWidth/200} textAnchor="middle" fill="white" fontSize={map.imageWidth/60}>◈</text><title>{m.label}</title></g>)}
            {start && <g><circle cx={start.x*map.imageWidth} cy={start.y*map.imageHeight} r={map.imageWidth/90} fill="#2563eb" stroke="white" strokeWidth={map.imageWidth/300}/><text x={start.x*map.imageWidth} y={start.y*map.imageHeight+map.imageWidth/30} textAnchor="middle" fontSize={map.imageWidth/65} fill="#1e40af">Bạn ở đây</text></g>}
          </svg></div>
          <div className="visitor-legend"><span>🔵 Vị trí xuất phát</span><span>◆ Hiện vật / tiện ích</span><span>━ Tuyến di chuyển</span></div>
          <div className="visitor-detail">{target ? <><div><small>{markerTypes[target.type]}</small><h2>{target.label}</h2><p>{target.nodeId && target.isDestination ? 'Tìm đường đến vị trí tiếp cận địa điểm này.' : 'Địa điểm này chưa hỗ trợ dẫn đường.'}</p></div><button className="visitor-primary" disabled={!from || !target.nodeId || !target.isDestination} onClick={() => setNavigate(true)}>Chỉ đường đến đây →</button></> : <p>Chọn một điểm trên bản đồ hoặc trong danh sách để bắt đầu.</p>}</div>
          {navigate && <div className="visitor-route" role="status">{path ? <><strong>{path.length === 1 ? 'Bạn đang ở điểm tiếp cận địa điểm này.' : `Đi theo đường màu xanh đến ${target.label}.`}</strong><p>Tuyến kết thúc tại {path.at(-1).label}. Quan sát vị trí hiện vật trên sơ đồ khi đến nơi.</p></> : <p>Không tìm được đường phù hợp. Thử vị trí xuất phát khác{accessible ? ' hoặc kiểm tra tùy chọn xe lăn' : ''}.</p>}</div>}
        </section>
      </div>}
      <footer className="visitor-footer">Trang thử giao diện · Dẫn đường trong một sơ đồ, chưa kết nối xuyên tầng.</footer>
    </main>
  </div>;
}
