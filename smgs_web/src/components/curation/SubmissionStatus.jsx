import React from 'react';
import { Clock3, FileCheck2, MessageSquareText, Send, Sparkles } from 'lucide-react';
import { useApp } from '../../context/AppContext';

const labels = {
  pending: 'Đang chờ Giám tuyển thẩm định',
  revision_requested: 'Giám tuyển yêu cầu hiệu đính',
  rejected: 'Không được phê duyệt',
  approved: 'Đã được xuất bản',
};

export default function SubmissionStatus() {
  const { curationQueue, artifacts, currentMuseum, setActiveTab } = useApp();
  const submissions = curationQueue.filter(item => artifacts.find(artifact => artifact.id === item.targetArtifactId)?.museumId === currentMuseum.id);

  return <div>
    <section className="role-dashboard-hero" style={{ marginBottom: '24px' }}>
      <div className="role-dashboard-eyebrow">LUỒNG PHỐI HỢP NỘI DUNG</div>
      <h1>Đệ trình để Giám tuyển thẩm định</h1>
      <p>Museum Staff tạo và gửi nội dung. Giám tuyển ở cổng kiểm định riêng sẽ hiệu đính, yêu cầu sửa, phê duyệt hoặc xuất bản.</p>
      <div className="role-dashboard-actions"><button type="button" className="btn btn-gold" onClick={() => setActiveTab('ai_studio')}><Sparkles size={16} /> Mở xưởng nội dung AI</button></div>
    </section>

    <section className="card">
      <div className="card-header"><div className="card-title"><Send size={19} color="var(--color-burgundy-700)" /> Nội dung đã đệ trình</div><span style={{ color: 'var(--color-charcoal-500)', fontSize: '.78rem' }}>{submissions.length} mục thuộc {currentMuseum.shortName}</span></div>
      <div className="role-dashboard-list">
        {submissions.length ? submissions.map(item => <article className="role-dashboard-row" key={item.id}>
          <div style={{ minWidth: 0 }}><strong>{item.title}</strong><small><Clock3 size={12} style={{ verticalAlign: 'middle' }} /> {item.submittedDate} · {item.targetArtifactName}</small>{item.feedback && <p style={{ marginTop: '8px', color: 'var(--color-charcoal-700)', fontSize: '.78rem' }}><MessageSquareText size={13} style={{ verticalAlign: 'middle', color: 'var(--color-gold-600)' }} /> Phản hồi Giám tuyển: {item.feedback}</p>}</div>
          <span className={`badge-status badge-${item.status === 'approved' ? 'approved' : item.status === 'pending' ? 'pending' : item.status === 'rejected' ? 'rejected' : 'pending_reply'}`}><FileCheck2 size={13} /> {labels[item.status] || item.status}</span>
        </article>) : <div className="role-dashboard-row">Chưa có nội dung nào được đệ trình từ bảo tàng này.</div>}
      </div>
    </section>
  </div>;
}
