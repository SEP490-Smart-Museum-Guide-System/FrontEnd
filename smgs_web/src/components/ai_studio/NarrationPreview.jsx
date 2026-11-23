import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Volume2, RefreshCw, Play, Pause, Sparkles, X } from 'lucide-react';
import { createSpeechPreview } from '../../services/speechPreviewApi.js';

const WAVE_DELAYS = [0.1, 0.35, 0.2, 0.5, 0.15, 0.4, 0.25, 0.6, 0.3, 0.45, 0.2, 0.55, 0.1, 0.35, 0.5, 0.25];

// Parent remounts this player when the edited script/artifact changes.
export default function NarrationPreview({ artifactId, text, languageCode = 'vi', disabled = false }) {
  const voiceLabel = languageCode === 'en' ? 'tiếng Anh' : 'tiếng Việt';
  const [url, setUrl] = useState(''), [busy, setBusy] = useState(false), [error, setError] = useState('');
  const [playing, setPlaying] = useState(false), [speed, setSpeed] = useState(1);
  const audio = useRef(null), request = useRef(null), blobUrl = useRef('');
  const setAudio = useCallback(element => {
    if (audio.current && audio.current !== element) audio.current.pause();
    audio.current = element;
  }, []);
  useEffect(() => () => {
    request.current?.abort();
    audio.current?.pause();
    if (blobUrl.current) URL.revokeObjectURL(blobUrl.current);
  }, []);

  async function generate() {
    if (busy || disabled || !text.trim()) return;
    const controller = new AbortController(); request.current = controller;
    setBusy(true); setError('');
    try {
      const blob = await createSpeechPreview(artifactId, text, controller.signal, languageCode);
      if (controller.signal.aborted) return;
      blobUrl.current = URL.createObjectURL(blob); setUrl(blobUrl.current);
    } catch (e) {
      if (!controller.signal.aborted) setError(e.name === 'TimeoutError' ? 'Tạo giọng đọc quá lâu. Vui lòng thử lại.' : e.message);
    } finally { if (!controller.signal.aborted) setBusy(false); }
  }

  async function toggle() {
    if (!audio.current) return;
    setError('');
    try {
      if (audio.current.paused) { audio.current.playbackRate = speed; await audio.current.play(); }
      else audio.current.pause();
    } catch { setError('Chưa phát được âm thanh. Hãy nhấn Phát để thử lại.'); }
  }

  return (
    <section aria-label="Nghe bản thuyết minh" style={{ border: '1px solid var(--color-paper-border, #d8d0c5)', borderRadius: 12, padding: 16, margin: '18px 0', background: 'var(--color-paper-bg, #fcfbf9)' }}>
      <style>{`
        @keyframes smgsWavePulse {
          0%, 100% { height: 6px; opacity: 0.4; }
          50% { height: 26px; opacity: 1; }
        }
      `}</style>

      <h3 style={{ display: 'flex', gap: 8, alignItems: 'center', margin: '0 0 8px' }}><Volume2 size={19} />Nghe bản thuyết minh</h3>
      <p style={{ fontSize: '.88rem', marginBottom: 12 }}>Giọng {voiceLabel} đọc đúng văn bản đang chỉnh sửa. Đây là bản nghe thử nội bộ, chưa xuất bản cho khách.</p>
      
      {!url && !busy && (
        <button type="button" className="btn btn-secondary" disabled={disabled || !text.trim()} onClick={generate}>
          <Volume2 size={16} /> Tạo giọng đọc
        </button>
      )}

      {/* Modern Waveform Synthesizer Shimmer Loading State */}
      {busy && (
        <div
          role="status"
          style={{
            borderRadius: 10,
            padding: '14px 16px',
            background: 'linear-gradient(135deg, #FAF7F2 0%, #F5EFEB 100%)',
            border: '1px solid var(--color-gold-500, #C4A482)',
            display: 'flex',
            flexDirection: 'column',
            gap: 12,
            boxShadow: '0 2px 8px rgba(92, 29, 36, 0.05)'
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--color-burgundy-900, #5C1D24)' }}>
              <Sparkles size={16} className="spin-animation" />
              <span>AI Voice Synthesizer · Đang tổng hợp giọng {voiceLabel}…</span>
            </div>
            <button
              type="button"
              className="btn btn-secondary"
              style={{ fontSize: '0.78rem', padding: '4px 8px', color: '#b91c1c', borderColor: '#fca5a5' }}
              onClick={() => request.current?.abort()}
            >
              <X size={13} style={{ marginRight: 3 }} /> Hủy
            </button>
          </div>

          {/* Soundwave Frequency Bars Visualizer */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5, height: 32, padding: '4px 0' }}>
            {WAVE_DELAYS.map((delay, idx) => (
              <span
                key={idx}
                style={{
                  width: 4,
                  borderRadius: 2,
                  background: 'linear-gradient(180deg, var(--color-burgundy-900, #5C1D24) 0%, var(--color-gold-500, #C4A482) 100%)',
                  animation: `smgsWavePulse 1.1s ease-in-out infinite`,
                  animationDelay: `${delay}s`,
                  display: 'inline-block'
                }}
              />
            ))}
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: '#786F66' }}>
            <span>Đang chuẩn bị dải âm học & kiểm tra ngữ điệu {voiceLabel}…</span>
            <span>Mô hình giọng đọc số</span>
          </div>
        </div>
      )}

      {url && (
        <>
          <audio ref={setAudio} aria-label={`Bản đọc ${voiceLabel}`} src={url} controls controlsList="nodownload" preload="metadata" style={{ width: '100%' }}
            onPlay={() => setPlaying(true)} onPause={() => setPlaying(false)} onEnded={() => setPlaying(false)}
            onError={() => { setPlaying(false); setError('Không phát được âm thanh. Hãy tạo lại bản đọc hoặc kiểm tra kết nối.'); }} />
          <div className="business-actions" style={{ marginTop: 10 }}>
            <button type="button" className="btn btn-primary" onClick={toggle}>{playing ? <Pause size={16} /> : <Play size={16} />}{playing ? 'Tạm dừng bản đọc' : 'Phát bản đọc'}</button>
            <label>Tốc độ đọc <select aria-label="Tốc độ nghe bản nháp" className="form-select" style={{ width: 'auto', display: 'inline-block' }} value={speed} onChange={e => { const value = Number(e.target.value); setSpeed(value); if (audio.current) audio.current.playbackRate = value; }}><option value={0.75}>0,75×</option><option value={1}>1×</option><option value={1.25}>1,25×</option></select></label>
            {error && <button className="btn btn-secondary" type="button" onClick={() => { audio.current?.pause(); if (blobUrl.current) URL.revokeObjectURL(blobUrl.current); blobUrl.current = ''; setUrl(''); setError(''); }}>Tạo lại bản đọc</button>}
          </div>
        </>
      )}

      {error && <p role="alert" style={{ marginTop: 8 }}>{error}</p>}
    </section>
  );
}
