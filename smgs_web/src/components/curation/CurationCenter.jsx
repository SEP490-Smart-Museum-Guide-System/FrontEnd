import React, { useMemo, useState } from 'react';
import { createPortal } from 'react-dom';
import {
  Check,
  CheckSquare,
  Eye,
  MessageSquare,
  Send,
  X,
  FileText,
  HelpCircle,
  Volume2,
  Sparkles,
  Smartphone,
  Columns,
  AlertCircle,
  ShieldCheck,
  Search
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { getCurationContentByIdApi } from '../../services/curationApi';

const statusLabel = {
  pending_review: 'Chờ thẩm định',
  published: 'Đã xuất bản',
  draft: 'Yêu cầu hiệu đính',
  rejected: 'Từ chối',
};

const typeIcon = {
  audio_narration: Volume2,
  quiz: HelpCircle,
  artifact_update: FileText,
  new_tour: Sparkles,
};

const typeName = {
  audio_narration: 'Thuyết minh đa phương tiện',
  quiz: 'Bộ câu hỏi tương tác (Quiz)',
  artifact_update: 'Cập nhật thông tin hiện vật',
  new_tour: 'Lịch trình / Tour mẫu mới',
};

export default function CurationCenter() {
  const {
    curationQueue,
    artifacts,
    currentMuseum,
    approveCurationItem,
    rejectCurationItem,
    requestRevisionCurationItem
  } = useApp();

  const [filter, setFilter] = useState('pending_review');
  const [searchTerm, setSearchTerm] = useState('');
  const [selected, setSelected] = useState(null);
  const [note, setNote] = useState('');
  const [decision, setDecision] = useState(''); // 'approve' | 'revision' | 'reject'
  const [previewMode, setPreviewMode] = useState('diff'); // 'diff' | 'mobile'
  const [checklist, setChecklist] = useState({
    factualAccuracy: true,
    heritageTone: true,
    ageAppropriate: true,
    sourceVerified: true
  });

  const museumArtifacts = useMemo(
    () => artifacts.filter(art => 
      String(art.museumId) === String(currentMuseum?.id) || 
      art.museumId === currentMuseum?.id ||
      String(art.museumId) === String(currentMuseum?.backendId)
    ),
    [artifacts, currentMuseum]
  );

  const museumArtifactIds = useMemo(
    () => new Set(museumArtifacts.map(item => String(item.id))),
    [museumArtifacts]
  );

  const queue = useMemo(
    () => curationQueue.filter(item => {
      if (item.museumId && (currentMuseum?.id || currentMuseum?.backendId)) {
        return String(item.museumId) === String(currentMuseum?.id) || String(item.museumId) === String(currentMuseum?.backendId);
      }
      if (!item.targetArtifactId) return true;
      return museumArtifactIds.has(String(item.targetArtifactId));
    }),
    [curationQueue, currentMuseum, museumArtifactIds]
  );

  const filteredItems = useMemo(() => {
    return queue.filter(item => {
      const matchStatus = filter === 'all' || item.status === filter;
      const artName = (item.targetArtifactName || item.artifactName || '').toLowerCase();
      const title = (item.title || '').toLowerCase();
      const submitter = (item.submittedBy || '').toLowerCase();
      const term = searchTerm.trim().toLowerCase();
      const matchSearch = term === '' || title.includes(term) || artName.includes(term) || submitter.includes(term);
      return matchStatus && matchSearch;
    });
  }, [queue, filter, searchTerm]);

  const countByStatus = (status) => queue.filter(item => item.status === status).length;

  const openItem = async (item) => {
    setSelected(item);
    setNote(item.feedback || '');
    setDecision('');
    setPreviewMode('diff');
    setChecklist({
      factualAccuracy: true,
      heritageTone: true,
      ageAppropriate: true,
      sourceVerified: true
    });

    const backendId = typeof item.id === 'number' ? item.id : item.backendId;
    if (backendId) {
      try {
        const res = await getCurationContentByIdApi(backendId);
        if (res?.data) {
          setSelected(prev => (prev && prev.id === item.id) ? {
            ...prev,
            title: res.data.title || prev.title,
            proposedContent: res.data.description || prev.proposedContent,
            feedback: res.data.reviewNote || prev.feedback,
            status: res.data.status || prev.status,
            versionNo: res.data.versionNo ?? prev.versionNo
          } : prev);
        }
      } catch (_) {}
    }
  };

  const closeItem = () => {
    setSelected(null);
    setNote('');
    setDecision('');
  };

  const submitDecision = () => {
    if (!decision || !selected) return;
    if (decision !== 'approve' && !note.trim()) {
      alert('Vui lòng nhập ghi chú chuyên môn cho Nhân viên bảo tàng khi yêu cầu hiệu đính hoặc từ chối.');
      return;
    }

    if (decision === 'approve') {
      approveCurationItem(selected.id, note || 'Đã thẩm định phê duyệt theo quy chuẩn lưu trữ và truyền thông di sản bảo tàng.');
    } else if (decision === 'revision') {
      requestRevisionCurationItem(selected.id, note);
    } else if (decision === 'reject') {
      rejectCurationItem(selected.id, note);
    }
    closeItem();
  };

  // Helper to parse Quiz JSON safely if applicable
  const parseQuizContent = (content) => {
    try {
      const parsed = JSON.parse(content);
      return Array.isArray(parsed) ? parsed : null;
    } catch {
      return null;
    }
  };

  const isQuiz = selected?.type === 'quiz';
  const parsedProposedQuiz = isQuiz ? parseQuizContent(selected.proposedContent) : null;

  return (
    <div className="curation-center-page">
      {/* Hero Header */}
      <section className="role-dashboard-hero" style={{ marginBottom: '24px' }}>
        <div className="role-dashboard-eyebrow">
          BÀN LÀM VIỆC GIÁM TUYỂN · {currentMuseum.shortName || currentMuseum.name}
        </div>
        <h1>Thẩm định & Kiểm chuẩn Nội dung Di sản</h1>
        <p>
          Thẩm tra độc lập thông tin hiện vật, bản dịch thuật ngữ, kịch bản thuyết minh và ngân hàng câu hỏi tương tác AI do Nhân viên bảo tàng đệ trình trước khi công bố cho Khách tham quan.
        </p>
      </section>

      {/* Filter and Search Bar */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '16px',
        marginBottom: '20px'
      }}>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          {[
            ['pending_review', 'Chờ thẩm định', 'var(--color-burgundy-700)'],
            ['draft', 'Yêu cầu hiệu đính', 'var(--color-gold-600)'],
            ['published', 'Đã xuất bản', 'var(--color-success)'],
            ['rejected', 'Từ chối', 'var(--color-charcoal-500)'],
            ['all', 'Tất cả', 'var(--color-charcoal-700)'],
          ].map(([value, label, color]) => {
            const isActive = filter === value;
            const count = value === 'all' ? queue.length : countByStatus(value);
            return (
              <button
                key={value}
                type="button"
                onClick={() => setFilter(value)}
                className={`btn btn-sm ${isActive ? 'btn-primary' : 'btn-secondary'}`}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  borderRadius: '20px',
                  padding: '6px 14px'
                }}
              >
                <span>{label}</span>
                <span style={{
                  padding: '2px 7px',
                  borderRadius: '10px',
                  fontSize: '0.72rem',
                  fontWeight: '700',
                  background: isActive ? 'rgba(255,255,255,0.2)' : 'var(--color-paper-accent)',
                  color: isActive ? '#FFF' : color
                }}>
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {/* Search input */}
        <div style={{ position: 'relative', width: '280px' }}>
          <Search size={15} style={{ position: 'absolute', left: '10px', top: '10px', color: 'var(--color-charcoal-400)' }} />
          <input
            type="text"
            className="form-input"
            style={{ paddingLeft: '32px', height: '36px', fontSize: '0.85rem' }}
            placeholder="Tìm hiện vật, tiêu đề, người nộp..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {/* Main Queue List Card */}
      <section className="card" style={{ padding: '0', overflow: 'hidden' }}>
        <div className="card-header" style={{ padding: '16px 20px', borderBottom: '1px solid var(--color-paper-border)' }}>
          <div>
            <h2 className="card-title" style={{ fontSize: '1.05rem', margin: 0 }}>
              Hàng đợi Thẩm định ({filteredItems.length})
            </h2>
            <span style={{ color: 'var(--color-charcoal-500)', fontSize: '.78rem' }}>
              Quy chế: Giám tuyển chỉ phê duyệt nội dung của bảo tàng mình phụ trách
            </span>
          </div>
          <span style={{ fontSize: '0.8rem', color: 'var(--color-gold-600)', fontWeight: '600' }}>
            {countByStatus('pending_review')} mục cần thẩm định ngay
          </span>
        </div>

        <div className="role-dashboard-list">
          {filteredItems.length > 0 ? (
            filteredItems.map(item => {
              const Icon = typeIcon[item.type] || FileText;
              return (
                <article
                  className="role-dashboard-row"
                  key={item.id}
                  style={{
                    padding: '16px 20px',
                    transition: 'background var(--transition-fast)',
                    cursor: 'pointer'
                  }}
                  onClick={() => openItem(item)}
                >
                  <div style={{ display: 'flex', gap: '14px', alignItems: 'flex-start', minWidth: 0 }}>
                    <div style={{
                      width: '38px',
                      height: '38px',
                      borderRadius: '8px',
                      background: 'var(--color-paper-accent)',
                      border: '1px solid var(--color-paper-border)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'var(--color-burgundy-700)',
                      flexShrink: 0
                    }}>
                      <Icon size={18} />
                    </div>
                    <div style={{ minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                        <strong style={{ fontSize: '0.925rem', color: 'var(--color-charcoal-900)' }}>
                          {item.title}
                        </strong>
                        {item.priority === 'high' && (
                          <span style={{
                            fontSize: '0.68rem',
                            fontWeight: '700',
                            padding: '1px 6px',
                            borderRadius: '4px',
                            background: 'var(--color-burgundy-50)',
                            color: 'var(--color-burgundy-700)',
                            border: '1px solid var(--color-burgundy-100)'
                          }}>
                            ƯU TIÊN CAO
                          </span>
                        )}
                      </div>
                      <small style={{ color: 'var(--color-charcoal-500)', display: 'block', marginTop: '2px' }}>
                        Hiện vật: <strong style={{ color: 'var(--color-burgundy-700)' }}>{item.targetArtifactName || item.artifactName || `Hiện vật #${item.targetArtifactId}`}</strong> · Người nộp: {item.submittedBy || 'Nhân viên bảo tàng'} · {item.submittedDate || 'Vừa xong'}
                      </small>
                      <p style={{ margin: '6px 0 0', color: 'var(--color-charcoal-700)', fontSize: '.82rem', lineHeight: 1.4 }}>
                        {item.changesSummary}
                      </p>
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexShrink: 0 }}>
                    <span className={`badge-status badge-${item.status}`}>
                      {statusLabel[item.status]}
                    </span>
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        openItem(item);
                      }}
                      style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
                    >
                      <Eye size={14} /> Thẩm định Diff
                    </button>
                  </div>
                </article>
              );
            })
          ) : (
            <div style={{ padding: '40px 20px', textAlign: 'center', color: 'var(--color-charcoal-500)' }}>
              Không có hồ sơ nào phù hợp với bộ lọc hiện tại.
            </div>
          )}
        </div>
      </section>

      {/* CURATOR INSPECTION MODAL (WEB-C03: DIFF VIEW) */}
      {selected && typeof document !== 'undefined' && createPortal(
        <div className="modal-overlay" onClick={closeItem}>
          <section
            className="modal-dialog"
            style={{ maxWidth: '1100px', width: '95vw', maxHeight: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', minHeight: 0 }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div className="modal-header" style={{ borderBottom: '1px solid var(--color-paper-border)', padding: '14px 20px' }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '2px' }}>
                  <span style={{
                    fontSize: '0.72rem',
                    textTransform: 'uppercase',
                    letterSpacing: '0.08em',
                    fontWeight: '700',
                    color: 'var(--color-burgundy-700)'
                  }}>
                    {typeName[selected.type] || 'HỒ SƠ THẨM ĐỊNH'}
                  </span>
                  <span style={{ color: 'var(--color-charcoal-300)' }}>·</span>
                  <span style={{ fontSize: '0.8rem', color: 'var(--color-charcoal-500)' }}>
                    Mã hồ sơ: {selected.id}
                  </span>
                </div>
                <h2 className="modal-title font-serif" style={{ fontSize: '1.25rem', color: 'var(--color-charcoal-900)' }}>
                  {selected.title}
                </h2>
                <p style={{ color: 'var(--color-charcoal-500)', fontSize: '.8rem', marginTop: '2px' }}>
                  Hiện vật tham chiếu: <strong>{selected.targetArtifactName || selected.artifactName || `Hiện vật #${selected.targetArtifactId}`}</strong> (ID: {selected.targetArtifactId}) · Đệ trình bởi: {selected.submittedBy || 'Nhân viên bảo tàng'} ({selected.submittedDate || 'Vừa xong'})
                </p>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                {/* Switch between Diff View and Mobile Preview */}
                <div style={{
                  display: 'flex',
                  background: 'var(--color-paper-accent)',
                  padding: '3px',
                  borderRadius: '8px',
                  border: '1px solid var(--color-paper-border)'
                }}>
                  <button
                    type="button"
                    onClick={() => setPreviewMode('diff')}
                    className={`btn btn-sm ${previewMode === 'diff' ? 'btn-primary' : 'btn-secondary'}`}
                    style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
                  >
                    <Columns size={13} /> So sánh Diff
                  </button>
                  <button
                    type="button"
                    onClick={() => setPreviewMode('mobile')}
                    className={`btn btn-sm ${previewMode === 'mobile' ? 'btn-primary' : 'btn-secondary'}`}
                    style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
                  >
                    <Smartphone size={13} /> Xem thử Mobile
                  </button>
                </div>

                <button type="button" className="btn btn-secondary btn-sm" onClick={closeItem}>
                  <X size={16} />
                </button>
              </div>
            </div>

            {/* Modal Body */}
            <div className="modal-body" style={{ flex: 1, minHeight: 0, overflowY: 'auto', padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {/* Summary of Changes */}
              <div style={{
                padding: '10px 14px',
                borderLeft: '4px solid var(--color-gold-500)',
                background: 'var(--color-paper-card)',
                borderRadius: '0 8px 8px 0',
                border: '1px solid var(--color-paper-border)',
                borderLeftWidth: '4px'
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '2px' }}>
                  <AlertCircle size={14} color="var(--color-gold-600)" />
                  <strong style={{ fontSize: '0.825rem', color: 'var(--color-charcoal-900)' }}>
                    Phạm vi & Mục đích thay đổi:
                  </strong>
                </div>
                <p style={{ margin: 0, fontSize: '.825rem', color: 'var(--color-charcoal-700)', lineHeight: 1.45 }}>
                  {selected.changesSummary}
                </p>
              </div>

              {/* CURATOR QUALITY GATE (Checklist tiêu chuẩn) */}
              {selected.status === 'pending_review' && (
                <div style={{
                  background: '#FFFDF9',
                  border: '1px dashed var(--color-gold-400)',
                  borderRadius: '8px',
                  padding: '10px 14px'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
                    <ShieldCheck size={15} color="var(--color-burgundy-700)" />
                    <strong style={{ fontSize: '0.8rem', color: 'var(--color-burgundy-900)' }}>
                      TIÊU CHUẨN THẨM ĐỊNH GIÁM TUYỂN (Kiểm tra trước khi phê duyệt):
                    </strong>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '10px' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.8rem', cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={checklist.factualAccuracy}
                        onChange={(e) => setChecklist(prev => ({ ...prev, factualAccuracy: e.target.checked }))}
                      />
                      <span>Đúng niên đại & dữ liệu khảo cổ</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.8rem', cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={checklist.heritageTone}
                        onChange={(e) => setChecklist(prev => ({ ...prev, heritageTone: e.target.checked }))}
                      />
                      <span>Văn phong chuẩn mực bảo tàng</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.8rem', cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={checklist.ageAppropriate}
                        onChange={(e) => setChecklist(prev => ({ ...prev, ageAppropriate: e.target.checked }))}
                      />
                      <span>Phù hợp độ tuổi đối tượng</span>
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.8rem', cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={checklist.sourceVerified}
                        onChange={(e) => setChecklist(prev => ({ ...prev, sourceVerified: e.target.checked }))}
                      />
                      <span>Không có lỗi suy diễn AI</span>
                    </label>
                  </div>
                </div>
              )}

              {/* VIEW 1: SIDE-BY-SIDE DIFF VIEW */}
              {previewMode === 'diff' && (
                <div>
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))',
                    gap: '16px'
                  }}>
                    {/* Left Column: Current Published Version */}
                    <article style={{
                      border: '1px solid var(--color-paper-border)',
                      borderRadius: '10px',
                      padding: '16px',
                      background: 'var(--color-paper-card)'
                    }}>
                      <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        paddingBottom: '10px',
                        marginBottom: '12px',
                        borderBottom: '1px solid var(--color-paper-border)'
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <span style={{
                            width: '8px',
                            height: '8px',
                            borderRadius: '50%',
                            background: 'var(--color-charcoal-400)'
                          }} />
                          <strong style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-800)' }}>
                            BẢN HIỆN TẠI (Đang xuất bản)
                          </strong>
                        </div>
                        <span style={{ fontSize: '0.72rem', color: 'var(--color-charcoal-500)' }}>v1.0 Live</span>
                      </div>

                      <div style={{
                        fontSize: '0.85rem',
                        lineHeight: 1.6,
                        color: 'var(--color-charcoal-700)',
                        whiteSpace: 'pre-line',
                        background: '#FFF',
                        padding: '12px 14px',
                        borderRadius: '6px',
                        border: '1px solid var(--color-paper-border)',
                        minHeight: '130px',
                        maxHeight: '240px',
                        overflowY: 'auto'
                      }}>
                        {selected.currentVersion || 'Hiện chưa có nội dung được phê duyệt trước đây cho phân mục này.'}
                      </div>
                    </article>

                    {/* Right Column: Proposed Revision */}
                    <article style={{
                      border: '1.5px solid var(--color-gold-400)',
                      borderRadius: '10px',
                      padding: '16px',
                      background: '#FFFDF8',
                      boxShadow: 'var(--shadow-gold)'
                    }}>
                      <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        paddingBottom: '10px',
                        marginBottom: '12px',
                        borderBottom: '1px solid var(--color-gold-200)'
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <span style={{
                            width: '8px',
                            height: '8px',
                            borderRadius: '50%',
                            background: 'var(--color-success)'
                          }} />
                          <strong style={{ fontSize: '0.875rem', color: 'var(--color-burgundy-900)' }}>
                            NỘI DUNG ĐỆ TRÌNH (Bản đề xuất sửa đổi)
                          </strong>
                        </div>
                        <span style={{
                          fontSize: '0.72rem',
                          padding: '2px 8px',
                          borderRadius: '10px',
                          background: 'var(--color-gold-100)',
                          color: 'var(--color-gold-700)',
                          fontWeight: '700'
                        }}>
                          MỚI ĐỆ TRÌNH
                        </span>
                      </div>

                      {/* Display as Quiz cards if JSON */}
                      {isQuiz && parsedProposedQuiz ? (
                        <div style={{ display: 'grid', gap: '10px', maxHeight: '240px', overflowY: 'auto', paddingRight: '4px' }}>
                          {parsedProposedQuiz.map((q, idx) => (
                            <div
                              key={idx}
                              style={{
                                background: '#FFF',
                                padding: '10px 12px',
                                borderRadius: '8px',
                                border: '1px solid var(--color-gold-300)'
                              }}
                            >
                              <strong style={{ fontSize: '0.825rem', color: 'var(--color-charcoal-900)' }}>
                                Câu {idx + 1}: {q.question}
                              </strong>
                              <div style={{ marginTop: '6px', display: 'grid', gap: '4px' }}>
                                {q.options.map((opt, oIdx) => (
                                  <div
                                    key={oIdx}
                                    style={{
                                      fontSize: '0.78rem',
                                      padding: '4px 8px',
                                      borderRadius: '4px',
                                      background: oIdx === q.correctIndex ? 'var(--color-success-bg)' : '#F9F9F9',
                                      color: oIdx === q.correctIndex ? 'var(--color-success)' : 'var(--color-charcoal-700)',
                                      fontWeight: oIdx === q.correctIndex ? '600' : 'normal',
                                      display: 'flex',
                                      alignItems: 'center',
                                      gap: '6px'
                                    }}
                                  >
                                    <span>{String.fromCharCode(65 + oIdx)}. {opt}</span>
                                    {oIdx === q.correctIndex && <Check size={13} />}
                                  </div>
                                ))}
                              </div>
                              {q.explanation && (
                                <p style={{ margin: '6px 0 0', fontSize: '0.72rem', color: 'var(--color-charcoal-600)', fontStyle: 'italic' }}>
                                  Giải thích: {q.explanation}
                                </p>
                              )}
                            </div>
                          ))}
                        </div>
                      ) : (
                        <div style={{
                          fontSize: '0.85rem',
                          lineHeight: 1.6,
                          color: 'var(--color-charcoal-900)',
                          whiteSpace: 'pre-line',
                          background: '#FFF',
                          padding: '12px 14px',
                          borderRadius: '6px',
                          border: '1px solid var(--color-gold-200)',
                          minHeight: '130px',
                          maxHeight: '240px',
                          overflowY: 'auto'
                        }}>
                          {selected.proposedContent}
                        </div>
                      )}
                    </article>
                  </div>
                </div>
              )}

              {/* VIEW 2: VISITOR MOBILE PREVIEW (Mô phỏng trải nghiệm khách tham quan) */}
              {previewMode === 'mobile' && (
                <div style={{
                  display: 'flex',
                  justifyContent: 'center',
                  padding: '10px 0',
                  background: 'var(--color-paper-bg)',
                  borderRadius: '12px',
                  border: '1px solid var(--color-paper-border)'
                }}>
                  <div style={{
                    width: '320px',
                    minHeight: '480px',
                    background: '#F4EBDD',
                    borderRadius: '24px',
                    border: '8px solid #2E2521',
                    boxShadow: '0 12px 30px rgba(0,0,0,0.25)',
                    padding: '16px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '12px'
                  }}>
                    <div style={{
                      height: '4px',
                      width: '40px',
                      background: '#555',
                      borderRadius: '2px',
                      margin: '0 auto 8px'
                    }} />

                    <div style={{
                      background: '#FFF',
                      padding: '12px',
                      borderRadius: '12px',
                      border: '1px solid #E5D6C5'
                    }}>
                      <span style={{ fontSize: '0.65rem', color: '#6B2E2E', fontWeight: '700', textTransform: 'uppercase' }}>
                        {typeName[selected.type]}
                      </span>
                      <h4 style={{ fontSize: '0.9rem', margin: '4px 0', color: '#2E2521' }}>
                        {selected.targetArtifactName}
                      </h4>
                      <p style={{ fontSize: '0.75rem', color: '#555', margin: 0, lineHeight: 1.4, whiteSpace: 'pre-line' }}>
                        {isQuiz && parsedProposedQuiz ? (
                          `Đã nạp ${parsedProposedQuiz.length} câu hỏi quiz tương tác vào bài học di sản.`
                        ) : (
                          selected.proposedContent.slice(0, 320) + (selected.proposedContent.length > 320 ? '...' : '')
                        )}
                      </p>
                    </div>

                    <div style={{
                      marginTop: 'auto',
                      padding: '8px',
                      background: '#6B2E2E',
                      borderRadius: '8px',
                      textAlign: 'center',
                      color: '#FFF',
                      fontSize: '0.75rem',
                      fontWeight: '600'
                    }}>
                      Giao diện hiển thị trực tiếp cho Khách
                    </div>
                  </div>
                </div>
              )}

              {/* Feedback Note Input */}
              {selected.status === 'pending_review' && (
                <div style={{ marginTop: '4px' }}>
                  <label className="form-label" style={{ fontWeight: '600', fontSize: '0.8125rem', color: 'var(--color-charcoal-800)', marginBottom: '4px' }}>
                    Ghi chú Chuyên môn của Giám tuyển (Bắt buộc nếu Yêu cầu hiệu đính / Từ chối):
                  </label>
                  <textarea
                    className="form-textarea"
                    rows={2}
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    style={{ minHeight: '56px', maxHeight: '90px', fontSize: '0.85rem' }}
                    placeholder="Nhập nhận xét về niên đại, tính xác thực, nguồn tài liệu hoặc văn phong cần Nhân viên bảo tàng điều chỉnh..."
                  />
                </div>
              )}

              {/* Previous Feedback History */}
              {selected.status !== 'pending_review' && selected.feedback && (
                <div style={{
                  padding: '12px 16px',
                  background: 'var(--color-paper-accent)',
                  borderRadius: '8px',
                  border: '1px solid var(--color-paper-border)',
                  display: 'flex',
                  gap: '10px',
                  alignItems: 'flex-start'
                }}>
                  <MessageSquare size={16} color="var(--color-burgundy-700)" style={{ marginTop: '2px', flexShrink: 0 }} />
                  <div>
                    <strong style={{ fontSize: '0.825rem', color: 'var(--color-charcoal-900)' }}>
                      Ý kiến Giám tuyển đã ghi nhận:
                    </strong>
                    <p style={{ margin: '4px 0 0', fontSize: '0.825rem', color: 'var(--color-charcoal-700)' }}>
                      {selected.feedback}
                    </p>
                  </div>
                </div>
              )}
            </div>

            {/* Modal Footer & Actions */}
            <div className="modal-footer" style={{
              padding: '12px 20px',
              borderTop: '1px solid var(--color-paper-border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              background: 'var(--color-paper-card)',
              flexShrink: 0
            }}>
              <button type="button" className="btn btn-secondary" onClick={closeItem}>
                Đóng
              </button>

              {selected.status === 'pending_review' && (
                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    style={{ color: 'var(--color-danger)', borderColor: 'var(--color-danger)' }}
                    onClick={() => setDecision('reject')}
                  >
                    <X size={14} /> Từ chối hồ sơ
                  </button>

                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    style={{ color: 'var(--color-warning)', borderColor: 'var(--color-warning)' }}
                    onClick={() => setDecision('revision')}
                  >
                    <Send size={14} /> Yêu cầu hiệu đính
                  </button>

                  <button
                    type="button"
                    className="btn btn-primary btn-sm"
                    style={{ background: 'var(--color-success)', borderColor: 'var(--color-success)' }}
                    onClick={() => setDecision('approve')}
                  >
                    <Check size={14} /> Phê duyệt & Xuất bản ngay
                  </button>
                </div>
              )}
            </div>

            {/* 2-Step Confirmation Banner */}
            {decision && (
              <div style={{
                padding: '14px 24px',
                background: decision === 'approve' ? 'var(--color-success-bg)' : decision === 'revision' ? 'var(--color-warning-bg)' : 'var(--color-danger-bg)',
                borderTop: '1px solid var(--color-paper-border)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: '12px'
              }}>
                <div style={{ fontSize: '0.85rem', color: 'var(--color-charcoal-900)' }}>
                  Xác nhận hành động: <strong>
                    {decision === 'approve'
                      ? 'PHÊ DUYỆT & XUẤT BẢN NGAY CHO KHÁCH THAM QUAN'
                      : decision === 'revision'
                      ? 'GỬI TRẢ NHÂN VIÊN BẢO TÀNG HIỆU ĐÍNH LẠI'
                      : 'TỪ CHỐI HỒ SƠ ĐỆ TRÌNH NÀY'}
                  </strong>
                </div>

                <div style={{ display: 'flex', gap: '8px' }}>
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    onClick={() => setDecision('')}
                  >
                    Hủy
                  </button>
                  <button
                    type="button"
                    className="btn btn-primary btn-sm"
                    style={{
                      background: decision === 'approve' ? 'var(--color-success)' : decision === 'revision' ? 'var(--color-warning)' : 'var(--color-danger)',
                      borderColor: 'transparent'
                    }}
                    onClick={submitDecision}
                  >
                    <CheckSquare size={14} /> Xác nhận thi hành
                  </button>
                </div>
              </div>
            )}
          </section>
        </div>,
        document.body
      )}
    </div>
  );
}
