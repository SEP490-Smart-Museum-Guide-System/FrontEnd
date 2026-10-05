import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Activity, AlertTriangle, CheckCircle2, Headset, RotateCcw, ShieldCheck, Sparkles } from 'lucide-react';

const groups = {
  support: { title: 'Hỗ trợ khách & xử lý khiếu nại', description: 'Tiếp nhận vấn đề của khách tham quan trên toàn hệ thống.', types: ['support', 'complaint'], icon: Headset },
  refunds: { title: 'Yêu cầu hoàn tiền', description: 'Kiểm tra yêu cầu, đối chiếu giao dịch và ghi nhận kết quả xử lý.', types: ['refund'], icon: RotateCcw },
  operations: { title: 'Lỗi vận hành & chất lượng AI', description: 'Theo dõi lỗi ứng dụng và câu trả lời AI cần kiểm tra trên toàn hệ thống.', types: ['operations', 'ai_quality'], icon: Activity }
};

const typeLabels = {
  support: 'Hỗ trợ khách', complaint: 'Khiếu nại', refund: 'Hoàn tiền',
  operations: 'Lỗi vận hành', ai_quality: 'Chất lượng AI'
};

const statusLabels = { new: 'Mới tiếp nhận', in_progress: 'Đang xử lý', resolved: 'Đã xử lý' };

export default function SystemOperations({ mode = 'support' }) {
  const { systemCases, updateSystemCase, transactions, reviews, moderateReview } = useApp();
  const [filter, setFilter] = useState('open');
  const [notes, setNotes] = useState({});

  if (mode === 'review_moderation') {
    const flagged = reviews.filter(item => !item.hidden);
    return (
      <div className="operations-page">
        <div className="operations-hero"><ShieldCheck size={30} /><div><span>NHÂN VIÊN HỆ THỐNG</span><h1>Kiểm duyệt feedback</h1><p>Rà soát phản hồi không phù hợp trên toàn bộ bảo tàng. Bảo tàng vẫn phụ trách trả lời khách.</p></div></div>
        <div className="operations-summary"><strong>{reviews.length}</strong> phản hồi · <strong>{flagged.length}</strong> đang hiển thị · <strong>{reviews.length - flagged.length}</strong> đã ẩn</div>
        <div className="operations-list">
          {reviews.map(item => <article className="card operations-case" key={item.id}>
            <div className="operations-case-top"><span className="operations-tag">{item.museumName}</span><span className={`badge-status ${item.hidden ? 'badge-rejected' : 'badge-approved'}`}>{item.hidden ? 'Đã ẩn' : 'Đang hiển thị'}</span></div>
            <h2>{item.visitorName} · {item.rating}/5 sao</h2><p>{item.comment}</p>
            <div className="operations-case-footer"><small>{item.artifactName} · {item.date}</small><button className="btn btn-secondary btn-sm" type="button" onClick={() => moderateReview(item.id, !item.hidden)}>{item.hidden ? 'Hiện lại phản hồi' : 'Ẩn phản hồi'}</button></div>
          </article>)}
        </div>
      </div>
    );
  }

  const config = groups[mode] || groups.support;
  const Icon = config.icon;
  const cases = systemCases.filter(item => config.types.includes(item.type));
  const shown = filter === 'all' ? cases : cases.filter(item => filter === 'open' ? item.status !== 'resolved' : item.status === filter);

  return (
    <div className="operations-page">
      <div className="operations-hero"><Icon size={30} /><div><span>NHÂN VIÊN HỆ THỐNG · TOÀN HỆ THỐNG</span><h1>{config.title}</h1><p>{config.description}</p></div></div>
      <div className="operations-metrics">
        <div className="card"><AlertTriangle size={20} /><strong>{cases.filter(item => item.status === 'new').length}</strong><span>Mới tiếp nhận</span></div>
        <div className="card"><Activity size={20} /><strong>{cases.filter(item => item.status === 'in_progress').length}</strong><span>Đang xử lý</span></div>
        <div className="card"><CheckCircle2 size={20} /><strong>{cases.filter(item => item.status === 'resolved').length}</strong><span>Đã xử lý</span></div>
      </div>
      <div className="operations-toolbar card"><div><strong>Danh sách công việc</strong><span>{shown.length} mục</span></div><select className="form-select" aria-label="Lọc trạng thái công việc" value={filter} onChange={event => setFilter(event.target.value)}><option value="open">Chưa hoàn tất</option><option value="new">Mới tiếp nhận</option><option value="in_progress">Đang xử lý</option><option value="resolved">Đã xử lý</option><option value="all">Tất cả</option></select></div>
      <div className="operations-list">
        {shown.map(item => {
          const transaction = transactions.find(value => value.id === item.transactionId);
          return <article className="card operations-case" key={item.id}>
            <div className="operations-case-top"><span className="operations-tag">{typeLabels[item.type]}</span><span className={`badge-status ${item.status === 'resolved' ? 'badge-approved' : 'badge-pending'}`}>{statusLabels[item.status]}</span></div>
            <h2>{item.title}</h2><p>{item.detail}</p>
            <div className="operations-meta"><span>{item.id} · {item.createdAt}</span><span>{item.visitor} · {item.museum}</span>{transaction && <span>Giao dịch {transaction.id} · {transaction.amount.toLocaleString('vi-VN')} đ · {transaction.status === 'refunded' ? 'Đã hoàn tiền' : 'Đã thanh toán'}</span>}</div>
            {item.status !== 'resolved' && <div className="operations-actions">
              <input className="form-input" aria-label={`Ghi chú xử lý ${item.id}`} value={notes[item.id] || ''} onChange={event => setNotes(prev => ({ ...prev, [item.id]: event.target.value }))} placeholder="Ghi chú kết quả xử lý..." />
              {item.status === 'new' && <button type="button" className="btn btn-secondary btn-sm" onClick={() => updateSystemCase(item.id, 'in_progress', notes[item.id] || '')}>Tiếp nhận</button>}
              <button type="button" className="btn btn-primary btn-sm" onClick={() => { if (item.type === 'refund' && !window.confirm(`Xác nhận hoàn tiền mô phỏng cho ${item.transactionId}?`)) return; updateSystemCase(item.id, 'resolved', notes[item.id] || 'Đã xử lý'); }}>Hoàn tất{item.type === 'refund' ? ' & hoàn tiền' : ''}</button>
            </div>}
            {item.note && <div className="operations-note">Ghi chú: {item.note}</div>}
          </article>;
        })}
        {!shown.length && <div className="card operations-empty"><Sparkles size={20} /> Không có công việc ở trạng thái này.</div>}
      </div>
    </div>
  );
}
