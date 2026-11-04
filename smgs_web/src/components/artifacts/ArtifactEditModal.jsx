import React, { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { useApp } from '../../context/AppContext';
import { backend } from '../../services/backend';

export default function ArtifactEditModal({ artifact, onClose, onSave }) {
  const { currentMuseum, museums, currentRole } = useApp();
  const [form, setForm] = useState({
    id: artifact?.id, name: artifact?.name || '', code: artifact?.code || '',
    museumId: artifact?.museumId ?? currentMuseum?.id ?? '', galleryId: artifact?.galleryId ?? '',
    qrCode: artifact?.qrCode || '', accessLevel: artifact?.accessLevel || 'free',
  });
  const [galleries, setGalleries] = useState([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    const controller = new AbortController();
    setGalleries([]); setError('');
    if (form.museumId) backend(`museums/${form.museumId}/galleries`, { signal: controller.signal })
      .then(rows => { if (!controller.signal.aborted) setGalleries(rows); })
      .catch(e => { if (!controller.signal.aborted) setError(e.message); });
    return () => controller.abort();
  }, [form.museumId]);
  const change = (key, value) => setForm(prev => ({ ...prev, [key]: value }));
  const close = () => { if (!busy) onClose(); };
  async function save(event) {
    event.preventDefault();
    if (busy) return;
    setBusy(true);
    try { const result = await onSave(form); if (result?.success) onClose(); }
    finally { setBusy(false); }
  }
  return createPortal(<div className="modal-overlay" onClick={close}>
    <div className="modal-dialog" style={{ maxWidth: 640, width: '95vw' }} onClick={e => e.stopPropagation()}>
      <div className="modal-header"><h3>{artifact?.id ? 'Chỉnh sửa hiện vật' : 'Thêm hiện vật'}</h3><button type="button" disabled={busy} onClick={close}>Đóng</button></div>
      <form onSubmit={save}>
        <div className="modal-body" style={{ display: 'grid', gap: 16 }}>
          <label className="form-group">Tên hiện vật<input className="form-input" required value={form.name} onChange={e => change('name', e.target.value)} /></label>
          <label className="form-group">Mã hiện vật<input className="form-input" value={form.code} onChange={e => change('code', e.target.value)} /></label>
          <label className="form-group">Bảo tàng<select className="form-select" required disabled={!!artifact?.id || currentRole !== 'administrator'} value={form.museumId} onChange={e => setForm(prev => ({ ...prev, museumId: e.target.value, galleryId: '' }))}>
            <option value="">Chọn bảo tàng</option>{museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
          </select></label>
          {error && <p role="alert">Chưa tải được phòng trưng bày: {error}. Phân công hiện tại được giữ nguyên.</p>}
          <label className="form-group">Phòng trưng bày<select className="form-select" disabled={!!error} value={form.galleryId} onChange={e => change('galleryId', e.target.value)}>
            <option value="">Chưa phân phòng</option>
            {form.galleryId && !galleries.some(g => String(g.id) === String(form.galleryId)) && <option value={form.galleryId}>{artifact?.galleryName || `Phòng #${form.galleryId}`}</option>}
            {galleries.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}
          </select></label>
          <label className="form-group">Quyền truy cập<select className="form-select" value={form.accessLevel} onChange={e => change('accessLevel', e.target.value)}><option value="free">Miễn phí</option><option value="premium">Trả phí</option></select></label>
          <p>Ảnh, âm thanh và mô hình 3D được quản lý trong chi tiết hiện vật. Thuyết minh được gửi kiểm duyệt riêng; vị trí được thiết lập trên bản đồ bảo tàng.</p>
        </div>
        <div className="modal-footer"><button className="btn btn-secondary" type="button" disabled={busy} onClick={close}>Hủy</button><button className="btn btn-primary" disabled={busy || !form.museumId || !form.name.trim()}>{busy ? 'Đang lưu…' : 'Lưu hiện vật'}</button></div>
      </form>
    </div>
  </div>, document.body);
}
