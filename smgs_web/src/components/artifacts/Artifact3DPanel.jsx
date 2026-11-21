import React, { useEffect, useRef, useState } from 'react';
import '@google/model-viewer';
import ArtifactModelViewer, { isSketchfabUrl } from '../common/ArtifactModelViewer';
import { mediaApi, uploadMedia } from '../../services/mediaApi';
import {
  prepareScanDataset,
  startScanSafely,
  getScanJobs,
  getScanJob,
  getScanModel,
  saveScanModel,
  discardScanModel,
  validateGlbPreview
} from '../../services/artifactScanApi';
import { scanProgress } from './scanProgress';
import {
  Box,
  Upload,
  Sparkles,
  Check,
  CheckCircle2,
  Trash2,
  RefreshCw,
  Folder,
  AlertCircle,
  Clock,
  Layers,
  Image as ImageIcon,
  Cpu,
  Eye,
  Info,
  ChevronRight,
  ExternalLink,
  Settings,
  Link2
} from 'lucide-react';

const running = s => ['QUEUED', 'PROCESSING', 'FINALIZING'].includes(s);
const labels = {
  QUEUED: 'Đang xếp hàng chờ xử lý',
  PROCESSING: 'AI đang phân tích & dựng lưới 3D',
  FINALIZING: 'Đang kiểm định & đóng gói GLB',
  REVIEW_REQUIRED: 'Đã dựng xong — Sẵn sàng xem thử',
  FAILED: 'Quá trình dựng 3D thất bại',
  COMPLETED: 'Đã lưu vào hiện vật',
  DISCARDED: 'Đã hủy kết quả scan'
};

