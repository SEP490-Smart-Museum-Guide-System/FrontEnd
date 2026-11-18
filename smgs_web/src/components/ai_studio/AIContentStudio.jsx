import React, { useEffect, useRef, useState } from 'react';
import { Sparkles, Volume2, HelpCircle, RefreshCw, Send, Copy, CheckCircle2, Loader2, X } from 'lucide-react';
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
  const [count, setCount] = useState(5), [difficulty, setDifficulty] = useState('medium');
  const [output, setOutput] = useState(''), [title, setTitle] = useState('');
  const [source, setSource] = useState(null), [evidence, setEvidence] = useState([]);
  const [error, setError] = useState(''), [busy, setBusy] = useState(false), [saving, setSaving] = useState(false), [submitted, setSubmitted] = useState(false);
  const [progress, setProgress] = useState('');
  const [currentStep, setCurrentStep] = useState(1);
  const activeRequest = useRef(null);
  useEffect(() => () => activeRequest.current?.abort(), []);
  const allowed = ['administrator', 'museumStaff'].includes(currentRole);

  function invalidate() { setOutput(''); setSource(null); setEvidence([]); setError(''); setSubmitted(false); setProgress(''); setCurrentStep(1); }

  async function generate() {
    if (!artifact || busy || !allowed) return;
    const controller = new AbortController(); activeRequest.current = controller;
    invalidate(); setBusy(true); setCurrentStep(1);
    const drafts = [];
    let lastItemError;
    try {
      const targetCount = mode === 'quiz' ? count : 1;
      let attempts = 0;
      let busyRetries = 0;
      const maxAttempts = targetCount === 1 ? 3 : targetCount + 4;
      const maxBusyRetries = 6; // max ~30s wait for busy model
      while (drafts.length < targetCount && attempts < maxAttempts) {
        attempts++;
        setCurrentStep(drafts.length === 0 ? 2 : 3);
        setProgress(mode === 'quiz' ? `Đang tạo câu đố ${drafts.length + 1}/${targetCount}…` : 'Đang soạn bản thuyết minh…');
        try {
          // Small delay between sequential quiz calls so the model lock has time to release
          if (drafts.length > 0 && mode === 'quiz') {
            await new Promise(r => setTimeout(r, 1500));
            if (controller.signal.aborted) return;
          }
          const response = await generateStaffDraft(artifact.id, {
            mode, sourceText, audience, tone, difficulty, excludeQuestions: drafts.map(d => d.question),
          }, controller.signal);
          if (controller.signal.aborted) return;
          if (mode === 'quiz' && drafts.some(d => d.question.normalize('NFC').trim().toLocaleLowerCase('vi').replace(/\s+/g, ' ') === response.draft.question.normalize('NFC').trim().toLocaleLowerCase('vi').replace(/\s+/g, ' '))) {
            throw new Error('AI trả lại câu hỏi đã có. Hãy tạo lại hoặc bổ sung tư liệu.');
          }
          busyRetries = 0; // reset on success
          drafts.push(response.draft);
          setSource(response.source);
          setEvidence(drafts.flatMap(d => mode === 'quiz' ? [d.evidenceQuote] : d.evidenceQuotes || []));
          setTitle(response.draft.title || `Câu hỏi về ${artifact.name}`);
          setOutput(mode === 'quiz' ? JSON.stringify(drafts.map(d => ({ question: d.question, options: d.options, correctIndex: d.correctIndex, explanation: d.explanation })), null, 2) : response.draft.narrationText);
        } catch (itemErr) {
          if (controller.signal.aborted) return;
          lastItemError = itemErr;
          // If model is busy (503), retry with backoff instead of counting as a failed attempt
          const isBusy = itemErr.message?.includes('đang bận') || itemErr.message?.includes('503');
          if (isBusy && busyRetries < maxBusyRetries) {
            busyRetries++;
            attempts--; // don't count busy-retry as a real attempt
            setProgress(mode === 'quiz' ? `Model đang bận, thử lại sau ${busyRetries * 5}s… (câu ${drafts.length + 1}/${targetCount})` : 'Model đang bận, thử lại…');
            await new Promise(r => setTimeout(r, busyRetries * 5000));
            if (controller.signal.aborted) return;
            continue;
          }
          busyRetries = 0;
          console.warn(`Lần thử ${attempts} cho câu ${drafts.length + 1} chưa đạt căn cứ:`, itemErr.message);
          if (attempts >= maxAttempts && !drafts.length) {
            throw itemErr;
          }
        }
      }
      if (drafts.length > 0) {
        setCurrentStep(4);
        showToast(mode === 'quiz' ? `Đã tạo ${drafts.length}/${targetCount} câu hỏi nháp. Cần kiểm tra trước khi lưu.` : 'Đã tạo bản nháp AI.');
        if (drafts.length < targetCount) {
          setError(`Mới tạo ${drafts.length}/${targetCount} câu hỏi. Bộ câu hỏi chưa hoàn tất. ${lastItemError?.message || 'Hãy kiểm tra kết nối, hạn mức AI và tư liệu rồi thử lại.'}`);
        }
      } else {
        throw new Error('Chưa thể tạo câu hỏi nào từ tư liệu này. Hãy bổ sung tư liệu cụ thể hơn.');
      }
    } catch (e) {
      if (!controller.signal.aborted) setError(`${drafts.length && mode === 'quiz' ? `Đã tạo ${drafts.length}/${count} câu. ` : ''}${e.message}`);
    } finally {
      if (activeRequest.current === controller) { setBusy(false); setProgress(''); activeRequest.current = null; }
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
    <p>Soạn thuyết minh và bộ câu hỏi tiếng Việt từ tư liệu bảo tàng. Bộ câu hỏi mặc định gồm 5 câu; kết quả luôn là bản nháp cần thẩm định.</p>
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
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button className="btn btn-gold" disabled={busy || saving || !artifact} onClick={generate}>
            {busy ? <Loader2 size={16} className="spin-animation" /> : <Sparkles size={16} />}
            {busy ? 'Đang tạo bản nháp…' : 'Sinh nội dung bằng AI'}
          </button>
          {busy && (
            <button
              type="button"
              className="btn btn-secondary"
              style={{ color: 'var(--color-burgundy-800, #6B2E2E)', borderColor: '#e2d7c9' }}
              onClick={() => activeRequest.current?.abort()}
            >
              <X size={15} style={{ marginRight: 4 }} /> Hủy
            </button>
          )}
        </div>
        {busy && <p role="status" style={{ fontSize: '0.85rem', color: 'var(--color-burgundy-900)', marginTop: 8 }}>{progress}</p>}
      </section>
      <section className="card business-card"><h2>Bản nháp để kiểm tra</h2>
        {error && <p role="alert" style={{ color: 'var(--color-burgundy-700)' }}>{error}</p>}
        {busy ? (
          <div style={{
            background: 'var(--color-paper-card, #FAF6EE)',
            border: '1.5px solid var(--color-gold-500, #C4A482)',
            borderRadius: '14px',
            padding: '20px',
            boxShadow: '0 6px 20px rgba(59, 48, 42, 0.06)'
          }}>
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{
                  width: '36px', height: '36px', borderRadius: '50%',
                  background: 'var(--color-burgundy-900, #6B2E2E)', color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                  <Sparkles size={18} />
                </div>
                <div>
                  <h3 style={{ margin: 0, color: 'var(--color-burgundy-900)', fontSize: '1rem', fontFamily: 'var(--font-heading)' }}>
                    {mode === 'quiz' ? 'Trợ lý AI đang soạn bộ câu đố di sản' : 'Trợ lý AI đang soạn thuyết minh'}
                  </h3>
                  <span style={{ fontSize: '0.78rem', color: 'var(--color-muted-text, #776E65)' }}>
                    Hiện vật: <strong>{artifact?.name}</strong>
                  </span>
                </div>
              </div>
              <button
                type="button"
                className="btn btn-secondary"
                style={{ fontSize: '0.78rem', padding: '5px 10px', color: '#b91c1c', borderColor: '#fca5a5' }}
                onClick={() => activeRequest.current?.abort()}
              >
                <X size={13} style={{ marginRight: 4 }} /> Dừng
              </button>
            </div>

            {/* Shimmer Fill Bar */}
            <div className="ai-scan-progress-shimmer" style={{ height: '6px', borderRadius: '3px', background: '#e5e0d8', overflow: 'hidden', marginBottom: '16px' }}>
              <div className="ai-scan-progress-shimmer-fill" style={{ width: `${Math.min(100, Math.max(20, (currentStep / 4) * 100))}%` }} />
            </div>

            {/* Multi-stage Stepper */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '18px' }}>
              {[
                { step: 1, title: 'Lấy tư liệu nguồn của hiện vật' },
                { step: 2, title: `Thiết lập phong cách (${mode === 'quiz' ? `Độ khó: ${difficulty}` : `Giọng điệu: ${tone}`}) & đối tượng` },
                { step: 3, title: mode === 'quiz' ? progress || `Đang biên soạn câu đố (1/${count})…` : progress || 'Đang tạo lời bình thuyết minh…' },
                { step: 4, title: 'Kiểm tra cấu trúc và trích dẫn của bản nháp' }
              ].map(s => {
                const isDone = s.step < currentStep;
                const isCurrent = s.step === currentStep;
                return (
                  <div key={s.step} style={{
                    display: 'flex', alignItems: 'center', gap: '10px', fontSize: '0.8rem',
                    padding: '7px 10px', borderRadius: '8px',
                    background: isCurrent ? '#fff' : 'transparent',
                    border: isCurrent ? '1px solid var(--color-gold-500, #C4A482)' : '1px solid transparent',
                    color: isCurrent ? 'var(--color-burgundy-900)' : (isDone ? '#15803d' : '#8c827a'),
                    fontWeight: isCurrent ? '600' : 'normal'
                  }}>
                    {isDone ? <CheckCircle2 size={15} color="#15803d" /> :
                     isCurrent ? <Loader2 size={15} className="spin-animation" color="var(--color-burgundy-900)" /> :
                     <div style={{ width: 14, height: 14, borderRadius: '50%', border: '1.5px solid #c5bcb4' }} />}
                    <span>{s.title}</span>
                  </div>
                );
              })}
            </div>

            {/* Skeleton Mockup */}
            <div style={{
              padding: '14px', borderRadius: '10px',
              background: '#fff', border: '1px dashed var(--color-paper-border, #d8d0c5)'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
                <div style={{ width: '75px', height: '16px', borderRadius: '4px', background: '#ece6dd', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                <div style={{ flex: 1, height: '13px', borderRadius: '4px', background: '#f5f0e9', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
              </div>

              {mode === 'quiz' ? (
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                  <div style={{ height: '34px', borderRadius: '6px', background: '#faf6f0', border: '1px solid #ebe5dc', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                  <div style={{ height: '34px', borderRadius: '6px', background: '#faf6f0', border: '1px solid #ebe5dc', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                  <div style={{ height: '34px', borderRadius: '6px', background: '#faf6f0', border: '1px solid #ebe5dc', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                  <div style={{ height: '34px', borderRadius: '6px', background: '#faf6f0', border: '1px solid #ebe5dc', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                  <div style={{ height: '11px', width: '95%', borderRadius: '3px', background: '#f2ece3', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                  <div style={{ height: '11px', width: '85%', borderRadius: '3px', background: '#f2ece3', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                  <div style={{ height: '11px', width: '90%', borderRadius: '3px', background: '#f2ece3', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                  <div style={{ height: '11px', width: '60%', borderRadius: '3px', background: '#f2ece3', animation: 'scanPulseGlow 1.8s infinite ease-in-out' }} />
                </div>
              )}
            </div>
          </div>
        ) : !output && mode === 'quiz' ? (
          <p>Chọn hiện vật, kiểm tra tư liệu rồi bấm “Sinh nội dung bằng AI”. Tạo bản nháp chưa lưu hoặc xuất bản dữ liệu.</p>
        ) : (
          <>
            {!output && <p>Nhập bản thuyết minh để nghe trực tiếp hoặc dùng AI soạn từ tư liệu. Nội dung chưa được lưu hay xuất bản.</p>}
            {mode === 'narration' && <div className="form-group"><label className="form-label" htmlFor="studio-title">Tiêu đề bản nháp</label><input id="studio-title" className="form-input" maxLength={200} value={title} disabled={busy || saving} onChange={e => { setTitle(e.target.value); setSubmitted(false); }} /></div>}
            <label className="form-label" htmlFor="studio-output">Nội dung bản nháp</label><textarea id="studio-output" className="form-input" rows={17} value={output} disabled={busy || saving} onChange={e => { setOutput(e.target.value); setSubmitted(false); }} style={{ fontFamily: mode === 'quiz' ? 'monospace' : 'inherit', lineHeight: 1.65 }} />
            <p>AI có thể diễn giải sai. Hãy đối chiếu tên, niên đại, chất liệu và đáp án trước khi gửi.</p>
            {mode === 'narration' && <NarrationPreview key={`${artifactId}:${output}`} artifactId={artifact.id} text={output} disabled={busy || saving} />}
            <details><summary>Tư liệu và đoạn trích AI tham khảo</summary>{source?.contentVersionId && <p>Nội dung đã xuất bản · Phiên bản {source.versionNo}</p>}<p style={{ whiteSpace: 'pre-wrap' }}>{source?.text}</p>{[...new Set(evidence)].map((q, i) => <blockquote key={i}>{q}</blockquote>)}</details>
            <div className="business-actions" style={{ marginTop: 16 }}><button className="btn btn-secondary" onClick={() => navigator.clipboard?.writeText(output)}><Copy size={16} />Sao chép</button><button className="btn btn-primary" disabled={busy || saving || submitted || !output.trim() || (mode === 'narration' && !title.trim())} onClick={submit}><Send size={16} />{submitted ? 'Đã gửi chờ thẩm định' : saving ? 'Đang gửi…' : mode === 'quiz' ? 'Chỉnh sửa & lưu vào Ngân hàng câu hỏi' : 'Gửi sang Hàng đợi Kiểm duyệt'}</button></div>
          </>
        )}
      </section>
    </div>}
  </div>;
}
