import React, { useState } from 'react';
import { backend } from '../../services/backend';
import { useData } from '../common/BusinessUI';
import { useApp } from '../../context/AppContext';
import {
  ArrowRight, Building2, CheckSquare, ClipboardCheck, CreditCard,
  Layers, MessageSquare, QrCode, ShieldCheck, Sparkles, Users
} from 'lucide-react';

const formatNumber = value => new Intl.NumberFormat('vi-VN').format(value ?? 0);
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
  const fallbackRevenueText = revenueData.busy ? '…' : revenueData.error ? 'Chưa tải được' : !currencyTotals.size ? 'Chưa phát sinh' : [...currencyTotals].map(([currency, value]) => `${formatNumber(value)} ${currency}`).join(' · ');
  const openCases = systemCases.filter(item => item.status !== 'resolved');

  // Connect to the Backend 25/11 Dashboard APIs
  const dashboardEndpoint = currentRole === 'administrator'
    ? 'dashboard/admin'
    : currentRole === 'systemStaff'
    ? 'dashboard/staff'
    : currentMuseum?.id
    ? `dashboard/museums/${currentMuseum.id}`
    : null;

  const dashboardState = useData(
    `dashboard-v2:${currentRole}:${currentMuseum?.id || 'all'}`,
    async signal => {
      if (!dashboardEndpoint) return null;
      try {
        return await backend(dashboardEndpoint, { signal });
      } catch {
        return null;
      }
    },
    null
  );
  const d = dashboardState.data;

  const config = currentRole === 'administrator' ? {
    eyebrow: 'Quản trị toàn hệ thống',
    title: 'Toàn cảnh vận hành SMGS',
    description: 'Theo dõi tài khoản, bảo tàng và giao dịch của hệ thống theo số liệu thời gian thực từ Backend.',
    primary: ['Quản lý người dùng', 'users'],
    secondary: ['Xem giao dịch', 'transactions'],
    metrics: [
      [Users, formatNumber(d?.overview?.totalUsers ?? users.length), 'Tài khoản', d?.overview ? `${d.overview.activeUsers} đang kích hoạt` : 'Toàn hệ thống', 'burgundy'],
      [Building2, formatNumber(d?.overview?.totalMuseums ?? museums.length), 'Bảo tàng', d?.overview ? `${d.overview.activeMuseums} đang mở cửa` : 'Đang kết nối', 'gold'],
      [CreditCard, d?.commerce?.revenueByCurrency?.length ? d.commerce.revenueByCurrency.map(r => `${formatNumber(r.netRevenue)} ${r.currency}`).join(' · ') : fallbackRevenueText, 'Doanh thu ròng', d?.commerce ? `${d.commerce.totalPaidOrders || 0} đơn thanh toán` : 'Theo báo cáo máy chủ · UTC', 'green'],
      [Sparkles, d?.engagement ? `${d.engagement.chatbotSupportRatePercent}%` : formatNumber(pending.length), d?.engagement ? 'Hỗ trợ AI thành công' : 'Chờ kiểm duyệt', d?.engagement ? `${d.engagement.supportedChatbotAnswers}/${d.engagement.totalChatbotQuestions} câu hỏi` : 'Nội dung chưa xuất bản', 'blue']
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
    asideText: d ? `Hệ thống có ${d.overview?.totalArtifacts || 0} hiện vật, ${d.engagement?.totalVisits || 0} lượt tham quan và ${d.supportAndFeedback?.totalComplaints || 0} khiếu nại đã tiếp nhận.` : `${pending.length} nội dung chờ duyệt và ${transactions.filter(item => item.status === 'pending').length} giao dịch đang xử lý.`,
    asideAction: ['Mở nhật ký hệ thống', 'audit']
  } : currentRole === 'systemStaff' ? {
    eyebrow: 'Vận hành toàn hệ thống',
    title: 'Hỗ trợ khách, giữ hệ thống thông suốt',
    description: 'Theo dõi khiếu nại, đối soát thanh toán, kiểm duyệt phản hồi và chất lượng câu trả lời AI toàn hệ thống.',
    primary: ['Xử lý yêu cầu', 'support'],
    secondary: ['Đối soát giao dịch', 'transactions'],
    metrics: [
      [ClipboardCheck, formatNumber(d?.complaints?.totalComplaints ?? openCases.length), 'Khiếu nại hệ thống', d?.complaints ? `${d.complaints.newComplaints} mới · ${d.complaints.inProgressComplaints} đang xử lý` : 'Cần theo dõi', 'burgundy'],
      [CreditCard, d?.paymentReconciliation ? `${formatNumber(d.paymentReconciliation.paidOrdersCount)} đơn` : fallbackRevenueText, 'Đối soát thanh toán', d?.paymentReconciliation ? `${d.paymentReconciliation.failedPaymentAttemptsCount} giao dịch lỗi` : 'Theo dõi đối soát', 'gold'],
      [Layers, d?.aiAndRecognitionQuality ? `${d.aiAndRecognitionQuality.chatbotSupportRatePercent}%` : '—', 'Chất lượng giải đáp AI', d?.aiAndRecognitionQuality ? `${d.aiAndRecognitionQuality.unsupportedChatbotAnswers} câu chưa có nguồn` : 'Tỷ lệ giải đáp', 'blue'],
      [MessageSquare, formatNumber(d?.feedbackModeration?.totalFeedbacks ?? reviews.filter(item => !item.hidden).length), 'Feedback kiểm duyệt', d?.feedbackModeration ? `${d.feedbackModeration.hiddenFeedbacks} bị ẩn vi phạm` : 'Cần giám sát', 'green']
    ],
    listTitle: d?.complaints?.recentPendingComplaints?.length ? 'Khiếu nại mới cần giải quyết' : 'Việc cần xử lý',
    listAction: ['Mở trung tâm hỗ trợ', 'support'],
    rows: d?.complaints?.recentPendingComplaints?.length ? d.complaints.recentPendingComplaints.map(item => ({
      title: item.subject,
      subtitle: `Khách: ${item.visitorId?.slice(0, 8)}... · ${item.createdAt?.slice(0, 10)}`,
      badge: item.status === 'new' ? 'Mới' : 'Đang xử lý',
      status: 'pending'
    })) : openCases.slice(0, 5).map(item => ({
      title: item.title,
      subtitle: `${item.museum} · ${item.createdAt}`,
      badge: item.status === 'new' ? 'Mới' : 'Đang xử lý', status: 'pending'
    })),
    asideTitle: 'Chất lượng vận hành & AI',
    asideText: d?.aiAndRecognitionQuality ? `Tỷ lệ nhận diện thị giác đạt ${d.aiAndRecognitionQuality.recognitionSuccessRatePercent}%. Đã xử lý ${d.complaints?.resolvedComplaints || 0}/${d.complaints?.totalComplaints || 0} khiếu nại của khách.` : 'Theo dõi lỗi ứng dụng, chất lượng câu trả lời AI và phản hồi không phù hợp.',
    asideAction: ['Xem lỗi & AI', 'operations']
  } : currentRole === 'curator' ? {
    eyebrow: `Giám tuyển · ${currentMuseum?.name || 'Bảo tàng'}`,
    title: 'Kiểm định nội dung di sản',
    description: 'Thẩm định thông tin hiện vật, bản dịch, thuyết minh và quiz AI trước khi công bố cho Khách tham quan.',
    primary: ['Mở hàng đợi thẩm định', 'curation_queue'],
    secondary: ['Tra cứu hiện vật', 'artifacts'],
    metrics: [
      [ClipboardCheck, formatNumber(d?.curationPipeline?.pendingArtifactContentsCount ?? museumQueue.filter(item => item.status === 'pending_review').length), 'Nội dung chờ duyệt', `${d?.curationPipeline?.publishedArtifactContentsCount || 0} đã duyệt`, 'burgundy'],
      [MessageSquare, formatNumber(d?.curationPipeline?.submittedTourVersionsCount ?? 0), 'Tour chờ thẩm định', `${d?.curationPipeline?.approvedTourVersionsCount || 0} tour đã xuất bản`, 'gold'],
      [CheckSquare, formatNumber(d?.curationPipeline?.publishedQuizzesCount ?? 0), 'Quiz đã xuất bản', `${d?.curationPipeline?.draftQuestionsCount || 0} câu hỏi nháp`, 'green'],
      [Layers, formatNumber(d?.catalog?.totalArtifacts ?? museumArtifacts.length), 'Hiện vật bảo tàng', `${d?.catalog?.artifactsWith3DModel || 0} hiện vật có 3D`, 'blue']
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
    asideText: d?.feedback ? `Bảo tàng ghi nhận ${d.feedback.totalFeedbacks} đánh giá với điểm trung bình ${d.feedback.averageOverallRating}/5★. Chỉ phê duyệt nội dung có nguồn đáng tin cậy.` : 'Chỉ phê duyệt nội dung có nguồn đáng tin cậy, thuật ngữ đúng và phù hợp với nhóm khách tham quan.',
    asideAction: ['Xem nhật ký thẩm định', 'audit']
  } : {
    eyebrow: currentMuseum?.name || 'Bảo tàng',
    title: 'Bàn làm việc bảo tàng',
    description: 'Quản lý nội dung, bản đồ, tour, kiểm duyệt AI và doanh thu của bảo tàng được phân công.',
    primary: ['Quản lý hiện vật', 'artifacts'],
    secondary: ['Xưởng nội dung AI', 'ai_studio'],
    metrics: [
      [Layers, formatNumber(d?.catalog?.totalArtifacts ?? museumArtifacts.length), 'Hiện vật', `${d?.catalog?.premiumArtifacts || 0} hiện vật cao cấp`, 'burgundy'],
      [QrCode, formatNumber(d?.visitsAndEngagement?.totalRecognitions ?? 0), 'Lượt nhận diện', `${d?.visitsAndEngagement?.totalVisits || 0} lượt tham quan`, 'green'],
      [Sparkles, formatNumber(d?.visitsAndEngagement?.totalChatbotQuestions ?? 0), 'Câu hỏi AI tại chỗ', `${d?.visitsAndEngagement?.supportedChatbotAnswers || 0} trả lời tốt`, 'gold'],
      [CreditCard, d?.commerce?.revenueByCurrency?.length ? d.commerce.revenueByCurrency.map(r => `${formatNumber(r.netRevenue)} ${r.currency}`).join(' · ') : fallbackRevenueText, 'Doanh thu bảo tàng', `${d?.commerce?.totalPaidOrders || 0} đơn đã thanh toán`, 'blue']
    ],
    listTitle: d?.visitsAndEngagement?.topScannedArtifacts?.length ? 'Top hiện vật quét nhiều nhất' : 'Hiện vật đang quản lý',
    listAction: ['Xem kho hiện vật', 'artifacts'],
    rows: d?.visitsAndEngagement?.topScannedArtifacts?.length ? d.visitsAndEngagement.topScannedArtifacts.slice(0, 5).map(item => ({
      title: item.artifactName,
      subtitle: `Mã hiện vật #${item.artifactId}`,
      badge: `${formatNumber(item.visits)} lượt quét`,
      status: 'approved'
    })) : museumArtifacts.slice(0, 5).map(item => ({
      title: item.name,
      subtitle: `${item.galleryName} · ${item.code}`,
      badge: item.status === 'published' ? 'Đã xuất bản' : 'Bản nháp',
      status: item.status === 'published' ? 'published' : 'draft'
    })),
    asideTitle: 'Tiếp tục công việc',
    asideText: d ? `Bảo tàng có ${d.catalog?.publishedIndoorMapsCount || 0} sơ đồ tầng đã xuất bản. Tỷ lệ khách hoàn tất lộ trình đạt ${d.visitsAndEngagement?.completionRatePercent || 0}%.` : `${museumTours.length} tour và ${museumReviews.length} phản hồi tại bảo tàng. Theo dõi phản hồi của Giám tuyển cho các nội dung đã đệ trình.`,
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
          <button type="button" className="btn btn-secondary" onClick={() => onNavigate(config.asideAction[1])}>
            {config.asideAction[0]} <ArrowRight size={16} />
          </button>
        </aside>
      </div>
    </div>
  );
}
