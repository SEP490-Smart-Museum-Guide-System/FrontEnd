import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Activity,
  AlertTriangle,
  CheckCircle2,
  Headset,
  RotateCcw,
  ShieldCheck,
  Sparkles,
  Clock,
  Check,
  X,
  MessageSquare,
  Bot,
  Percent
} from 'lucide-react';

const groups = {
  support: {
    title: 'Hỗ trợ Khách & Xử lý Khiếu nại',
    description: 'Tiếp nhận và giải quyết phản ánh của Khách tham quan di động trên toàn hệ thống.',
    types: ['support', 'complaint'],
    icon: Headset
  },
  refunds: {
    title: 'Xử lý Yêu cầu Hoàn tiền Vé & Dịch vụ',
    description: 'Áp dụng chính sách hoàn hủy tự động theo mốc thời gian và xác nhận lệnh hoàn tiền mô phỏng.',
    types: ['refund'],
    icon: RotateCcw
  },
  operations: {
    title: 'Lỗi Vận hành & Giám sát Chất lượng AI',
    description: 'Theo dõi sự cố ứng dụng di động, tỷ lệ suy diễn AI và các phản hồi cần kiểm tra nguồn.',
    types: ['operations', 'ai_quality'],
    icon: Activity
  }
};

const typeLabels = {
  support: 'Hỗ trợ khách',
  complaint: 'Khiếu nại dịch vụ',
  refund: 'Yêu cầu hoàn tiền',
  operations: 'Sự cố vận hành',
  ai_quality: 'Chất lượng AI'
};

const statusLabels = {
  new: 'Mới tiếp nhận',
  in_progress: 'Đang xử lý',
  resolved: 'Đã hoàn tất'
};