export default function Artifact3DPanel({ artifactId, name, canManage = false, onModelChange }) {
  const validId = Number.isInteger(Number(artifactId)) && Number(artifactId) > 0;
  const path = `artifacts/${artifactId}/model-3d`;
  const [model, setModel] = useState(null), [savedUrl, setSavedUrl] = useState('');
  const [draft, setDraft] = useState(null), [job, setJob] = useState(null), [files, setFiles] = useState([]);
  const [mode, setMode] = useState('auto'), [busy, setBusy] = useState(false), [progress, setProgress] = useState(0);
  const [error, setError] = useState(''), [message, setMessage] = useState(''), [jobError, setJobError] = useState('');
  const [revision, setRevision] = useState(0), [loading, setLoading] = useState(true);
  const [processedPhotoCount, setProcessedPhotoCount] = useState(0);
  const [manualShowProcessing, setManualShowProcessing] = useState(false);
  const [uploading, setUploading] = useState(false), [needsJobCheck, setNeedsJobCheck] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [showSketchfab, setShowSketchfab] = useState(false);
  const [sketchfabUrl, setSketchfabUrl] = useState('');
  const [settingsForm, setSettingsForm] = useState({
    name: '',
    autoRotate: true,
    cameraOrbit: '',
    fieldOfView: '',
    scale: 1.0,
    posterUrl: ''
  });
  const action = useRef(null), selection = useRef(0), viewer = useRef(null);
  const [viewerError, setViewerError] = useState('');

  useEffect(() => {
    if (model) {
      setSettingsForm({
        name: model.name || '',
        autoRotate: model.autoRotate ?? true,
        cameraOrbit: model.cameraOrbit || '',
        fieldOfView: model.fieldOfView || '',
        scale: model.scale || 1.0,
        posterUrl: model.posterUrl || ''
      });
    }
  }, [model]);

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
        if (!controller.signal.aborted) {
          const first = rows[0] || null;
          setJob(first);
          if (first?.imageCount) setProcessedPhotoCount(first.imageCount);
        }
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
          if (next?.imageCount) setProcessedPhotoCount(next.imageCount);
        }
      } catch (e) {
        if (!controller.signal.aborted) setJobError(e.message);
      }
      if (!controller.signal.aborted) timer = setTimeout(poll, 4000);
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
      if (e.requiresJobCheck) setNeedsJobCheck(true);
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
      const photoCount = dataset.images.length;
      setProcessedPhotoCount(photoCount);
      setProgress(0);
      setUploading(true);
      try {
        const { job: created, recovered } = await startScanSafely(artifactId, dataset, { onProgress: setProgress, signal });
        setJob(created);
        setProcessedPhotoCount(created.imageCount || photoCount);
        setMode(created.mode || dataset.mode);
        setNeedsJobCheck(false);
        setJobError('');
        setFiles([]);
        setDraft(null);
        setMessage(recovered ? 'Đã tìm thấy tác vụ trên máy chủ; tiếp tục theo dõi, không gửi lại bộ ảnh.' : 'Đã nhận bộ ảnh. Dựng 3D có thể mất 15–20 phút hoặc lâu hơn tùy bộ ảnh; bạn có thể đóng trang rồi quay lại xem tiến độ.');
      } finally { setUploading(false); }
    });

  const checkReceived = () => perform(async signal => {
    const rows = await getScanJobs(artifactId, signal);
    const found = rows.find(row => running(row.status) || row.status === 'REVIEW_REQUIRED') || rows[0] || null;
    setJob(found);
    setNeedsJobCheck(false);
    setJobError('');
    if (found?.imageCount) setProcessedPhotoCount(found.imageCount);
    setMessage(found ? 'Đã tải lại tác vụ trên máy chủ. Kiểm tra trạng thái trước khi gửi bộ ảnh mới.' : 'Máy chủ chưa có tác vụ cho hiện vật này. Bạn có thể gửi lại bộ ảnh.');
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
      setManualShowProcessing(false);
      setMessage('Đã bỏ kết quả scan.');
    });

  const saveSettings = () =>
    perform(async () => {
      const updated = await mediaApi(path + '/settings', {
        method: 'PATCH',
        body: {
          name: settingsForm.name?.trim() || null,
          autoRotate: Boolean(settingsForm.autoRotate),
          cameraOrbit: settingsForm.cameraOrbit?.trim() || null,
          fieldOfView: settingsForm.fieldOfView?.trim() || null,
          scale: Number(settingsForm.scale) || 1.0,
          posterUrl: settingsForm.posterUrl?.trim() || null
        }
      });
      setModel(prev => ({ ...prev, ...updated }));
      setShowSettings(false);
      setMessage('Đã cập nhật cấu hình hiển thị và camera 3D.');
    });

  const linkSketchfab = () => {
    if (!sketchfabUrl.trim()) return;
    perform(async () => {
      const updated = await mediaApi(path + '/sketchfab', {
        method: 'PUT',
        body: { url: sketchfabUrl.trim() }
      });
      setModel(updated);
      setSavedUrl(updated?.modelUrl || sketchfabUrl.trim());
      setShowSketchfab(false);
      setSketchfabUrl('');
      setMessage('Đã liên kết mô hình 3D từ Sketchfab thành công.');
    });
  };

  const openViewerPage = () => {
    const apiBase = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');
    window.open(`${apiBase}/artifacts/${artifactId}/viewer-ui`, '_blank', 'noopener,noreferrer');
  };

  if (!validId) return <p>Lưu hiện vật trước khi thêm mô hình 3D.</p>;

  const activeModelUrl = draft?.url || savedUrl;
  const { running: isScanning, review: isReview, step: currentStep, percent: currentPercent } = scanProgress({ uploading, uploadProgress: progress, job, hasPreview: !!draft });
  const showProcessingScreen = uploading || isScanning || isReview || manualShowProcessing;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* Alert Messages */}
      {error && <p role="alert" className="business-error">{error}</p>}
      {canManage && needsJobCheck && <button type="button" className="btn btn-secondary btn-sm" disabled={busy} onClick={checkReceived}><RefreshCw size={14} /> Kiểm tra job đã nhận</button>}
      {message && (
        <div style={{ padding: '10px 14px', borderRadius: '8px', background: '#F0FDF4', color: '#166534', border: '1px solid #BBF7D0', fontSize: '0.82rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <CheckCircle2 size={16} /> {message}
        </div>
      )}
      {viewerError && <p role="alert" className="business-error">{viewerError}</p>}

      {/* Modern Pipeline Stepper Header */}
      <div className="ai-scan-stepper">
        <div className={`ai-scan-step ${currentStep >= 1 ? 'completed' : 'active'}`}>
          <div className="ai-scan-step-circle">
            {currentStep > 1 ? <Check size={16} /> : '1'}
          </div>
          <span className="ai-scan-step-label">1. Chuẩn bị ảnh</span>
        </div>

        <div className={`ai-scan-step ${currentStep > 2 ? 'completed' : currentStep === 2 ? 'active' : ''}`}>
          <div className="ai-scan-step-circle">
            {currentStep > 2 ? <Check size={16} /> : currentStep === 2 ? <RefreshCw size={14} className="spin" /> : '2'}
          </div>
          <span className="ai-scan-step-label">2. Tải lên máy chủ</span>
        </div>

        <div className={`ai-scan-step ${currentStep > 3 ? 'completed' : currentStep === 3 ? 'active' : ''}`}>
          <div className="ai-scan-step-circle">
            {currentStep > 3 ? <Check size={16} /> : currentStep === 3 ? <Sparkles size={14} /> : '3'}
          </div>
          <span className="ai-scan-step-label">3. AI Dựng 3D</span>
        </div>

        <div className={`ai-scan-step ${currentStep === 4 ? (draft || model ? 'completed' : 'active') : ''}`}>
          <div className="ai-scan-step-circle">
            {model && !draft ? <Check size={16} /> : '4'}
          </div>
          <span className="ai-scan-step-label">4. Xem & Lưu</span>
        </div>
      </div>

      {/* 2-Column Responsive Layout */}
      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(280px, 340px) minmax(0, 1fr)', gap: '20px', alignItems: 'start' }}>
        
        {/* Left Column: Compact 3D Preview Box & Direct GLB Controls */}
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
                  {isScanning ? 'AI đang tạo mô hình 3D từ ảnh...' : 'Tải file .glb hoặc sử dụng AI để dựng 3D từ ảnh chụp'}
                </p>
              </div>
            )}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', fontSize: '0.74rem', color: 'var(--color-charcoal-500)' }}>
            <span>🖱️ Kéo để xoay 360°</span>
            <span>•</span>
            <span>Cuộn để phóng to/nhỏ</span>
          </div>

          <button
            type="button"
            className="btn btn-secondary btn-sm"
            style={{ width: '100%', justifyContent: 'center', gap: '6px' }}
            onClick={openViewerPage}
            title="Mở giao diện tương tác 3D và audio thuyết minh toàn màn hình"
          >
            <ExternalLink size={13} /> Mở 3D Viewer UI
          </button>

          {/* Quick Actions for Current Model */}
          {canManage && (
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              <label
                className="btn btn-secondary btn-sm"
                style={{ flex: 1, cursor: busy ? 'not-allowed' : 'pointer', justifyContent: 'center' }}
              >
                <Upload size={14} /> Tải file GLB có sẵn
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

              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => setShowSketchfab(v => !v)}
                title="Nhúng mô hình từ Sketchfab"
              >
                <Link2 size={13} /> Sketchfab
              </button>

              {model && !draft && (
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  onClick={() => setShowSettings(v => !v)}
                  title="Cấu hình hiển thị và góc camera 3D"
                >
                  <Settings size={13} /> Cài đặt 3D
                </button>
              )}

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

          {showSketchfab && canManage && (
            <div style={{ padding: '12px', background: '#F8FAFC', borderRadius: '8px', border: '1px solid #CBD5E1', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <strong style={{ fontSize: '0.8rem', color: '#1E293B' }}>Liên kết mô hình từ Sketchfab</strong>
              <input
                type="url"
                className="form-input"
                style={{ fontSize: '0.8rem', padding: '6px 10px' }}
                placeholder="https://sketchfab.com/3d-models/... hoặc Model UID"
                value={sketchfabUrl}
                onChange={e => setSketchfabUrl(e.target.value)}
                disabled={busy}
              />
              <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                <button type="button" className="btn btn-secondary btn-sm" onClick={() => setShowSketchfab(false)}>Đóng</button>
                <button type="button" className="btn btn-primary btn-sm" disabled={busy || !sketchfabUrl.trim()} onClick={linkSketchfab}>Liên kết</button>
              </div>
            </div>
          )}

          {showSettings && canManage && (
            <div style={{ padding: '14px', background: '#F8FAFC', borderRadius: '8px', border: '1px solid #CBD5E1', display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <strong style={{ fontSize: '0.82rem', color: '#1E293B' }}>Cấu hình hiển thị 3D & Camera</strong>
                <button type="button" className="btn btn-secondary btn-sm" style={{ padding: '2px 6px', height: 'auto' }} onClick={() => setShowSettings(false)}>✕</button>
              </div>
              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.8rem', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={settingsForm.autoRotate}
                  onChange={e => setSettingsForm(prev => ({ ...prev, autoRotate: e.target.checked }))}
                />
                Tự động xoay quanh tâm (Auto Rotate)
              </label>
              <div>
                <span style={{ fontSize: '0.75rem', color: '#64748B', display: 'block', marginBottom: '3px' }}>Góc quỹ đạo camera (Camera Orbit)</span>
                <input
                  type="text"
                  className="form-input"
                  style={{ fontSize: '0.8rem', padding: '5px 8px' }}
                  placeholder="vd: 45deg 55deg 2.5m hoặc 0deg 75deg 105%"
                  value={settingsForm.cameraOrbit}
                  onChange={e => setSettingsForm(prev => ({ ...prev, cameraOrbit: e.target.value }))}
                />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748B', display: 'block', marginBottom: '3px' }}>Góc nhìn (FOV)</span>
                  <input
                    type="text"
                    className="form-input"
                    style={{ fontSize: '0.8rem', padding: '5px 8px' }}
                    placeholder="vd: 30deg"
                    value={settingsForm.fieldOfView}
                    onChange={e => setSettingsForm(prev => ({ ...prev, fieldOfView: e.target.value }))}
                  />
                </div>
                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748B', display: 'block', marginBottom: '3px' }}>Tỷ lệ phóng to (Scale)</span>
                  <input
                    type="number"
                    step="0.1"
                    min="0.1"
                    max="50"
                    className="form-input"
                    style={{ fontSize: '0.8rem', padding: '5px 8px' }}
                    value={settingsForm.scale}
                    onChange={e => setSettingsForm(prev => ({ ...prev, scale: parseFloat(e.target.value) || 1.0 }))}
                  />
                </div>
              </div>
              <div>
                <span style={{ fontSize: '0.75rem', color: '#64748B', display: 'block', marginBottom: '3px' }}>Tên nhãn / Tiêu đề model</span>
                <input
                  type="text"
                  className="form-input"
                  style={{ fontSize: '0.8rem', padding: '5px 8px' }}
                  placeholder="Tên hiển thị khi xoay..."
                  value={settingsForm.name}
                  onChange={e => setSettingsForm(prev => ({ ...prev, name: e.target.value }))}
                />
              </div>
              <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', marginTop: '4px' }}>
                <button type="button" className="btn btn-secondary btn-sm" onClick={() => setShowSettings(false)}>Hủy</button>
                <button type="button" className="btn btn-primary btn-sm" disabled={busy} onClick={saveSettings}>Lưu cấu hình</button>
              </div>
            </div>
          )}
        </div>

        {/* Right Column: AI 3D Processing Console or Input Form */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          
          {/* =========================================================
              VIEW A: DEDICATED PROCESSING & REVIEW SCREEN (Requested UI)
              ========================================================= */}
          {showProcessingScreen ? (
            <div style={{ padding: '18px 20px', borderRadius: '14px', background: '#FFFDF9', border: '1px solid var(--color-paper-border)', boxShadow: 'var(--shadow-sm)' }}>
              
              {/* Header Status Bar */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', marginBottom: '14px', flexWrap: 'wrap' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Sparkles size={18} color="var(--color-gold-600)" />
                  <span style={{ fontSize: '0.75rem', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--color-burgundy-900)' }}>
                    {uploading ? 'BƯỚC 2/4 · TẢI BỘ ẢNH LÊN MÁY CHỦ' : !job ? 'CHƯA CÓ TÁC VỤ DỰNG 3D' : isReview ? 'BƯỚC 4/4 · XEM KẾT QUẢ' : 'TÁC VỤ DỰNG 3D'}
                  </span>
                </div>
                <span
                  style={{
                    fontSize: '0.75rem',
                    fontWeight: '600',
                    padding: '4px 10px',
                    borderRadius: '20px',
                    background: isReview ? '#DCFCE7' : '#FEF3C7',
                    color: isReview ? '#166534' : '#92400E',
                    border: `1px solid ${isReview ? '#86EFAC' : '#FDE68A'}`
                  }}
                >
                  {uploading ? 'Đang tải bộ ảnh...' : labels[job?.status] || 'Chưa có tác vụ'}
                </span>
              </div>

              {/* 3D Scanning Holographic Radar Viewport */}
              <div className="ai-scan-radar-viewport">
                <div className="ai-scan-radar-sweep" />
                <div className="ai-scan-laser-line" />
                
                <div className="ai-scan-3d-hologram">
                  <Box size={52} color="var(--color-gold-400)" style={{ filter: 'drop-shadow(0 0 16px rgba(245, 158, 11, 0.6))' }} />
                  <span style={{ marginTop: '8px', fontSize: '0.72rem', letterSpacing: '0.08em', fontWeight: '700', color: '#F1F5F9', textTransform: 'uppercase' }}>
                    {uploading ? 'ĐANG TẢI BỘ ẢNH' : isReview ? '3D MESH READY' : job ? 'PHOTOGRAMMETRY SCAN' : 'CHƯA BẮT ĐẦU'}
                  </span>
                </div>

                <div
                  style={{
                    position: 'absolute',
                    bottom: '12px',
                    background: 'rgba(15, 23, 42, 0.75)',
                    padding: '4px 14px',
                    borderRadius: '20px',
                    backdropFilter: 'blur(6px)',
                    border: '1px solid rgba(197, 160, 89, 0.3)',
                    color: '#FEF08A',
                    fontSize: '0.75rem',
                    fontWeight: '700'
                  }}
                >
                  {uploading ? `Tải bộ ảnh: ${currentPercent}%` : isReview ? '✓ Đã tạo xong mô hình 3D (100%)' : `Tiến độ dựng: ${currentPercent}%`}
                </div>
              </div>

              {/* Information & Instructions */}
              <div style={{ marginTop: '16px', textAlign: 'center' }}>
                <h4 style={{ fontSize: '1.05rem', fontWeight: '700', color: 'var(--color-burgundy-900)', margin: '0 0 6px' }}>
                  {uploading ? (progress >= 100 ? 'Đang chờ máy chủ xác nhận tác vụ...' : `Đang tải bộ ảnh: ${progress}%`) : !job ? 'Chưa có tác vụ dựng 3D.' : isReview
                    ? 'AI đã tái tạo mô hình 3D thành công!'
                    : `AI đang phân tích và dựng mô hình 3D từ ${processedPhotoCount || files.length || 'bộ'} ảnh chụp...`}
                </h4>
                <p style={{ fontSize: '0.8rem', color: 'var(--color-charcoal-600)', margin: '0 auto', maxWidth: '520px', lineHeight: 1.55 }}>
                  {uploading ? 'Giữ trang mở trong khi tải ảnh. Tiến độ này là tải dữ liệu, chưa phải dựng 3D.' : !job ? 'Chọn bộ ảnh rồi bấm Bắt đầu dựng 3D.' : isReview
                    ? 'Quá trình trích xuất mây điểm và xây dựng lưới đa giác đã hoàn tất. Bạn có thể bấm "Xem kết quả" để nạp mô hình vào khung xoay 360° bên trái trước khi lưu vào hiện vật.'
                    : 'Đang trích xuất đặc trưng điểm ảnh (SfM) và tái tạo mạng lưới đa giác bề mặt (Dense Mesh). Quá trình xử lý diễn ra hoàn toàn trên máy chủ AI; bạn có thể đóng cửa sổ này rồi quay lại kiểm tra bất cứ lúc nào.'}
                </p>
              </div>

              {/* Live Shimmer Progress Bar */}
              <div style={{ marginTop: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.78rem', marginBottom: '6px' }}>
                  <span style={{ fontWeight: '600', color: 'var(--color-charcoal-700)' }}>
                    {uploading ? 'Tiến độ tải ảnh:' : isReview ? 'Hoàn thành dựng 3D' : 'Tiến độ dựng 3D:'}
                  </span>
                  <span style={{ fontWeight: '700', color: 'var(--color-burgundy-700)' }}>
                    {currentPercent}%
                  </span>
                </div>
                <div className="ai-scan-progress-shimmer">
                  <div className="ai-scan-progress-shimmer-fill" style={{ width: `${currentPercent}%` }} />
                </div>
              </div>

              {/* Sub-phase Checklist */}
              {!uploading && job && <div className="ai-scan-phase-list">
                <div className={`ai-scan-phase-item ${currentPercent >= 25 ? 'done' : 'current'}`}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    {currentPercent >= 25 ? <Check size={14} color="#166534" /> : <RefreshCw size={14} className="spin" color="var(--color-gold-600)" />}
                    <span>1. Phân tích ảnh chụp & định hướng tiêu cự (Feature Extraction)</span>
                  </div>
                  <span style={{ fontSize: '0.7rem', color: currentPercent >= 25 ? '#166534' : 'var(--color-gold-700)', fontWeight: '600' }}>
                    {currentPercent >= 25 ? 'Hoàn tất' : 'Đang chạy'}
                  </span>
                </div>

                <div className={`ai-scan-phase-item ${currentPercent >= 55 ? 'done' : currentPercent >= 25 ? 'current' : ''}`}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    {currentPercent >= 55 ? <Check size={14} color="#166534" /> : currentPercent >= 25 ? <RefreshCw size={14} className="spin" color="var(--color-gold-600)" /> : <Clock size={14} color="#94A3B8" />}
                    <span>2. Khớp đám mây điểm thưa không gian (Sparse Point Cloud - SfM)</span>
                  </div>
                  <span style={{ fontSize: '0.7rem', color: currentPercent >= 55 ? '#166534' : currentPercent >= 25 ? 'var(--color-gold-700)' : '#94A3B8', fontWeight: '600' }}>
                    {currentPercent >= 55 ? 'Hoàn tất' : currentPercent >= 25 ? 'Đang chạy' : 'Đang chờ'}
                  </span>
                </div>

                <div className={`ai-scan-phase-item ${currentPercent >= 85 ? 'done' : currentPercent >= 55 ? 'current' : ''}`}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    {currentPercent >= 85 ? <Check size={14} color="#166534" /> : currentPercent >= 55 ? <RefreshCw size={14} className="spin" color="var(--color-gold-600)" /> : <Clock size={14} color="#94A3B8" />}
                    <span>3. Dựng mạng lưới bề mặt đa giác dày đặc (Dense Mesh Modeling)</span>
                  </div>
                  <span style={{ fontSize: '0.7rem', color: currentPercent >= 85 ? '#166534' : currentPercent >= 55 ? 'var(--color-gold-700)' : '#94A3B8', fontWeight: '600' }}>
                    {currentPercent >= 85 ? 'Hoàn tất' : currentPercent >= 55 ? 'Đang chạy' : 'Đang chờ'}
                  </span>
                </div>

                <div className={`ai-scan-phase-item ${currentPercent >= 100 ? 'done' : currentPercent >= 85 ? 'current' : ''}`}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    {currentPercent >= 100 ? <Check size={14} color="#166534" /> : currentPercent >= 85 ? <RefreshCw size={14} className="spin" color="var(--color-gold-600)" /> : <Clock size={14} color="#94A3B8" />}
                    <span>4. Tạo bản đồ màu & Xuất file GLB chuẩn Web/AR (Texture & Export)</span>
                  </div>
                  <span style={{ fontSize: '0.7rem', color: currentPercent >= 100 ? '#166534' : currentPercent >= 85 ? 'var(--color-gold-700)' : '#94A3B8', fontWeight: '600' }}>
                    {currentPercent >= 100 ? 'Hoàn tất' : currentPercent >= 85 ? 'Đang đóng gói' : 'Đang chờ'}
                  </span>
                </div>
              </div>}

              {/* Side Specification Grid (Matching user's reference image cards) */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: '10px', marginTop: '16px' }}>
                <div className="ai-scan-spec-card">
                  <small>Ảnh đầu vào</small>
                  <strong>{processedPhotoCount || job?.imageCount || 0} ảnh JPG/PNG</strong>
                </div>
                <div className="ai-scan-spec-card">
                  <small>Chất lượng lưới</small>
                  <strong>Kiểm tra khi xem kết quả</strong>
                </div>
                <div className="ai-scan-spec-card">
                  <small>Chế độ dựng</small>
                  <strong>{mode === 'auto' ? 'Tự động tối ưu' : mode === 'photos' ? 'Chỉ ảnh chụp' : 'Bộ chuẩn có OBJ'}</strong>
                </div>
                <div className="ai-scan-spec-card">
                  <small>Định dạng xuất</small>
                  <strong>.GLB (Web 3D/AR)</strong>
                </div>
              </div>

              {/* Action Buttons for Processing / Review */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '10px', marginTop: '18px', paddingTop: '14px', borderTop: '1px solid var(--color-paper-border)', flexWrap: 'wrap' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.74rem', color: 'var(--color-charcoal-500)' }}>
                  <Cpu size={14} />
                  <span>Mã tác vụ: <b>{job?.scanJobId ? '#' + String(job.scanJobId).substring(0, 8) : 'Chưa được xác nhận'}</b></span>
                </div>

                <div style={{ display: 'flex', gap: '8px' }}>
                  {isReview && (
                    <button
                      type="button"
                      className="btn btn-primary btn-sm"
                      disabled={busy}
                      onClick={viewScan}
                      style={{ background: 'var(--color-burgundy-900)', border: 'none', color: '#fff', gap: '6px' }}
                    >
                      <Eye size={15} /> Xem kết quả 3D
                    </button>
                  )}

                  {['REVIEW_REQUIRED', 'FAILED'].includes(job?.status) && (
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      disabled={busy}
                      onClick={discard}
                      style={{ color: 'var(--color-charcoal-700)' }}
                    >
                      <Trash2 size={14} /> Bỏ kết quả
                    </button>
                  )}

                  {running(job?.status) && (
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      disabled={busy}
                      onClick={() => {
                        const controller = new AbortController();
                        getScanJob(artifactId, job.scanJobId, controller.signal).then(res => setJob(res));
                      }}
                      title="Làm mới trạng thái"
                    >
                      <RefreshCw size={13} className={busy ? 'spin' : ''} /> Kiểm tra ngay
                    </button>
                  )}

                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    onClick={() => setManualShowProcessing(false)}
                    style={{ fontSize: '0.76rem' }}
                  >
                    Đóng bảng tiến trình
                  </button>
                </div>
              </div>

              {jobError && (
                <div style={{ marginTop: '10px', padding: '8px 12px', borderRadius: '6px', background: '#FEF2F2', border: '1px solid #FECACA', color: '#B91C1C', fontSize: '0.75rem' }}>
                  {jobError}
                </div>
              )}
            </div>
          ) : (

            /* =========================================================
               VIEW B: INPUT & UPLOAD FORM (When no scan active)
               ========================================================= */
            <div style={{ padding: '16px 18px', borderRadius: '12px', background: '#FAF7F2', border: '1px solid var(--color-paper-border)' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px', marginBottom: '6px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Sparkles size={16} color="var(--color-gold-600)" />
                  <h4 style={{ fontSize: '0.92rem', fontWeight: '700', color: 'var(--color-burgundy-900)', margin: 0 }}>
                    Tạo mô hình 3D tự động bằng AI
                  </h4>
                </div>
                {job && (
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    style={{ fontSize: '0.72rem', height: '28px', padding: '2px 8px' }}
                    onClick={() => setManualShowProcessing(true)}
                  >
                    <Eye size={12} /> Xem tác vụ #{String(job.scanJobId).substring(0, 6)}
                  </button>
                )}
              </div>

              <p style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-600)', margin: '0 0 14px', lineHeight: 1.5 }}>
                Tải lên bộ ảnh chụp quanh hiện vật (từ 5 đến 200 ảnh). Mô hình AI sẽ trích xuất góc chụp và dựng file GLB 3D trực tiếp trên máy chủ.
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
                      {files.length ? `✓ Đã chọn ${files.length} ảnh` : 'Chưa chọn ảnh (cần 5–200 ảnh)'}
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

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '6px' }}>
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      style={{ fontSize: '0.74rem', color: 'var(--color-charcoal-600)' }}
                      onClick={() => setManualShowProcessing(true)}
                    >
                      <Layers size={13} /> Mở bảng tiến trình AI
                    </button>

                    <button
                      type="button"
                      className="btn btn-gold btn-sm"
                      disabled={busy || needsJobCheck || running(job?.status) || !files.length}
                      onClick={start}
                    >
                      <Sparkles size={14} /> Bắt đầu dựng 3D
                    </button>
                  </div>

                  {jobError && <p role="alert" className="business-error" style={{ fontSize: '0.75rem', margin: '4px 0' }}>{jobError}</p>}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
