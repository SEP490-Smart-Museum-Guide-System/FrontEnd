import React, { useEffect, useRef, useState } from 'react';
import { ImagePlus, X } from 'lucide-react';
import { validateMediaFile } from '../../services/mediaApi';

export default function MuseumCoverPicker({ file, currentUrl, onChange, disabled }) {
  const input = useRef(null);
  const [preview, setPreview] = useState('');
  const [error, setError] = useState('');
  useEffect(() => {
    if (!file) { setPreview(''); return; }
    const url = URL.createObjectURL(file);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);
  const image = file ? preview : currentUrl;
  return <div className="form-group" style={{ marginBottom: 0 }}>
    <span className="form-label">Ảnh đại diện</span>
    {image && <img src={image} alt="Xem trước ảnh đại diện bảo tàng"
      style={{ width: '100%', height: 170, objectFit: 'cover', borderRadius: 10, marginBottom: 10 }} />}
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, alignItems: 'center' }}>
      <button type="button" className="btn btn-secondary" disabled={disabled} onClick={() => input.current?.click()}>
        <ImagePlus size={16} /> {file || currentUrl ? 'Chọn ảnh khác' : 'Chọn ảnh từ máy'}
      </button>
      <input ref={input} type="file" aria-label="Chọn ảnh đại diện" accept=".png,.jpg,.jpeg,.webp" hidden disabled={disabled}
        onChange={event => {
          const selected = event.target.files?.[0]; event.target.value = '';
          if (!selected) return;
          try { validateMediaFile(selected); setError(''); onChange(selected); }
          catch (e) { setError(e.message); }
        }} />
      {file && <button type="button" className="btn btn-secondary btn-sm" disabled={disabled} onClick={() => { onChange(null); setError(''); }}>
        <X size={14} /> Bỏ ảnh đã chọn
      </button>}
    </div>
    <p style={{ fontSize: 12, color: 'var(--color-charcoal-500)', marginTop: 8, overflowWrap: 'anywhere' }}>
      {file ? `${file.name} · ${(file.size / 1024 / 1024).toFixed(2)} MB. ` : ''}
      PNG, JPEG hoặc WebP, tối đa 15 MB. Ảnh được tải lên khi bạn lưu thông tin.
    </p>
    {error && <p role="alert">{error}</p>}
  </div>;
}
