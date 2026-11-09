import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Volume2, RefreshCw, Play, Pause } from 'lucide-react';
import { createSpeechPreview } from '../../services/speechPreviewApi.js';

// Parent remounts this player when the edited script/artifact changes.
export default function NarrationPreview({ artifactId, text, disabled = false }) {
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
      const blob = await createSpeechPreview(artifactId, text, controller.signal);
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

  return <section aria-label="Nghe bản thuyết minh" style={{ border: '1px solid var(--color-paper-border)', borderRadius: 12, padding: 16, margin: '18px 0', background: 'var(--color-paper-bg)' }}>
    <h3 style={{ display: 'flex', gap: 8, alignItems: 'center', margin: '0 0 8px' }}><Volume2 size={19} />Nghe bản thuyết minh</h3>
    <p style={{ fontSize: '.88rem', marginBottom: 12 }}>Giọng tiếng Việt đọc đúng văn bản đang chỉnh sửa. Đây là bản nghe thử nội bộ, chưa xuất bản cho khách.</p>
    {!url ? <button type="button" className="btn btn-secondary" disabled={busy || disabled || !text.trim()} onClick={generate}>{busy ? <RefreshCw size={16} className="spin-animation" /> : <Volume2 size={16} />}{busy ? 'Đang tạo giọng đọc…' : 'Tạo giọng đọc'}</button> : <>
      <audio ref={setAudio} aria-label="Bản đọc tiếng Việt" src={url} controls controlsList="nodownload" preload="metadata" style={{ width: '100%' }}
        onPlay={() => setPlaying(true)} onPause={() => setPlaying(false)} onEnded={() => setPlaying(false)}
        onError={() => { setPlaying(false); setError('Không phát được âm thanh. Hãy tạo lại bản đọc hoặc kiểm tra kết nối.'); }} />
      <div className="business-actions" style={{ marginTop: 10 }}>
        <button type="button" className="btn btn-primary" onClick={toggle}>{playing ? <Pause size={16} /> : <Play size={16} />}{playing ? 'Tạm dừng bản đọc' : 'Phát bản đọc'}</button>
        <label>Tốc độ đọc <select aria-label="Tốc độ nghe bản nháp" className="form-select" style={{ width: 'auto', display: 'inline-block' }} value={speed} onChange={e => { const value = Number(e.target.value); setSpeed(value); if (audio.current) audio.current.playbackRate = value; }}><option value={0.75}>0,75×</option><option value={1}>1×</option><option value={1.25}>1,25×</option></select></label>
        {error && <button className="btn btn-secondary" type="button" onClick={() => { audio.current?.pause(); if (blobUrl.current) URL.revokeObjectURL(blobUrl.current); blobUrl.current = ''; setUrl(''); setError(''); }}>Tạo lại bản đọc</button>}
      </div>
    </>}
    {busy && <p role="status">Đang tổng hợp giọng tiếng Việt…</p>}
    {error && <p role="alert">{error}</p>}
  </section>;
}
