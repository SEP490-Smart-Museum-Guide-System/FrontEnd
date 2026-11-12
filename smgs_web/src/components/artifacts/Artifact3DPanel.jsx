import React, { useEffect, useRef, useState } from 'react';
import '@google/model-viewer';
import ArtifactModelViewer, { isSketchfabUrl } from '../common/ArtifactModelViewer';
import { mediaApi, uploadMedia } from '../../services/mediaApi';
import { prepareScanDataset, startArtifactScan, getScanJobs, getScanJob, getScanModel, saveScanModel, discardScanModel, validateGlbPreview } from '../../services/artifactScanApi';

const running = s => ['QUEUED', 'PROCESSING', 'FINALIZING'].includes(s);
const labels = { QUEUED: 'Đang chờ xử lý', PROCESSING: 'Đang dựng bằng CPU', FINALIZING: 'Đang kiểm tra GLB', REVIEW_REQUIRED: 'Đã dựng xong — xem thử trước khi lưu', FAILED: 'Dựng thất bại', COMPLETED: 'Đã lưu vào hiện vật', DISCARDED: 'Đã bỏ kết quả' };

export default function Artifact3DPanel({ artifactId, name, canManage = false, onModelChange }) {
  const validId = Number.isInteger(Number(artifactId)) && Number(artifactId) > 0;
  const path = `artifacts/${artifactId}/model-3d`;
  const [model, setModel] = useState(null), [savedUrl, setSavedUrl] = useState('');
  const [draft, setDraft] = useState(null), [job, setJob] = useState(null), [files, setFiles] = useState([]);
  const [mode, setMode] = useState('auto'), [busy, setBusy] = useState(false), [progress, setProgress] = useState(0);
  const [error, setError] = useState(''), [message, setMessage] = useState(''), [jobError, setJobError] = useState('');
  const [revision, setRevision] = useState(0), [loading, setLoading] = useState(true);
  const action = useRef(null), selection = useRef(0), viewer = useRef(null);
  const [viewerError, setViewerError] = useState('');
  useEffect(() => {
    const element = viewer.current?.querySelector('model-viewer');
    const failed = () => setViewerError('Không hiển thị được GLB. Kiểm tra file và khả năng WebGL của trình duyệt trước khi lưu.');
    const loaded = () => setViewerError('');
    element?.addEventListener('error', failed); element?.addEventListener('load', loaded);
    return () => { element?.removeEventListener('error', failed); element?.removeEventListener('load', loaded); };
  }, [draft?.url, savedUrl]);
  useEffect(() => () => action.current?.abort(), []);
  useEffect(() => () => { if (draft?.url) URL.revokeObjectURL(draft.url); }, [draft]);
  useEffect(() => {
    if (!validId) return;
    const controller = new AbortController(); let objectUrl;
    setLoading(true); setSavedUrl('');
    mediaApi(path, { signal: controller.signal }).then(async item => {
      if (controller.signal.aborted) return;
      setModel(item);
      onModelChange?.(!!item);
      if (isSketchfabUrl(item?.modelUrl)) setSavedUrl(item.modelUrl);
      else if (item) {
        const blob = await mediaApi(path + '/file', { blob: true, signal: controller.signal });
        if (controller.signal.aborted) return;
        objectUrl = URL.createObjectURL(blob); setSavedUrl(objectUrl);
      }
    }).catch(e => { if (controller.signal.aborted) return; if (e.status === 404) { setModel(null); onModelChange?.(false); } else setError(e.message); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => { controller.abort(); if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [path, revision, validId, onModelChange]);
  useEffect(() => {
    if (!canManage || !validId) return;
    const controller = new AbortController();
    getScanJobs(artifactId, controller.signal).then(rows => { if (!controller.signal.aborted) setJob(rows[0] || null); })
      .catch(e => { if (!controller.signal.aborted) setJobError(e.message); });
    return () => controller.abort();
  }, [artifactId, canManage, validId]);
  useEffect(() => {
    if (!job?.scanJobId || !running(job.status)) return;
    const controller = new AbortController(); let timer;
    async function poll() {
      try { const next = await getScanJob(artifactId, job.scanJobId, controller.signal); if (!controller.signal.aborted) { setJob(next); setJobError(''); } }
      catch (e) { if (!controller.signal.aborted) setJobError(e.message); }
      if (!controller.signal.aborted) timer = setTimeout(poll, 5000);
    }
    timer = setTimeout(poll, 2500);
    return () => { controller.abort(); clearTimeout(timer); };
  }, [artifactId, job?.scanJobId, job?.status]);

  async function chooseGlb(file) {
    if (!file) return;
    const ticket = ++selection.current;
    try { setError(''); await validateGlbPreview(file); if (ticket !== selection.current) return;
      setViewerError(''); setDraft({ file, url: URL.createObjectURL(file), source: 'file' }); setMessage('Bản xem thử chưa được lưu vào hiện vật.');
    } catch (e) { setError(e.message); }
  }
  async function perform(task) {
    setBusy(true); setError(''); setMessage(''); action.current = new AbortController();
    try { await task(action.current.signal); } catch (e) { setError(e.name === 'AbortError' ? 'Đã ngắt yêu cầu; kiểm tra danh sách job trước khi gửi lại.' : e.message); }
    finally { setBusy(false); }
  }
  const viewScan = () => perform(async signal => {
    const blob = await getScanModel(artifactId, job.scanJobId, signal);
    setViewerError(''); setDraft({ url: URL.createObjectURL(blob), source: 'scan', jobId: job.scanJobId });
    setMessage('Bản AI mới dựng. Kiểm tra hình dáng và texture trước khi lưu.');
  });
  const start = () => perform(async signal => {
    const dataset = prepareScanDataset(files, mode);
    setProgress(0); const created = await startArtifactScan(artifactId, dataset, setProgress, signal);
    setJob(created); setJobError(''); setFiles([]); setDraft(null);
    setMessage('Đã nhận bộ ảnh. Bạn có thể đóng trang rồi quay lại xem tiến độ.');
  });
  const save = () => {
    if (model && !window.confirm('Thay mô hình hiện đang lưu bằng bản xem thử này?')) return;
    perform(async signal => {
      if (draft.source === 'scan') { await saveScanModel(artifactId, draft.jobId); setJob(prev => prev?.scanJobId === draft.jobId ? { ...prev, status: 'COMPLETED' } : prev); }
      else { const form = new FormData(); form.append('file', draft.file); form.append('name', name || ''); await uploadMedia(path, form, setProgress, signal); }
      setDraft(null); setRevision(v => v + 1); setMessage('Đã lưu mô hình vào hiện vật.');
    });
  };
  const remove = () => {
    if (!window.confirm('Xóa mô hình đã lưu của hiện vật này?')) return;
    perform(async () => { await mediaApi(path, { method: 'DELETE' }); setModel(null); setSavedUrl(''); setRevision(v => v + 1); setMessage('Đã xóa mô hình đã lưu.'); });
  };
  const discard = () => perform(async () => {
    await discardScanModel(artifactId, job.scanJobId);
    if (draft?.jobId === job.scanJobId) setDraft(null);
    setJob(null); setMessage('Đã bỏ kết quả scan. Mô hình đã lưu không thay đổi.');
  });
  if (!validId) return <p>Lưu hiện vật trước khi thêm mô hình 3D.</p>;
  return <section aria-label="Mô hình 3D của hiện vật" style={{ display: 'grid', gap: 16 }}>
    <div><h3>Mô hình 3D · {name}</h3><p>Kéo để xoay, cuộn để phóng to. Xem thử trước khi lưu vào hiện vật.</p></div>
    {error && <p role="alert">{error}</p>}{message && <p role="status">{message}</p>}
    {viewerError && <p role="alert">{viewerError}</p>}
    {(draft?.url || savedUrl) ? <div ref={viewer} style={{ background: '#e4e6e8', borderRadius: 12, overflow: 'hidden' }}>
      <p style={{ padding: '8px 16px', color: '#18233b' }}>{draft ? 'Bản xem thử — chưa lưu' : 'Mô hình đang lưu'}</p>
      <ArtifactModelViewer key={draft?.url || savedUrl} url={draft?.url || savedUrl} name={name} style={{ height: 460 }} />
    </div> : <p role="status">{loading ? 'Đang tải mô hình…' : 'Hiện vật chưa có mô hình 3D.'}</p>}
    {canManage && <>
      <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
        <label className="btn btn-secondary">Chọn GLB để xem thử<input aria-label="Chọn GLB để xem thử" type="file" accept=".glb" disabled={busy} onChange={e => { chooseGlb(e.target.files[0]); e.target.value = ''; }} /></label>
        {draft && <><button className="btn btn-gold" disabled={busy || loading || !!viewerError} onClick={save}>Lưu vào hiện vật</button><button className="btn btn-secondary" disabled={busy} onClick={() => { selection.current++; setDraft(null); setViewerError(''); setMessage('Đã bỏ bản xem thử.'); }}>Bỏ bản xem thử</button></>}
        {model && <button className="btn btn-secondary" disabled={busy} onClick={remove}>Xóa model đã lưu</button>}
      </div>
      {busy && <div role="status"><progress max="100" value={progress} /> Đang xử lý…</div>}
      <section className="card" style={{ padding: 20 }} aria-label="Tạo 3D từ bộ ảnh">
        <h4>Tạo 3D từ bộ ảnh</h4><p>Chọn folder của một hiện vật. AI dựng trên CPU; không cần chạy lệnh PowerShell.</p>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
          <label>Chọn folder ảnh<input aria-label="Chọn folder ảnh" type="file" webkitdirectory="" multiple disabled={busy || running(job?.status)} onChange={e => { setFiles(Array.from(e.target.files || [])); e.target.value = ''; }} /></label>
          <label>Hoặc chọn nhiều ảnh<input aria-label="Chọn nhiều ảnh" type="file" accept=".jpg,.jpeg,.png" multiple disabled={busy || running(job?.status)} onChange={e => { setFiles(Array.from(e.target.files || [])); e.target.value = ''; }} /></label>
          <label>Chế độ <select aria-label="Chế độ dựng 3D" value={mode} onChange={e => setMode(e.target.value)} disabled={busy}><option value="auto">Tự nhận diện bộ dữ liệu</option><option value="photos">Chỉ ảnh chụp</option><option value="benchmark">Dataset có metadata và OBJ</option></select></label>
        </div>
        <p>{files.length ? `Đã chọn ${files.length} tệp. Chỉ ảnh và dữ liệu camera cần thiết được gửi.` : '5–200 ảnh JPG/PNG; tối đa 500 MiB mỗi bộ.'}</p>
        <p>Dataset có metadata và OBJ dùng tham chiếu để hiệu chỉnh camera. Ảnh chụp thường được COLMAP tự ước lượng camera; chất lượng phụ thuộc bộ ảnh.</p>
        <button className="btn btn-gold" disabled={busy || running(job?.status) || !files.length} onClick={start}>Tạo mô hình 3D</button>
        {jobError && <p role="alert">{jobError}</p>}
        {job && <div style={{ marginTop: 16 }}><p><strong>{labels[job.status] || job.status}</strong> · {job.progress || 0}%</p><progress max="100" value={job.progress || 0} />
          {running(job.status) && <p>Tiến độ cập nhật theo giai đoạn. Xử lý CPU có thể giữ một mức trong vài phút.</p>}
          <p>Mã tác vụ: {job.scanJobId}</p>{job.mode === 'benchmark' && <p>Benchmark có dùng OBJ để hiệu chỉnh camera.</p>}{job.error && <p role="alert">{job.error}</p>}
          {job.status === 'REVIEW_REQUIRED' && <button className="btn btn-secondary" disabled={busy} onClick={viewScan}>Xem kết quả AI</button>}
          {['REVIEW_REQUIRED', 'FAILED'].includes(job.status) && <button className="btn btn-secondary" disabled={busy} onClick={discard}>Bỏ kết quả scan</button>}
        </div>}
      </section>
    </>}
  </section>;
}
