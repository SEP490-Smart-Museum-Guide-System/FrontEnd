import { artifactReviewLabels } from '../../services/backend';
import ArtifactContentManager from './ArtifactContentManager';
import ArtifactMediaPanel from './ArtifactMediaPanel';
import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import '@google/model-viewer';
import { useApp } from '../../context/AppContext';
import { getArtifactQrImageUrl } from '../../services/artifactApi';
import { getPublishedArtifactContentApi } from '../../services/contentSubmissionApi';
import { generateSpeechApi } from '../../services/ttsApi';
import { uploadReferenceImageApi, deleteReferenceImagesApi, checkVisionHealthApi } from '../../services/visionApi';
import Artifact3DPanel from './Artifact3DPanel';
import {
  X,
  QrCode,
  Box,
  Volume2,
  Globe,
  Award,
  Layers,
  Sparkles,
  Printer,
  Check,
  Play,
  Pause,
  HelpCircle,
  Download,
  RefreshCw
} from 'lucide-react';

export default function ArtifactDetailModal({ artifact, onClose, onOpenAIStudio, onEdit, readOnly = false }) {
  const { artifactReviewStatus, downloadArtifactQr, regenerateArtifactQr, currentRole, showToast } = useApp();
  const [activeTab, setActiveTab] = useState('overview'); // overview | 3d | qr | multilingual | quizzes
  const [has3DModel, setHas3DModel] = useState(!!artifact?.has3DModel);
  const [isPlayingAudio, setIsPlayingAudio] = useState(false);
  const [copiedQR, setCopiedQR] = useState(false);
  const [qrImgError, setQrImgError] = useState(false);
  const [isRegenerating, setIsRegenerating] = useState(false);
  const [activeQrCode, setActiveQrCode] = useState(artifact?.qrCode || '');
  const [publishedContent, setPublishedContent] = useState(null);
  const [referenceImages, setReferenceImages] = useState(() =>
    (artifact?.referenceImages || []).map((image, index) => typeof image === 'string'
      ? { id: `existing-${index}`, url: image, name: `Ảnh tham chiếu ${index + 1}`, status: 'Chưa đồng bộ' }
      : { ...image, status: image.status || 'Chưa đồng bộ' })
  );

  const audioRef = useRef(null);
  const [ttsLoading, setTtsLoading] = useState(false);
  const [ttsAudioUrl, setTtsAudioUrl] = useState(null);
  const [ttsProgress, setTtsProgress] = useState(0);
  const [ttsDuration, setTtsDuration] = useState('00:00');
  const [ttsCurrentTime, setTtsCurrentTime] = useState('00:00');
  const [ttsSpeed, setTtsSpeed] = useState(1.0);
  const [ttsError, setTtsError] = useState(null);
  const [ttsVoice, setTtsVoice] = useState('');
  const [ttsCacheHit, setTtsCacheHit] = useState(false);

  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current = null;
      }
    };
  }, []);

  const formatAudioTime = (sec) => {
    if (!sec || isNaN(sec)) return '00:00';
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const handleToggleAudio = async () => {
    if (isPlayingAudio && audioRef.current) {
      audioRef.current.pause();
      setIsPlayingAudio(false);
      return;
    }

    if (audioRef.current && ttsAudioUrl) {
      audioRef.current.playbackRate = ttsSpeed;
      audioRef.current.play()
        .then(() => setIsPlayingAudio(true))
        .catch(err => setTtsError('Không thể phát âm thanh: ' + err.message));
      return;
    }

    const narrationScript = (
      publishedContent?.narration ||
      publishedContent?.description ||
      artifact?.audioNarration ||
      artifact?.description ||
      artifact?.historicalContext ||
      `Hiện vật ${artifact?.name || ''}. Niên đại ${artifact?.period || 'chưa rõ'}. ${artifact?.historicalSignificance || ''}`
    ).trim();

    setTtsLoading(true);
    setTtsError(null);
    try {
      const res = await generateSpeechApi({
        text: narrationScript,
        speed: ttsSpeed,
        language: 'vi-VN'
      });
      setTtsAudioUrl(res.audioUrl);
      setTtsVoice(res.voice);
      setTtsCacheHit(res.cacheHit);

      if (audioRef.current) {
        audioRef.current.pause();
      }

      const audio = new Audio(res.audioUrl);
      audio.playbackRate = ttsSpeed;
      audioRef.current = audio;

      audio.ontimeupdate = () => {
        if (audio.duration) {
          setTtsProgress((audio.currentTime / audio.duration) * 100);
          setTtsCurrentTime(formatAudioTime(audio.currentTime));
          setTtsDuration(formatAudioTime(audio.duration));
        }
      };

      audio.onended = () => {
        setIsPlayingAudio(false);
        setTtsProgress(0);
        setTtsCurrentTime('00:00');
      };

      audio.onerror = () => {
        setIsPlayingAudio(false);
        setTtsError('Lỗi khi phát tệp âm thanh WAV từ microservice');
      };

      await audio.play();
      setIsPlayingAudio(true);
    } catch (err) {
      setTtsError(err.message || 'Dịch vụ TTS AI (Port 8000) chưa kết nối.');
      setIsPlayingAudio(false);
    } finally {
      setTtsLoading(false);
    }
  };

  const handleChangeSpeed = (newSpeed) => {
    setTtsSpeed(newSpeed);
    if (audioRef.current) {
      audioRef.current.playbackRate = newSpeed;
    }
  };

  const [visionHealth, setVisionHealth] = useState(null);
  const [isSyncingVision, setIsSyncingVision] = useState(false);
  const [visionSyncError, setVisionSyncError] = useState(null);

  useEffect(() => {
    checkVisionHealthApi().then(setVisionHealth).catch(() => {});
  }, []);

  const handleSyncReferenceToVision = async (imageItem) => {
    if (!imageItem.file) {
      showToast('Ảnh này không có tệp nguồn trong phiên để đồng bộ lại.', 'warning');
      return;
    }
    const targetArtifactId = typeof artifact?.id === 'number' ? artifact.id : (artifact?.backendId || artifact?.id);
    setReferenceImages(prev => prev.map(img => img.id === imageItem.id ? { ...img, status: 'Đang trích xuất vector 512d...' } : img));
    try {
      await uploadReferenceImageApi({ artifactId: targetArtifactId, file: imageItem.file });
      setReferenceImages(prev => prev.map(img => img.id === imageItem.id ? { ...img, status: 'Đã index vào AI Vision' } : img));
    } catch (err) {
      setReferenceImages(prev => prev.map(img => img.id === imageItem.id ? { ...img, status: 'Lỗi: ' + err.message } : img));
    }
  };

  const handleSyncAllReferences = async () => {
    const unsynced = referenceImages.filter(img => img.file && !img.status?.includes('Đã index'));
    if (!unsynced.length) {
      showToast('Tất cả ảnh tham chiếu mới đã được đồng bộ vào AI Vision.', 'info');
      return;
    }
    setIsSyncingVision(true);
    setVisionSyncError(null);
    const targetArtifactId = typeof artifact?.id === 'number' ? artifact.id : (artifact?.backendId || artifact?.id);
    for (const img of unsynced) {
      setReferenceImages(prev => prev.map(item => item.id === img.id ? { ...item, status: 'Đang trích xuất vector 512d...' } : item));
      try {
        await uploadReferenceImageApi({ artifactId: targetArtifactId, file: img.file });
        setReferenceImages(prev => prev.map(item => item.id === img.id ? { ...item, status: 'Đã index vào AI Vision' } : item));
      } catch (err) {
        setReferenceImages(prev => prev.map(item => item.id === img.id ? { ...item, status: 'Lỗi: ' + err.message } : item));
        setVisionSyncError(err.message);
      }
    }
    setIsSyncingVision(false);
    checkVisionHealthApi().then(setVisionHealth).catch(() => {});
  };

  const handleClearAllReferences = async () => {
    if (!window.confirm(`Bạn có chắc chắn muốn xóa tất cả vector ảnh tham chiếu của hiện vật "${artifact.name}" trên AI Vision?`)) {
      return;
    }
    const targetArtifactId = typeof artifact?.id === 'number' ? artifact.id : (artifact?.backendId || artifact?.id);
    try {
      await deleteReferenceImagesApi({ artifactId: targetArtifactId });
      setReferenceImages(prev => prev.map(img => ({ ...img, status: 'Đã gỡ bỏ khỏi AI Vision' })));
      showToast('Đã gỡ bỏ toàn bộ vector tham chiếu trên AI Vision.', 'success');
      checkVisionHealthApi().then(setVisionHealth).catch(() => {});
    } catch (err) {
      showToast('Lỗi khi gỡ vector: ' + err.message, 'error');
    }
  };

  useEffect(() => {
    const backendId = typeof artifact?.id === 'number' ? artifact.id : artifact?.backendId;
    if (backendId) {
      getPublishedArtifactContentApi(backendId, 'vi')
        .then(res => {
          if (res?.data) {
            setPublishedContent(res.data);
          }
        })
        .catch(() => {});
    }
  }, [artifact]);

  if (!artifact) return null;

  const handleCopyQR = () => {
    navigator.clipboard?.writeText(activeQrCode || artifact.qrCode);
    setCopiedQR(true);
    setTimeout(() => setCopiedQR(false), 2000);
  };

  const handleRegenerateQR = async () => {
    if (!window.confirm(`Bạn có chắc chắn muốn cấp mã QR mới cho "${artifact.name}"?\nKhách tham quan quét mã cũ sẽ không truy cập được nữa.`)) {
      return;
    }
    setIsRegenerating(true);
    try {
      const res = await regenerateArtifactQr(artifact.id);
      if (res?.qrCode) {
        setActiveQrCode(res.qrCode);
        setQrImgError(false);
      }
    } finally {
      setIsRegenerating(false);
    }
  };

  const handlePrintQR = () => {
    const qrSrc = !qrImgError ? getArtifactQrImageUrl(artifact.id) : '';
    const printWindow = window.open('', '_blank');
    printWindow.document.write(`
      <html>
        <head>
          <title>In Bảng Mã QR — ${artifact.name}</title>
          <style>
            body { font-family: 'Times New Roman', serif; text-align: center; padding: 40px; background: #FFF; color: #1E232B; }
            .card { border: 3px double #800020; border-radius: 12px; padding: 32px; max-width: 420px; margin: 0 auto; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
            .brand { font-size: 11px; text-transform: uppercase; color: #C5A059; font-weight: bold; letter-spacing: 2px; }
            h2 { color: #800020; margin: 8px 0 4px; font-size: 22px; }
            p { color: #555; margin: 0 0 16px; font-size: 13px; font-style: italic; }
            .code { font-family: monospace; font-size: 16px; font-weight: bold; background: #FAF7F2; padding: 6px 14px; border-radius: 6px; display: inline-block; margin: 12px 0; border: 1px solid #E8E2D8; color: #800020; }
            .qr-box { margin: 16px auto; width: 210px; height: 210px; border: 1px solid #E8E2D8; display: flex; align-items: center; justify-content: center; background: #FAF7F2; border-radius: 8px; }
            .qr-box img { max-width: 190px; max-height: 190px; }
            .footer { font-size: 11px; color: #777; margin-top: 16px; line-height: 1.5; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="brand">Smart Museum Guide System</div>
            <h2>${artifact.name}</h2>
            <p>${artifact.museumName || ''} — ${artifact.galleryName || ''}</p>
            <div class="qr-box">
              ${qrSrc ? `<img src="${qrSrc}" alt="QR Code" />` : `<span style="font-family: monospace; font-weight: bold;">${activeQrCode || artifact.qrCode}</span>`}
            </div>
            <div class="code">${activeQrCode || artifact.qrCode}</div>
            <div class="footer">Quét mã bằng ứng dụng di động SMGS để lắng nghe thuyết minh đa phương tiện và tương tác di sản.</div>
          </div>
          <script>
            window.onload = function() { window.print(); }
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  const modalContent = (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-dialog" style={{ maxWidth: '980px', width: '95vw', maxHeight: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', minHeight: 0 }} onClick={(e) => e.stopPropagation()}>
        {/* Modal Header */}
        <div className="modal-header" style={{ flexShrink: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{
              width: '40px',
              height: '40px',
              borderRadius: '10px',
              background: 'var(--color-burgundy-100)',
              color: 'var(--color-burgundy-700)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <Award size={22} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <h2 className="modal-title font-serif">{artifact.name}</h2>
                {artifact.isNationalTreasure && (
                  <span className="badge-status badge-treasure">⭐ Bảo vật Quốc gia</span>
                )}
                <span className={`badge-status badge-${artifactReviewStatus(artifact.id) ?? "draft"}`}>
                  {artifactReviewLabels[artifactReviewStatus(artifact.id)] ?? 'Chưa tải được trạng thái'}
                </span>
              </div>
              <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', marginTop: '2px' }}>
                Mã: <strong>{artifact.code}</strong> • {artifact.museumName} • {artifact.galleryName}
              </p>
            </div>
          </div>
          <button type="button" onClick={onClose} className="btn btn-secondary btn-sm" style={{ borderRadius: '50%', padding: '6px' }}>
            <X size={20} />
          </button>
        </div>

        {/* Navigation Tabs - Clean, no horizontal scroll */}
        <div
          className="artifact-modal-tabs"
          style={{
            flexShrink: 0,
            display: 'flex',
            borderBottom: '1px solid var(--color-paper-border)',
            background: '#FDFCF9',
            padding: '0 20px',
            gap: '4px'
          }}
        >
          {[
            { id: 'overview', label: 'Tổng quan', icon: Layers },
            { id: '3d', label: 'Mô hình 3D', icon: Box, badge: has3DModel ? '3D' : null },
            { id: 'qr', label: 'Mã QR & Vision', icon: QrCode },
            { id: 'multilingual', label: 'Đa ngôn ngữ', icon: Globe },
            { id: 'quizzes', label: 'Quiz & Câu hỏi', icon: HelpCircle, badge: artifact.quizzes?.length ? `${artifact.quizzes.length}` : null }
          ].map(tab => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => setActiveTab(tab.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '7px',
                  padding: '12px 14px',
                  fontSize: '0.84rem',
                  fontWeight: isActive ? '600' : '500',
                  color: isActive ? 'var(--color-burgundy-700)' : 'var(--color-charcoal-600)',
                  borderBottom: isActive ? '2px solid var(--color-burgundy-700)' : '2px solid transparent',
                  background: 'none',
                  borderTop: 'none',
                  borderLeft: 'none',
                  borderRight: 'none',
                  cursor: 'pointer',
                  transition: 'all var(--transition-fast)'
                }}
              >
                <Icon size={15} />
                <span>{tab.label}</span>
                {tab.badge && (
                  <span
                    style={{
                      fontSize: '0.675rem',
                      padding: '1px 6px',
                      borderRadius: '4px',
                      background: has3DModel || tab.id === 'quizzes' ? '#DCFCE7' : '#F1F5F9',
                      color: has3DModel || tab.id === 'quizzes' ? '#166534' : '#64748B',
                      fontWeight: '700'
                    }}
                  >
                    {tab.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Modal Body */}
        <div className="modal-body" style={{ overflowY: 'auto', flex: 1, minHeight: 0, padding: '20px 24px' }}>
          {activeTab === 'overview' && (
            <div className="artifact-detail-grid" style={{ display: 'grid', gridTemplateColumns: '320px minmax(0, 1fr)', gap: '28px' }}>
              {/* Left Column: Image & Audio */}
              <div>
                <div style={{
                  borderRadius: '12px',
                  overflow: 'hidden',
                  border: '1px solid var(--color-paper-border)',
                  boxShadow: 'var(--shadow-sm)',
                  marginBottom: '16px',
                  background: '#1A1F26',
                  height: '240px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <img
                    src={artifact.image || '/assets/images/placeholder.svg'}
                    alt={artifact.name}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    onError={(e) => {
                      e.target.onerror = null; e.target.src = '/assets/images/placeholder.svg';
                    }}
                  />
                </div>

                {/* Audio Guide Player Preview (Connected to TTS AI Service) */}
                <div className="card" style={{ padding: '16px', background: '#F8F5EE', border: '1px solid #EADCC8' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Volume2 size={16} color="var(--color-burgundy-700)" />
                      <span style={{ fontSize: '0.8125rem', fontWeight: '600' }}>Thuyết minh AI (TTS)</span>
                    </div>
                    {ttsVoice && (
                      <span style={{
                        fontSize: '0.675rem',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        background: ttsCacheHit ? '#DCFCE7' : '#FEF3C7',
                        color: ttsCacheHit ? '#166534' : '#92400E',
                        fontWeight: '600'
                      }}>
                        {ttsCacheHit ? 'Cache HIT' : 'AI Speech'}
                      </span>
                    )}
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <button
                      type="button"
                      onClick={handleToggleAudio}
                      disabled={ttsLoading}
                      className="btn btn-primary btn-sm"
                      style={{
                        borderRadius: '50%',
                        width: '36px',
                        height: '36px',
                        padding: 0,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        cursor: ttsLoading ? 'wait' : 'pointer'
                      }}
                      title={isPlayingAudio ? 'Tạm dừng' : 'Phát thuyết minh âm thanh'}
                    >
                      {ttsLoading ? (
                        <RefreshCw size={15} className="spin" style={{ animation: 'spin 1s linear infinite' }} />
                      ) : isPlayingAudio ? (
                        <Pause size={16} />
                      ) : (
                        <Play size={16} />
                      )}
                    </button>
                    <div
                      style={{ flex: 1, height: '8px', background: '#E2E8F0', borderRadius: '4px', overflow: 'hidden', cursor: 'pointer', position: 'relative' }}
                      onClick={(e) => {
                        if (audioRef.current && audioRef.current.duration) {
                          const rect = e.currentTarget.getBoundingClientRect();
                          const pos = (e.clientX - rect.left) / rect.width;
                          audioRef.current.currentTime = pos * audioRef.current.duration;
                        }
                      }}
                    >
                      <div style={{ width: `${ttsProgress}%`, height: '100%', background: 'var(--color-burgundy-700)', transition: 'width 150ms' }} />
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '8px', fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                    <span>{ttsCurrentTime} / {ttsDuration !== '00:00' ? ttsDuration : (artifact.audioDuration || 'Chưa có thời lượng')}</span>
                    <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
                      <span style={{ fontSize: '0.7rem' }}>Tốc độ:</span>
                      {[0.75, 1.0, 1.25].map(sp => (
                        <button
                          key={sp}
                          type="button"
                          onClick={() => handleChangeSpeed(sp)}
                          style={{
                            border: '1px solid ' + (ttsSpeed === sp ? 'var(--color-burgundy-700)' : '#CBD5E1'),
                            background: ttsSpeed === sp ? 'var(--color-burgundy-700)' : '#FFF',
                            color: ttsSpeed === sp ? '#FFF' : '#475569',
                            borderRadius: '3px',
                            fontSize: '0.65rem',
                            padding: '1px 5px',
                            cursor: 'pointer',
                            fontWeight: ttsSpeed === sp ? '700' : '400'
                          }}
                        >
                          {sp}x
                        </button>
                      ))}
                    </div>
                  </div>

                  {ttsLoading && (
                    <p style={{ fontSize: '0.7rem', color: 'var(--color-burgundy-700)', marginTop: '6px', fontStyle: 'italic' }}>
                      Đang kết nối microservice TTS AI (Port 8000) để tổng hợp giọng đọc...
                    </p>
                  )}

                  {ttsError && (
                    <div style={{ marginTop: '8px', padding: '6px 8px', background: '#FEF2F2', border: '1px solid #FCA5A5', borderRadius: '4px', fontSize: '0.7rem', color: '#991B1B' }}>
                      {ttsError}
                    </div>
                  )}
                </div>

                {/* Key Spec Grid */}
                <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8125rem' }}>
                    <span style={{ color: 'var(--color-charcoal-500)' }}>Niên đại:</span>
                    <span style={{ fontWeight: '600' }}>{artifact.period}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8125rem' }}>
                    <span style={{ color: 'var(--color-charcoal-500)' }}>Chất liệu:</span>
                    <span style={{ fontWeight: '600' }}>{artifact.material}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8125rem' }}>
                    <span style={{ color: 'var(--color-charcoal-500)' }}>Chủ đề:</span>
                    <span style={{ fontWeight: '600' }}>{artifact.theme}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8125rem' }}>
                    <span style={{ color: 'var(--color-charcoal-500)' }}>Lượt quét QR:</span>
                    <span style={{ fontWeight: '600', color: 'var(--color-burgundy-700)' }}>{artifact.scansCount == null ? 'Chưa có dữ liệu' : `${artifact.scansCount.toLocaleString()} lượt`}</span>
                  </div>
                </div>
              </div>

              {/* Right Column: Descriptions & Details */}
              <div>
                <div style={{ marginBottom: '20px' }}>
                  <h4 style={{ fontSize: '0.9375rem', fontWeight: '700', marginBottom: '8px', color: 'var(--color-burgundy-800)' }}>
                    Tóm tắt nội dung
                  </h4>
                  <p style={{ fontSize: '0.875rem', lineHeight: '1.6', color: 'var(--color-charcoal-800)', background: '#FAF7F2', padding: '14px', borderRadius: '8px', borderLeft: '4px solid var(--color-gold-500)' }}>
                    {artifact.shortDesc}
                  </p>
                </div>

                <div style={{ marginBottom: '20px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <h4 style={{ fontSize: '0.9375rem', fontWeight: '700', color: 'var(--color-burgundy-800)', margin: 0 }}>
                      Nội dung Thuyết minh Chi tiết
                    </h4>
                    {publishedContent && (
                      <span style={{
                        fontSize: '0.72rem',
                        fontWeight: '600',
                        color: '#166534',
                        background: '#DCFCE7',
                        padding: '2px 8px',
                        borderRadius: '12px',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '4px'
                      }}>
                        <Check size={12} /> Đã Giám tuyển duyệt (v{publishedContent.versionNo})
                      </span>
                    )}
                  </div>
                  {publishedContent && (
                    <div style={{ fontWeight: '600', fontSize: '0.85rem', color: 'var(--color-burgundy-900)', marginBottom: '6px' }}>
                      {publishedContent.title}
                    </div>
                  )}
                  <div style={{
                    fontSize: '0.875rem',
                    lineHeight: '1.7',
                    color: 'var(--color-charcoal-800)',
                    whiteSpace: 'pre-line',
                    maxHeight: '260px',
                    overflowY: 'auto',
                    paddingRight: '8px'
                  }}>
                    {publishedContent?.description || artifact.fullDesc}
                  </div>
                </div>

                {!readOnly && <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                  <button
                    type="button"
                    onClick={() => {
                      onClose();
                      onOpenAIStudio(artifact);
                    }}
                    className="btn btn-gold"
                    style={{ flex: 1 }}
                  >
                    <Sparkles size={16} /> Tạo thêm thuyết minh / câu hỏi bằng AI
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      onClose();
                      onEdit(artifact);
                    }}
                    className="btn btn-secondary"
                  >
                    Chỉnh sửa thông số
                  </button>
                </div>}

                {!readOnly && ['administrator', 'museumStaff', 'curator'].includes(currentRole) && (
                  <details style={{ marginTop: '20px', borderRadius: '10px', border: '1px solid var(--color-paper-border)', background: '#FAF7F2', padding: '12px 16px' }}>
                    <summary style={{ cursor: 'pointer', fontWeight: '600', fontSize: '0.84rem', color: 'var(--color-burgundy-900)' }}>
                      ⚙️ Lịch sử biên tập & Đệ trình bản thuyết minh mới
                    </summary>
                    <div style={{ marginTop: '14px' }}>
                      <ArtifactContentManager
                        key={`contents-${artifact.id}`}
                        artifactId={artifact.backendId || artifact.id}
                        canWrite={!readOnly && ['administrator', 'museumStaff'].includes(currentRole)}
                        canReadVersions={['administrator', 'museumStaff', 'curator'].includes(currentRole)}
                      />
                    </div>
                  </details>
                )}
              </div>
            </div>
          )}

          {activeTab === '3d' && <Artifact3DPanel
            key={artifact.backendId || artifact.id}
            artifactId={artifact.backendId || artifact.id}
            name={artifact.name}
            onModelChange={setHas3DModel}
            canManage={!readOnly && ['administrator', 'museumStaff'].includes(currentRole)}
          />}

          {activeTab === 'qr' && (
            <div>
            <div className="artifact-detail-grid" style={{ display: 'grid', gridTemplateColumns: '260px minmax(0, 1fr)', gap: '28px', alignItems: 'center' }}>
              <div style={{
                background: '#FFFFFF',
                padding: '20px',
                borderRadius: '12px',
                border: '2px solid var(--color-burgundy-700)',
                textAlign: 'center',
                boxShadow: 'var(--shadow-md)'
              }}>
                <div style={{ width: '200px', height: '200px', margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#FAF7F2', borderRadius: '8px', overflow: 'hidden' }}>
                  {!qrImgError ? (
                    <img
                      src={getArtifactQrImageUrl(artifact.id)}
                      alt={`Mã QR ${artifact.name}`}
                      style={{ width: '190px', height: '190px', objectFit: 'contain' }}
                      onError={() => setQrImgError(true)}
                    />
                  ) : (
                    <svg viewBox="0 0 100 100" width="180" height="180">
                      <rect width="100" height="100" fill="#ffffff" />
                      <rect x="10" y="10" width="25" height="25" fill="#8B1E28" />
                      <rect x="15" y="15" width="15" height="15" fill="#ffffff" />
                      <rect x="18" y="18" width="9" height="9" fill="#8B1E28" />
                      <rect x="65" y="10" width="25" height="25" fill="#8B1E28" />
                      <rect x="70" y="15" width="15" height="15" fill="#ffffff" />
                      <rect x="73" y="18" width="9" height="9" fill="#8B1E28" />
                      <rect x="10" y="65" width="25" height="25" fill="#8B1E28" />
                      <rect x="15" y="70" width="15" height="15" fill="#ffffff" />
                      <rect x="18" y="73" width="9" height="9" fill="#8B1E28" />
                      <rect x="42" y="42" width="16" height="16" fill="#D4AF37" />
                      <rect x="42" y="15" width="6" height="16" fill="#14181E" />
                      <rect x="65" y="45" width="20" height="6" fill="#14181E" />
                      <rect x="45" y="70" width="15" height="15" fill="#14181E" />
                      <rect x="70" y="70" width="10" height="10" fill="#14181E" />
                    </svg>
                  )}
                </div>
                <div style={{ marginTop: '12px', fontWeight: '700', fontSize: '0.875rem', fontFamily: 'monospace', color: 'var(--color-burgundy-800)' }}>
                  {activeQrCode || artifact.qrCode}
                </div>
              </div>

              <div>
                <h4 style={{ fontSize: '1.125rem', fontWeight: '700', marginBottom: '8px', color: 'var(--color-burgundy-900)' }}>
                  Mã QR gắn hiện vật và hồ sơ số
                </h4>
                <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-700)', lineHeight: '1.6', marginBottom: '16px' }}>
                  Khách tham quan dùng ứng dụng di động quét mã này ngay tại tủ kính trưng bày để:
                </p>
                <ul style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-700)', marginLeft: '20px', lineHeight: '1.8', marginBottom: '20px' }}>
                  <li>Tự động ghi nhận lượt tham quan vào lịch sử và bản đồ hành trình.</li>
                  <li>Kích hoạt thuyết minh âm thanh đa ngôn ngữ theo sở thích.</li>
                  <li>Mở giao diện hỏi đáp tương tác với Trợ lý AI Bảo tàng.</li>
                  <li>Mở câu hỏi tương tác để tích điểm huy hiệu.</li>
                </ul>

                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                  <button type="button" onClick={handlePrintQR} className="btn btn-primary">
                    <Printer size={16} /> In Bảng Mã QR
                  </button>
                  <button
                    type="button"
                    onClick={() => downloadArtifactQr(artifact.id, artifact.name)}
                    className="btn btn-secondary"
                    title="Tải ảnh PNG từ Backend"
                  >
                    <Download size={16} /> Tải ảnh QR PNG
                  </button>
                  {!readOnly && (
                    <button
                      type="button"
                      disabled={isRegenerating}
                      onClick={handleRegenerateQR}
                      className="btn btn-secondary"
                      title="Cấp mã QR hoàn toàn mới từ Backend"
                    >
                      <RefreshCw size={16} className={isRegenerating ? 'spin-animation' : ''} />
                      <span>{isRegenerating ? 'Đang cấp lại...' : 'Tạo lại mã QR'}</span>
                    </button>
                  )}
                  <button type="button" onClick={handleCopyQR} className="btn btn-secondary">
                    {copiedQR ? <Check size={16} color="var(--color-success)" /> : <QrCode size={16} />}
                    {copiedQR ? 'Đã sao chép mã!' : 'Sao chép chuỗi mã'}
                  </button>
                </div>
              </div>
            </div>
            <section className="card" style={{ marginTop: '24px', padding: '20px', background: '#FAF7F2', border: '1px solid #EADCC8' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
                    <h4 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--color-burgundy-900)', margin: 0 }}>Ảnh tham chiếu nhận diện AI Vision</h4>
                    <span style={{
                      fontSize: '0.675rem',
                      padding: '2px 8px',
                      borderRadius: '4px',
                      background: visionHealth?.ok ? '#DCFCE7' : '#FEF3C7',
                      color: visionHealth?.ok ? '#166534' : '#92400E',
                      fontWeight: '600'
                    }}>
                      {visionHealth?.ok ? `AI Vision (Port 8001): ${visionHealth.referenceCount} vectors đã index` : 'AI Vision: Ngoại tuyến'}
                    </span>
                  </div>
                  <p style={{ fontSize: '0.8125rem', lineHeight: '1.5', color: 'var(--color-charcoal-600)', maxWidth: '650px', margin: 0 }}>
                    Ảnh được trích xuất vector đặc trưng 512 chiều bằng mô hình CLIP ViT-B/32 ONNX và lưu vào schema <code>ai_vision</code> của database. Phục vụ nhận diện camera cho khách tham quan.
                  </p>
                </div>

                {!readOnly && (
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                    <label className="btn btn-primary btn-sm" style={{ cursor: referenceImages.length >= 20 ? 'not-allowed' : 'pointer', opacity: referenceImages.length >= 20 ? 0.55 : 1 }}>
                      + Tải ảnh tham chiếu
                      <input
                        type="file"
                        accept="image/jpeg,image/png,image/webp"
                        multiple
                        disabled={referenceImages.length >= 20}
                        style={{ display: 'none' }}
                        onChange={(event) => {
                          const files = Array.from(event.target.files || []).filter(file => file.type.startsWith('image/'));
                          const remaining = Math.max(0, 20 - referenceImages.length);
                          setReferenceImages(current => [...current, ...files.slice(0, remaining).map((file, index) => ({
                            id: `${Date.now()}-${index}-${file.name}`,
                            url: URL.createObjectURL(file),
                            file: file,
                            name: file.name,
                            status: 'Chưa đồng bộ vector'
                          }))]);
                          event.target.value = '';
                        }}
                      />
                    </label>

                    <button
                      type="button"
                      disabled={isSyncingVision || !referenceImages.some(img => img.file && !img.status?.includes('Đã index'))}
                      onClick={handleSyncAllReferences}
                      className="btn btn-gold btn-sm"
                      title="Đẩy ảnh vào AI Vision để tính toán vector 512 chiều"
                    >
                      {isSyncingVision ? (
                        <>
                          <RefreshCw size={13} className="spin" style={{ animation: 'spin 1s linear infinite' }} />
                          <span>Đang trích xuất vector...</span>
                        </>
                      ) : (
                        <>
                          <Sparkles size={13} />
                          <span>Đồng bộ vào AI Vision</span>
                        </>
                      )}
                    </button>

                    {referenceImages.length > 0 && (
                      <button
                        type="button"
                        onClick={handleClearAllReferences}
                        className="btn btn-secondary btn-sm"
                        style={{ color: '#991B1B' }}
                        title="Xóa toàn bộ vector tham chiếu của hiện vật này trên AI Vision"
                      >
                        Xóa vector
                      </button>
                    )}
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginTop: '12px', fontSize: '0.75rem', color: 'var(--color-charcoal-600)' }}>
                <span>{referenceImages.length}/20 ảnh</span>
                <span>•</span>
                <span>Model: CLIP ViT-B/32 ONNX (512d)</span>
                <span>•</span>
                <span>Chỉ quản trị viên / nhân viên bảo tàng có quyền chỉnh sửa</span>
              </div>

              {visionSyncError && (
                <div style={{ marginTop: '10px', padding: '8px 12px', background: '#FEF2F2', border: '1px solid #FCA5A5', borderRadius: '6px', fontSize: '0.75rem', color: '#991B1B' }}>
                  {visionSyncError}
                </div>
              )}

              {referenceImages.length ? (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))', gap: '12px', marginTop: '16px' }}>
                  {referenceImages.map(image => (
                    <div key={image.id} style={{ overflow: 'hidden', border: '1px solid var(--color-paper-border)', borderRadius: '8px', background: 'white' }}>
                      <img src={image.url} alt={image.name} style={{ width: '100%', height: '112px', objectFit: 'cover', display: 'block' }} />
                      <div style={{ padding: '8px' }}>
                        <div title={image.name} style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: '0.75rem', fontWeight: 600 }}>{image.name}</div>
                        <div style={{
                          marginTop: '4px',
                          fontSize: '0.6875rem',
                          color: image.status?.includes('Đã index') ? 'var(--color-success)' : 'var(--color-charcoal-500)',
                          fontWeight: image.status?.includes('Đã index') ? '600' : 'normal'
                        }}>
                          {image.status || 'Đã index'}
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '6px' }}>
                          {!readOnly && image.file && !image.status?.includes('Đã index') && (
                            <button
                              type="button"
                              onClick={() => handleSyncReferenceToVision(image)}
                              style={{ fontSize: '0.675rem', color: 'var(--color-burgundy-700)', fontWeight: '600', background: 'none', border: 'none', padding: 0, cursor: 'pointer' }}
                            >
                              Sync vector
                            </button>
                          )}
                          {!readOnly && (
                            <button
                              type="button"
                              onClick={() => setReferenceImages(current => current.filter(item => item.id !== image.id))}
                              style={{ fontSize: '0.675rem', color: '#991B1B', background: 'none', border: 'none', padding: 0, cursor: 'pointer' }}
                            >
                              Gỡ ảnh
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ marginTop: '16px', padding: '24px', textAlign: 'center', border: '1px dashed var(--color-paper-border)', borderRadius: '8px', color: 'var(--color-charcoal-500)', fontSize: '0.8125rem' }}>
                  Chưa có ảnh tham chiếu. Tải ảnh hiện vật đã được nhân viên kiểm duyệt để chuẩn bị lập chỉ mục nhận diện.
                </div>
              )}
            </section>
            </div>
          )}

          {/* Multilingual Tab */}
          {activeTab === 'multilingual' && (
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <h4 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }}>
                  Bản dịch thuyết minh đa ngôn ngữ
                </h4>
                {!readOnly && <button
                  type="button"
                  onClick={() => {
                    onClose();
                    onOpenAIStudio(artifact);
                  }}
                  className="btn btn-gold btn-sm"
                >
                  <Sparkles size={14} /> Dịch tự động bằng xưởng nội dung AI
                </button>}
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {/* English */}
                <div className="card" style={{ padding: '16px', background: '#FAFAF8' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                    <span style={{ fontSize: '1.25rem' }}>🇬🇧</span>
                    <strong style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-900)' }}>
                      Tiếng Anh — {artifact.multilingual?.en?.name || artifact.altName || artifact.name}
                    </strong>
                  </div>
                  <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', lineHeight: '1.6' }}>
                    {artifact.multilingual?.en?.shortDesc || 'Chưa có bản dịch tiếng Anh cho hiện vật này.'}
                  </p>
                </div>

                {/* French */}
                <div className="card" style={{ padding: '16px', background: '#FAFAF8' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                    <span style={{ fontSize: '1.25rem' }}>🇫🇷</span>
                    <strong style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-900)' }}>
                      Français — {artifact.multilingual?.fr?.name || artifact.name}
                    </strong>
                  </div>
                  <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', lineHeight: '1.6' }}>
                    {artifact.multilingual?.fr?.shortDesc || 'Chưa có bản dịch tiếng Pháp cho hiện vật này.'}
                  </p>
                </div>

                {/* Japanese */}
                <div className="card" style={{ padding: '16px', background: '#FAFAF8' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                    <span style={{ fontSize: '1.25rem' }}>🇯🇵</span>
                    <strong style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-900)' }}>
                      日本語 — {artifact.multilingual?.ja?.name || artifact.name}
                    </strong>
                  </div>
                  <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', lineHeight: '1.6' }}>
                    {artifact.multilingual?.ja?.shortDesc || 'Chưa có bản dịch tiếng Nhật cho hiện vật này.'}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Quizzes Tab */}
          {activeTab === 'quizzes' && (
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <h4 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }}>
                  Kho câu hỏi tương tác ({artifact.quizzes?.length || 0} câu)
                </h4>
                {!readOnly && <button
                  type="button"
                  onClick={() => {
                    onClose();
                    onOpenAIStudio(artifact);
                  }}
                  className="btn btn-gold btn-sm"
                >
                  <Sparkles size={14} /> Tạo thêm câu hỏi bằng AI
                </button>}
              </div>

              {artifact.quizzes && artifact.quizzes.length > 0 ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  {artifact.quizzes.map((q, idx) => (
                    <div key={q.id || idx} className="card" style={{ padding: '16px', borderLeft: '4px solid var(--color-burgundy-600)' }}>
                      <div style={{ fontWeight: '600', fontSize: '0.875rem', marginBottom: '10px' }}>
                        Câu {idx + 1}: {q.question}
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginBottom: '10px' }}>
                        {q.options.map((opt, oIdx) => (
                          <div
                            key={oIdx}
                            style={{
                              padding: '8px 12px',
                              borderRadius: '6px',
                              fontSize: '0.8125rem',
                              background: oIdx === q.correctIndex ? '#DCFCE7' : '#F1F5F9',
                              border: oIdx === q.correctIndex ? '1px solid #86EFAC' : '1px solid #E2E8F0',
                              color: oIdx === q.correctIndex ? '#166534' : 'var(--color-charcoal-800)',
                              fontWeight: oIdx === q.correctIndex ? '600' : '400'
                            }}
                          >
                            {String.fromCharCode(65 + oIdx)}. {opt} {oIdx === q.correctIndex && '✓ (Đáp án đúng)'}
                          </div>
                        ))}
                      </div>
                      {q.explanation && (
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-600)', background: '#F8F5EE', padding: '8px 12px', borderRadius: '6px' }}>
                          💡 <strong>Giải thích lịch sử:</strong> {q.explanation}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ padding: '40px 20px', textAlign: 'center', background: '#F8F5EE', borderRadius: '12px' }}>
                  <HelpCircle size={40} color="var(--color-charcoal-400)" style={{ margin: '0 auto 12px' }} />
                  <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-600)', marginBottom: '16px' }}>
                    Hiện vật này chưa có bộ câu hỏi tương tác. Hãy dùng xưởng nội dung AI để tạo bộ trắc nghiệm!
                  </p>
                  {!readOnly && <button
                    type="button"
                    onClick={() => {
                      onClose();
                      onOpenAIStudio(artifact);
                    }}
                    className="btn btn-gold btn-sm"
                  >
                    <Sparkles size={14} /> Mở xưởng câu hỏi AI
                  </button>}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="modal-footer" style={{ flexShrink: 0 }}>
          <button type="button" onClick={onClose} className="btn btn-secondary">
            Đóng cửa sổ
          </button>
        </div>
      </div>
    </div>
  );

  return typeof document !== 'undefined' ? createPortal(modalContent, document.body) : modalContent;
}
