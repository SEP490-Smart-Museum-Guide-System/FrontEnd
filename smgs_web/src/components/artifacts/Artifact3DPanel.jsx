import React, { useEffect, useRef, useState } from 'react';
import '@google/model-viewer';
import ArtifactModelViewer, { isSketchfabUrl } from '../common/ArtifactModelViewer';
import { mediaApi, uploadMedia } from '../../services/mediaApi';
import {
  prepareScanDataset,
  startArtifactScan,
  getScanJobs,
  getScanJob,
  getScanModel,
  saveScanModel,
  discardScanModel,
  validateGlbPreview
} from '../../services/artifactScanApi';
import { Box, Upload, Sparkles, Check, Trash2, RefreshCw, Folder, AlertCircle } from 'lucide-react';

const running = s => ['QUEUED', 'PROCESSING', 'FINALIZING'].includes(s);
const labels = {
  QUEUED: 'Đang chờ xử lý',
  PROCESSING: 'Đang dựng bằng CPU',
  FINALIZING: 'Đang kiểm tra GLB',
  REVIEW_REQUIRED: 'Đã dựng xong — xem thử trước khi lưu',
  FAILED: 'Dựng thất bại',
  COMPLETED: 'Đã lưu vào hiện vật',
  DISCARDED: 'Đã bỏ kết quả'
};

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
    element?.addEventListener('error', failed);
    element?.addEventListener('load', loaded);
    return () => {
      element?.removeEventListener('error', failed);
      element?.removeEventListener('load', loaded);
    };
  }, [draft?.url, savedUrl]);

  useEffect(() => () => action.current?.abort(), []);
  useEffect(() => () => { if (draft?.url) URL.revokeObjectURL(draft.url); }, [draft]);

  useEffect(() => {
    if (!validId) return;
    const controller = new AbortController();
    let objectUrl;
    setLoading(true);
    setSavedUrl('');
    mediaApi(path, { signal: controller.signal })
      .then(async item => {
        if (controller.signal.aborted) return;
        setModel(item);
        onModelChange?.(!!item);
        if (isSketchfabUrl(item?.modelUrl)) setSavedUrl(item.modelUrl);
        else if (item) {
          const blob = await mediaApi(path + '/file', { blob: true, signal: controller.signal });
          if (controller.signal.aborted) return;
          objectUrl = URL.createObjectURL(blob);
          setSavedUrl(objectUrl);
        }
      })
      .catch(e => {
        if (controller.signal.aborted) return;
        if (e.status === 404) {
          setModel(null);
          onModelChange?.(false);
        } else setError(e.message);
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });
    return () => {
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [path, revision, validId, onModelChange]);

  useEffect(() => {
    if (!canManage || !validId) return;
    const controller = new AbortController();
    getScanJobs(artifactId, controller.signal)
      .then(rows => {
        if (!controller.signal.aborted) setJob(rows[0] || null);
      })
      .catch(e => {
        if (!controller.signal.aborted) setJobError(e.message);
      });
    return () => controller.abort();
  }, [artifactId, canManage, validId]);

  useEffect(() => {
    if (!job?.scanJobId || !running(job.status)) return;
    const controller = new AbortController();
    let timer;
    async function poll() {
      try {
        const next = await getScanJob(artifactId, job.scanJobId, controller.signal);
        if (!controller.signal.aborted) {
          setJob(next);
          setJobError('');
        }
      } catch (e) {
        if (!controller.signal.aborted) setJobError(e.message);
      }
      if (!controller.signal.aborted) timer = setTimeout(poll, 5000);
    }
    timer = setTimeout(poll, 2500);
    return () => {
      controller.abort();
      clearTimeout(timer);
    };
  }, [artifactId, job?.scanJobId, job?.status]);

  async function chooseGlb(file) {
    if (!file) return;
    const ticket = ++selection.current;
    try {
      setError('');
      await validateGlbPreview(file);
      if (ticket !== selection.current) return;
      setViewerError('');
      setDraft({ file, url: URL.createObjectURL(file), source: 'file' });
      setMessage('Bản xem thử chưa được lưu vào hiện vật.');
    } catch (e) {
      setError(e.message);
    }
  }

  async function perform(task) {
    setBusy(true);
    setError('');
    setMessage('');
    action.current = new AbortController();
    try {
      await task(action.current.signal);
    } catch (e) {
      setError(e.name === 'AbortError' ? 'Đã ngắt yêu cầu; kiểm tra danh sách job trước khi gửi lại.' : e.message);
    } finally {
      setBusy(false);
    }
  }

  const viewScan = () =>
    perform(async signal => {
      const blob = await getScanModel(artifactId, job.scanJobId, signal);
      setViewerError('');
      setDraft({ url: URL.createObjectURL(blob), source: 'scan', jobId: job.scanJobId });
      setMessage('Bản AI mới dựng. Kiểm tra hình dáng và texture trước khi lưu.');
    });

  const start = () =>
    perform(async signal => {
      const dataset = prepareScanDataset(files, mode);
      setProgress(0);
      const created = await startArtifactScan(artifactId, dataset, setProgress, signal);
      setJob(created);
      setJobError('');
      setFiles([]);
      setDraft(null);
      setMessage('Đã nhận bộ ảnh. Bạn có thể đóng trang rồi quay lại xem tiến độ.');
    });

  const save = () => {
    if (model && !window.confirm('Thay mô hình hiện đang lưu bằng bản xem thử này?')) return;
    perform(async signal => {
      if (draft.source === 'scan') {
        await saveScanModel(artifactId, draft.jobId);
        setJob(prev => (prev?.scanJobId === draft.jobId ? { ...prev, status: 'COMPLETED' } : prev));
      } else {
        const form = new FormData();
        form.append('file', draft.file);
        form.append('name', name || '');
        await uploadMedia(path, form, setProgress, signal);
      }
      setDraft(null);
      setRevision(v => v + 1);
      setMessage('Đã lưu mô hình vào hiện vật thành công.');
    });
  };

  const remove = () => {
    if (!window.confirm('Xóa mô hình đã lưu của hiện vật này?')) return;
    perform(async () => {
      await mediaApi(path, { method: 'DELETE' });
      setModel(null);
      setSavedUrl('');
      setRevision(v => v + 1);
      setMessage('Đã xóa mô hình đã lưu.');
    });
  };

  const discard = () =>
    perform(async () => {
      await discardScanModel(artifactId, job.scanJobId);
      if (draft?.jobId === job.scanJobId) setDraft(null);
      setJob(null);
      setMessage('Đã bỏ kết quả scan.');
    });

  if (!validId) return <p>Lưu hiện vật trước khi thêm mô hình 3D.</p>;

  const activeModelUrl = draft?.url || savedUrl;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* Alert Messages */}
      {error && <p role="alert" className="business-error">{error}</p>}
      {message && <div style={{ padding: '10px 14px', borderRadius: '8px', background: '#F0FDF4', color: '#166534', border: '1px solid #BBF7D0', fontSize: '0.82rem' }}>{message}</div>}
      {viewerError && <p role="alert" className="business-error">{viewerError}</p>}

      {/* 2-Column Responsive Layout */}
      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(280px, 360px) minmax(0, 1fr)', gap: '20px', alignItems: 'start' }}>
        {/* Left Column: Compact 3D Preview Box */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          <div
            ref={viewer}
            style={{
              position: 'relative',
              height: '280px',
              borderRadius: '12px',
              overflow: 'hidden',
              background: 'linear-gradient(180deg, #1A1F26 0%, #11151A 100%)',
              border: '1px solid var(--color-paper-border)',
              boxShadow: 'var(--shadow-sm)'
            }}
          >
            {activeModelUrl ? (
              <>
                <ArtifactModelViewer key={activeModelUrl} url={activeModelUrl} name={name} style={{ height: '280px' }} />
                <span
                  style={{
                    position: 'absolute',
                    top: '10px',
                    left: '10px',
                    fontSize: '0.7rem',
                    fontWeight: '700',
                    padding: '3px 8px',
                    borderRadius: '6px',
                    background: draft ? '#FEF3C7' : '#DCFCE7',
                    color: draft ? '#92400E' : '#166534',
                    backdropFilter: 'blur(4px)',
                    border: '1px solid rgba(255,255,255,0.2)'
                  }}
                >
                  {draft ? '⚡ Bản xem thử (chưa lưu)' : '✓ Mô hình đang lưu'}
                </span>
              </>
            ) : (
              <div style={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: '#94A3B8', padding: '20px', textAlign: 'center' }}>
                <Box size={36} color="var(--color-gold-400)" style={{ marginBottom: '8px', opacity: 0.8 }} />
                <strong style={{ fontSize: '0.85rem', color: '#E2E8F0' }}>
                  {loading ? 'Đang tải mô hình…' : 'Chưa có mô hình 3D'}
                </strong>
                <p style={{ fontSize: '0.75rem', marginTop: '4px', maxWidth: '200px' }}>
                  Tải file .glb hoặc sử dụng AI để dựng 3D từ ảnh chụp
                </p>
              </div>
            )}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', fontSize: '0.74rem', color: 'var(--color-charcoal-500)' }}>
            <span>🖱️ Kéo để xoay 360°</span>
            <span>•</span>
            <span>Cuộn để phóng to/nhỏ</span>
          </div>

          {/* Quick Actions for Current Model */}
          {canManage && (
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              <label
                className="btn btn-secondary btn-sm"
                style={{ flex: 1, cursor: busy ? 'not-allowed' : 'pointer', justifyContent: 'center' }}
              >
                <Upload size={14} /> Chọn GLB mới
                <input
                  aria-label="Chọn GLB để xem thử"
                  type="file"
                  accept=".glb"
                  disabled={busy}
                  style={{ display: 'none' }}
                  onChange={e => {
                    chooseGlb(e.target.files[0]);
                    e.target.value = '';
                  }}
                />
              </label>

              {draft && (
                <>
                  <button
                    type="button"
                    className="btn btn-primary btn-sm"
                    disabled={busy || loading || !!viewerError}
                    onClick={save}
                  >
                    <Check size={14} /> Lưu vào hiện vật
                  </button>
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    disabled={busy}
                    onClick={() => {
                      selection.current++;
                      setDraft(null);
                      setViewerError('');
                      setMessage('Đã hủy bản xem thử.');
                    }}
                  >
                    Hủy
                  </button>
                </>
              )}

              {model && !draft && (
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  style={{ color: 'var(--color-danger)' }}
                  disabled={busy}
                  onClick={remove}
                  title="Xóa mô hình 3D đã lưu"
                >
                  <Trash2 size={13} /> Xóa model
                </button>
              )}
            </div>
          )}
        </div>

        {/* Right Column: AI 3D Reconstruction & Information */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div style={{ padding: '16px 18px', borderRadius: '10px', background: '#FAF7F2', border: '1px solid var(--color-paper-border)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
              <Sparkles size={16} color="var(--color-gold-600)" />
              <h4 style={{ fontSize: '0.92rem', fontWeight: '700', color: 'var(--color-burgundy-900)', margin: 0 }}>
                Tạo mô hình 3D tự động bằng AI
              </h4>
            </div>
            <p style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-600)', margin: '0 0 14px', lineHeight: 1.5 }}>
              Tải lên bộ ảnh chụp quanh hiện vật (từ 5 đến 200 ảnh). Mô hình AI sẽ trích xuất điểm đặc trưng và dựng file GLB trực tiếp trên máy chủ.
            </p>

            {canManage && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: '8px' }}>
                  <label className="btn btn-secondary btn-sm" style={{ cursor: busy ? 'not-allowed' : 'pointer', justifyContent: 'center' }}>
                    <Folder size={14} /> Chọn folder ảnh
                    <input
                      aria-label="Chọn folder ảnh"
                      type="file"
                      webkitdirectory=""
                      multiple
                      disabled={busy || running(job?.status)}
                      style={{ display: 'none' }}
                      onChange={e => {
                        setFiles(Array.from(e.target.files || []));
                        e.target.value = '';
                      }}
                    />
                  </label>

                  <label className="btn btn-secondary btn-sm" style={{ cursor: busy ? 'not-allowed' : 'pointer', justifyContent: 'center' }}>
                    <Upload size={14} /> Chọn nhiều ảnh
                    <input
                      aria-label="Chọn nhiều ảnh"
                      type="file"
                      accept=".jpg,.jpeg,.png"
                      multiple
                      disabled={busy || running(job?.status)}
                      style={{ display: 'none' }}
                      onChange={e => {
                        setFiles(Array.from(e.target.files || []));
                        e.target.value = '';
                      }}
                    />
                  </label>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '10px', flexWrap: 'wrap' }}>
                  <span style={{ fontSize: '0.76rem', color: files.length ? 'var(--color-burgundy-700)' : 'var(--color-charcoal-500)', fontWeight: files.length ? '600' : '400' }}>
                    {files.length ? `✓ Đã chọn ${files.length} ảnh` : 'Chưa chọn ảnh (5–200 ảnh)'}
                  </span>

                  <select
                    className="form-select form-select-sm"
                    style={{ width: 'auto' }}
                    value={mode}
                    onChange={e => setMode(e.target.value)}
                    disabled={busy}
                  >
                    <option value="auto">Chế độ tự động</option>
                    <option value="photos">Chỉ ảnh chụp</option>
                    <option value="benchmark">Dataset có OBJ</option>
                  </select>
                </div>

                <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '4px' }}>
                  <button
                    type="button"
                    className="btn btn-gold btn-sm"
                    disabled={busy || running(job?.status) || !files.length}
                    onClick={start}
                  >
                    <Sparkles size={14} /> Bắt đầu dựng 3D
                  </button>
                </div>

                {busy && (
                  <div style={{ marginTop: '6px' }}>
                    <progress max="100" value={progress} style={{ width: '100%', height: '6px' }} />
                    <span style={{ fontSize: '0.72rem', color: 'var(--color-charcoal-500)' }}>Đang tải bộ ảnh lên máy chủ...</span>
                  </div>
                )}

                {jobError && <p role="alert" className="business-error" style={{ fontSize: '0.75rem', margin: '4px 0' }}>{jobError}</p>}

                {/* Job Tracking Card */}
                {job && (
                  <div style={{ marginTop: '8px', padding: '10px 12px', background: '#FFF', borderRadius: '8px', border: '1px solid var(--color-paper-border)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '0.78rem' }}>
                      <strong>{labels[job.status] || job.status}</strong>
                      <span style={{ color: 'var(--color-burgundy-700)', fontWeight: '700' }}>{job.progress || 0}%</span>
                    </div>
                    <progress max="100" value={job.progress || 0} style={{ width: '100%', height: '5px', margin: '6px 0' }} />
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '6px' }}>
                      <span style={{ fontSize: '0.7rem', color: 'var(--color-charcoal-400)' }}>Mã tác vụ: #{job.scanJobId}</span>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        {job.status === 'REVIEW_REQUIRED' && (
                          <button type="button" className="btn btn-primary btn-sm" disabled={busy} onClick={viewScan}>
                            Xem kết quả
                          </button>
                        )}
                        {['REVIEW_REQUIRED', 'FAILED'].includes(job.status) && (
                          <button type="button" className="btn btn-secondary btn-sm" disabled={busy} onClick={discard}>
                            Bỏ kết quả
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
