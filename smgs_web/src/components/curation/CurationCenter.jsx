import React, { useMemo, useState } from 'react';
import { Check, CheckSquare, Eye, MessageSquare, Send, X } from 'lucide-react';
import { useApp } from '../../context/AppContext';

const statusLabel = {
  pending_review: 'Chờ thẩm định',
  published: 'Đã xuất bản',
  draft: 'Yêu cầu hiệu đính',
  rejected: 'Từ chối',
};

export default function CurationCenter() {
  const { curationQueue, artifacts, currentMuseum, approveCurationItem, rejectCurationItem, requestRevisionCurationItem } = useApp();
  const [filter, setFilter] = useState('pending_review');
  const [selected, setSelected] = useState(null);
  const [note, setNote] = useState('');
  const [decision, setDecision] = useState('');

  const queue = useMemo(
    () => curationQueue.filter(item => artifacts.find(artifact => artifact.id === item.targetArtifactId)?.museumId === currentMuseum.id),
    [artifacts, curationQueue, currentMuseum.id],
  );
  const visibleItems = filter === 'all' ? queue : queue.filter(item => item.status === filter);
  const count = status => queue.filter(item => item.status === status).length;

  const openItem = item => { setSelected(item); setNote(item.feedback || ''); setDecision(''); };
  const closeItem = () => { setSelected(null); setNote(''); setDecision(''); };
  const submitDecision = () => {
    if (!decision || !selected) return;
    if (decision !== 'approve' && !note.trim()) return;
    if (decision === 'approve') approveCurationItem(selected.id, note || 'Đã thẩm định theo tiêu chuẩn nội dung bảo tàng.');
    if (decision === 'revision') requestRevisionCurationItem(selected.id, note);
    if (decision === 'reject') rejectCurationItem(selected.id, note);
    closeItem();
  };

  return <div>
    <section className="role-dashboard-hero" style={{ marginBottom: '24px' }}>
      <div className="role-dashboard-eyebrow">GIÁM TUYỂN · {currentMuseum.shortName}</div>
      <h1>Thẩm định trước khi xuất bản</h1>
      <p>Kiểm tra thông tin hiện vật, bản dịch, thuyết minh và quiz AI do Nhân viên bảo tàng đệ trình.</p>
    </section>

    <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap', marginBottom: '20px' }}>
      {[
        ['pending_review', 'Chờ thẩm định'], ['draft', 'Yêu cầu hiệu đính'], ['published', 'Đã xuất bản'], ['rejected', 'Từ chối'], ['all', 'Tất cả'],
      ].map(([value, label]) => <button key={value} type="button" onClick={() => setFilter(value)} className={`btn btn-sm ${filter === value ? 'btn-primary' : 'btn-secondary'}`}>
        {label} <span style={{ marginLeft: '5px' }}>{value === 'all' ? queue.length : count(value)}</span>
      </button>)}
    </div>

    <section className="card">
      <div className="card-header"><h2 className="card-title">Hàng đợi nội dung</h2><span style={{ color: 'var(--color-charcoal-500)', fontSize: '.8rem' }}>Chỉ hiển thị nội dung của bảo tàng được phân công</span></div>
      <div className="role-dashboard-list">
        {visibleItems.length ? visibleItems.map(item => <article className="role-dashboard-row" key={item.id}>
          <div style={{ minWidth: 0 }}><strong>{item.title}</strong><small>{item.targetArtifactName} · {item.submittedBy} · {item.submittedDate}</small><p style={{ margin: '6px 0 0', color: 'var(--color-charcoal-600)', fontSize: '.78rem' }}>{item.changesSummary}</p></div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '9px' }}><span className={`badge-status badge-${item.status}`}>{statusLabel[item.status]}</span><button type="button" className="btn btn-secondary btn-sm" onClick={() => openItem(item)}><Eye size={14} /> Xem</button></div>
        </article>) : <div className="role-dashboard-row">Không có nội dung ở trạng thái này.</div>}
      </div>
    </section>

    {selected && <div className="modal-overlay" onClick={closeItem}>
      <section className="modal-dialog" style={{ maxWidth: '960px' }} onClick={event => event.stopPropagation()}>
        <div className="modal-header"><div><h2 className="modal-title font-serif">{selected.title}</h2><p style={{ color: 'var(--color-charcoal-500)', fontSize: '.78rem', marginTop: '4px' }}>{selected.targetArtifactName} · {selected.submittedBy}</p></div><button type="button" className="btn btn-secondary btn-sm" onClick={closeItem}><X size={16} /></button></div>
        <div className="modal-body" style={{ display: 'grid', gap: '16px' }}>
          <div style={{ padding: '12px', borderLeft: '4px solid var(--color-gold-500)', background: 'var(--color-paper-accent)' }}><strong>Phạm vi thay đổi</strong><p style={{ marginTop: '4px', fontSize: '.83rem' }}>{selected.changesSummary}</p></div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '14px' }}>
            <article style={{ border: '1px solid var(--color-paper-border)', borderRadius: '8px', padding: '14px' }}><strong>Bản hiện tại</strong><p style={{ marginTop: '9px', whiteSpace: 'pre-line', fontSize: '.83rem', lineHeight: 1.6 }}>{selected.currentVersion || 'Chưa có nội dung.'}</p></article>
            <article style={{ border: '1px solid var(--color-gold-300)', borderRadius: '8px', padding: '14px', background: '#FFFCF6' }}><strong>Nội dung đệ trình</strong><p style={{ marginTop: '9px', whiteSpace: 'pre-line', fontSize: '.83rem', lineHeight: 1.6 }}>{selected.proposedContent}</p></article>
          </div>
          {selected.status === 'pending_review' && <div><label className="form-label">Ghi chú thẩm định</label><textarea className="form-textarea" rows={3} value={note} onChange={event => setNote(event.target.value)} placeholder="Nhập góp ý khi yêu cầu hiệu đính hoặc từ chối…" /></div>}
          {selected.status !== 'pending_review' && selected.feedback && <div style={{ padding: '12px', background: 'var(--color-paper-accent)', borderRadius: '8px' }}><MessageSquare size={15} /> Phản hồi: {selected.feedback}</div>}
        </div>
        <div className="modal-footer" style={{ justifyContent: 'space-between' }}>
          <button type="button" className="btn btn-secondary" onClick={closeItem}>Đóng</button>
          {selected.status === 'pending_review' && <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
            <button type="button" className="btn btn-secondary btn-sm" style={{ color: 'var(--color-danger)' }} onClick={() => setDecision('reject')}><X size={14} /> Từ chối</button>
            <button type="button" className="btn btn-secondary btn-sm" onClick={() => setDecision('revision')}><Send size={14} /> Yêu cầu sửa</button>
            <button type="button" className="btn btn-primary btn-sm" onClick={() => setDecision('approve')}><Check size={14} /> Phê duyệt</button>
          </div>}
        </div>
        {decision && <div style={{ padding: '0 20px 20px' }}><button type="button" className="btn btn-primary" onClick={submitDecision}><CheckSquare size={15} /> Xác nhận {decision === 'approve' ? 'phê duyệt & xuất bản' : decision === 'revision' ? 'yêu cầu hiệu đính' : 'từ chối'}</button></div>}
      </section>
    </div>}
  </div>;
}
