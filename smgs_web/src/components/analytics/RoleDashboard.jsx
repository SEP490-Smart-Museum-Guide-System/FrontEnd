import React from 'react';
import { useApp } from '../../context/AppContext';
import {
  ArrowRight, Building2, ClipboardCheck, CreditCard,
  Layers, MessageSquare, QrCode, ShieldCheck, Sparkles, Users
} from 'lucide-react';

const formatNumber = value => new Intl.NumberFormat('vi-VN').format(value);
const formatMoney = value => `${formatNumber(value)} đ`;

export default function RoleDashboard({ onNavigate }) {
  const {
    currentRole, currentMuseum, artifacts, museums, tours,
    curationQueue, transactions, users, reviews, systemCases
  } = useApp();

  const museumQueue = curationQueue.filter(item => artifacts.find(artifact => artifact.id === item.targetArtifactId)?.museumId === currentMuseum.id);
  const pending = curationQueue.filter(item => item.status === 'pending');
  const museumArtifacts = artifacts.filter(item => item.museumId === currentMuseum.id);
  const museumTours = tours.filter(item => item.museumId === currentMuseum.id);
  const museumReviews = reviews.filter(item => item.museumName === currentMuseum.name);
  const revenue = transactions.filter(item => item.status === 'completed').reduce((sum, item) => sum + item.amount, 0);
  const museumRevenue = transactions.filter(item => item.status === 'completed' && item.museumCode === currentMuseum.code).reduce((sum, item) => sum + item.amount, 0);
  const openCases = systemCases.filter(item => item.status !== 'resolved');
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
  } : currentRole === 'systemStaff' ? {
    eyebrow: 'Vận hành toàn hệ thống',
    title: 'Hỗ trợ khách, giữ hệ thống thông suốt',
    description: 'Theo dõi khiếu nại, hoàn tiền, giao dịch, feedback và chất lượng AI trên toàn hệ thống.',
    primary: ['Xử lý yêu cầu', 'support'],
    secondary: ['Đối soát giao dịch', 'transactions'],
    metrics: [
      [ClipboardCheck, formatNumber(openCases.length), 'Yêu cầu mở', 'Cần theo dõi', 'burgundy'],
      [CreditCard, formatNumber(systemCases.filter(item => item.type === 'refund' && item.status !== 'resolved').length), 'Hoàn tiền', 'Chờ đối soát', 'gold'],
      [Layers, formatNumber(systemCases.filter(item => ['operations', 'ai_quality'].includes(item.type) && item.status !== 'resolved').length), 'Lỗi & chất lượng AI', 'Toàn hệ thống', 'blue'],
      [MessageSquare, formatNumber(reviews.filter(item => !item.hidden).length), 'Feedback hiển thị', 'Cần giám sát', 'green']
    ],
    listTitle: 'Việc cần xử lý',
    listAction: ['Mở trung tâm hỗ trợ', 'support'],
    rows: openCases.slice(0, 5).map(item => ({
      title: item.title,
      subtitle: `${item.museum} · ${item.createdAt}`,
      badge: item.status === 'new' ? 'Mới' : 'Đang xử lý', status: 'pending'
    })),
    asideTitle: 'Chất lượng vận hành',
    asideText: 'Theo dõi lỗi ứng dụng, chất lượng câu trả lời AI và phản hồi không phù hợp.',
    asideAction: ['Xem lỗi & AI', 'operations']
  } : {
    eyebrow: currentMuseum.name,
    title: 'Bàn làm việc bảo tàng',
    description: 'Quản lý nội dung, bản đồ, tour, kiểm duyệt AI và doanh thu của bảo tàng mình.',
    primary: ['Quản lý hiện vật', 'artifacts'],
    secondary: ['Xưởng nội dung AI', 'ai_studio'],
    metrics: [
      [Layers, formatNumber(museumArtifacts.length), 'Hiện vật', 'Trong bảo tàng đã chọn', 'burgundy'],
      [QrCode, formatNumber(scans), 'Lượt quét mã', 'Từ các hiện vật', 'green'],
      [Sparkles, formatNumber(museumQueue.filter(item => item.status === 'pending').length), 'AI chờ kiểm tra', 'Trước khi xuất bản', 'gold'],
      [CreditCard, formatMoney(museumRevenue), 'Doanh thu mô phỏng', 'Chỉ bảo tàng này', 'blue']
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
    asideText: `${museumTours.length} tour và ${museumReviews.length} phản hồi tại bảo tàng. Kiểm tra nội dung AI trước khi xuất bản.`,
    asideAction: ['Mở kiểm duyệt AI', 'curation_queue']
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
