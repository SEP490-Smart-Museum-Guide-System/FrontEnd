import React, { useMemo, useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { alertAppDialog } from '../common/appDialogs';
import {
  Check,
  CheckSquare,
  Eye,
  MessageSquare,
  X,
  FileText,
  HelpCircle,
  Volume2,
  Sparkles,
  AlertCircle,
  ShieldCheck,
  Search
} from 'lucide-react';
import { useApp, resolveSubmitterName, formatCurationDate } from '../../context/AppContext';
import { backend } from '../../services/backend';
import { getCurationContentByIdApi } from '../../services/curationApi';
import { mediaApi } from '../../services/mediaApi';
import { findContentWarnings, inappropriateContentWarning } from '../../utils/contentModeration';
import './curation.css';

const itemMeta = (item) => item.type === 'new_tour'
  ? `Tuyến tham quan · v${item.versionNo || 1} · ${(item.items || []).length} trạm · ${item.estimatedMinutes || 0} phút`
  : `Hiện vật: ${item.targetArtifactName || item.artifactName || 'Chưa xác định'}`;

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
    users,
    currentUser,
    approveCurationItem,
    rejectCurationItem,
    pendingNotificationTarget,
    setPendingNotificationTarget
  } = useApp();

  const [filter, setFilter] = useState('pending_review');
  const [searchTerm, setSearchTerm] = useState('');
  const [selected, setSelected] = useState(null);
  const [reviewAudioUrl, setReviewAudioUrl] = useState('');
  const [reviewAudioError, setReviewAudioError] = useState('');
  const [note, setNote] = useState('');
  const [decision, setDecision] = useState(''); // 'approve' | 'reject'
  const [publishMode, setPublishMode] = useState('immediate'); // 'immediate' | 'scheduled'
  const [scheduledPublicAt, setScheduledPublicAt] = useState('');
  const [tourDiff, setTourDiff] = useState(null);
  const [loadingDiff, setLoadingDiff] = useState(false);
  const [tourVersionDetail, setTourVersionDetail] = useState(null);
  const [checklist, setChecklist] = useState({
    factualAccuracy: true,
    heritageTone: true,
    ageAppropriate: true
  });

  useEffect(() => {
    if (!selected?.audioUrl) {
      setReviewAudioUrl('');
      setReviewAudioError('');
      return;
    }

    let objectUrl;
    const controller = new AbortController();
    let url;
    try { url = new URL(selected.audioUrl, window.location.origin); }
    catch { setReviewAudioUrl(''); setReviewAudioError('Đường dẫn audio không hợp lệ.'); return; }
    const match = url.pathname.match(/^\/api\/artifacts\/(\d+)\/media\/(\d+)\/file$/);
    if (!match) {
      setReviewAudioError('');
      setReviewAudioUrl(selected.audioUrl);
      return () => controller.abort();
    }

    setReviewAudioUrl('');
    setReviewAudioError('');
    mediaApi(`artifacts/${match[1]}/media/${match[2]}/file`, { blob: true, signal: controller.signal })
      .then(blob => {
        if (!blob.type.startsWith('audio/')) throw new Error('Tệp audio không hợp lệ.');
        objectUrl = URL.createObjectURL(blob);
        setReviewAudioUrl(objectUrl);
      })
      .catch(() => {
        if (!controller.signal.aborted) {
          setReviewAudioUrl('');
          setReviewAudioError('Không tải được audio của bản nháp.');
        }
      });

    return () => {
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [selected?.audioUrl]);

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

  // Tự động mở hồ sơ thẩm định khi điều hướng từ thông báo (Deep-Link)
  useEffect(() => {
    if (!pendingNotificationTarget || !queue.length) return;
    const { type, referenceType, referenceId } = pendingNotificationTarget;
    if (!referenceId) return;

    const isTourRef = referenceType === 'TourVersion' || type?.startsWith('TOUR_');
    const isContentRef = referenceType === 'ArtifactContent' || type?.startsWith('CONTENT_');
    if (!isTourRef && !isContentRef) return;

    const matched = queue.find((item) => {
      if (isTourRef) {
        return item.type === 'new_tour' && (String(item.backendId) === String(referenceId) || String(item.id) === `tour_version_${referenceId}`);
      }
      return item.type !== 'new_tour' && (String(item.backendId) === String(referenceId) || String(item.id) === String(referenceId));
    });

    if (matched) {
      if (filter !== 'all' && matched.status !== filter) {
        setFilter('all');
      }
      openItem(matched);
      if (typeof setPendingNotificationTarget === 'function') {
        setPendingNotificationTarget(null);
      }
    }
  }, [pendingNotificationTarget, queue]);

  const openItem = async (item) => {
    setSelected(item);
    setNote(item.feedback || '');
    setDecision('');
    setPublishMode('immediate');
    setScheduledPublicAt('');
    setTourDiff(null);
    setTourVersionDetail(null);
    setChecklist({
      factualAccuracy: true,
      heritageTone: true,
      ageAppropriate: true
    });

    const backendId = typeof item.id === 'number' ? item.id : item.backendId;
    if (backendId && item.type === 'new_tour') {
      try {
        const detail = await backend(`tours/versions/${backendId}`);
        if (detail) {
          setTourVersionDetail(detail);
        }
      } catch (_) {}

      if (item.tourId && (item.versionNo || 1) > 1) {
        setLoadingDiff(true);
        try {
          const diff = await backend(`tours/${item.tourId}/versions/compare?toVersionId=${backendId}`);
          if (diff) setTourDiff(diff);
        } catch (_) {
          setTourDiff(null);
        } finally {
          setLoadingDiff(false);
        }
      }
      return;
    }

    if (backendId && item.type !== 'new_tour') {
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
    setPublishMode('immediate');
    setScheduledPublicAt('');
    setTourDiff(null);
    setTourVersionDetail(null);
  };

  const submitDecision = async () => {
    if (!decision || !selected) return;
    if (decision === 'approve' && selectedContentWarnings.length) {
      alertAppDialog(inappropriateContentWarning, { title: 'Cần chỉnh sửa nội dung' });
      return;
    }
    if (decision !== 'approve' && !note.trim()) {
      alertAppDialog('Vui lòng nhập ghi chú chuyên môn cho Nhân viên bảo tàng khi từ chối.', { title: 'Cần ghi chú chuyên môn' });
      return;
    }
    if (decision === 'approve' && selected.type === 'new_tour' && publishMode === 'scheduled') {
      if (!scheduledPublicAt) {
        alertAppDialog('Vui lòng chọn ngày và giờ công bố cho phiên bản hành trình này.', { title: 'Thiếu thời điểm công bố' });
        return;
      }
    }

    let result;
    if (decision === 'approve') {
      const targetPublicAt = (selected.type === 'new_tour' && publishMode === 'scheduled' && scheduledPublicAt)
        ? scheduledPublicAt
        : null;
      result = await approveCurationItem(
        selected.id,
        note || 'Đã thẩm định phê duyệt theo quy chuẩn lưu trữ và truyền thông di sản bảo tàng.',
        targetPublicAt
      );
    } else if (decision === 'reject') {
      result = await rejectCurationItem(selected.id, note);
    }
    if (result?.success) closeItem();
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
  const selectedContentWarnings = selected
    ? findContentWarnings(selected.title, selected.proposedContent)
    : [];

  return (
    <div className="curation-center-page">
      {/* Hero Header */}
      <section className="role-dashboard-hero" style={{ marginBottom: '24px' }}>
        <div className="role-dashboard-eyebrow">
          BÀN LÀM VIỆC GIÁM TUYỂN · {currentMuseum?.shortName || currentMuseum?.name}
        </div>
        <h1>Thẩm định & Kiểm chuẩn Nội dung Di sản</h1>
        <p>
          Thẩm tra độc lập thông tin hiện vật, bản dịch thuật ngữ, kịch bản thuyết minh và ngân hàng câu hỏi tương tác AI do Nhân viên bảo tàng đệ trình trước khi công bố cho Khách tham quan.
        </p>
      </section>

      <div className="cc-kpis">
        {[
          ['pending_review', 'Chờ thẩm định', 'warn'],
          ['draft', 'Yêu cầu hiệu đính', 'gold'],
          ['published', 'Đã xuất bản', 'ok'],
          ['rejected', 'Đã từ chối', 'bad'],
        ].map(([value, label, tone]) => (
          <button type="button" key={value} className={`cc-kpi cc-kpi-${tone} ${filter === value ? 'is-active' : ''}`} onClick={() => setFilter(value)}>
            <strong>{countByStatus(value)}</strong>
            <span>{label}</span>
          </button>
        ))}
        <div className="cc-kpi cc-kpi-total"><strong>{queue.length}</strong><span>Tổng hồ sơ</span></div>
      </div>

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
              const submitterDisplay = resolveSubmitterName(item.submittedBy, item.isAiGenerated, users, currentUser);
              const dateDisplay = formatCurationDate(item.submittedDate);
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
                        {item.languageCode && (
                          <span style={{
                            fontSize: '0.68rem',
                            fontWeight: '700',
                            padding: '1px 6px',
                            borderRadius: '4px',
                            background: item.languageCode?.toLowerCase() === 'en' ? '#EFF6FF' : '#F1F5F9',
                            color: item.languageCode?.toLowerCase() === 'en' ? '#1D4ED8' : '#475569',
                            border: `1px solid ${item.languageCode?.toLowerCase() === 'en' ? '#BFDBFE' : '#CBD5E1'}`
                          }}>
                            {item.languageCode?.toUpperCase()}
                          </span>
                        )}
                        {false && (
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
                        <strong style={{ color: 'var(--color-burgundy-700)' }}>{itemMeta(item)}</strong> · Người nộp: {submitterDisplay} · {dateDisplay}
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
                      <Eye size={14} /> Thẩm định
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
                  {selected.languageCode && (
                    <>
                      <span style={{ color: 'var(--color-charcoal-300)' }}>·</span>
                      <span style={{
                        fontSize: '0.72rem',
                        fontWeight: '700',
                        padding: '1px 7px',
                        borderRadius: '4px',
                        background: selected.languageCode?.toLowerCase() === 'en' ? '#EFF6FF' : '#F1F5F9',
                        color: selected.languageCode?.toLowerCase() === 'en' ? '#1D4ED8' : '#475569',
                        border: `1px solid ${selected.languageCode?.toLowerCase() === 'en' ? '#BFDBFE' : '#CBD5E1'}`
                      }}>
                        Ngôn ngữ: {selected.languageCode?.toUpperCase()} {selected.languageCode?.toLowerCase() === 'en' ? '(Tiếng Anh)' : '(Tiếng Việt)'}
                      </span>
                    </>
                  )}
                </div>
                <h2 className="modal-title font-serif" style={{ fontSize: '1.25rem', color: 'var(--color-charcoal-900)' }}>
                  {selected.title}
                </h2>
                <p style={{ color: 'var(--color-charcoal-500)', fontSize: '.8rem', marginTop: '2px' }}>
                  <strong>{itemMeta(selected)}</strong> · Đệ trình bởi: {resolveSubmitterName(selected.submittedBy, selected.isAiGenerated, users, currentUser)} ({formatCurationDate(selected.submittedDate)})
                </p>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <button type="button" className="dialog-icon-close btn btn-secondary btn-sm" aria-label="Đóng" onClick={closeItem}>
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
                  background: 'var(--admin-bg, #FFFDF9)',
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
                  </div>
                </div>
              )}

              {/* VIEW: SIDE-BY-SIDE DIFF VIEW OR TOUR STOP INSPECTION */}
              {selected.type === 'new_tour' ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div style={{ background: 'var(--admin-bg, #FAF7F2)', padding: '14px 18px', borderRadius: '8px', border: '1px solid var(--color-paper-border)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px', flexWrap: 'wrap', gap: '8px' }}>
                      <strong style={{ color: 'var(--color-burgundy-900)', fontSize: '0.95rem' }}>
                        Thông tin Lộ trình Tham quan (Phiên bản v{selected.versionNo})
                      </strong>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        {tourVersionDetail?.publicAt && (
                          <span style={{ fontSize: '0.72rem', padding: '2px 8px', borderRadius: '12px', background: '#EFF6FF', color: '#1D4ED8', fontWeight: '600', border: '1px solid #BFDBFE' }}>
                            Công bố: {formatCurationDate(tourVersionDetail.publicAt)}
                          </span>
                        )}
                        <span className="badge-status badge-active" style={{ fontSize: '0.72rem' }}>
                          {selected.estimatedMinutes} phút
                        </span>
                      </div>
                    </div>
                    <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--color-charcoal-700)', lineHeight: '1.5' }}>
                      {selected.proposedContent || 'Hành trình chưa có mô tả chi tiết.'}
                    </p>
                  </div>

                  {/* KHUNG SO SÁNH SỰ KHÁC BIỆT GIỮA 2 PHIÊN BẢN (VERSION DIFF) */}
                  {loadingDiff ? (
                    <div style={{ padding: '12px', background: 'var(--admin-bg, #FFFDF8)', borderRadius: '8px', border: '1px solid var(--color-gold-300)', fontSize: '0.8rem', color: 'var(--color-charcoal-600)' }}>
                      Đang phân tích so sánh thay đổi so với phiên bản trước…
                    </div>
                  ) : tourDiff && (
                    <div style={{ background: '#FFFDF8', padding: '14px 16px', borderRadius: '8px', border: '1.5px solid var(--color-gold-400)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px', flexWrap: 'wrap', gap: '8px' }}>
                        <strong style={{ fontSize: '0.85rem', color: 'var(--color-burgundy-900)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <Sparkles size={15} color="var(--color-gold-600)" />
                          Đối chiếu Thay đổi Phiên bản (v{tourDiff.fromVersionNo} → v{tourDiff.toVersionNo})
                        </strong>
                        <span style={{
                          fontSize: '0.74rem',
                          fontWeight: '700',
                          padding: '2px 8px',
                          borderRadius: '12px',
                          background: tourDiff.estimatedMinutesDelta > 0 ? '#FEF3C7' : tourDiff.estimatedMinutesDelta < 0 ? '#DBEAFE' : '#F1F5F9',
                          color: tourDiff.estimatedMinutesDelta > 0 ? '#B45309' : tourDiff.estimatedMinutesDelta < 0 ? '#1D4ED8' : '#475569'
                        }}>
                          Thời lượng: {tourDiff.fromEstimatedMinutes}p → {tourDiff.toEstimatedMinutes}p ({tourDiff.estimatedMinutesDelta >= 0 ? `+${tourDiff.estimatedMinutesDelta}` : tourDiff.estimatedMinutesDelta} phút)
                        </span>
                      </div>

                      <p style={{ margin: '0 0 10px', fontSize: '0.8rem', color: 'var(--color-charcoal-700)' }}>
                        {tourDiff.summary}
                      </p>

                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '10px' }}>
                        {tourDiff.titleChanged && (
                          <div style={{ padding: '8px 10px', background: '#FFF', borderRadius: '6px', border: '1px solid var(--color-paper-border)', fontSize: '0.78rem' }}>
                            <strong style={{ color: 'var(--color-burgundy-800)', display: 'block', marginBottom: '2px' }}>Đổi tên hành trình:</strong>
                            <div style={{ color: 'var(--color-charcoal-500)', textDecoration: 'line-through' }}>{tourDiff.fromTitle}</div>
                            <div style={{ color: 'var(--color-charcoal-900)', fontWeight: '600' }}>{tourDiff.toTitle}</div>
                          </div>
                        )}
                        {(tourDiff.addedStops || []).length > 0 && (
                          <div style={{ padding: '8px 10px', background: '#F0FDF4', borderRadius: '6px', border: '1px solid #BBF7D0', fontSize: '0.78rem' }}>
                            <strong style={{ color: '#166534', display: 'block', marginBottom: '4px' }}>
                              + Thêm {tourDiff.addedStops.length} trạm dừng mới:
                            </strong>
                            {tourDiff.addedStops.map(s => (
                              <div key={s.artifactId} style={{ color: '#14532D', fontWeight: '600' }}>
                                • Trạm {s.orderNo}: {s.artifactName}
                              </div>
                            ))}
                          </div>
                        )}
                        {(tourDiff.removedStops || []).length > 0 && (
                          <div style={{ padding: '8px 10px', background: '#FEF2F2', borderRadius: '6px', border: '1px solid #FECACA', fontSize: '0.78rem' }}>
                            <strong style={{ color: '#991B1B', display: 'block', marginBottom: '4px' }}>
                              - Lược bỏ {tourDiff.removedStops.length} trạm dừng:
                            </strong>
                            {tourDiff.removedStops.map(s => (
                              <div key={s.artifactId} style={{ color: '#7F1D1D', fontWeight: '600' }}>
                                • {s.artifactName}
                              </div>
                            ))}
                          </div>
                        )}
                        {(tourDiff.reorderedStops || []).length > 0 && (
                          <div style={{ padding: '8px 10px', background: '#FFFBEB', borderRadius: '6px', border: '1px solid #FDE68A', fontSize: '0.78rem' }}>
                            <strong style={{ color: '#92400E', display: 'block', marginBottom: '4px' }}>
                              ⇄ Đổi thứ tự {tourDiff.reorderedStops.length} trạm:
                            </strong>
                            {tourDiff.reorderedStops.map(s => (
                              <div key={s.artifactId} style={{ color: '#78350F', fontWeight: '600' }}>
                                • {s.artifactName}: Trạm {s.fromOrderNo} → Trạm {s.toOrderNo}
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  <div>
                    <strong style={{ display: 'block', marginBottom: '8px', fontSize: '0.825rem', color: 'var(--color-charcoal-900)' }}>
                      Danh sách trạm dừng hiện vật theo thứ tự ({ (tourVersionDetail?.stops || selected.items || []).length } trạm):
                    </strong>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', maxHeight: '240px', overflowY: 'auto' }}>
                      {(tourVersionDetail?.stops || selected.items || []).length === 0 ? (
                        <div style={{ padding: '12px', background: '#FFF', borderRadius: '6px', border: '1px dashed var(--color-paper-border)', fontSize: '0.825rem', color: 'var(--color-charcoal-500)', textAlign: 'center' }}>
                          Lộ trình này chưa gắn trạm dừng hiện vật nào.
                        </div>
                      ) : (
                        (tourVersionDetail?.stops || selected.items || []).map((stop, idx) => {
                          const art = museumArtifacts.find(a => a.id === stop.artifactId);
                          const stopTopics = stop.topicNames?.length
                            ? stop.topicNames
                            : (art?.topics?.map(t => typeof t === 'string' ? t : t?.name).filter(Boolean) || []);
                          const isNewlyAdded = (tourDiff?.addedStops || []).some(a => a.artifactId === stop.artifactId);
                          return (
                            <div
                              key={stop.artifactId || idx}
                              style={{
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'space-between',
                                gap: '12px',
                                padding: '10px 14px',
                                background: isNewlyAdded ? '#F0FDF4' : '#FFFFFF',
                                border: isNewlyAdded ? '1px solid #86EFAC' : '1px solid var(--color-paper-border)',
                                borderRadius: '6px'
                              }}
                            >
                              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', minWidth: 0, flex: 1 }}>
                                <div style={{
                                  width: '26px',
                                  height: '26px',
                                  borderRadius: '50%',
                                  background: isNewlyAdded ? '#16A34A' : 'var(--color-burgundy-700)',
                                  color: '#FFFFFF',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  fontSize: '0.75rem',
                                  fontWeight: '700',
                                  flexShrink: 0
                                }}>
                                  {stop.orderNo || idx + 1}
                                </div>
                                <div style={{ flex: 1, minWidth: 0 }}>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                                    <span style={{ fontWeight: '600', fontSize: '0.85rem', color: 'var(--color-charcoal-900)' }}>
                                      {stop.artifactName || (art ? art.name : `Hiện vật #${stop.artifactId}`)}
                                    </span>
                                    {isNewlyAdded && (
                                      <span style={{ fontSize: '0.68rem', fontWeight: '700', padding: '1px 6px', borderRadius: '8px', background: '#DCFCE7', color: '#15803D' }}>
                                        + MỚI
                                      </span>
                                    )}
                                  </div>
                                  <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                                    Mã: {stop.artifactCode || art?.code || `#${stop.artifactId}`} {(stop.galleryName || art?.galleryName) ? `• Phòng: ${stop.galleryName || art?.galleryName}` : ''}
                                  </div>
                                </div>
                              </div>
                              {stopTopics.length > 0 && (
                                <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                                  {stopTopics.map(tName => (
                                    <span
                                      key={tName}
                                      style={{
                                        fontSize: '0.68rem',
                                        fontWeight: '600',
                                        padding: '2px 8px',
                                        borderRadius: '10px',
                                        background: '#F1ECE1',
                                        color: 'var(--color-burgundy-800)',
                                        border: '1px solid var(--color-paper-border)'
                                      }}
                                    >
                                      {tName}
                                    </span>
                                  ))}
                                </div>
                              )}
                            </div>
                          );
                        })
                      )}
                    </div>
                  </div>

                  {/* TÙY CHỌN THỜI ĐIỂM CÔNG BỐ (PUBLIC_AT) CHO GIÁM TUYỂN */}
                  {selected.status === 'pending_review' && (
                    <div style={{ padding: '12px 14px', background: '#FAF7F2', borderRadius: '8px', border: '1px solid var(--color-paper-border)' }}>
                      <strong style={{ display: 'block', fontSize: '0.8125rem', color: 'var(--color-burgundy-900)', marginBottom: '8px' }}>
                        Chế độ Công bố Phiên bản Lộ trình (PublicAt):
                      </strong>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '18px', flexWrap: 'wrap' }}>
                        <label style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '0.82rem', cursor: 'pointer', fontWeight: publishMode === 'immediate' ? '600' : 'normal' }}>
                          <input
                            type="radio"
                            name="tourPublishMode"
                            checked={publishMode === 'immediate'}
                            onChange={() => setPublishMode('immediate')}
                          />
                          <span>Xuất bản ngay sau khi duyệt</span>
                        </label>
                        <label style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '0.82rem', cursor: 'pointer', fontWeight: publishMode === 'scheduled' ? '600' : 'normal' }}>
                          <input
                            type="radio"
                            name="tourPublishMode"
                            checked={publishMode === 'scheduled'}
                            onChange={() => setPublishMode('scheduled')}
                          />
                          <span>Hẹn giờ công bố trong tương lai</span>
                        </label>
                        {publishMode === 'scheduled' && (
                          <input
                            type="datetime-local"
                            className="form-input"
                            style={{ width: 'auto', height: '34px', fontSize: '0.82rem', padding: '4px 10px' }}
                            value={scheduledPublicAt}
                            onChange={(e) => setScheduledPublicAt(e.target.value)}
                          />
                        )}
                      </div>
                    </div>
                  )}
                </div>
              ) : (
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
                    {selectedContentWarnings.length > 0 && (
                      <div role="alert" style={{ marginBottom: 12, padding: '10px 12px', borderRadius: 8, border: '1px solid #F0B44D', background: '#FFF8E8', color: '#7A3E00', fontSize: '.84rem' }}>
                        <strong>Chưa thể phê duyệt: phát hiện nội dung cần chỉnh sửa.</strong>
                        <ul style={{ margin: '6px 0 0', paddingLeft: 20 }}>
                          {selectedContentWarnings.map(warning => <li key={warning}>{warning}</li>)}
                        </ul>
                        <div style={{ marginTop: 6 }}>{inappropriateContentWarning}</div>
                      </div>
                    )}

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
                      {selected.audioUrl && (
                        <div style={{ marginTop: 12, padding: '10px 12px', background: '#FFF', border: '1px solid var(--color-gold-200)', borderRadius: 8 }}>
                          <strong style={{ display: 'block', marginBottom: 8, fontSize: '.85rem' }}>Bản đọc đính kèm</strong>
                          {reviewAudioUrl ? <audio aria-label="Nghe audio bản nháp" controls preload="metadata" src={reviewAudioUrl} style={{ width: '100%' }} /> : <p role={reviewAudioError ? 'alert' : 'status'} style={{ margin: 0, fontSize: '.8rem' }}>{reviewAudioError || 'Đang tải bản đọc…'}</p>}
                        </div>
                      )}
                    </article>
                  </div>
                </div>
              )}


              {/* Feedback Note Input */}
              {selected.status === 'pending_review' && (
                <div style={{ marginTop: '4px' }}>
                  <label className="form-label" style={{ fontWeight: '600', fontSize: '0.8125rem', color: 'var(--color-charcoal-800)', marginBottom: '4px' }}>
                    Ghi chú Chuyên môn của Giám tuyển (Bắt buộc khi từ chối):
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
                    className="btn btn-primary btn-sm"
                    style={{ background: 'var(--color-success)', borderColor: 'var(--color-success)' }}
                    disabled={selectedContentWarnings.length > 0}
                    onClick={() => setDecision('approve')}
                  >
                    <Check size={14} /> {selected.type === 'new_tour' && publishMode === 'scheduled' ? 'Phê duyệt & Hẹn giờ công bố' : 'Phê duyệt & Xuất bản ngay'}
                  </button>
                </div>
              )}
            </div>

            {/* 2-Step Confirmation Banner */}
            {decision && (
              <div style={{
                padding: '14px 24px',
                background: decision === 'approve' ? 'var(--color-success-bg)' : 'var(--color-danger-bg)',
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
                      ? (selected.type === 'new_tour' && publishMode === 'scheduled' && scheduledPublicAt
                          ? `PHÊ DUYỆT & HẸN GIỜ CÔNG BỐ (${formatCurationDate(scheduledPublicAt)})`
                          : 'PHÊ DUYỆT & XUẤT BẢN NGAY CHO KHÁCH THAM QUAN')
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
                      background: decision === 'approve' ? 'var(--color-success)' : 'var(--color-danger)',
                      borderColor: 'transparent'
                    }}
                    disabled={decision === 'approve' && selectedContentWarnings.length > 0}
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
