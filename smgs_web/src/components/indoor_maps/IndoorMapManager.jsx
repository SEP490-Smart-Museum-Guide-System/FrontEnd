import StructureManager from './StructureManager';
import { uploadMedia } from '../../services/mediaApi';
import React, { useEffect, useRef, useState } from 'react';
import { useApp } from '../../context/AppContext';
import { indoorApi } from '../../services/indoorMapApi';
import MapCanvas from './MapCanvas';
import { hasOverlappingEdge, markerTypes, nodeTypes, removeObject } from './indoorGraph';
import './indoorMaps.css';

const tools = { marker: 'Thêm điểm đánh dấu', node: 'Thêm điểm dẫn đường', connect: 'Nối điểm', stair: 'Thêm cầu thang', elevator: 'Thêm thang máy', pan: 'Kéo sơ đồ' };

export default function IndoorMapManager() {
  const { currentRole, registerNavigationGuard } = useApp();
  const [museums, setMuseums] = useState([]);
  const [museumId, setMuseumId] = useState('');
  const [structure, setStructure] = useState(null);
  const [maps, setMaps] = useState([]);
  const [map, setMap] = useState(null);
  const [links, setLinks] = useState({ artifacts: [], galleries: [] });
  const [imageUrl, setImageUrl] = useState('');
  const [uploadProgress, setUploadProgress] = useState(null);
  const [busy, setBusy] = useState(true);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [dirty, setDirty] = useState(false);
  const [tool, setTool] = useState('');
  const [selected, setSelected] = useState(null);
  const [connectFrom, setConnectFrom] = useState(null);
  const [route, setRoute] = useState(null);
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [accessible, setAccessible] = useState(false);
  const [floorId, setFloorId] = useState('');
  const [buildingId, setBuildingId] = useState('');
  const [buildingName, setBuildingName] = useState('');
  const [floorName, setFloorName] = useState('');
  const [level, setLevel] = useState('0');
  const [staffId, setStaffId] = useState('');
  const alive = useRef(true);

  useEffect(() => {
    alive.current = true;
    const controller = new AbortController();
    indoorApi('me/museums', { signal: controller.signal }).then(items => {
      setMuseums(items); if (items.length) setMuseumId(String(items[0].id));
    }).catch(e => { if (e.name !== 'AbortError') setError(e.message); }).finally(() => { if (!controller.signal.aborted) setBusy(false); });
    return () => { alive.current = false; controller.abort(); };
  }, []);

  useEffect(() => {
    if (!museumId) return;
    const controller = new AbortController();
    Promise.all([
      indoorApi(`museums/${museumId}/indoor-structure`, { signal: controller.signal }),
      indoorApi(`museums/${museumId}/indoor-maps`, { signal: controller.signal }),
    ]).then(([s, list]) => { setStructure(s); setMaps(list); }).catch(e => {
      if (e.name !== 'AbortError') setError(e.message);
    }).finally(() => { if (!controller.signal.aborted) setBusy(false); });
    return () => controller.abort();
  }, [museumId]);

  useEffect(() => {
    if (!map?.imageKey) return;
    const controller = new AbortController(); let url;
    indoorApi(`indoor-maps/${map.id}/image?key=${encodeURIComponent(map.imageKey)}`, { blob: true, signal: controller.signal }).then(blob => {
      if (controller.signal.aborted) return;
      url = URL.createObjectURL(blob); setImageUrl(url);
    }).catch(e => { if (e.name !== 'AbortError') setError(e.message); });
    return () => { controller.abort(); if (url) URL.revokeObjectURL(url); };
  }, [map?.id, map?.imageKey]);

  useEffect(() => {
    const guard = () => !busy && (!dirty || window.confirm('Bạn có thay đổi chưa lưu. Rời trang và bỏ các thay đổi này?'));
    const unregister = registerNavigationGuard(guard);
    const unload = event => { if (dirty || busy) { event.preventDefault(); event.returnValue = ''; } };
    window.addEventListener('beforeunload', unload);
    return () => { unregister(); window.removeEventListener('beforeunload', unload); };
  }, [dirty, busy, registerNavigationGuard]);

  async function run(action) {
    if (busy) return;
    setBusy(true); setError(''); setMessage('');
    try { await action(); } catch (e) { if (alive.current) setError(e.message); }
    finally { if (alive.current) setBusy(false); }
  }
  function discard() { return !dirty || window.confirm('Bỏ các thay đổi chưa lưu để tiếp tục?'); }
  async function refreshStructure() { setStructure(await indoorApi(`museums/${museumId}/indoor-structure`)); }
  async function refreshMaps() { setMaps(await indoorApi(`museums/${museumId}/indoor-maps`)); }
  async function open(id) {
    const [document, options] = await Promise.all([indoorApi(`indoor-maps/${id}/draft`), indoorApi(`indoor-maps/${id}/links`)]);
    setImageUrl(''); setMap(document); setLinks(options); setDirty(false); setSelected(null); setRoute(null); setConnectFrom(null); setTool(''); setFrom(''); setTo('');
  }
  function change(update) { setMap(prev => typeof update === 'function' ? update(prev) : update); setDirty(true); setRoute(null); }
  function update(kind, id, patch) { change(prev => ({ ...prev, [kind]: prev[kind].map(item => item.id === id ? { ...item, ...patch } : item) })); }
  async function save() {
    const result = await indoorApi(`indoor-maps/${map.id}/draft`, { method: 'PUT', body: { revision: map.revision, nodes: map.nodes, markers: map.markers, edges: map.edges } });
    setMap(result); setDirty(false); return result;
  }
  function select(kind, id, connect = true) {
    if (connect && tool === 'connect' && kind === 'nodes') {
      if (!connectFrom) { setConnectFrom(id); setSelected({ kind, id }); setMessage('Chọn điểm dẫn đường thứ hai.'); }
      else if (id === connectFrom) setError('Không thể nối một điểm với chính nó.');
      else if (hasOverlappingEdge(map.edges, connectFrom, id)) setError('Hai điểm đã có đoạn nối.');
      else {
        const edge = { id: crypto.randomUUID(), fromNodeId: connectFrom, toNodeId: id, bidirectional: true, isAccessible: true };
        change(prev => ({ ...prev, edges: [...prev.edges, edge] })); setConnectFrom(null); setSelected({ kind: 'edges', id: edge.id }); setMessage('Đã nối hai điểm.');
      }
    } else setSelected({ kind, id });
  }
  function place(point) {
    const id = crypto.randomUUID();
    if (tool === 'node' || tool === 'stair' || tool === 'elevator') {
      const type = tool === 'node' ? 'corridor' : tool;
      change(prev => ({ ...prev, nodes: [...prev.nodes, { id, ...point, type, label: `${nodeTypes[type]} ${prev.nodes.length + 1}` }] }));
      setSelected({ kind: 'nodes', id });
    } else if (tool === 'marker') {
      change(prev => ({ ...prev, markers: [...prev.markers, { id, ...point, type: 'artifact', label: `Hiện vật ${prev.markers.length + 1}`, isActive: true, isDestination: true }] }));
      setSelected({ kind: 'markers', id });
    }
    setTool('');
  }
  function remove() {
    if (!selected) return;
    const prompt = selected.kind === 'nodes' ? 'Xóa điểm này và các đoạn nối liên quan? Các điểm đánh dấu liên kết sẽ cần chọn lại điểm dẫn đường.' : 'Xóa đối tượng đang chọn?';
    if (!window.confirm(prompt)) return;
    change(prev => removeObject(prev, selected.kind, selected.id)); setSelected(null); setConnectFrom(null);
  }
  async function upload(file) {
    if (!file) return;
    if (!/\.(png|jpe?g|webp)$/i.test(file.name) || file.size > 10 * 1024 * 1024) throw new Error('Hãy chọn ảnh PNG/JPG/WebP không quá 10 MB.');
    if (dirty) throw new Error('Hãy lưu bản nháp trước khi thay ảnh.');
    const bitmap = await createImageBitmap(file);
    const differs = map.imageWidth > 0 && Math.abs(bitmap.width / bitmap.height - map.imageWidth / map.imageHeight) > 0.001;
    bitmap.close();
    if (differs && !window.confirm('Ảnh mới có tỷ lệ khác. Các điểm đã đặt có thể lệch vị trí. Bạn có muốn thay ảnh?')) return;
    const form = new FormData(); form.append('file', file); form.append('revision', map.revision); form.append('confirm', String(differs));
    let uploaded;
    setUploadProgress(0);
    try { uploaded = await uploadMedia(`indoor-maps/${map.id}/image`, form, setUploadProgress); }
    finally { setUploadProgress(null); }
    setImageUrl(''); setMap(uploaded); setRoute(null); setMessage('Đã lưu ảnh sơ đồ.');
  }
  async function downloadQr() {
    const blob = await indoorApi(`indoor-maps/${map.id}/qr/${selected.id}`, { blob: true });
    const url = URL.createObjectURL(blob); const a = window.document.createElement('a'); a.href = url; a.download = `qr-hien-vat-${item.artifactId}.png`; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  const item = selected && map?.[selected.kind].find(object => object.id === selected.id);
  const options = items => items.map(option => <option key={option.id} value={option.id}>{option.name || option.label}</option>);

  return <section className="indoor-page" onKeyDown={e => { if (e.key === 'Escape') { setTool(''); setConnectFrom(null); } }}>
    <h1>Bản đồ trong bảo tàng</h1>
    <a href={map ? `/visitor-map?map=${map.id}&preview=draft` : '/visitor-map'} target="_blank" rel="noreferrer">Xem thử phía khách {map ? '(bản nháp đã lưu)' : '(bản đồ mẫu)'} ↗</a>
    <p>Quản lý sơ đồ, điểm thông tin và đường đi trong phạm vi bảo tàng được phân công.</p>
    
    {error && <div className="indoor-error" role="alert">{error}</div>}
    {message && <div className="indoor-message" role="status">{message}</div>}
    {busy && <p role="status">Đang xử lý…</p>}
    {uploadProgress !== null && <progress value={uploadProgress} max="100" aria-label="Tiến trình tải sơ đồ" />}
    {!busy && !museums.length && <p>Bạn chưa được phân công quản lý bảo tàng. Liên hệ quản trị viên để được cấp quyền.</p>}
    <fieldset disabled={busy}>
      <label>Bảo tàng<select value={museumId} onChange={e => { if (discard()) { setDirty(false); setStructure(null); setMap(null); setMaps([]); setFloorId(''); setBuildingId(''); setError(''); setBusy(!!e.target.value); setMuseumId(e.target.value); } }}><option value="">Chọn bảo tàng</option>{options(museums)}</select></label>

      {structure?.layout === 'unknown' && <div className="indoor-box"><h2>Xác định cấu trúc bảo tàng</h2>
        <p>Chưa có thông tin phân tầng. Chọn theo cấu trúc thực tế; hệ thống không tự tạo tầng.</p>
        <div className="indoor-row">{[['single', 'Dùng mặt bằng chung, không phân tầng'], ['floors', 'Quản lý theo tòa nhà và tầng']].map(([value, label]) =>
          <button key={value} type="button" onClick={() => run(async () => { await indoorApi(`museums/${museumId}/indoor-structure`, { method: 'PUT', body: { layout: value } }); await refreshStructure(); })}>{label}</button>)}</div>
      </div>}
      {structure?.layout === 'floors' && !structure.floors.length && (
        <div className="indoor-box" style={{ padding: '16px', background: '#FEF3C7', border: '1px solid #FCD34D', borderRadius: '8px', color: '#92400E' }}>
          <strong>Chưa có tầng thực tế:</strong> Bảo tàng chưa có danh sách tầng để liên kết sơ đồ. Vui lòng vào trang <strong>Cấu trúc bảo tàng</strong> để tạo tòa nhà và các tầng.
        </div>
      )}
      {structure && structure.layout !== 'unknown' && <div className="indoor-row indoor-box">
        <label>Sơ đồ hiện có<select value={map?.id || ''} onChange={e => { const id = e.target.value; if (id && discard()) run(() => open(id)); }}><option value="">Chọn sơ đồ</option>{maps.map(m => <option key={m.id} value={m.id}>{m.name} — {m.publishedAt ? 'Đã xuất bản' : 'Bản nháp'}</option>)}</select></label>
        {structure.layout === 'floors' && <label>Tầng cần tạo sơ đồ<select value={floorId} onChange={e => setFloorId(e.target.value)}><option value="">Chọn tầng thực tế</option>{structure.floors.filter(f => !maps.some(m => m.floorId === f.id)).map(f => <option key={f.id} value={f.id}>{f.buildingName} / {f.name || `Tầng ${f.levelNo}`}</option>)}</select></label>}
        <button type="button" disabled={structure.layout === 'floors' ? !floorId : maps.length > 0} onClick={() => {
          if (!discard()) return;
          run(async () => { const floor = structure.floors.find(f => f.id === Number(floorId));
            const id = await indoorApi(`museums/${museumId}/indoor-maps`, { method: 'POST', body: { floorId: structure.layout === 'floors' ? Number(floorId) : null, name: (floor ? `${floor.buildingName} / ${floor.name || `Tầng ${floor.levelNo}`}` : 'Sơ đồ bảo tàng').slice(0, 200) } });
            await refreshMaps(); await open(id); setFloorId('');
          });
        }}>Tạo sơ đồ</button>
      </div>}
      {map && <>
        <div className="indoor-row"><h2>{map.name}</h2><span>{map.publishedAt ? 'Có bản đã xuất bản' : 'Bản nháp'} · Phiên bản {map.revision}{dirty ? ' · Chưa lưu' : ''}</span></div>
        <div className="indoor-row indoor-box">
          <label>Ảnh sơ đồ (PNG/JPG/WebP, tối đa 10 MB)<input type="file" accept=".png,.jpg,.jpeg,.webp" disabled={dirty || busy} onChange={e => { const file = e.target.files[0]; e.target.value = ''; run(() => upload(file)); }} /></label>
          <button type="button" onClick={() => run(async () => { await save(); setMessage('Đã lưu bản nháp.'); })}>Lưu bản nháp</button>
          <button type="button" onClick={() => { if (discard()) run(() => open(map.id)); }}>Tải lại</button>
          <button type="button" disabled={dirty || !map.imageKey} onClick={() => run(async () => {
            if (!window.confirm('Xuất bản cấu hình đã lưu để khách tham quan sử dụng?')) return;
            const result = await indoorApi(`indoor-maps/${map.id}/publish`, { method: 'POST', body: { revision: map.revision } }); setMap(result); await refreshMaps(); setMessage(`Đã xuất bản. ${result.warnings.join(' ')}`);
          })}>Xuất bản</button>
          <button type="button" disabled={dirty || !map.publishedAt} onClick={() => run(async () => {
            if (!window.confirm('Ngừng cung cấp sơ đồ đã xuất bản cho khách?')) return;
            setMap(await indoorApi(`indoor-maps/${map.id}/unpublish`, { method: 'POST', body: { revision: map.revision } })); await refreshMaps(); setMessage('Đã ngừng xuất bản.');
          })}>Ngừng xuất bản</button>
        </div>
        <p className="indoor-hint">Bản nháp không thay đổi bản đang phục vụ khách. Lưu trước khi xuất bản hoặc thử đường đi. Phiên bản này chỉ tìm đường trong một sơ đồ, chưa kết nối xuyên tầng.</p>
        {!map.imageKey ? <p>Tải ảnh mặt bằng để bắt đầu đặt điểm.</p> : <>
          {map.markers.some(marker => marker.type === 'qr') && <p role="alert" className="indoor-error">Sơ đồ có điểm QR riêng từ phiên bản cũ. Hãy chọn từng điểm này, đổi loại sang hiện vật và liên kết hiện vật tương ứng, hoặc chọn loại điểm khác trước khi lưu/xuất bản.</p>}
          <div className="indoor-row" role="toolbar" aria-label="Công cụ chỉnh sửa sơ đồ">{Object.entries(tools).map(([key, label]) => <button key={key} type="button" aria-pressed={tool === key} onClick={() => { setTool(tool === key ? '' : key); setConnectFrom(null); setMessage(tool !== key && key === 'connect' ? 'Nhấn lần lượt hai điểm để nối; giữ và kéo để di chuyển điểm. Nhấn Esc để thoát.' : ''); }}>{label}</button>)}<button type="button" disabled={!selected} onClick={remove}>Xóa đối tượng</button></div>
          <div className="indoor-editor">
            <MapCanvas key={map.id} document={map} imageUrl={imageUrl} tool={tool} selected={selected} onSelect={select} onPlace={place} onMove={update} route={route} disabled={busy} />
            <aside className="indoor-properties"><h3>Thuộc tính</h3>
              <label>Đối tượng<select value={selected ? `${selected.kind}:${selected.id}` : ''} onChange={e => { if (!e.target.value) setSelected(null); else { const [kind, id] = e.target.value.split(':'); select(kind, id); } }}><option value="">Chọn đối tượng</option>
                {['nodes', 'markers', 'edges'].map(kind => <optgroup key={kind} label={{ nodes: 'Điểm dẫn đường', markers: 'Điểm đánh dấu', edges: 'Đoạn đường' }[kind]}>{map[kind].map((o, i) => <option key={o.id} value={`${kind}:${o.id}`}>{o.label || `Đoạn đường ${i + 1}`}</option>)}</optgroup>)}
              </select></label>
              <p>{map.floorId ? `Tầng: ${structure?.floors.find(f => f.id === map.floorId)?.name || map.name}` : 'Mặt bằng chung của bảo tàng'}</p>
              {item && selected.kind !== 'edges' && <>
                <label>Tên<input maxLength={200} value={item.label} onChange={e => update(selected.kind, item.id, { label: e.target.value })} /></label>
                <label>Loại<select value={item.type} onChange={e => update(selected.kind, item.id, { type: e.target.value, ...(selected.kind === 'markers' ? { artifactId: null, galleryId: null } : {}) })}>{item.type === 'qr' && <option value="qr">{selected.kind === 'nodes' ? 'Điểm dẫn đường cũ' : 'QR riêng cũ — hãy đổi loại'}</option>}{Object.entries(selected.kind === 'nodes' ? nodeTypes : markerTypes).map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></label>
                {['x', 'y'].map(axis => <label key={axis}>Tọa độ {axis.toUpperCase()} (0–1)<input type="number" min="0" max="1" step="0.001" value={Number(item[axis].toFixed(4))} onChange={e => { const n = Number(e.target.value); if (Number.isFinite(n) && n >= 0 && n <= 1) update(selected.kind, item.id, { [axis]: n }); }} /></label>)}
              </>}
              {item && selected.kind === 'markers' && <>
                {item.type === 'artifact' && <label>Hiện vật<select value={item.artifactId || ''} onChange={e => { const artifact = links.artifacts.find(a => a.id === Number(e.target.value)); update('markers', item.id, { artifactId: artifact?.id || null, ...(artifact ? { label: artifact.name } : {}) }); }}><option value="">Chọn hiện vật</option>{options(links.artifacts)}</select></label>}
                {item.type === 'gallery' && <label>Phòng trưng bày<select value={item.galleryId || ''} onChange={e => update('markers', item.id, { galleryId: Number(e.target.value) || null })}><option value="">Chọn phòng</option>{options(links.galleries)}</select></label>}
                <label>Điểm dẫn đường liên kết<select value={item.nodeId || ''} onChange={e => update('markers', item.id, { nodeId: e.target.value || null })}><option value="">Chưa liên kết</option>{options(map.nodes)}</select></label>
                <label className="indoor-check"><input type="checkbox" checked={item.isDestination} onChange={e => update('markers', item.id, { isDestination: e.target.checked })} />Là điểm đến có thể dẫn đường</label>
                <label className="indoor-check"><input type="checkbox" checked={item.isActive} onChange={e => update('markers', item.id, { isActive: e.target.checked })} />Đang hoạt động</label>
                {item.type === 'artifact' && <>
                  <p className="indoor-hint">Dùng mã QR có sẵn của hiện vật để xem thông tin và xác định vị trí trên sơ đồ. Chọn điểm dẫn đường liên kết để xác định vị trí xuất phát sau khi quét. Các loại điểm khác không có QR.</p>
                  <button type="button" disabled={dirty || !item.isActive || !item.artifactId} onClick={() => run(downloadQr)}>Tải QR hiện vật</button>
                </>}
              </>}
              {item && selected.kind === 'edges' && <>
                <p>Từ: {map.nodes.find(n => n.id === item.fromNodeId)?.label}<br />Đến: {map.nodes.find(n => n.id === item.toNodeId)?.label}</p>
                <button type="button" onClick={() => update('edges', item.id, { fromNodeId: item.toNodeId, toNodeId: item.fromNodeId })}>Đảo hướng</button>
                <label className="indoor-check"><input type="checkbox" checked={item.bidirectional} onChange={e => update('edges', item.id, { bidirectional: e.target.checked })} />Đi được hai chiều</label>
                <label className="indoor-check"><input type="checkbox" checked={item.isAccessible} onChange={e => update('edges', item.id, { isAccessible: e.target.checked })} />Phù hợp xe lăn</label>
              </>}
              <p className="indoor-hint">Có thể chỉnh tọa độ bằng ô số. Để thêm điểm bằng bàn phím, chọn công cụ rồi dùng nút dưới đây.</p>
              <button type="button" disabled={!tool || ['pan', 'connect'].includes(tool)} onClick={() => place({ x: 0.5, y: 0.5 })}>Thêm điểm ở giữa sơ đồ</button>
            </aside>
          </div>
          <form className="indoor-row indoor-box" onSubmit={e => { e.preventDefault(); run(async () => {
            setRoute(null); const result = await indoorApi(`indoor-maps/${map.id}/preview-route`, { method: 'POST', body: { revision: map.revision, fromNodeId: from, toNodeId: to, accessibleOnly: accessible } }); setRoute(result); setMessage('Đã hiển thị tuyến đường. Chi phí theo ảnh, không phải khoảng cách mét.');
          }); }}>
            <label>Điểm bắt đầu<select required value={from} onChange={e => { setFrom(e.target.value); setRoute(null); }}><option value="">Chọn điểm</option>{options(map.nodes)}</select></label>
            <label>Điểm kết thúc<select required value={to} onChange={e => { setTo(e.target.value); setRoute(null); }}><option value="">Chọn điểm</option>{options(map.nodes)}</select></label>
            <label className="indoor-check"><input type="checkbox" checked={accessible} onChange={e => { setAccessible(e.target.checked); setRoute(null); }} />Chỉ đường phù hợp xe lăn</label>
            <button disabled={dirty || !from || !to}>Xem thử đường đi</button>
          </form>
        </>}
      </>}
    </fieldset>
  </section>;
}
