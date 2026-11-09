import React, { useEffect, useRef, useState } from 'react';
import { Sparkles, Volume2, HelpCircle, RefreshCw, Send, Copy } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { parseQuestionDrafts } from '../../services/questionDrafts';
import { generateStaffDraft } from '../../services/staffAiApi';
import NarrationPreview from './NarrationPreview';

export default function AIContentStudio(props) {
  const app = useApp();
  return <Studio key={`${app.currentMuseum?.id}:${props.initialArtifact?.id || ''}:${props.initialMode || 'narration'}`} app={app} {...props} />;
}

function Studio({ app, initialArtifact, initialMode = 'narration', onOpenQuestionBank }) {
  const { artifacts, currentMuseum, currentRole, museums, setSelectedMuseumId, submitToCuration, showToast } = app;
  const available = artifacts.filter(a => String(a.museumId) === String(currentMuseum?.id) && Number.isSafeInteger(Number(a.id)) && Number(a.id) > 0);
  const [artifactId, setArtifactId] = useState(String(available.find(a => String(a.id) === String(initialArtifact?.id))?.id || available[0]?.id || ''));
  const artifact = available.find(a => String(a.id) === artifactId);
  const [mode, setMode] = useState(initialMode);
  const [sourceText, setSourceText] = useState('');
  const [audience, setAudience] = useState('general'), [tone, setTone] = useState('vivid');
  const [count, setCount] = useState(1), [difficulty, setDifficulty] = useState('medium');
  const [output, setOutput] = useState(''), [title, setTitle] = useState('');
  const [source, setSource] = useState(null), [evidence, setEvidence] = useState([]);
  const [error, setError] = useState(''), [busy, setBusy] = useState(false), [saving, setSaving] = useState(false), [submitted, setSubmitted] = useState(false);
  const [progress, setProgress] = useState('');
  const activeRequest = useRef(null);
  useEffect(() => () => activeRequest.current?.abort(), []);
  const allowed = ['administrator', 'museumStaff'].includes(currentRole);

  function invalidate() { setOutput(''); setSource(null); setEvidence([]); setError(''); setSubmitted(false); setProgress(''); }

  async function generate() {
    if (!artifact || busy || !allowed) return;
    const controller = new AbortController(); activeRequest.current = controller;
    invalidate(); setBusy(true);
    const drafts = [];
    try {
      const total = mode === 'quiz' ? count : 1;
      for (let i = 0; i < total; i++) {
        setProgress(mode === 'quiz' ? `Đang tạo câu ${i + 1}/${total}…` : 'Đang soạn bản thuyết minh…');
        const response = await generateStaffDraft(artifact.id, {
          mode, sourceText, audience, tone, difficulty, excludeQuestions: drafts.map(d => d.question),
        }, controller.signal);
        if (controller.signal.aborted) return;
        drafts.push(response.draft); setSource(response.source);
        setEvidence(drafts.flatMap(d => mode === 'quiz' ? [d.evidenceQuote] : d.evidenceQuotes || []));
        setTitle(response.draft.title || `Câu hỏi về ${artifact.name}`);
        setOutput(mode === 'quiz' ? JSON.stringify(drafts.map(d => ({ question: d.question, options: d.options, correctIndex: d.correctIndex, explanation: d.explanation })), null, 2) : response.draft.narrationText);
      }
      showToast('Đã tạo bản nháp AI. Hãy kiểm tra tư liệu, nội dung và đáp án.');
    } catch (e) {
      if (!controller.signal.aborted) setError(`${drafts.length && mode === 'quiz' ? `Đã tạo ${drafts.length}/${count} câu. ` : ''}${e.message}`);
    } finally {
      if (!controller.signal.aborted) { setBusy(false); setProgress(''); }
    }
  }

  async function submit() {
    if (!output.trim() || !artifact || busy || saving || submitted) return;
    if (mode === 'quiz') {
      try { onOpenQuestionBank?.({ artifactId: artifact.id, drafts: parseQuestionDrafts(output) }); }
      catch (e) { setError(e.message); }
      return;
    }
    setSaving(true); setError('');
    try {
      const result = await submitToCuration({ targetArtifactId: artifact.id, title: title.trim(), proposedContent: output, narrationText: output, languageCode: 'vi', isAiGenerated: true });
      if (result.success) setSubmitted(true); else setError(result.error);
    } finally { setSaving(false); }
  }

  if (!allowed) return <p role="alert">Chức năng tạo bản nháp dành cho Quản trị viên và Nhân viên bảo tàng.</p>;
  return <div>
    <h1 style={{ fontFamily: 'var(--font-heading)', color: 'var(--color-burgundy-900)', fontSize: '1.75rem' }}><Sparkles size={25} /> Xưởng nội dung AI</h1>
    <p>Soạn thuyết minh và câu hỏi tiếng Việt bằng model ONNX local từ tư liệu bảo tàng. Kết quả luôn là bản nháp cần thẩm định.</p>
    {currentRole === 'administrator' && <div className="form-group"><label className="form-label" htmlFor="studio-museum">Bảo tàng</label><select id="studio-museum" className="form-select" value={currentMuseum?.id || ''} disabled={busy || saving} onChange={e => setSelectedMuseumId(Number(e.target.value))}>{museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}</select></div>}
    {!available.length ? <div className="card business-card">Bảo tàng chưa có hiện vật đã lưu. Hãy tạo hiện vật và bổ sung tư liệu trước.</div> : <div className="business-grid" style={{ alignItems: 'start' }}>
      <section className="card business-card">
        <h2>Cấu hình bản nháp</h2>
        <div className="form-group"><label className="form-label" htmlFor="studio-artifact">Hiện vật</label><select id="studio-artifact" className="form-select" value={artifactId} disabled={busy || saving} onChange={e => { setArtifactId(e.target.value); setSourceText(''); invalidate(); }}>{available.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}</select></div>
        {(artifact?.image || artifact?.imageUrl) && <img src={artifact.image || artifact.imageUrl} alt={`Ảnh đối chiếu ${artifact.name}`} style={{ maxWidth: '100%', height: 170, objectFit: 'contain', borderRadius: 10, marginBottom: 12 }} />}
        <div className="form-group"><label className="form-label" htmlFor="studio-source">Tư liệu nguồn bổ sung</label><textarea id="studio-source" className="form-input" rows={6} maxLength={6000} disabled={busy || saving} value={sourceText} onChange={e => { setSourceText(e.target.value); invalidate(); }} placeholder="Chép nội dung bảng tên, tài liệu hoặc thông tin đã kiểm chứng về hiện vật…" /><small>Để trống để dùng nội dung tiếng Việt đã xuất bản nếu có. Nếu chưa có nội dung, cần nhập ít nhất 20 ký tự tư liệu. Ảnh dùng để đối chiếu; model hiện tại nhận chữ, chưa phân tích ảnh.</small></div>
        <div className="business-actions" style={{ marginBottom: 16 }}>{[{ id: 'narration', label: 'Thuyết minh âm thanh', Icon: Volume2 }, { id: 'quiz', label: 'Bộ câu hỏi trắc nghiệm', Icon: HelpCircle }].map(({ id, label, Icon }) => <button key={id} className={`btn ${mode === id ? 'btn-primary' : 'btn-secondary'}`} aria-pressed={mode === id} disabled={busy || saving} onClick={() => { setMode(id); invalidate(); }}><Icon size={16} />{label}</button>)}</div>
        {mode === 'narration' ? <>
          <div className="form-group"><label className="form-label" htmlFor="studio-audience">Đối tượng tiếp nhận</label><select id="studio-audience" className="form-select" value={audience} disabled={busy || saving} onChange={e => { setAudience(e.target.value); invalidate(); }}><option value="children">Thiếu nhi</option><option value="general">Khách đại chúng</option><option value="scholar">Người nghiên cứu</option></select></div>
          <div className="form-group"><label className="form-label" htmlFor="studio-tone">Phong cách</label><select id="studio-tone" className="form-select" value={tone} disabled={busy || saving} onChange={e => { setTone(e.target.value); invalidate(); }}><option value="vivid">Sinh động, dễ hiểu</option><option value="inspiring">Truyền cảm</option><option value="academic">Trang trọng</option></select></div>
        </> : <>
          <div className="form-group"><label className="form-label" htmlFor="studio-count">Số lượng câu hỏi</label><select id="studio-count" className="form-select" value={count} disabled={busy || saving} onChange={e => { setCount(Number(e.target.value)); invalidate(); }}><option value={1}>1 câu hỏi</option><option value={3}>3 câu hỏi</option><option value={5}>5 câu hỏi</option></select><small>Model tạo từng câu; nếu tư liệu ít hoặc trùng câu hỏi, hệ thống giữ các câu đã tạo để bạn kiểm tra.</small></div>
          <div className="form-group"><label className="form-label" htmlFor="studio-difficulty">Độ khó</label><select id="studio-difficulty" className="form-select" value={difficulty} disabled={busy || saving} onChange={e => { setDifficulty(e.target.value); invalidate(); }}><option value="easy">Dễ</option><option value="medium">Trung bình</option><option value="hard">Thử thách</option></select></div>
        </>}
        <button className="btn btn-gold" disabled={busy || saving || !artifact} onClick={generate}>{busy ? <RefreshCw size={16} className="spin-animation" /> : <Sparkles size={16} />}{busy ? 'Đang tạo bản nháp…' : 'Sinh nội dung bằng AI'}</button>
        {busy && <p role="status">{progress}</p>}
      </section>
      <section className="card business-card"><h2>Bản nháp để kiểm tra</h2>
        {error && <p role="alert" style={{ color: 'var(--color-burgundy-700)' }}>{error}</p>}
        {!output && mode === 'quiz' ? <p>Chọn hiện vật, kiểm tra tư liệu rồi bấm “Sinh nội dung bằng AI”. Tạo bản nháp chưa lưu hoặc xuất bản dữ liệu.</p> : <>
          {!output && <p>Nhập bản thuyết minh để nghe trực tiếp hoặc dùng AI soạn từ tư liệu. Nội dung chưa được lưu hay xuất bản.</p>}
          {mode === 'narration' && <div className="form-group"><label className="form-label" htmlFor="studio-title">Tiêu đề bản nháp</label><input id="studio-title" className="form-input" maxLength={200} value={title} disabled={busy || saving} onChange={e => { setTitle(e.target.value); setSubmitted(false); }} /></div>}
          <label className="form-label" htmlFor="studio-output">Nội dung bản nháp</label><textarea id="studio-output" className="form-input" rows={17} value={output} disabled={busy || saving} onChange={e => { setOutput(e.target.value); setSubmitted(false); }} style={{ fontFamily: mode === 'quiz' ? 'monospace' : 'inherit', lineHeight: 1.65 }} />
          <p>AI có thể diễn giải sai. Hãy đối chiếu tên, niên đại, chất liệu và đáp án trước khi gửi.</p>
          {mode === 'narration' && <NarrationPreview key={`${artifactId}:${output}`} artifactId={artifact.id} text={output} disabled={busy || saving} />}
          <details><summary>Tư liệu và đoạn trích AI tham khảo</summary>{source?.contentVersionId && <p>Nội dung đã xuất bản · Phiên bản {source.versionNo}</p>}<p style={{ whiteSpace: 'pre-wrap' }}>{source?.text}</p>{[...new Set(evidence)].map((q, i) => <blockquote key={i}>{q}</blockquote>)}</details>
          <div className="business-actions" style={{ marginTop: 16 }}><button className="btn btn-secondary" onClick={() => navigator.clipboard?.writeText(output)}><Copy size={16} />Sao chép</button><button className="btn btn-primary" disabled={busy || saving || submitted || !output.trim() || (mode === 'narration' && !title.trim())} onClick={submit}><Send size={16} />{submitted ? 'Đã gửi chờ thẩm định' : saving ? 'Đang gửi…' : mode === 'quiz' ? 'Chỉnh sửa & lưu vào Ngân hàng câu hỏi' : 'Gửi sang Hàng đợi Kiểm duyệt'}</button></div>
        </>}
      </section>
    </div>}
  </div>;
}
