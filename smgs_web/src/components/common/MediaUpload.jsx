import React, { useEffect, useRef, useState } from 'react';
import { uploadMedia, validateMediaFile } from '../../services/mediaApi';

export default function MediaUpload({ path, model = false, onSaved, label = 'Tải ảnh lên' }) {
  const [busy, setBusy] = useState(false);
  const [progress, setProgress] = useState(0);
  const [message, setMessage] = useState('');
  const controller = useRef(null);
  useEffect(() => () => controller.current?.abort(), []);
  async function upload(file) {
    try {
      validateMediaFile(file, model);
      setBusy(true); setProgress(0); setMessage('');
      controller.current = new AbortController();
      const form = new FormData(); form.append('file', file);
      const result = await uploadMedia(path, form, setProgress, controller.current.signal);
      setMessage('Đã lưu file.'); await onSaved?.(result);
    } catch (e) { setMessage(e.message); }
    finally { setBusy(false); }
  }
  return <div style={{ margin: '12px 0' }}>
    <label>{label} ({model ? 'GLB, 100 MB' : 'PNG/JPEG/WebP, 15 MB'})
      <input type="file" accept={model ? '.glb' : '.png,.jpg,.jpeg,.webp'} disabled={busy}
        onChange={e => { const file = e.target.files[0]; e.target.value = ''; if (file) upload(file); }} />
    </label>
    {busy && <div role="status"><progress max="100" value={progress} aria-label="Tiến trình tải file" /> {progress}% {progress === 100 ? 'Đang lưu…' : ''}
      <button type="button" onClick={() => controller.current?.abort()}>Hủy</button></div>}
    {message && <p role="status">{message}</p>}
  </div>;
}