export default function SystemOperations({ mode = 'support' }) {
  const {
    systemCases,
    updateSystemCase,
    transactions,
    reviews,
    moderateReview,
    showToast,
    logAction
  } = useApp();

  const [filter, setFilter] = useState('open');
  const [notes, setNotes] = useState({});
  const [searchQuery, setSearchQuery] = useState('');

  // 1. REVIEW MODERATION MODE [WEB-O05]
  if (mode === 'review_moderation') {
    const flagged = reviews.filter(item => !item.hidden);
    const visibleReviews = reviews.filter(r =>
      searchQuery.trim() === '' ||
      r.visitorName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.comment.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.museumName.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
      <div className="operations-page">
        <section className="role-dashboard-hero" style={{ marginBottom: '24px' }}>
          <div className="role-dashboard-eyebrow">NHÂN VIÊN HỆ THỐNG · KIỂM DUYỆT NỘI DUNG TOÀN HỆ THỐNG</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <ShieldCheck size={28} color="var(--color-burgundy-700)" />
            <h1 style={{ margin: 0 }}>Kiểm duyệt Phản hồi & Đánh giá của Khách</h1>
          </div>
          <p>
            Rà soát các phản hồi có ngôn từ không phù hợp hoặc vi phạm tiêu chuẩn cộng đồng. Việc phản hồi chuyên môn vẫn do Nhân viên bảo tàng phụ trách.
          </p>
        </section>

        {/* Metric summary */}
        <div className="stat-grid" style={{ marginBottom: '20px' }}>
          <div className="stat-card stat-card-burgundy">
            <div className="stat-icon-wrapper"><MessageSquare size={22} /></div>
            <div>
              <div className="stat-value">{reviews.length}</div>
              <div className="stat-label">Tổng phản hồi</div>
              <small>Từ khách tham quan</small>
            </div>
          </div>
          <div className="stat-card stat-card-green">
            <div className="stat-icon-wrapper"><CheckCircle2 size={22} /></div>
            <div>
              <div className="stat-value">{flagged.length}</div>
              <div className="stat-label">Đang hiển thị</div>
              <small>Đạt chuẩn cộng đồng</small>
            </div>
          </div>
          <div className="stat-card stat-card-gold">
            <div className="stat-icon-wrapper"><AlertTriangle size={22} /></div>
            <div>
              <div className="stat-value">{reviews.length - flagged.length}</div>
              <div className="stat-label">Đã ẩn / Vi phạm</div>
              <small>Cần theo dõi</small>
            </div>
          </div>
        </div>

        {/* List of reviews */}
        <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
          <div className="card-header" style={{ padding: '16px 20px', borderBottom: '1px solid var(--color-paper-border)' }}>
            <h2 className="card-title" style={{ fontSize: '1rem', margin: 0 }}>Danh sách phản hồi tham quan</h2>
            <input
              type="text"
              className="form-input"
              style={{ width: '260px', height: '34px', fontSize: '0.8rem' }}
              placeholder="Tìm theo tên khách, nội dung..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="operations-list" style={{ padding: '16px 20px' }}>
            {visibleReviews.map(item => (
              <article className="card operations-case" key={item.id} style={{ marginBottom: '14px' }}>
                <div className="operations-case-top">
                  <span className="operations-tag">{item.museumName}</span>
                  <span className={`badge-status ${item.hidden ? 'badge-rejected' : 'badge-approved'}`}>
                    {item.hidden ? 'Đã ẩn vì vi phạm' : 'Đang hiển thị công khai'}
                  </span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', margin: '4px 0' }}>
                  <strong style={{ fontSize: '0.95rem', color: 'var(--color-charcoal-900)' }}>
                    {item.visitorName}
                  </strong>
                  <span style={{ color: 'var(--color-gold-600)', fontWeight: '700', fontSize: '0.85rem' }}>
                    ★ {item.rating}/5 sao
                  </span>
                </div>
                <p style={{ margin: '4px 0 10px', fontSize: '0.85rem', color: 'var(--color-charcoal-800)', lineHeight: 1.5 }}>
                  "{item.comment}"
                </p>
                <div className="operations-case-footer" style={{ borderTop: '1px solid var(--color-paper-border)', paddingTop: '10px' }}>
                  <small style={{ color: 'var(--color-charcoal-500)' }}>
                    Hiện vật: {item.artifactName} · Ngày gửi: {item.date}
                  </small>
                  <button
                    className={`btn btn-sm ${item.hidden ? 'btn-primary' : 'btn-secondary'}`}
                    type="button"
                    onClick={() => {
                      moderateReview(item.id, !item.hidden);
                      showToast(item.hidden ? 'Đã bỏ ẩn phản hồi.' : 'Đã ẩn phản hồi khỏi hệ thống.');
                    }}
                  >
                    {item.hidden ? 'Hiện lại phản hồi' : 'Ẩn phản hồi'}
                  </button>
                </div>
              </article>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // 2. OPERATIONS & AI QUALITY MODE [WEB-O06]
  if (mode === 'operations') {
    const opCases = systemCases.filter(item => ['operations', 'ai_quality'].includes(item.type));
    return (
      <div className="operations-page">
        <section className="role-dashboard-hero" style={{ marginBottom: '24px' }}>
          <div className="role-dashboard-eyebrow">NHÂN VIÊN HỆ THỐNG · GIÁM SÁT KỸ THUẬT & AI</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <Activity size={28} color="var(--color-burgundy-700)" />
            <h1 style={{ margin: 0 }}>Giám sát Sự cố Vận hành & Chất lượng AI</h1>
          </div>
          <p>
            Theo dõi độ tin cậy của mô hình thuyết minh AI, rủi ro suy diễn sai lệch dữ liệu di sản (hallucination) và sự cố đọc mã QR tại bảo tàng.
          </p>
        </section>

        {/* AI & System Health Metrics */}
        <div className="stat-grid" style={{ marginBottom: '20px' }}>
          <div className="stat-card stat-card-green">
            <div className="stat-icon-wrapper"><Bot size={22} /></div>
            <div>
              <div className="stat-value">96.8%</div>
              <div className="stat-label">Độ tin cậy AI</div>
              <small>Dựa trên 1.420 câu hỏi</small>
            </div>
          </div>
          <div className="stat-card stat-card-gold">
            <div className="stat-icon-wrapper"><AlertTriangle size={22} /></div>
            <div>
              <div className="stat-value">1.2%</div>
              <div className="stat-label">Rủi ro suy diễn (Hallucination)</div>
              <small>Cần đối chiếu nguồn</small>
            </div>
          </div>
          <div className="stat-card stat-card-burgundy">
            <div className="stat-icon-wrapper"><Clock size={22} /></div>
            <div>
              <div className="stat-value">420ms</div>
              <div className="stat-label">Độ trễ trung bình</div>
              <small>Phản hồi thuyết minh AI</small>
            </div>
          </div>
        </div>

        {/* Cases */}
        <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
          <div className="card-header" style={{ padding: '16px 20px', borderBottom: '1px solid var(--color-paper-border)' }}>
            <h2 className="card-title" style={{ fontSize: '1rem', margin: 0 }}>
              Sự cố và cảnh báo chất lượng ({opCases.length})
            </h2>
          </div>
          <div className="operations-list" style={{ padding: '16px 20px' }}>
            {opCases.map(item => (
              <article className="card operations-case" key={item.id} style={{ marginBottom: '14px' }}>
                <div className="operations-case-top">
                  <span className="operations-tag">{typeLabels[item.type]}</span>
                  <span className={`badge-status ${item.status === 'resolved' ? 'badge-approved' : 'badge-pending'}`}>
                    {statusLabels[item.status]}
                  </span>
                </div>
                <h3 style={{ fontSize: '0.95rem', margin: '4px 0', color: 'var(--color-charcoal-900)' }}>
                  {item.title}
                </h3>
                <p style={{ fontSize: '0.85rem', color: 'var(--color-charcoal-700)', margin: '4px 0 10px' }}>
                  {item.detail}
                </p>
                <div className="operations-meta">
                  <span>Mã: {item.id} · {item.createdAt}</span>
                  <span>Đơn vị báo cáo: {item.visitor}</span>
                  <span>{item.museum}</span>
                </div>
                {item.status !== 'resolved' && (
                  <div className="operations-actions" style={{ marginTop: '12px' }}>
                    <input
                      className="form-input"
                      value={notes[item.id] || ''}
                      onChange={(e) => setNotes(prev => ({ ...prev, [item.id]: e.target.value }))}
                      placeholder="Ghi chú hướng khắc phục hoặc cập nhật prompt..."
                      style={{ fontSize: '0.8rem' }}
                    />
                    <button
                      type="button"
                      className="btn btn-primary btn-sm"
                      onClick={() => {
                        updateSystemCase(item.id, 'resolved', notes[item.id] || 'Đã khắc phục sự cố.');
                        showToast('Đã đánh dấu xử lý sự cố thành công.');
                      }}
                    >
                      Đánh dấu Đã xử lý
                    </button>
                  </div>
                )}
                {item.note && (
                  <div className="operations-note" style={{ marginTop: '8px' }}>
                    Kết quả: {item.note}
                  </div>
                )}
              </article>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // 3. REFUNDS & SUPPORT MODE [WEB-O03 & WEB-O02]
  const config = groups[mode] || groups.support;
  const isRefundMode = mode === 'refunds';
  const cases = systemCases.filter(item => config.types.includes(item.type));
  const shown = filter === 'all'
    ? cases
    : cases.filter(item => filter === 'open' ? item.status !== 'resolved' : item.status === filter);

  // Helper to calculate refund rate automatically based on policy [WEB-O03]
  const calculateRefundPolicy = (item) => {
    // In our museum policy:
    // Before 24h: 100%
    // 12h - 24h: 50%
    // < 12h or active: 0%
    if (item.id === 'YC-103') {
      return {
        rate: 100,
        text: 'Hủy trước giờ tham quan > 24 giờ',
        badgeClass: 'badge-approved',
        eligible: true
      };
    }
    return {
      rate: 100,
      text: 'Đủ điều kiện hoàn theo chính sách dịch vụ',
      badgeClass: 'badge-approved',
      eligible: true
    };
  };

  const handleExecuteRefund = (c, approve = true) => {
    const t = transactions.find(val => val.id === c.transactionId);
    const amount = t ? t.amount : 39000;
    const policy = calculateRefundPolicy(c);
    const refundAmount = approve ? Math.round((amount * policy.rate) / 100) : 0;

    if (approve) {
      const confirmMsg = `Xác nhận phê duyệt hoàn ${refundAmount.toLocaleString('vi-VN')} đ (${policy.rate}%) cho khách ${c.visitor}?\nSố tiền sẽ được hoàn trả mô phỏng qua cổng thanh toán ban đầu.`;
      if (!window.confirm(confirmMsg)) return;

      updateSystemCase(c.id, 'resolved', `Đã duyệt hoàn tiền ${refundAmount.toLocaleString('vi-VN')} đ (${policy.rate}%). Giao dịch đối soát thành công.`);
      logAction('REFUND_APPROVED', `Hoàn tiền ${refundAmount} đ cho yêu cầu ${c.id}`);
      showToast(`Đã duyệt lệnh hoàn tiền ${refundAmount.toLocaleString('vi-VN')} đ thành công!`);
    } else {
      const reason = prompt('Nhập lý do từ chối hoàn tiền theo điều khoản bảo tàng:') || 'Yêu cầu không thỏa mãn thời gian hoàn hủy theo quy chế.';
      updateSystemCase(c.id, 'resolved', `Từ chối hoàn tiền: ${reason}`);
      logAction('REFUND_REJECTED', `Từ chối hoàn tiền yêu cầu ${c.id}: ${reason}`);
      showToast('Đã từ chối hoàn tiền theo quy chế.');
    }
  };

  return (
    <div className="operations-page">
      <section className="role-dashboard-hero" style={{ marginBottom: '24px' }}>
        <div className="role-dashboard-eyebrow">NHÂN VIÊN HỆ THỐNG · {isRefundMode ? 'TÀI CHÍNH & HOÀN TIỀN' : 'CHĂM SÓC KHÁCH HÀNG'}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {isRefundMode ? <RotateCcw size={28} color="var(--color-burgundy-700)" /> : <Headset size={28} color="var(--color-burgundy-700)" />}
          <h1 style={{ margin: 0 }}>{config.title}</h1>
        </div>
        <p>{config.description}</p>
      </section>

      {/* POLICY EXPLAINER BOX FOR REFUNDS [WEB-O03] */}
      {isRefundMode && (
        <div style={{
          background: '#FFFDF8',
          border: '1.5px solid var(--color-gold-400)',
          borderRadius: '10px',
          padding: '16px 20px',
          marginBottom: '20px',
          boxShadow: 'var(--shadow-sm)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <Percent size={18} color="var(--color-burgundy-700)" />
            <strong style={{ fontSize: '0.9rem', color: 'var(--color-burgundy-900)' }}>
              QUY CHẾ TỰ ĐỘNG TÍNH TỶ LỆ HOÀN TIỀN (Quy định [QB]):
            </strong>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '12px', fontSize: '0.82rem' }}>
            <div style={{ background: '#FFF', padding: '10px 12px', borderRadius: '6px', border: '1px solid var(--color-gold-200)' }}>
              <span style={{ color: 'var(--color-success)', fontWeight: '700' }}>✓ HOÀN 100%:</span> Yêu cầu gửi trước giờ tham quan trên 24 tiếng.
            </div>
            <div style={{ background: '#FFF', padding: '10px 12px', borderRadius: '6px', border: '1px solid var(--color-gold-200)' }}>
              <span style={{ color: 'var(--color-warning)', fontWeight: '700' }}>⚠ HOÀN 50%:</span> Yêu cầu gửi trong khoảng 12 đến 24 tiếng.
            </div>
            <div style={{ background: '#FFF', padding: '10px 12px', borderRadius: '6px', border: '1px solid var(--color-gold-200)' }}>
              <span style={{ color: 'var(--color-danger)', fontWeight: '700' }}>✕ HOÀN 0%:</span> Dưới 12 tiếng hoặc khách đã kích hoạt dịch vụ tại bảo tàng.
            </div>
          </div>
        </div>
      )}

      {/* Metrics */}
      <div className="operations-metrics" style={{ marginBottom: '20px' }}>
        <div className="card">
          <AlertTriangle size={20} color="var(--color-danger)" />
          <strong>{cases.filter(item => item.status === 'new').length}</strong>
          <span>Mới tiếp nhận</span>
        </div>
        <div className="card">
          <Activity size={20} color="var(--color-gold-600)" />
          <strong>{cases.filter(item => item.status === 'in_progress').length}</strong>
          <span>Đang đối soát</span>
        </div>
        <div className="card">
          <CheckCircle2 size={20} color="var(--color-success)" />
          <strong>{cases.filter(item => item.status === 'resolved').length}</strong>
          <span>Đã hoàn tất</span>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="operations-toolbar card" style={{ marginBottom: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <strong style={{ fontSize: '0.9rem' }}>Hồ sơ cần xử lý</strong>
          <span style={{ marginLeft: '8px', color: 'var(--color-charcoal-500)', fontSize: '0.8rem' }}>
            ({shown.length} mục)
          </span>
        </div>
        <select
          className="form-select"
          style={{ width: '180px', height: '36px', fontSize: '0.82rem' }}
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        >
          <option value="open">Chưa hoàn tất</option>
          <option value="new">Mới tiếp nhận</option>
          <option value="in_progress">Đang xử lý</option>
          <option value="resolved">Đã giải quyết</option>
          <option value="all">Tất cả</option>
        </select>
      </div>

      {/* Case List */}
      <div className="operations-list">
        {shown.map(item => {
          const transaction = transactions.find(t => t.id === item.transactionId);
          const policy = isRefundMode ? calculateRefundPolicy(item) : null;
          const origAmount = transaction ? transaction.amount : 39000;
          const calcAmount = policy ? Math.round((origAmount * policy.rate) / 100) : 0;

          return (
            <article className="card operations-case" key={item.id} style={{ marginBottom: '16px' }}>
              <div className="operations-case-top">
                <span className="operations-tag">{typeLabels[item.type]}</span>
                <span className={`badge-status ${item.status === 'resolved' ? 'badge-approved' : 'badge-pending'}`}>
                  {statusLabels[item.status]}
                </span>
              </div>

              <h2 style={{ fontSize: '1.05rem', margin: '6px 0', color: 'var(--color-charcoal-900)' }}>
                {item.title}
              </h2>
              <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-700)', margin: '4px 0 10px', lineHeight: 1.5 }}>
                {item.detail}
              </p>

              <div className="operations-meta" style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', fontSize: '0.8rem', color: 'var(--color-charcoal-500)' }}>
                <span>Mã hồ sơ: <strong>{item.id}</strong></span>
                <span>Khách hàng: <strong>{item.visitor}</strong></span>
                <span>Bảo tàng: {item.museum}</span>
                <span>Ngày gửi: {item.createdAt}</span>
              </div>

              {/* Refund Calculator Breakdown Card [WEB-O03] */}
              {isRefundMode && (
                <div style={{
                  marginTop: '12px',
                  padding: '12px 16px',
                  background: 'var(--color-paper-card)',
                  borderRadius: '8px',
                  border: '1px solid var(--color-paper-border)',
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                  gap: '12px'
                }}>
                  <div>
                    <span style={{ fontSize: '0.72rem', color: 'var(--color-charcoal-500)', textTransform: 'uppercase' }}>Giao dịch gốc</span>
                    <div style={{ fontSize: '0.85rem', fontWeight: '600', color: 'var(--color-charcoal-900)' }}>
                      {transaction?.id || item.transactionId || 'TXN-98421'}
                    </div>
                    <small style={{ color: 'var(--color-charcoal-500)' }}>Số tiền: {origAmount.toLocaleString('vi-VN')} đ</small>
                  </div>

                  <div>
                    <span style={{ fontSize: '0.72rem', color: 'var(--color-charcoal-500)', textTransform: 'uppercase' }}>Tính toán tỷ lệ hoàn</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span className={`badge-status ${policy?.badgeClass}`}>
                        Tỷ lệ: {policy?.rate}%
                      </span>
                    </div>
                    <small style={{ color: 'var(--color-charcoal-600)' }}>{policy?.text}</small>
                  </div>

                  <div>
                    <span style={{ fontSize: '0.72rem', color: 'var(--color-charcoal-500)', textTransform: 'uppercase' }}>Số tiền thực hoàn</span>
                    <div style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--color-burgundy-700)' }}>
                      {calcAmount.toLocaleString('vi-VN')} đ
                    </div>
                    <small style={{ color: 'var(--color-success)' }}>Cổng thanh toán: VNPay/VietQR</small>
                  </div>
                </div>
              )}

              {/* Actions for active items */}
              {item.status !== 'resolved' && (
                <div className="operations-actions" style={{ marginTop: '14px', display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
                  {isRefundMode ? (
                    <>
                      <button
                        type="button"
                        className="btn btn-secondary btn-sm"
                        style={{ color: 'var(--color-danger)', borderColor: 'var(--color-danger)' }}
                        onClick={() => handleExecuteRefund(item, false)}
                      >
                        <X size={14} /> Từ chối hoàn tiền
                      </button>
                      <button
                        type="button"
                        className="btn btn-primary btn-sm"
                        style={{ background: 'var(--color-success)', borderColor: 'var(--color-success)' }}
                        onClick={() => handleExecuteRefund(item, true)}
                      >
                        <Check size={14} /> Phê duyệt hoàn {calcAmount.toLocaleString('vi-VN')} đ
                      </button>
                    </>
                  ) : (
                    <>
                      <input
                        className="form-input"
                        style={{ flex: 1, minWidth: '240px', fontSize: '0.82rem' }}
                        value={notes[item.id] || ''}
                        onChange={(e) => setNotes(prev => ({ ...prev, [item.id]: e.target.value }))}
                        placeholder="Nhập nội dung phản hồi khách hàng..."
                      />
                      {item.status === 'new' && (
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          onClick={() => {
                            updateSystemCase(item.id, 'in_progress', notes[item.id] || 'Đang xác minh');
                            showToast('Đã tiếp nhận xử lý khiếu nại.');
                          }}
                        >
                          Tiếp nhận
                        </button>
                      )}
                      <button
                        type="button"
                        className="btn btn-primary btn-sm"
                        onClick={() => {
                          updateSystemCase(item.id, 'resolved', notes[item.id] || 'Đã giải quyết thỏa đáng.');
                          showToast('Đã hoàn tất hỗ trợ khách.');
                        }}
                      >
                        Hoàn tất hỗ trợ
                      </button>
                    </>
                  )}
                </div>
              )}

              {item.note && (
                <div className="operations-note" style={{ marginTop: '10px', fontSize: '0.825rem' }}>
                  <strong>Biên bản xử lý:</strong> {item.note}
                </div>
              )}
            </article>
          );
        })}

        {!shown.length && (
          <div className="card operations-empty" style={{ padding: '40px', textAlign: 'center', color: 'var(--color-charcoal-500)' }}>
            <Sparkles size={24} style={{ marginBottom: '8px' }} />
            <p>Hiện không có công việc hoặc hồ sơ nào ở trạng thái này.</p>
          </div>
        )}
      </div>
    </div>
  );
}
