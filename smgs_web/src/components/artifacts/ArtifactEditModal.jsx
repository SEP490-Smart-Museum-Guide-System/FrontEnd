import React, { useEffect, useState, useRef } from 'react';
import { createPortal } from 'react-dom';
import { useApp } from '../../context/AppContext';
import { backend } from '../../services/backend';
import { uploadMedia, validateMediaFile } from '../../services/mediaApi';
import { UploadCloud, X, AlertCircle } from 'lucide-react';

export default function ArtifactEditModal({ artifact, onClose, onSave }) {
  const { currentMuseum, museums, currentRole, showToast } = useApp();
  const [form, setForm] = useState({
    id: artifact?.id, name: artifact?.name || '', code: artifact?.code || '',
    museumId: artifact?.museumId ?? currentMuseum?.id ?? '', galleryId: artifact?.galleryId ?? '',
    qrCode: artifact?.qrCode || '', accessLevel: artifact?.accessLevel || 'free',
  });
  const [galleries, setGalleries] = useState([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [uploadStatus, setUploadStatus] = useState('');
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [filePreviews, setFilePreviews] = useState([]);
  const fileInputRef = useRef(null);

  useEffect(() => {
    const controller = new AbortController();
    setGalleries([]); setError('');
    if (form.museumId) backend(`museums/${form.museumId}/galleries`, { signal: controller.signal })
      .then(rows => { if (!controller.signal.aborted) setGalleries(rows); })
      .catch(e => { if (!controller.signal.aborted) setError(e.message); });
    return () => controller.abort();
  }, [form.museumId]);

  useEffect(() => {
    const previews = selectedFiles.map(file => ({
      file,
      url: URL.createObjectURL(file),
      name: file.name,
      size: (file.size / 1024).toFixed(1) + ' KB'
    }));
    setFilePreviews(previews);

    return () => {
      previews.forEach(p => URL.revokeObjectURL(p.url));
    };
  }, [selectedFiles]);

  const change = (key, value) => setForm(prev => ({ ...prev, [key]: value }));
  const close = () => { if (!busy) onClose(); };

  function handleFileSelect(e) {
    const newFiles = Array.from(e.target.files || []);
    if (!newFiles.length) return;

    const validFiles = [];
    let fileError = '';
    for (const f of newFiles) {
      try {
        validateMediaFile(f, false, 15);
        validFiles.push(f);
      } catch (err) {
        fileError = err.message;
      }
    }

    if (fileError) {
      setError(fileError);
    } else {
      setError('');
    }

    if (validFiles.length > 0) {
      setSelectedFiles(prev => [...prev, ...validFiles]);
    }
    e.target.value = '';
  }

  function handleRemoveFile(index) {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
  }

  async function save(event) {
    event.preventDefault();
    if (busy) return;
    setBusy(true);
    setUploadStatus('');
    try {
      const result = await onSave(form);
      if (result?.success) {
        const targetId = result.data?.id || form.id;
        if (targetId && selectedFiles.length > 0) {
          for (let i = 0; i < selectedFiles.length; i++) {
            const f = selectedFiles[i];
            setUploadStatus(`Đang tải ảnh (${i + 1}/${selectedFiles.length}): ${f.name}…`);
            const formData = new FormData();
            formData.append('file', f);
            formData.append('mediaType', 'image');
            formData.append('title', f.name.replace(/\.[^/.]+$/, ''));
            formData.append('sortOrder', i);
            await uploadMedia(`artifacts/${targetId}/media`, formData);
          }
        }
        showToast?.(`Đã lưu hiện vật${selectedFiles.length > 0 ? ` kèm ${selectedFiles.length} hình ảnh` : ''}.`);
        onClose();
      }
    } catch (err) {
      setError(err.message || 'Lỗi khi lưu hiện vật hoặc tải ảnh.');
    } finally {
      setBusy(false);
      setUploadStatus('');
    }
  }

  return createPortal(<div className="modal-overlay" onClick={close}>
    <div className="modal-dialog" style={{ maxWidth: 640, width: '95vw', maxHeight: '92vh', display: 'flex', flexDirection: 'column' }} onClick={e => e.stopPropagation()}>
      <div className="modal-header">
        <h3>{artifact?.id ? 'Chỉnh sửa hiện vật' : 'Thêm hiện vật'}</h3>
        <button type="button" disabled={busy} onClick={close}>Đóng</button>
      </div>
      <form onSubmit={save} style={{ display: 'flex', flexDirection: 'column', overflow: 'hidden', flex: 1 }}>
        <div className="modal-body" style={{ display: 'grid', gap: 16, overflowY: 'auto', paddingRight: 6 }}>
          <label className="form-group">
            Tên hiện vật
            <input className="form-input" required maxLength={200} value={form.name} onChange={e => change('name', e.target.value)} />
          </label>
          <label className="form-group">
            Mã hiện vật
            <input className="form-input" maxLength={100} value={form.code} onChange={e => change('code', e.target.value)} />
          </label>
          <label className="form-group">
            Bảo tàng
            <select className="form-select" required disabled={!!artifact?.id || currentRole !== 'administrator'} value={form.museumId} onChange={e => setForm(prev => ({ ...prev, museumId: e.target.value, galleryId: '' }))}>
              <option value="">Chọn bảo tàng</option>
              {museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
            </select>
          </label>
          {error && <p role="alert" style={{ color: '#b91c1c', display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.85rem' }}><AlertCircle style={{ width: 16, height: 16, flexShrink: 0 }} />{error}</p>}
          <label className="form-group">
            Phòng trưng bày
            <select className="form-select" disabled={!!error && galleries.length === 0} value={form.galleryId} onChange={e => change('galleryId', e.target.value)}>
              <option value="">Chưa phân phòng</option>
              {form.galleryId && !galleries.some(g => String(g.id) === String(form.galleryId)) && <option value={form.galleryId}>{artifact?.galleryName || `Phòng #${form.galleryId}`}</option>}
              {galleries.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}
            </select>
          </label>

          {/* Khu vực chọn hình ảnh hiện vật (Hỗ trợ tải nhiều ảnh) */}
          <div className="form-group">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
              <span style={{ fontWeight: 600, fontSize: '0.9rem', color: 'var(--color-ink, #2c2520)' }}>
                Hình ảnh hiện vật (Có thể chọn nhiều ảnh)
              </span>
              {selectedFiles.length > 0 && (
                <span style={{ fontSize: '0.8rem', fontWeight: 600, color: '#92400e', background: '#fef3c7', padding: '2px 8px', borderRadius: 12 }}>
                  Đã chọn {selectedFiles.length} ảnh
                </span>
              )}
            </div>

            <div
              style={{
                border: '2px dashed var(--color-paper-border, #d1c7bd)',
                borderRadius: 10,
                padding: '16px 20px',
                textAlign: 'center',
                backgroundColor: '#fbf9f5',
                cursor: busy ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s',
                marginBottom: selectedFiles.length > 0 ? 12 : 0
              }}
              onClick={() => !busy && fileInputRef.current?.click()}
            >
              <input
                ref={fileInputRef}
                type="file"
                multiple
                accept=".png,.jpg,.jpeg,.webp"
                style={{ display: 'none' }}
                disabled={busy}
                onChange={handleFileSelect}
              />
              <UploadCloud style={{ width: 26, height: 26, margin: '0 auto 6px', color: '#8c6d58', opacity: 0.85 }} />
              <p style={{ margin: 0, fontSize: '0.88rem', fontWeight: 500, color: 'var(--color-ink, #3d332a)' }}>
                Nhấn để chọn ảnh hoặc kéo thả nhiều ảnh vào đây
              </p>
              <p style={{ margin: '4px 0 0', fontSize: '0.78rem', color: '#7a7067' }}>
                Hỗ trợ định dạng PNG, JPG, JPEG, WebP • Tối đa 15 MB mỗi ảnh
              </p>
            </div>

            {filePreviews.length > 0 && (
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(95px, 1fr))',
                gap: 10,
                maxHeight: 180,
                overflowY: 'auto',
                padding: '4px 2px'
              }}>
                {filePreviews.map((p, idx) => (
                  <div
                    key={p.url}
                    style={{
                      position: 'relative',
                      borderRadius: 8,
                      overflow: 'hidden',
                      border: '1px solid #e0d8cf',
                      background: '#fff',
                      boxShadow: '0 1px 3px rgba(0,0,0,0.06)'
                    }}
                  >
                    <img
                      src={p.url}
                      alt={p.name}
                      style={{ width: '100%', height: 70, objectFit: 'cover', display: 'block' }}
                    />
                    <div style={{ padding: '3px 4px', fontSize: '0.68rem', color: '#555', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={p.name}>
                      {p.name}
                    </div>
                    {!busy && (
                      <button
                        type="button"
                        onClick={(e) => { e.stopPropagation(); handleRemoveFile(idx); }}
                        style={{
                          position: 'absolute',
                          top: 3,
                          right: 3,
                          width: 18,
                          height: 18,
                          borderRadius: '50%',
                          background: 'rgba(0,0,0,0.65)',
                          color: '#fff',
                          border: 'none',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          padding: 0
                        }}
                        title="Gỡ ảnh này"
                      >
                        <X style={{ width: 11, height: 11 }} />
                      </button>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          <p style={{ margin: '4px 0 0', fontSize: '0.8rem', color: '#78716c', fontStyle: 'italic' }}>
            Ảnh được chọn sẽ tự động tải lên sau khi tạo hiện vật. Âm thanh thuyết minh và mô hình 3D có thể bổ sung trong chi tiết hiện vật; vị trí được gắn trên bản đồ bảo tàng.
          </p>
        </div>

        <div className="modal-footer" style={{ borderTop: '1px solid var(--color-paper-border, #e7e5e4)', marginTop: 12, paddingTop: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontSize: '0.82rem', color: '#78350f', fontWeight: 500 }}>
            {uploadStatus && <span>{uploadStatus}</span>}
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button className="btn btn-secondary" type="button" disabled={busy} onClick={close}>Hủy</button>
            <button className="btn btn-primary" disabled={busy || !form.museumId || !form.name.trim()}>
              {busy ? (uploadStatus || 'Đang lưu…') : 'Lưu hiện vật'}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>, document.body);
}
