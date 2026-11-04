import { backend } from '../../services/backend';
import { Field, ErrorNotice, useAction } from '../common/BusinessUI';
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
    {model && <>{!readOnly && <ModelSettings key={`${model.id}-${version}`} artifactId={artifactId} model={model} onSaved={() => setVersion(v => v + 1)} />}<Preview key={`${model.id}-${version}`} path={`${path}/model-3d/file`} model />
      {!readOnly && <button type="button" disabled={busy} onClick={() => remove(`${path}/model-3d`)}>Xóa mô hình</button>}</>}
  </section>;
}

function ModelSettings({ artifactId, model, onSaved }) {
  const [form, setForm] = useState({ name: model.name || '', posterUrl: model.posterUrl || '', autoRotate: model.autoRotate, cameraOrbit: model.cameraOrbit || '', fieldOfView: model.fieldOfView || '', scale: model.scale }), action = useAction();
  const change = e => setForm(p => ({ ...p, [e.target.name]: e.target.value }));
  return <details><summary>Cấu hình mô hình 3D</summary><form style={{ display: 'grid', gap: 12 }} onSubmit={e => { e.preventDefault(); action.run(() => backend(`artifacts/${artifactId}/model-3d/settings`, { method: 'PATCH', body: { ...form, posterUrl: form.posterUrl || null, cameraOrbit: form.cameraOrbit || null, fieldOfView: form.fieldOfView || null, scale: Number(form.scale) } }), onSaved); }}><ErrorNotice>{action.error}</ErrorNotice><Field label="Tên mô hình"><input className="form-input" name="name" maxLength={300} value={form.name} onChange={change} /></Field><Field label="Ảnh đại diện mô hình"><input className="form-input" name="posterUrl" maxLength={1000} value={form.posterUrl} onChange={change} /></Field><Field label="Góc camera"><input className="form-input" name="cameraOrbit" maxLength={100} value={form.cameraOrbit} onChange={change} /></Field><Field label="Góc nhìn"><input className="form-input" name="fieldOfView" maxLength={50} value={form.fieldOfView} onChange={change} /></Field><Field label="Tỷ lệ"><input className="form-input" name="scale" type="number" min="0.01" max={1000} step="0.01" required value={form.scale} onChange={change} /></Field><label className="business-check"><input type="checkbox" checked={form.autoRotate} onChange={e => setForm(p => ({ ...p, autoRotate: e.target.checked }))} />Tự xoay mô hình</label><button className="btn btn-primary" disabled={action.busy}>Lưu cấu hình 3D</button></form></details>;
}
