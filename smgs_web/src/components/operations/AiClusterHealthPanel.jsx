import React, { useState, useEffect } from 'react';
import {
  Activity,
  Bot,
  Box,
  CheckCircle2,
  Clock,
  Eye,
  Headphones,
  Layers,
  Play,
  RefreshCw,
  Server,
  ShieldCheck,
  Sparkles,
  Volume2,
  Wifi,
  WifiOff,
  XCircle
} from 'lucide-react';
import { checkTtsHealthApi, generateSpeechApi } from '../../services/ttsApi';
import { checkVisionHealthApi } from '../../services/visionApi';
import { checkScanHealthApi } from '../../services/scan3dApi';

export default function AiClusterHealthPanel() {
  const [loading, setLoading] = useState(false);
  const [lastCheck, setLastCheck] = useState(null);
  const [ttsSampleText, setTtsSampleText] = useState('Trống đồng Ngọc Lũ là tuyệt tác đỉnh cao của nghệ thuật đúc đồng Đông Sơn.');
  const [ttsPlaying, setTtsPlaying] = useState(false);
  const [ttsAudioUrl, setTtsAudioUrl] = useState(null);
  const [activeTab, setActiveTab] = useState('overview'); // 'overview' | 'interactive_test'

  const [statuses, setStatuses] = useState({
    tts: { name: 'TTS AI Microservice', port: 8000, status: 'unknown', latency: 0, details: null },
    vision: { name: 'AI Vision Microservice', port: 8001, status: 'unknown', latency: 0, details: null },
    scan: { name: '3D Photogrammetry Scan', port: 8002, status: 'unknown', latency: 0, details: null },
    backend: { name: 'SMGS Backend Core API', port: 5169, status: 'unknown', latency: 0, details: null }
  });

  const checkAllServices = async () => {
    setLoading(true);

    // 1. Check TTS (Port 8000)
    const ttsStart = performance.now();
    let ttsRes = { ok: false, status: 'offline' };
    try {
      ttsRes = await checkTtsHealthApi();
    } catch (_) {}
    const ttsLatency = Math.round(performance.now() - ttsStart);

    // 2. Check Vision (Port 8001)
    const visionStart = performance.now();
    let visionRes = { ok: false, status: 'offline' };
    try {
      visionRes = await checkVisionHealthApi();
    } catch (_) {}
    const visionLatency = Math.round(performance.now() - visionStart);

    // 3. Check 3D Scan (Port 8002)
    const scanStart = performance.now();
    let scanRes = { ok: false, status: 'offline' };
    try {
      scanRes = await checkScanHealthApi();
    } catch (_) {}
    const scanLatency = Math.round(performance.now() - scanStart);

    // 4. Check Backend Core (Port 5169)
    const beStart = performance.now();
    let beRes = { ok: false, status: 'offline' };
    try {
      const res = await fetch('/api/museums', { signal: AbortSignal.timeout(3000) });
      beRes = { ok: res.ok, status: res.ok ? 'ok' : `HTTP ${res.status}` };
    } catch (e) {
      beRes = { ok: false, status: 'offline', error: e.message };
    }
    const beLatency = Math.round(performance.now() - beStart);

    setStatuses({
      tts: {
        name: 'TTS AI Microservice',
        port: 8000,
        status: ttsRes.ok ? 'online' : 'offline',
        latency: ttsLatency,
        details: ttsRes.ok ? `Piper voice: ${ttsRes.voice || 'vi_VN-vais1000-medium'}` : 'Chưa kết nối cổng 8000'
      },
      vision: {
        name: 'AI Vision Microservice',
        port: 8001,
        status: visionRes.ok ? 'online' : 'offline',
        latency: visionLatency,
        details: visionRes.ok ? `CLIP ONNX 512d · ${visionRes.referenceCount || 0} vectors index` : 'Chưa kết nối cổng 8001'
      },
      scan: {
        name: '3D Photogrammetry Scan',
        port: 8002,
        status: scanRes.ok ? 'online' : 'offline',
        latency: scanLatency,
        details: scanRes.ok ? `COLMAP worker · ${scanRes.colmapAvailable ? 'Sẵn sàng' : 'Chờ cấu hình'}` : 'Chưa kết nối cổng 8002'
      },
      backend: {
        name: 'SMGS Backend Core API',
        port: 5169,
        status: beRes.ok ? 'online' : 'offline',
        latency: beLatency,
        details: beRes.ok ? 'ASP.NET Core 8 · PostgreSQL smgs_db' : 'Chưa kết nối cổng 5169'
      }
    });

    setLastCheck(new Date().toLocaleTimeString('vi-VN'));
    setLoading(false);
  };

  useEffect(() => {
    checkAllServices();
  }, []);

  const handleTestTtsPlay = async () => {
    if (!ttsSampleText.trim()) return;
    setTtsPlaying(true);
    try {
      const res = await generateSpeechApi({ text: ttsSampleText });
      if (res?.audioUrl) {
        setTtsAudioUrl(res.audioUrl);
        const audio = new Audio(res.audioUrl);
        audio.onended = () => setTtsPlaying(false);
        audio.onerror = () => setTtsPlaying(false);
        await audio.play();
      }
    } catch (err) {
      alert('Không thể phát thử nghiệm TTS: ' + err.message + '\n\nHãy đảm bảo service TTS :8000 đang được bật.');
      setTtsPlaying(false);
    }
  };

  const allHealthy = Object.values(statuses).every(s => s.status === 'online');
  const onlineCount = Object.values(statuses).filter(s => s.status === 'online').length;

  return (
    <section
      style={{
        background: '#FAF7F2',
        border: '1px solid var(--color-gold-200)',
        borderRadius: '12px',
        padding: '24px',
        marginBottom: '28px',
        boxShadow: '0 4px 20px rgba(0, 0, 0, 0.04)'
      }}
    >
      {/* Header Bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px', marginBottom: '20px' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
            <span
              style={{
                display: 'inline-block',
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                background: allHealthy ? '#16A34A' : onlineCount > 0 ? '#EAB308' : '#DC2626'
              }}
            />
            <span style={{ fontSize: '0.72rem', letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--color-burgundy-800)', fontWeight: '700' }}>
              KIỂM TRA HỆ THỐNG TRỰC TIẾP · ARCHITECTURE MONITOR
            </span>
          </div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: '700', color: 'var(--color-burgundy-900)', margin: 0 }} className="font-serif">
            Trung tâm Giám sát Kết nối Cụm Microservices AI & Backend
          </h2>
          <p style={{ fontSize: '0.825rem', color: 'var(--color-charcoal-600)', margin: '4px 0 0' }}>
            Theo dõi trạng thái thời gian thực của bộ ba AI-System (TTS :8000, Vision :8001, 3D Scan :8002) và Backend ASP.NET Core 8.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {lastCheck && (
            <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', fontVariantNumeric: 'tabular-nums' }}>
              Kiểm tra lúc: {lastCheck}
            </span>
          )}
          <button
            type="button"
            className="btn btn-secondary btn-sm"
            onClick={checkAllServices}
            disabled={loading}
            style={{ display: 'flex', alignItems: 'center', gap: '6px', background: '#FFF' }}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            <span>{loading ? 'Đang kiểm tra...' : 'Kiểm tra kết nối lại'}</span>
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '18px', borderBottom: '1px solid var(--color-gold-200)', paddingBottom: '10px' }}>
        <button
          type="button"
          onClick={() => setActiveTab('overview')}
          style={{
            background: activeTab === 'overview' ? 'var(--color-burgundy-900)' : 'transparent',
            color: activeTab === 'overview' ? '#FFF' : 'var(--color-charcoal-700)',
            border: 'none',
            padding: '6px 14px',
            borderRadius: '6px',
            fontSize: '0.8rem',
            fontWeight: '600',
            cursor: 'pointer'
          }}
        >
          Trạng thái 4 Cụm dịch vụ ({onlineCount}/4 Online)
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('interactive_test')}
          style={{
            background: activeTab === 'interactive_test' ? 'var(--color-burgundy-900)' : 'transparent',
            color: activeTab === 'interactive_test' ? '#FFF' : 'var(--color-charcoal-700)',
            border: 'none',
            padding: '6px 14px',
            borderRadius: '6px',
            fontSize: '0.8rem',
            fontWeight: '600',
            cursor: 'pointer'
          }}
        >
          Thử nghiệm Microservice Trực tiếp (Quick Diagnostic)
        </button>
      </div>

      {activeTab === 'overview' ? (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
          {/* 1. TTS Card */}
          <div
            style={{
              background: '#FFF',
              border: `1px solid ${statuses.tts.status === 'online' ? '#BBF7D0' : '#FECACA'}`,
              borderRadius: '8px',
              padding: '16px',
              position: 'relative'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Headphones size={20} color="var(--color-burgundy-800)" />
                <strong style={{ fontSize: '0.9rem', color: 'var(--color-charcoal-900)' }}>TTS AI (:8000)</strong>
              </div>
              <span
                style={{
                  fontSize: '0.7rem',
                  fontWeight: '700',
                  padding: '3px 8px',
                  borderRadius: '12px',
                  background: statuses.tts.status === 'online' ? '#DCFCE7' : '#FEE2E2',
                  color: statuses.tts.status === 'online' ? '#166534' : '#991B1B'
                }}
              >
                {statuses.tts.status === 'online' ? '● ONLINE' : '○ OFFLINE'}
              </span>
            </div>
            <p style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-600)', margin: '0 0 10px', minHeight: '36px' }}>
              {statuses.tts.details}
            </p>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--color-charcoal-500)', borderTop: '1px solid #F1F5F9', paddingTop: '8px' }}>
              <span>Độ trễ phản hồi:</span>
              <strong style={{ fontVariantNumeric: 'tabular-nums', color: statuses.tts.status === 'online' ? '#16A34A' : '#64748B' }}>
                {statuses.tts.latency} ms
              </strong>
            </div>
          </div>

          {/* 2. AI Vision Card */}
          <div
            style={{
              background: '#FFF',
              border: `1px solid ${statuses.vision.status === 'online' ? '#BBF7D0' : '#FECACA'}`,
              borderRadius: '8px',
              padding: '16px'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Eye size={20} color="var(--color-burgundy-800)" />
                <strong style={{ fontSize: '0.9rem', color: 'var(--color-charcoal-900)' }}>AI Vision (:8001)</strong>
              </div>
              <span
                style={{
                  fontSize: '0.7rem',
                  fontWeight: '700',
                  padding: '3px 8px',
                  borderRadius: '12px',
                  background: statuses.vision.status === 'online' ? '#DCFCE7' : '#FEE2E2',
                  color: statuses.vision.status === 'online' ? '#166534' : '#991B1B'
                }}
              >
                {statuses.vision.status === 'online' ? '● ONLINE' : '○ OFFLINE'}
              </span>
            </div>
            <p style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-600)', margin: '0 0 10px', minHeight: '36px' }}>
              {statuses.vision.details}
            </p>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--color-charcoal-500)', borderTop: '1px solid #F1F5F9', paddingTop: '8px' }}>
              <span>Độ trễ phản hồi:</span>
              <strong style={{ fontVariantNumeric: 'tabular-nums', color: statuses.vision.status === 'online' ? '#16A34A' : '#64748B' }}>
                {statuses.vision.latency} ms
              </strong>
            </div>
          </div>

          {/* 3. 3D Scan Card */}
          <div
            style={{
              background: '#FFF',
              border: `1px solid ${statuses.scan.status === 'online' ? '#BBF7D0' : '#FECACA'}`,
              borderRadius: '8px',
              padding: '16px'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Box size={20} color="var(--color-burgundy-800)" />
                <strong style={{ fontSize: '0.9rem', color: 'var(--color-charcoal-900)' }}>3D Scan (:8002)</strong>
              </div>
              <span
                style={{
                  fontSize: '0.7rem',
                  fontWeight: '700',
                  padding: '3px 8px',
                  borderRadius: '12px',
                  background: statuses.scan.status === 'online' ? '#DCFCE7' : '#FEE2E2',
                  color: statuses.scan.status === 'online' ? '#166534' : '#991B1B'
                }}
              >
                {statuses.scan.status === 'online' ? '● ONLINE' : '○ OFFLINE'}
              </span>
            </div>
            <p style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-600)', margin: '0 0 10px', minHeight: '36px' }}>
              {statuses.scan.details}
            </p>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--color-charcoal-500)', borderTop: '1px solid #F1F5F9', paddingTop: '8px' }}>
              <span>Độ trễ phản hồi:</span>
              <strong style={{ fontVariantNumeric: 'tabular-nums', color: statuses.scan.status === 'online' ? '#16A34A' : '#64748B' }}>
                {statuses.scan.latency} ms
              </strong>
            </div>
          </div>

          {/* 4. Backend Core Card */}
          <div
            style={{
              background: '#FFF',
              border: `1px solid ${statuses.backend.status === 'online' ? '#BBF7D0' : '#FECACA'}`,
              borderRadius: '8px',
              padding: '16px'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Server size={20} color="var(--color-burgundy-800)" />
                <strong style={{ fontSize: '0.9rem', color: 'var(--color-charcoal-900)' }}>Backend API (:5169)</strong>
              </div>
              <span
                style={{
                  fontSize: '0.7rem',
                  fontWeight: '700',
                  padding: '3px 8px',
                  borderRadius: '12px',
                  background: statuses.backend.status === 'online' ? '#DCFCE7' : '#FEE2E2',
                  color: statuses.backend.status === 'online' ? '#166534' : '#991B1B'
                }}
              >
                {statuses.backend.status === 'online' ? '● ONLINE' : '○ OFFLINE'}
              </span>
            </div>
            <p style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-600)', margin: '0 0 10px', minHeight: '36px' }}>
              {statuses.backend.details}
            </p>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--color-charcoal-500)', borderTop: '1px solid #F1F5F9', paddingTop: '8px' }}>
              <span>Độ trễ phản hồi:</span>
              <strong style={{ fontVariantNumeric: 'tabular-nums', color: statuses.backend.status === 'online' ? '#16A34A' : '#64748B' }}>
                {statuses.backend.latency} ms
              </strong>
            </div>
          </div>
        </div>
      ) : (
        /* Interactive Diagnostic Test Area */
        <div style={{ background: '#FFF', borderRadius: '8px', padding: '16px', border: '1px solid var(--color-gold-200)' }}>
          <strong style={{ fontSize: '0.9rem', color: 'var(--color-burgundy-900)', display: 'block', marginBottom: '10px' }}>
            Thử nghiệm Trực tiếp Giọng đọc Tiếng Việt (Piper TTS :8000)
          </strong>
          <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
            <input
              type="text"
              className="form-input"
              value={ttsSampleText}
              onChange={(e) => setTtsSampleText(e.target.value)}
              placeholder="Nhập câu tiếng Việt để thử nghiệm âm thanh..."
              style={{ flex: 1, minWidth: '280px', fontSize: '0.85rem' }}
            />
            <button
              type="button"
              className="btn btn-primary btn-sm"
              onClick={handleTestTtsPlay}
              disabled={ttsPlaying}
              style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
            >
              <Volume2 size={16} />
              <span>{ttsPlaying ? 'Đang tổng hợp & phát...' : 'Phát âm thanh'}</span>
            </button>
          </div>
          {ttsAudioUrl && (
            <div style={{ marginTop: '12px', fontSize: '0.78rem', color: '#166534', background: '#F0FDF4', padding: '8px 12px', borderRadius: '6px', border: '1px solid #BBF7D0' }}>
              ✓ Đã nhận dữ liệu âm thanh WAV từ microservice cổng 8000 thành công.
            </div>
          )}
        </div>
      )}
    </section>
  );
}
