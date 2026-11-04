import React, { useState } from 'react';
import { backend } from '../../services/backend';
import { useData } from '../common/BusinessUI';
import { useApp } from '../../context/AppContext';
import {
  ArrowRight, Building2, CheckSquare, ClipboardCheck, CreditCard,
  Layers, MessageSquare, QrCode, ShieldCheck, Sparkles, Users
} from 'lucide-react';

const formatNumber = value => new Intl.NumberFormat('vi-VN').format(value);
const formatMoney = value => `${formatNumber(value)} đ`;

export default function RoleDashboard({ onNavigate }) {
  const {
    currentRole, currentMuseum, artifacts, museums, tours,
    curationQueue, transactions, users, reviews, systemCases
  } = useApp();

  const museumQueue = curationQueue.filter(item => artifacts.find(artifact => artifact.id === item.targetArtifactId)?.museumId === currentMuseum?.id);
  const pending = curationQueue.filter(item => item.status === 'pending_review');
  const museumArtifacts = artifacts.filter(item => item.museumId === currentMuseum?.id);
  const museumTours = tours.filter(item => item.museumId === currentMuseum?.id);
  const museumReviews = reviews.filter(item => item.museumName === currentMuseum?.name);
  const [period] = useState(() => { const end = new Date(); return { from: new Date(Date.UTC(end.getUTCFullYear(), end.getUTCMonth(), 1)).toISOString(), to: end.toISOString() }; });
  const revenueIds = currentRole === 'administrator' ? museums.filter(m => m.isActive).map(m => m.id) : currentRole === 'museumStaff' && currentMuseum ? [currentMuseum.id] : [];
  const revenueData = useData(`dashboard-revenue:${currentRole}:${revenueIds.join(',')}`, async signal => (await Promise.all(revenueIds.map(id => backend(`commerce/museums/${id}/revenue?from=${encodeURIComponent(period.from)}&to=${encodeURIComponent(period.to)}`, { signal })))).flat(), []);
  const currencyTotals = new Map();
  for (const row of revenueData.data) currencyTotals.set(row.currency, (currencyTotals.get(row.currency) || 0) + row.revenue);
  const revenueText = revenueData.busy ? '…' : revenueData.error ? 'Chưa tải được' : !currencyTotals.size ? 'Chưa phát sinh' : [...currencyTotals].map(([currency, value]) => `${formatNumber(value)} ${currency}`).join(' · ');
  const openCases = systemCases.filter(item => item.status !== 'resolved');

  const config = currentRole === 'administrator' ? {
    eyebrow: 'Quản trị toàn hệ thống',
    title: 'Toàn cảnh vận hành SMGS',
    description: 'Theo dõi tài khoản, bảo tàng và giao dịch của hệ thống trong một nơi.',
    primary: ['Quản lý người dùng', 'users'],
    secondary: ['Xem giao dịch', 'transactions'],
    metrics: [
      [Users, formatNumber(users.length), 'Tài khoản', 'Toàn hệ thống', 'burgundy'],
      [Building2, formatNumber(museums.length), 'Bảo tàng', 'Đang kết nối', 'gold'],
      [CreditCard, revenueText, 'Doanh thu tháng này', 'Theo báo cáo máy chủ · UTC', 'green'],
      [ClipboardCheck, formatNumber(pending.length), 'Chờ kiểm duyệt', 'Nội dung chưa xuất bản', 'blue']
    ],
    listTitle: 'Giao dịch gần đây',
    listAction: ['Xem tất cả giao dịch', 'transactions'],
    rows: transactions.slice(0, 5).map(item => ({
      title: item.packageName,
      subtitle: `${item.userName} · ${item.timestamp}`,
      badge: `${formatNumber(item.amount)} ${item.currency || ''}`,
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
      [CreditCard, '—', 'Hoàn tiền', 'Chưa có API', 'gold'],
      [Layers, '—', 'Lỗi & chất lượng AI', 'Chưa có API sự cố', 'blue'],
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
  } : currentRole === 'curator' ? {
    eyebrow: `Giám tuyển · ${currentMuseum?.name}`,
    title: 'Kiểm định nội dung di sản',
    description: 'Thẩm định thông tin hiện vật, bản dịch, thuyết minh và quiz AI trước khi công bố cho Khách tham quan.',
    primary: ['Mở hàng đợi thẩm định', 'curation_queue'],
    secondary: ['Tra cứu hiện vật', 'artifacts'],
    metrics: [
      [ClipboardCheck, formatNumber(museumQueue.filter(item => item.status === 'pending_review').length), 'Chờ thẩm định', 'Cần quyết định', 'burgundy'],
      [MessageSquare, formatNumber(museumQueue.filter(item => item.status === 'draft').length), 'Chờ hiệu đính', 'Đã phản hồi', 'gold'],
      [CheckSquare, formatNumber(museumQueue.filter(item => item.status === 'published').length), 'Đã xuất bản', 'Qua kiểm định', 'green'],
      [Layers, formatNumber(museumArtifacts.length), 'Hiện vật tham chiếu', 'Theo bảo tàng phân công', 'blue']
    ],
    listTitle: 'Nội dung ưu tiên',
    listAction: ['Mở hàng đợi', 'curation_queue'],
    rows: museumQueue.slice(0, 5).map(item => ({
      title: item.title,
      subtitle: `${item.targetArtifactName} · ${item.submittedDate}`,
      badge: item.status === 'pending_review' ? 'Chờ thẩm định' : item.status === 'published' ? 'Đã xuất bản' : item.status === 'draft' ? 'Chờ hiệu đính' : 'Từ chối',
      status: item.status
    })),
    asideTitle: 'Nguyên tắc thẩm định',
    asideText: 'Chỉ phê duyệt nội dung có nguồn đáng tin cậy, thuật ngữ đúng và phù hợp với nhóm khách tham quan.',
    asideAction: ['Xem nhật ký thẩm định', 'audit']
  } : {
    eyebrow: currentMuseum?.name,
    title: 'Bàn làm việc bảo tàng',
    description: 'Quản lý nội dung, bản đồ, tour, kiểm duyệt AI và doanh thu của bảo tàng mình.',
    primary: ['Quản lý hiện vật', 'artifacts'],
    secondary: ['Xưởng nội dung AI', 'ai_studio'],
    metrics: [
      [Layers, formatNumber(museumArtifacts.length), 'Hiện vật', 'Trong bảo tàng đã chọn', 'burgundy'],
      [QrCode, '—', 'Lượt quét mã', 'Từ các hiện vật', 'green'],
      [Sparkles, formatNumber(museumQueue.filter(item => item.status === 'pending_review').length), 'AI chờ kiểm tra', 'Trước khi xuất bản', 'gold'],
      [CreditCard, revenueText, 'Doanh thu tháng này', 'Bảo tàng đã chọn · UTC', 'blue']
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
    asideText: `${museumTours.length} tour và ${museumReviews.length} phản hồi tại bảo tàng. Theo dõi phản hồi của Giám tuyển cho các nội dung đã đệ trình.`,
    asideAction: ['Xem trạng thái đệ trình', 'submission_status']
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
