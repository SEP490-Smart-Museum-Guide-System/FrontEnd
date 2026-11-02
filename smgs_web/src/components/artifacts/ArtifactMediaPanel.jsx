import React, { useEffect, useState } from 'react';
import MediaUpload from '../common/MediaUpload';
import { mediaApi } from '../../services/mediaApi';

function Preview({ path, model = false }) {
  const [url, setUrl] = useState('');
  const [error, setError] = useState('');
  useEffect(() => {
    const controller = new AbortController(); let objectUrl;
    mediaApi(path, { blob: true, signal: controller.signal }).then(blob => {
      if (controller.signal.aborted) return;
      objectUrl = URL.createObjectURL(blob); setUrl(objectUrl);
    }).catch(e => { if (e.name !== 'AbortError') setError(e.message); });
    return () => { controller.abort(); if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [path]);
  if (!url) return <p role="status">{error || 'Đang tải xem trước…'}</p>;
  return model ? <model-viewer src={url} camera-controls alt="Mô hình hiện vật" style={{ width: '100%', height: 300 }} />
    : <img src={url} alt="Ảnh hiện vật" style={{ maxWidth: 240, maxHeight: 180, objectFit: 'contain' }} />;
}

export default function ArtifactMediaPanel({ artifactId, readOnly }) {
  const [media, setMedia] = useState([]), [model, setModel] = useState(null), [error, setError] = useState('');
  const [version, setVersion] = useState(0), [busy, setBusy] = useState(false);
  const path = `artifacts/${artifactId}`;
  useEffect(() => {
    if (!Number.isInteger(Number(artifactId)) || Number(artifactId) <= 0) return;
    const controller = new AbortController();
    Promise.all([mediaApi(`${path}/media?mediaType=image`, { signal: controller.signal }),
      mediaApi(`${path}/model-3d`, { signal: controller.signal }).catch(e => { if (e.status === 404) return null; throw e; })])
      .then(([images, item]) => { setMedia(images); setModel(item); setError('' ); })
      .catch(e => { if (e.name !== 'AbortError') setError(e.message); });
    return () => controller.abort();
  }, [path, version, artifactId]);
  if (!Number.isInteger(Number(artifactId)) || Number(artifactId) <= 0) return <p>Lưu hiện vật trước khi tải media.</p>;
  async function remove(endpoint) {
    setBusy(true); setError('');
    try { await mediaApi(endpoint, { method: 'DELETE' }); setVersion(v => v + 1); }
    catch (e) { setError(e.message); } finally { setBusy(false); }
  }
  return <section style={{ padding: 16, border: '1px solid var(--color-paper-border)', borderRadius: 12, marginBottom: 20 }}>
    <h3>Ảnh và mô hình hiện vật</h3>
    {error && <p role="alert">{error}</p>}
    {!readOnly && <MediaUpload path={`${path}/media`} onSaved={() => setVersion(v => v + 1)} />}
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>{media.map(item => <div key={item.id}>
      <Preview path={`${path}/media/${item.id}/file`} /><p>{item.title}</p>
      {!readOnly && <button type="button" disabled={busy} onClick={() => remove(`${path}/media/${item.id}`)}>Xóa ảnh</button>}
    </div>)}</div>
    {!readOnly && <MediaUpload path={`${path}/model-3d`} model label={model ? 'Thay mô hình' : 'Tải mô hình'} onSaved={() => setVersion(v => v + 1)} />}
    {model && <><Preview key={`${model.id}-${version}`} path={`${path}/model-3d/file`} model />
      {!readOnly && <button type="button" disabled={busy} onClick={() => remove(`${path}/model-3d`)}>Xóa mô hình</button>}</>}
  </section>;
}
