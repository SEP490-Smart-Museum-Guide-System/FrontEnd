import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import '@google/model-viewer';
import { useApp } from '../../context/AppContext';
import { getArtifactQrImageUrl } from '../../services/artifactApi';
import { getPublishedArtifactContentApi } from '../../services/contentSubmissionApi';
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
  const { downloadArtifactQr, regenerateArtifactQr, currentRole } = useApp();
  const [activeTab, setActiveTab] = useState('overview'); // overview | 3d | qr | multilingual | quizzes
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
        <div className="modal-header">
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
                <span className={`badge-status badge-${artifact.status}`}>
                  {artifact.status === 'published' ? 'Đã xuất bản' : artifact.status === 'pending_review' ? 'Chờ duyệt' : 'Bản nháp'}
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

        {/* Navigation Tabs */}
        <div className="artifact-modal-tabs" style={{
          display: 'flex',
          borderBottom: '1px solid var(--color-paper-border)',
          background: '#FDFCF9',
          padding: '0 24px'
        }}>
          {[
            { id: 'overview', label: 'Tổng quan & Thuyết minh', icon: Layers },
            { id: '3d', label: 'Xem Mô hình 3D (AR)', icon: Box, badge: artifact.has3DModel ? 'Sẵn sàng' : 'Chưa có' },
            { id: 'qr', label: 'Mã QR & Nhận diện', icon: QrCode },
            { id: 'multilingual', label: 'Đa ngôn ngữ', icon: Globe },
            { id: 'quizzes', label: `Câu hỏi tương tác (${artifact.quizzes?.length || 0})`, icon: HelpCircle }
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
                  gap: '8px',
                  padding: '14px 18px',
                  fontSize: '0.875rem',
                  fontWeight: isActive ? '600' : '500',
                  color: isActive ? 'var(--color-burgundy-700)' : 'var(--color-charcoal-600)',
                  borderBottom: isActive ? '3px solid var(--color-burgundy-700)' : '3px solid transparent',
                  background: 'none',
                  transition: 'all var(--transition-fast)'
                }}
              >
                <Icon size={16} />
                <span>{tab.label}</span>
                {tab.badge && (
                  <span style={{
                    fontSize: '0.675rem',
                    padding: '2px 6px',
                    borderRadius: '4px',
                    background: artifact.has3DModel ? '#DCFCE7' : '#F1F5F9',
                    color: artifact.has3DModel ? '#166534' : '#64748B'
                  }}>
                    {tab.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Modal Body */}
        <div className="modal-body">
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
                    src={artifact.image || '/assets/images/ngoc-lu-web.jpg'}
                    alt={artifact.name}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    onError={(e) => {
                      e.target.src = '/assets/images/national-museum-web.jpg';
                    }}
                  />
                </div>

                {/* Audio Guide Player Preview */}
                <div className="card" style={{ padding: '16px', background: '#F8F5EE' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Volume2 size={16} color="var(--color-burgundy-700)" />
                      <span style={{ fontSize: '0.8125rem', fontWeight: '600' }}>Thuyết minh âm thanh</span>
                    </div>
                    <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', fontWeight: '500' }}>
                      {artifact.audioDuration || '03:45'}
                    </span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <button
                      type="button"
                      onClick={() => setIsPlayingAudio(!isPlayingAudio)}
                      className="btn btn-primary btn-sm"
                      style={{ borderRadius: '50%', width: '36px', height: '36px', padding: 0 }}
                    >
                      {isPlayingAudio ? <Pause size={16} /> : <Play size={16} />}
                    </button>
                    <div style={{ flex: 1, height: '6px', background: '#E2E8F0', borderRadius: '4px', overflow: 'hidden' }}>
                      <div style={{ width: isPlayingAudio ? '45%' : '0%', height: '100%', background: 'var(--color-burgundy-700)', transition: 'width 300ms' }} />
                    </div>
                  </div>
                  {isPlayingAudio && (
                    <p style={{ fontSize: '0.7rem', color: 'var(--color-burgundy-700)', marginTop: '6px', fontStyle: 'italic' }}>
                      Đang phát mẫu âm thanh thuyết minh di sản...
                    </p>
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
                    <span style={{ fontWeight: '600', color: 'var(--color-burgundy-700)' }}>{artifact.scansCount.toLocaleString()} lượt</span>
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
              </div>
            </div>
          )}

          {/* 3D Model Tab */}
          {activeTab === '3d' && (
            <div style={{ textAlign: 'center' }}>
              {artifact.has3DModel ? (
                <div>
                  <div style={{
                    height: '420px',
                    borderRadius: '12px',
                    overflow: 'hidden',
                    background: 'radial-gradient(circle, #2A303C 0%, #121519 100%)',
                    border: '1px solid var(--color-paper-border)',
                    position: 'relative'
                  }}>
                    <model-viewer
                      src={artifact.modelUrl || '/assets/models/trong_dong_dong_son.glb'}
                      alt={artifact.name}
                      auto-rotate
                      camera-controls
                      ar
                      shadow-intensity="1"
                      style={{ width: '100%', height: '100%' }}
                    />
                    <div style={{
                      position: 'absolute',
                      bottom: '16px',
                      left: '50%',
                      transform: 'translateX(-50%)',
                      background: 'rgba(0, 0, 0, 0.7)',
                      color: '#FFFFFF',
                      padding: '6px 16px',
                      borderRadius: '20px',
                      fontSize: '0.75rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px'
                    }}>
                      <Box size={14} color="var(--color-gold-400)" />
                      <span>Dùng chuột kéo để xoay 360° • Cuộn để phóng to/thu nhỏ • Hỗ trợ AR di động</span>
                    </div>
                  </div>
                  <p style={{ marginTop: '12px', fontSize: '0.8125rem', color: 'var(--color-charcoal-500)' }}>
                    Mô hình 3D định dạng GLTF/GLB tương thích với WebGL và ứng dụng di động SMGS.
                  </p>
                </div>
              ) : (
                <div style={{ padding: '60px 20px', background: '#F8F5EE', borderRadius: '12px', border: '1px dashed var(--color-paper-border)' }}>
                  <Box size={48} color="var(--color-charcoal-400)" style={{ margin: '0 auto 16px' }} />
                  <h4 style={{ fontSize: '1.125rem', fontWeight: '600', marginBottom: '6px' }}>Chưa có mô hình 3D</h4>
                  <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', maxWidth: '440px', margin: '0 auto 20px' }}>
                    Hiện vật này đang trong quá trình scan 3D và số hóa không gian. Nhân viên có thể tải lên tệp .glb bất cứ lúc nào.
                  </p>
                  {!readOnly && <button type="button" onClick={() => onEdit(artifact)} className="btn btn-primary btn-sm">
                    Tải lên file 3D (.glb / .gltf)
                  </button>}
                </div>
              )}
            </div>
          )}

          {/* QR Code Tab */}
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
            <section className="card" style={{ marginTop: '24px', padding: '20px', background: '#FAF7F2' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
                <div>
                  <h4 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--color-burgundy-900)', marginBottom: '6px' }}>Ảnh tham chiếu nhận diện</h4>
                  <p style={{ fontSize: '0.8125rem', lineHeight: '1.5', color: 'var(--color-charcoal-600)', maxWidth: '650px' }}>
                    Ảnh được gắn với hiện vật <strong>{artifact.name}</strong>. Chọn nhiều góc chụp rõ nét; ảnh khách gửi để nhận diện không tự động thêm vào bộ ảnh này.
                  </p>
                </div>
                {!readOnly && <label className="btn btn-primary btn-sm" style={{ cursor: referenceImages.length >= 20 ? 'not-allowed' : 'pointer', opacity: referenceImages.length >= 20 ? 0.55 : 1 }}>
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
                        name: file.name,
                        status: 'Chờ kết nối BE'
                      }))]);
                      event.target.value = '';
                    }}
                  />
                </label>}
              </div>
              <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginTop: '12px', fontSize: '0.75rem', color: 'var(--color-charcoal-600)' }}>
                <span>{referenceImages.length}/20 ảnh</span>
                <span>•</span>
                <span>Chỉ quản trị viên / nhân viên bảo tàng có quyền chỉnh sửa</span>
              </div>
              {referenceImages.length ? <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(145px, 1fr))', gap: '12px', marginTop: '16px' }}>
                {referenceImages.map(image => <div key={image.id} style={{ overflow: 'hidden', border: '1px solid var(--color-paper-border)', borderRadius: '8px', background: 'white' }}>
                  <img src={image.url} alt={image.name} style={{ width: '100%', height: '112px', objectFit: 'cover', display: 'block' }} />
                  <div style={{ padding: '8px' }}>
                    <div title={image.name} style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: '0.75rem', fontWeight: 600 }}>{image.name}</div>
                    <div style={{ marginTop: '4px', fontSize: '0.6875rem', color: 'var(--color-charcoal-500)' }}>{image.status || 'Đã index'}</div>
                    {!readOnly && <button type="button" onClick={() => setReferenceImages(current => current.filter(item => item.id !== image.id))} style={{ marginTop: '6px', fontSize: '0.7rem', color: 'var(--color-burgundy-700)' }}>Gỡ khỏi danh sách</button>}
                  </div>
                </div>)}
              </div> : <div style={{ marginTop: '16px', padding: '24px', textAlign: 'center', border: '1px dashed var(--color-paper-border)', borderRadius: '8px', color: 'var(--color-charcoal-500)', fontSize: '0.8125rem' }}>
                Chưa có ảnh tham chiếu. Tải ảnh hiện vật đã được nhân viên kiểm duyệt để chuẩn bị lập chỉ mục nhận diện.
              </div>}
              <p style={{ marginTop: '12px', fontSize: '0.7rem', color: 'var(--color-charcoal-500)' }}>
                Bản giao diện hiện chỉ tạo xem trước trong phiên này; chưa tải file lên backend hay gọi AI Vision.
              </p>
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
        <div className="modal-footer">
          <button type="button" onClick={onClose} className="btn btn-secondary">
            Đóng cửa sổ
          </button>
        </div>
      </div>
    </div>
  );

  return typeof document !== 'undefined' ? createPortal(modalContent, document.body) : modalContent;
}
