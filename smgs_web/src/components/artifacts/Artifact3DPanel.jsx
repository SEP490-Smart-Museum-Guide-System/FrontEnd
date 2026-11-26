import React, { useEffect, useRef, useState } from 'react';
import '@google/model-viewer';
import ArtifactModelViewer, { isSketchfabUrl } from '../common/ArtifactModelViewer';
import { mediaApi, uploadMedia } from '../../services/mediaApi';
import { Modal, Field } from '../common/BusinessUI';
import {
  prepareScanDataset,
  startScanSafely,
  getScanJobs,
  getScanJob,
  getScanModel,
  saveScanModel,
  discardScanModel,
  cancelScanJob,
  validateGlbPreview
} from '../../services/artifactScanApi';
import { scanProgress, scanActivity } from './scanProgress';
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
  CANCELLED: 'Đã hủy tác vụ dựng 3D',
  COMPLETED: 'Đã lưu vào hiện vật',
  DISCARDED: 'Đã hủy kết quả scan'
};

export default function Artifact3DPanel({ artifactId, name, canManage = false, onModelChange }) {
  const validId = Number.isInteger(Number(artifactId)) && Number(artifactId) > 0;
  const path = `artifacts/${artifactId}/model-3d`;
  const [model, setModel] = useState(null), [savedUrl, setSavedUrl] = useState('');
  const [draft, setDraft] = useState(null), [job, setJob] = useState(null), [files, setFiles] = useState([]);
  const [mode, setMode] = useState('auto'), [busy, setBusy] = useState(false), [progress, setProgress] = useState(0);
  const [quality, setQuality] = useState('balanced'), [captureOrder, setCaptureOrder] = useState('unordered');
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
      const dataset = prepareScanDataset(files, mode, { quality, captureOrder });
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

  const cancel = () => {
    if (!job?.scanJobId || !window.confirm('Hủy tác vụ dựng 3D này? Bộ ảnh và log vẫn được giữ lại.')) return;
    perform(async () => {
      const next = await cancelScanJob(artifactId, job.scanJobId);
      setJob(next);
      setJobError('');
      setNeedsJobCheck(false);
      setMessage('Đã hủy tác vụ dựng 3D. Bạn có thể chọn bộ ảnh để tạo tác vụ mới.');
    });
  };

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
  const isStopped = ['FAILED', 'CANCELLED', 'DISCARDED'].includes(job?.status);
  const activity = scanActivity(job);
  const stagePercent = uploading ? currentPercent : isReview ? 100 : isScanning ? activity.percent : currentPercent;
  const indeterminate = isScanning && stagePercent == null;
  const stageLabel = uploading ? `Tải bộ ảnh: ${currentPercent}%` : isStopped ? 'Tác vụ đã dừng' : isReview ? 'Đã tạo xong mô hình 3D' : isScanning ? `${activity.title}${stagePercent == null ? '' : `: ${stagePercent}%`}` : 'Chưa có tác vụ';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* Alert Messages */}
      {error && <p role="alert" className="business-error">{error}</p>}
      {job?.error && !uploading && <p role={job.status === 'FAILED' ? 'alert' : 'status'} className="business-error">{job.error}</p>}
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
                {(isScanning || uploading) && <><div className="ai-scan-radar-sweep" /><div className="ai-scan-laser-line" /></>}
                
                <div className="ai-scan-3d-hologram">
                  <Box size={52} color="var(--color-gold-400)" style={{ filter: 'drop-shadow(0 0 16px rgba(245, 158, 11, 0.6))' }} />
                  <span style={{ marginTop: '8px', fontSize: '0.72rem', letterSpacing: '0.08em', fontWeight: '700', color: '#F1F5F9', textTransform: 'uppercase' }}>
                    {uploading ? 'ĐANG TẢI BỘ ẢNH' : isStopped ? 'TÁC VỤ ĐÃ DỪNG' : isReview ? '3D MESH READY' : job ? 'PHOTOGRAMMETRY SCAN' : 'CHƯA BẮT ĐẦU'}
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
                  {stageLabel}
                </div>
              </div>

              {/* Information & Instructions */}
              <div style={{ marginTop: '16px', textAlign: 'center' }}>
                <h4 style={{ fontSize: '1.05rem', fontWeight: '700', color: 'var(--color-burgundy-900)', margin: '0 0 6px' }}>
                  {uploading ? (progress >= 100 ? 'Đang chờ máy chủ xác nhận tác vụ...' : `Đang tải bộ ảnh: ${progress}%`) : !job ? 'Chưa có tác vụ dựng 3D.' : isStopped ? labels[job.status] : isReview
                    ? 'AI đã tái tạo mô hình 3D thành công!'
                    : activity.title}
                </h4>
                <p style={{ fontSize: '0.8rem', color: 'var(--color-charcoal-600)', margin: '0 auto', maxWidth: '520px', lineHeight: 1.55 }}>
                  {uploading ? 'Giữ trang mở trong khi tải ảnh. Tiến độ này là tải dữ liệu, chưa phải dựng 3D.' : !job ? 'Chọn bộ ảnh rồi bấm Bắt đầu dựng 3D.' : isStopped ? 'Tác vụ này không còn chạy. Bộ ảnh và log vẫn được giữ trên máy chủ; bạn có thể đóng bảng tiến trình và tạo tác vụ mới.' : isReview
                    ? 'Quá trình trích xuất mây điểm và xây dựng lưới đa giác đã hoàn tất. Bạn có thể bấm "Xem kết quả" để nạp mô hình vào khung xoay 360° bên trái trước khi lưu vào hiện vật.'
                    : activity.detail + ' Bạn có thể đóng cửa sổ này rồi quay lại kiểm tra.'}
                </p>
                {isScanning && activity.lastActivityAt && Number.isFinite(Date.parse(activity.lastActivityAt)) && <p style={{ fontSize: '0.74rem', color: 'var(--color-charcoal-500)', margin: '8px 0 0' }}>Log cập nhật lúc {new Date(activity.lastActivityAt).toLocaleTimeString('vi-VN')}</p>}
              </div>

              {/* Live Shimmer Progress Bar */}
              <div style={{ marginTop: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.78rem', marginBottom: '6px' }}>
                  <span style={{ fontWeight: '600', color: 'var(--color-charcoal-700)' }}>
                    {uploading ? 'Tiến độ tải ảnh:' : isReview ? 'Hoàn thành dựng 3D' : 'Giai đoạn hiện tại:'}
                  </span>
                  <span style={{ fontWeight: '700', color: 'var(--color-burgundy-700)' }}>
                    {isStopped ? 'Đã dừng' : indeterminate ? 'Đang xử lý' : `${stagePercent}%`}
                  </span>
                </div>
                <div className={`ai-scan-progress-shimmer ${indeterminate ? 'is-indeterminate' : ''}`} role="progressbar" aria-label={uploading ? 'Tải ảnh' : activity.title} aria-valuemin={0} aria-valuemax={100} aria-valuenow={indeterminate ? undefined : stagePercent} aria-valuetext={indeterminate ? 'Đang xử lý, chưa có bộ đếm tiến độ' : undefined}>
                  <div className="ai-scan-progress-shimmer-fill" style={{ width: indeterminate ? '35%' : `${stagePercent}%` }} />
                </div>
              </div>

              {/* Sub-phase Checklist */}
              {(isScanning || isReview) && Number.isInteger(activity.depthImages) && <p role="status" aria-live="polite" style={{ margin: '12px 0 0', padding: '10px 12px', borderRadius: 8, background: '#FBF4E6', color: 'var(--color-burgundy-900)', fontWeight: 700 }}>
                {activity.depthImages} ảnh đã xử lý · {activity.depthOperations} lượt tính độ sâu
              </p>}
              {isScanning && !Number.isInteger(activity.depthImages) && Number.isInteger(activity.completed) && activity.completed >= 0 && <p role="status" aria-live="polite" style={{ margin: '12px 0 0', padding: '10px 12px', borderRadius: 8, background: '#FBF4E6', color: 'var(--color-burgundy-900)', fontWeight: 700 }}>
                {activity.completed}{Number.isInteger(activity.total) ? `/${activity.total}` : ''} {activity.stage === 'matching' ? 'nhóm ảnh đã khớp' : activity.stage === 'dense' ? 'ảnh đã tính độ sâu' : 'ảnh đã xử lý'}
                {activity.stage === 'dense' && activity.operations > activity.completed && ` · ${activity.operations} lượt tính`}
              </p>}
              {!uploading && job && !isStopped && (!isScanning || job.activity) && <div className="ai-scan-phase-list">
                {['Trích xuất đặc trưng ảnh', 'Khớp ảnh và tính camera', 'Tạo độ sâu và dựng lưới bề mặt', 'Tạo texture và đóng gói GLB'].map((title, index) => {
                  const phase = isReview ? 5 : activity.phase;
                  const done = phase > index + 1, current = phase === index + 1;
                  return <div key={title} className={`ai-scan-phase-item ${done ? 'done' : current ? 'current' : ''}`}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      {done ? <Check size={14} color="#166534" /> : current ? <RefreshCw size={14} className="spin" /> : <Clock size={14} color="#94A3B8" />}
                      <span>{index + 1}. {title}</span>
                    </div>
                    <span style={{ fontSize: '0.7rem', fontWeight: '600' }}>{done ? 'Hoàn tất' : current ? 'Đang chạy' : 'Đang chờ'}</span>
                  </div>;
                })}
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

                  {canManage && running(job?.status) && <button type="button" className="btn btn-secondary btn-sm" disabled={busy} onClick={cancel} style={{ color: '#B91C1C' }}><Trash2 size={14} /> Hủy dựng 3D</button>}
                  {canManage && uploading && <button type="button" className="btn btn-secondary btn-sm" onClick={() => { setNeedsJobCheck(true); action.current?.abort(); }}>Ngừng tải ảnh</button>}
                  {running(job?.status) && (
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      disabled={busy}
                      onClick={checkReceived}
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
            <div style={{ padding: '16px 18px', borderRadius: '12px', background: 'var(--admin-bg, #FAF7F2)', border: '1px solid var(--color-paper-border)' }}>
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

                  <label style={{ fontSize: '0.8rem', display: 'grid', gap: 6 }}>
                    Chất lượng dựng 3D
                    <select className="form-select form-select-sm" value={quality} onChange={e => setQuality(e.target.value)} disabled={busy || running(job?.status)}>
                      <option value="balanced">Cân bằng — ưu tiên thời gian</option>
                      <option value="detailed">Chi tiết cao — xử lý lâu hơn</option>
                      <option value="preview">Bản nháp nhanh — ít chi tiết</option>
                    </select>
                    <span style={{ color: 'var(--color-charcoal-500)', lineHeight: 1.5 }}>
                      {quality === 'balanced' ? 'Giảm độ phân giải tính độ sâu, giữ bước tinh chỉnh bề mặt và texture 4K.' : quality === 'preview' ? 'Giảm thêm độ phân giải, bỏ bước tinh chỉnh bề mặt, texture tối đa 2K. Dùng để kiểm tra góc chụp trước.' : 'Tính độ sâu ở độ phân giải gốc của pipeline, giữ đầy đủ bước tinh chỉnh và texture 4K.'}
                    </span>
                  </label>
                  <label style={{ fontSize: '0.8rem', display: 'flex', gap: 8, alignItems: 'flex-start', lineHeight: 1.5 }}>
                    <input type="checkbox" checked={captureOrder === 'ordered'} onChange={e => setCaptureOrder(e.target.checked ? 'ordered' : 'unordered')} disabled={busy || running(job?.status)} />
                    <span>Ảnh đã xếp theo vòng chụp. Chỉ bật khi thứ tự tên file đúng thứ tự chụp quanh hiện vật; giúp giảm số cặp ảnh cần khớp.</span>
                  </label>

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
    
      {/* Heritage Modals for 3D Settings and Sketchfab */}
      {showSketchfab && canManage && (
        <Modal
          title="Liên kết mô hình 3D từ Sketchfab"
          busy={busy}
          onClose={() => setShowSketchfab(false)}
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <p style={{ fontSize: '0.85rem', color: 'var(--color-charcoal-600)', margin: 0, lineHeight: 1.5 }}>
              Dán đường dẫn trang mô hình Sketchfab hoặc mã định danh (Model UID). Mô hình sẽ được đồng bộ và hiển thị trực tiếp trong khung xoay 360°.
            </p>
            <Field label="Đường dẫn hoặc UID Sketchfab">
              <input
                type="url"
                className="form-input"
                placeholder="vd: https://sketchfab.com/3d-models/... hoặc 4a12b3c..."
                value={sketchfabUrl}
                onChange={e => setSketchfabUrl(e.target.value)}
                disabled={busy}
              />
            </Field>
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end', marginTop: '10px' }}>
              <button type="button" className="btn btn-secondary" onClick={() => setShowSketchfab(false)}>
                Hủy bỏ
              </button>
              <button
                type="button"
                className="btn btn-primary"
                disabled={busy || !sketchfabUrl.trim()}
                onClick={linkSketchfab}
              >
                Liên kết mô hình
              </button>
            </div>
          </div>
        </Modal>
      )}

      {showSettings && canManage && (
        <Modal
          title="Cấu hình hiển thị mô hình 3D và góc Camera"
          busy={busy}
          onClose={() => setShowSettings(false)}
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <label className="business-check" style={{ cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={settingsForm.autoRotate}
                onChange={e => setSettingsForm(prev => ({ ...prev, autoRotate: e.target.checked }))}
              />
              Tự động xoay quanh tâm (Auto Rotate 360°)
            </label>

            <Field label="Góc quỹ đạo camera ban đầu (Camera Orbit)">
              <input
                type="text"
                className="form-input"
                placeholder="vd: 0deg 75deg 105% (nhìn thẳng) hoặc 45deg 55deg 2.5m"
                value={settingsForm.cameraOrbit}
                onChange={e => setSettingsForm(prev => ({ ...prev, cameraOrbit: e.target.value }))}
              />
            </Field>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <Field label="Góc nhìn thị giác (FOV)">
                <input
                  type="text"
                  className="form-input"
                  placeholder="vd: 30deg"
                  value={settingsForm.fieldOfView}
                  onChange={e => setSettingsForm(prev => ({ ...prev, fieldOfView: e.target.value }))}
                />
              </Field>
              <Field label="Tỷ lệ phóng to (Scale)">
                <input
                  type="number"
                  step="0.1"
                  min="0.1"
                  max="50"
                  className="form-input"
                  value={settingsForm.scale}
                  onChange={e => setSettingsForm(prev => ({ ...prev, scale: parseFloat(e.target.value) || 1.0 }))}
                />
              </Field>
            </div>

            <Field label="Tiêu đề hiển thị của mô hình">
              <input
                type="text"
                className="form-input"
                placeholder="Nhập tên gọi hiển thị khi tương tác 3D..."
                value={settingsForm.name}
                onChange={e => setSettingsForm(prev => ({ ...prev, name: e.target.value }))}
              />
            </Field>

            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end', marginTop: '10px' }}>
              <button type="button" className="btn btn-secondary" onClick={() => setShowSettings(false)}>
                Hủy bỏ
              </button>
              <button type="button" className="btn btn-primary" disabled={busy} onClick={saveSettings}>
                Lưu cấu hình 3D
              </button>
            </div>
          </div>
        </Modal>
      )}

    </div>
  );
}
