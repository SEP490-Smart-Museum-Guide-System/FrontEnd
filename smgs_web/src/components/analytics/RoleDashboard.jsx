import React from 'react';
import { useApp } from '../../context/AppContext';
import {
  ArrowRight, Building2, CheckCheck, ClipboardCheck, CreditCard,
  Layers, MessageSquare, QrCode, ShieldCheck, Sparkles, Users
} from 'lucide-react';

const formatNumber = value => new Intl.NumberFormat('vi-VN').format(value);
const formatMoney = value => `${formatNumber(value)} đ`;

export default function RoleDashboard({ onNavigate }) {
  const {
    currentRole, currentMuseum, artifacts, museums, tours,
    curationQueue, transactions, users, reviews
  } = useApp();

  const museumQueue = curationQueue.filter(item => artifacts.find(artifact => artifact.id === item.targetArtifactId)?.museumId === currentMuseum.id);
  const curatorQueue = currentRole === 'curator' ? museumQueue : curationQueue;
  const pending = curatorQueue.filter(item => item.status === 'pending');
  const museumArtifacts = artifacts.filter(item => item.museumId === currentMuseum.id);
  const museumTours = tours.filter(item => item.museumId === currentMuseum.id);
  const museumReviews = reviews.filter(item => item.museumName === currentMuseum.name);
  const revenue = transactions.filter(item => item.status === 'completed').reduce((sum, item) => sum + item.amount, 0);
  const scans = museumArtifacts.reduce((sum, item) => sum + (item.scansCount || 0), 0);

  const config = currentRole === 'administrator' ? {
    eyebrow: 'Quản trị toàn hệ thống',
    title: 'Toàn cảnh vận hành SMGS',
    description: 'Theo dõi tài khoản, bảo tàng và giao dịch của hệ thống trong một nơi.',
    primary: ['Quản lý người dùng', 'users'],
    secondary: ['Xem giao dịch', 'transactions'],
    metrics: [
      [Users, formatNumber(users.length), 'Tài khoản', 'Toàn hệ thống', 'burgundy'],
      [Building2, formatNumber(museums.length), 'Bảo tàng', 'Đang kết nối', 'gold'],
      [CreditCard, formatMoney(revenue), 'Doanh thu mô phỏng', 'Giao dịch thành công', 'green'],
      [ClipboardCheck, formatNumber(pending.length), 'Chờ kiểm duyệt', 'Nội dung chưa xuất bản', 'blue']
    ],
    listTitle: 'Giao dịch gần đây',
    listAction: ['Xem tất cả giao dịch', 'transactions'],
    rows: transactions.slice(0, 5).map(item => ({
      title: item.packageName,
      subtitle: `${item.userName} · ${item.timestamp}`,
      badge: formatMoney(item.amount),
      status: item.status === 'completed' ? 'approved' : item.status === 'refunded' ? 'refunded' : 'pending'
    })),
    asideTitle: 'Việc cần theo dõi',
    asideText: `${pending.length} nội dung chờ duyệt và ${transactions.filter(item => item.status === 'pending').length} giao dịch đang xử lý.`,
    asideAction: ['Mở nhật ký hệ thống', 'audit']
  } : currentRole === 'curator' ? {
    eyebrow: 'Không gian kiểm duyệt',
    title: 'Đưa nội dung tốt đến khách tham quan',
    description: 'Xem bản nháp, phản hồi và tiến độ phê duyệt trước khi xuất bản.',
    primary: ['Mở hàng đợi', 'curation_queue'],
    secondary: ['Xem phản hồi', 'reviews'],
    metrics: [
      [ClipboardCheck, formatNumber(pending.length), 'Chờ duyệt', 'Cần xem nội dung', 'burgundy'],
      [CheckCheck, formatNumber(curatorQueue.filter(item => item.status === 'approved').length), 'Đã phê duyệt', 'Nội dung sẵn sàng', 'green'],
      [Layers, formatNumber(curatorQueue.filter(item => item.status === 'revision_requested').length), 'Cần hiệu đính', 'Đã gửi góp ý', 'gold'],
      [MessageSquare, formatNumber(museumReviews.filter(item => item.status === 'pending_reply').length), 'Phản hồi mới', 'Khách đang chờ trả lời', 'blue']
    ],
    listTitle: 'Nội dung cần kiểm duyệt',
    listAction: ['Xem hàng đợi', 'curation_queue'],
    rows: pending.slice(0, 5).map(item => ({
      title: item.title,
      subtitle: `${item.submittedBy} · ${item.submittedDate}`,
      badge: 'Chờ duyệt', status: 'pending'
    })),
    asideTitle: 'Quy trình hôm nay',
    asideText: 'Đọc bản nháp, đối chiếu hồ sơ hiện vật, yêu cầu sửa hoặc phê duyệt nội dung.',
    asideAction: ['Xem đánh giá của khách', 'reviews']
  } : {
    eyebrow: currentMuseum.name,
    title: 'Bàn làm việc bảo tàng',
    description: 'Cập nhật hiện vật, tạo nội dung số và chuẩn bị hành trình tham quan.',
    primary: ['Quản lý hiện vật', 'artifacts'],
    secondary: ['Xưởng nội dung AI', 'ai_studio'],
    metrics: [
      [Layers, formatNumber(museumArtifacts.length), 'Hiện vật', 'Trong bảo tàng đã chọn', 'burgundy'],
      [QrCode, formatNumber(scans), 'Lượt quét mã', 'Từ các hiện vật', 'green'],
      [Sparkles, formatNumber(museumQueue.filter(item => item.status === 'pending' && item.submittedBy?.includes('Nhân viên bảo tàng')).length), 'Bản gửi duyệt', 'Đang trong quy trình', 'gold'],
      [Building2, formatNumber(museumTours.length), 'Hành trình mẫu', 'Tại bảo tàng đã chọn', 'blue']
    ],
    listTitle: 'Hiện vật đang quản lý',
    listAction: ['Xem kho hiện vật', 'artifacts'],
    rows: museumArtifacts.slice(0, 5).map(item => ({
      title: item.name,
      subtitle: `${item.galleryName} · ${item.code}`,
      badge: item.status === 'published' ? 'Đã xuất bản' : 'Bản nháp',
      status: item.status === 'published' ? 'published' : 'draft'
    })),
    asideTitle: 'Tiếp tục công việc',
    asideText: 'Hoàn thiện hồ sơ, hình ảnh và thuyết minh trước khi gửi kiểm duyệt.',
    asideAction: ['Tạo nội dung AI', 'ai_studio']
  };

  return (
    <div className={`role-dashboard role-dashboard--${currentRole}`}>
      <section className="role-dashboard-hero">
        <div className="role-dashboard-eyebrow">{config.eyebrow}</div>
        <h1>{config.title}</h1>
        <p>{config.description}</p>
        <div className="role-dashboard-actions">
          <button type="button" className="btn btn-gold" onClick={() => onNavigate(config.primary[1])}>
            {config.primary[0]} <ArrowRight size={16} />
          </button>
          <button type="button" className="btn btn-secondary" onClick={() => onNavigate(config.secondary[1])}>
            {config.secondary[0]}
          </button>
        </div>
      </section>

      <div className="stat-grid">
        {config.metrics.map(([Icon, value, label, note, tone]) => (
          <div className={`stat-card stat-card-${tone}`} key={label}>
            <div className="stat-icon-wrapper"><Icon size={24} /></div>
            <div><div className="stat-value">{value}</div><div className="stat-label">{label}</div><small>{note}</small></div>
          </div>
        ))}
      </div>

      <div className="role-dashboard-grid">
        <section className="card">
          <div className="card-header">
            <h2 className="card-title">{config.listTitle}</h2>
            <button type="button" className="btn btn-secondary btn-sm" onClick={() => onNavigate(config.listAction[1])}>
              {config.listAction[0]}
            </button>
          </div>
          <div className="role-dashboard-list">
            {config.rows.length ? config.rows.map((row, index) => (
              <div className="role-dashboard-row" key={`${row.title}-${index}`}>
                <div><strong>{row.title}</strong><small>{row.subtitle}</small></div>
                <span className={`badge-status badge-${row.status}`}>{row.badge}</span>
              </div>
            )) : <div className="role-dashboard-row">Chưa có nội dung trong mục này.</div>}
          </div>
        </section>
        <aside className="card role-dashboard-aside">
          <ShieldCheck size={24} color="var(--color-burgundy-700)" />
          <h2 className="card-title">{config.asideTitle}</h2>
          <p>{config.asideText}</p>
          <button type="button" className="btn btn-primary" onClick={() => onNavigate(config.asideAction[1])}>
            {config.asideAction[0]} <ArrowRight size={16} />
          </button>
        </aside>
      </div>
    </div>
  );
}
