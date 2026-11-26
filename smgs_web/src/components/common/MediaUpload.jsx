import React, { useEffect, useRef, useState } from 'react';
import { Image as ImageIcon, UploadCloud } from 'lucide-react';
import { uploadMedia, validateMediaFile } from '../../services/mediaApi';
import { uploadBatch } from '../../services/uploadBatch';
import { useApp } from '../../context/AppContext';

export default function MediaUpload({ path, model = false, multiple = false, compact = false, onSaved, label = 'Tải ảnh lên' }) {
  const { showToast } = useApp();
  const [busy, setBusy] = useState(false), [progress, setProgress] = useState(null);
  const [failures, setFailures] = useState([]);
  const inputId = React.useId();
  const fileInput = useRef(null);
  const controller = useRef(null), lock = useRef(false), alive = useRef(true);
  useEffect(() => { alive.current = true; return () => { alive.current = false; controller.current?.abort(); }; }, []);
  async function upload(files) {
    if (lock.current || !files.length) return;
    lock.current = true; setBusy(true); setFailures([]); setProgress(null);
    controller.current = new AbortController();
    const result = await uploadBatch(files, {
      signal: controller.current.signal,
      onProgress: value => { if (alive.current) setProgress(value); },
      upload: (file, report) => {
        validateMediaFile(file, model);
        const form = new FormData(); form.append('file', file);
        return uploadMedia(path, form, report, controller.current.signal);
      },
    });
    if (alive.current) {
      setFailures(result.failed);
      if (result.saved.length) {
        showToast(`Đã tải lên ${result.saved.length}/${files.length} ${model ? 'mô hình' : 'ảnh'}.`, result.failed.length ? 'warning' : 'success');
        try { await onSaved?.(result.saved[0].result); }
        catch { showToast('Tệp đã lưu, nhưng danh sách chưa cập nhật. Hãy tải lại trang.', 'warning'); }
      } else showToast('Chưa có tệp nào được lưu. Xem lỗi bên dưới để thử lại.', 'error');
      setBusy(false); setProgress(null);
    }
    lock.current = false;
  }
  return <div className="media-upload" aria-busy={busy}>
    {compact ? <button type="button" className="btn cover-change" disabled={busy} onClick={() => fileInput.current?.click()}>
      <ImageIcon size={16} /> {busy ? 'Đang tải…' : label}
    </button> : <label htmlFor={inputId} className="upload-dropzone">
      <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: '#FAF5EE', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '4px', border: '1px solid var(--color-paper-border)' }}>
        <UploadCloud size={24} color="var(--color-burgundy-900)" />
      </div>
      <strong style={{ fontSize: '0.92rem', color: 'var(--color-burgundy-900)' }}>{busy ? 'Đang tải và lưu…' : label}</strong>
      <span style={{ fontSize: '0.76rem', color: 'var(--color-charcoal-500)', marginTop: '2px', marginBottom: '8px' }}>
        {model ? 'GLB · tối đa 100 MB' : `${multiple ? 'Chọn nhiều ảnh · ' : ''}PNG, JPEG, WebP · tối đa 15 MB/ảnh`}
      </span>
      <span className="btn btn-secondary btn-sm" style={{ pointerEvents: 'none', fontSize: '0.78rem', height: '32px', gap: '6px' }}>
        <UploadCloud size={14} /> Chọn tệp từ thiết bị
      </span>
    </label>}
      <input
        ref={fileInput}
        id={inputId}
        type="file"
        aria-label={label}
        accept={model ? '.glb' : '.png,.jpg,.jpeg,.webp'}
        multiple={!model && multiple}
        disabled={busy}
        style={{ display: 'none' }}
        onChange={e => { const files = Array.from(e.target.files || []); e.target.value = ''; upload(files); }}
      />
    {busy && <div role="status" className="upload-progress">
      <span>{progress ? `${progress.index + 1}/${progress.total} · ${progress.file.name}` : 'Đang chuẩn bị tệp…'}</span>
      <progress max="100" value={progress?.progress || 0} aria-label="Tiến trình tải tệp" />
      <small>{progress?.progress === 100 ? 'Đang chờ máy chủ xác nhận lưu…' : `${progress?.progress || 0}%`}</small>
      <button type="button" className="btn btn-secondary btn-sm" onClick={() => controller.current?.abort()}>Dừng tải</button>
    </div>}
    {!!failures.length && <div className="business-error" role="alert"><strong>{failures.length} tệp chưa được lưu</strong>
      <ul>{failures.map(({ file, message }, index) => <li key={index}>{file.name}: {message}</li>)}</ul>
      <button type="button" className="btn btn-secondary btn-sm" disabled={busy} onClick={() => upload(failures.map(item => item.file))}>Thử lại các tệp lỗi</button>
    </div>}
  </div>;
}
