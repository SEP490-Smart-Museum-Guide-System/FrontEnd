import React from 'react';
import { useApp } from '../../context/AppContext';
import {
  Layers,
  Users,
  DollarSign,
  QrCode,
  Sparkles,
  TrendingUp,
  Award,
  Clock,
  ArrowUpRight,
  ShieldCheck,
  CheckCircle,
  Landmark
} from 'lucide-react';

export default function AdminDashboard({ onNavigate }) {
  const {
    currentRole,
    artifacts,
    museums,
    tours,
    curationQueue,
    transactions,
    reviews,
    auditLogs
  } = useApp();

  const totalVisitorsToday = museums.reduce((acc, curr) => acc + (curr.visitorCountToday || 0), 0);
  const totalScans = artifacts.reduce((acc, curr) => acc + (curr.scansCount || 0), 0);
  const totalRevenue = transactions
    .filter(t => t.status === 'completed')
    .reduce((acc, curr) => acc + curr.amount, 0);

  const pendingCuration = curationQueue.filter(c => c.status === 'pending').length;

  return (
    <div>
      {/* Welcome Banner */}
      <div className="card" style={{
        padding: '28px 32px',
        marginBottom: '28px',
        background: 'linear-gradient(135deg, #65121B 0%, #8B1E28 50%, #460C12 100%)',
        color: '#FFFFFF',
        border: 'none',
        boxShadow: 'var(--shadow-burgundy)'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '20px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
              <span style={{ background: 'rgba(212, 175, 55, 0.2)', border: '1px solid rgba(212, 175, 55, 0.4)', color: 'var(--color-gold-300)', padding: '3px 10px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: '700', textTransform: 'uppercase' }}>
                Hệ Thống Quản Trị Trung Tâm SMGS
              </span>
            </div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: '800', color: '#FFFFFF', letterSpacing: '-0.01em' }} className="font-serif">
              Xin chào, {currentRole === 'administrator' ? 'Vũ Hải Đăng (Tổng Quản Trị)' : currentRole === 'curator' ? 'TS. Trần Văn Phong (Trưởng Ban Giám Định)' : 'Nguyễn Mai Anh (Nhân Viên Nghiệp Vụ)'}
            </h1>
            <p style={{ fontSize: '0.9375rem', color: '#F3DC91', opacity: 0.9, marginTop: '6px' }}>
              Hôm nay có <strong>{totalVisitorsToday.toLocaleString()}</strong> lượt khách tham quan bảo tàng và <strong>{totalScans.toLocaleString()}</strong> lượt tương tác hiện vật số hóa.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <button
              type="button"
              onClick={() => onNavigate('ai_studio')}
              className="btn btn-gold"
              style={{ padding: '10px 18px', fontSize: '0.875rem' }}
            >
              <Sparkles size={16} /> Mở AI Studio
            </button>
            <button
              type="button"
              onClick={() => onNavigate('artifacts')}
              className="btn"
              style={{ background: 'rgba(255, 255, 255, 0.15)', color: '#FFF', border: '1px solid rgba(255, 255, 255, 0.3)' }}
            >
              <Layers size={16} /> Quản lý Hiện vật
            </button>
          </div>
        </div>
      </div>

      {/* KPI Stats Grid */}
      <div className="stat-grid">
        <div className="stat-card stat-card-burgundy">
          <div className="stat-icon-wrapper">
            <Layers size={26} />
          </div>
          <div style={{ flex: 1 }}>
            <div className="stat-value">{artifacts.length}</div>
            <div className="stat-label">Hiện vật số hóa</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--color-burgundy-700)', fontWeight: '600', marginTop: '4px' }}>
              ⭐ {artifacts.filter(a => a.isNationalTreasure).length} Bảo vật Quốc gia
            </div>
          </div>
        </div>

        <div className="stat-card stat-card-blue">
          <div className="stat-icon-wrapper">
            <Users size={26} />
          </div>
          <div style={{ flex: 1 }}>
            <div className="stat-value">{totalVisitorsToday.toLocaleString()}</div>
            <div className="stat-label">Lượt khách hôm nay</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--color-info)', fontWeight: '600', marginTop: '4px' }}>
              ↑ 18.5% so với tuần trước
            </div>
          </div>
        </div>

        <div className="stat-card stat-card-gold">
          <div className="stat-icon-wrapper">
            <DollarSign size={26} />
          </div>
          <div style={{ flex: 1 }}>
            <div className="stat-value">{totalRevenue.toLocaleString()} đ</div>
            <div className="stat-label">Doanh thu Digital Pass</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--color-gold-700)', fontWeight: '600', marginTop: '4px' }}>
              Tổng 3 gói dịch vụ số
            </div>
          </div>
        </div>

        <div className="stat-card stat-card-green">
          <div className="stat-icon-wrapper">
            <QrCode size={26} />
          </div>
          <div style={{ flex: 1 }}>
            <div className="stat-value">{totalScans.toLocaleString()}</div>
            <div className="stat-label">Lượt quét QR ghi nhận</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--color-success)', fontWeight: '600', marginTop: '4px' }}>
              Tỉ lệ đạt Quiz: 86.4%
            </div>
          </div>
        </div>
      </div>

      {/* Two Column Layout: Charts & Live Activities */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 380px', gap: '28px', marginBottom: '28px' }}>
        {/* Left Column: Top Artifacts & Spatial Statistics */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          {/* Top Scanned Artifacts */}
          <div className="card">
            <div className="card-header">
              <div className="card-title">
                <Award size={18} color="var(--color-burgundy-700)" />
                <span>Top Hiện Vật Được Tương Tác & Quét QR Nhiều Nhất</span>
              </div>
              <button type="button" onClick={() => onNavigate('artifacts')} className="btn btn-secondary btn-sm">
                Xem tất cả
              </button>
            </div>

            <div className="card-body" style={{ padding: '16px 24px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {artifacts.slice(0, 4).map((art, idx) => (
                  <div key={art.id} style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <div style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      background: idx === 0 ? 'var(--color-gold-500)' : idx === 1 ? 'var(--color-paper-border)' : 'var(--color-paper-accent)',
                      color: idx === 0 ? '#1A1810' : 'var(--color-charcoal-800)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: '700',
                      fontSize: '0.8125rem',
                      flexShrink: 0
                    }}>
                      {idx + 1}
                    </div>

                    <div style={{ width: '46px', height: '46px', borderRadius: '8px', overflow: 'hidden', flexShrink: 0, background: '#1A1F26' }}>
                      <img
                        src={art.image || '/assets/images/ngoc-lu-web.jpg'}
                        alt=""
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        onError={(e) => { e.target.src = '/assets/images/national-museum-web.jpg'; }}
                      />
                    </div>

                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <strong style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-900)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {art.name}
                        </strong>
                        {art.isNationalTreasure && (
                          <span className="badge-status badge-treasure" style={{ fontSize: '0.65rem' }}>Bảo vật</span>
                        )}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                        {art.galleryName} • Tỉ lệ đỗ Quiz: {art.quizPassRate}
                      </div>
                    </div>

                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontWeight: '700', fontSize: '0.9375rem', color: 'var(--color-burgundy-800)' }}>
                        {art.scansCount.toLocaleString()}
                      </div>
                      <div style={{ fontSize: '0.7rem', color: 'var(--color-charcoal-500)' }}>lượt quét</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Museum Distribution Breakdown */}
          <div className="card">
            <div className="card-header">
              <div className="card-title">
                <Landmark size={18} color="var(--color-burgundy-700)" />
                <span>Phân Bổ Khách Tham Quan Theo Cụm Bảo Tàng</span>
              </div>
            </div>
            <div className="card-body">
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {museums.map(m => {
                  const percent = Math.round((m.visitorCountToday / (totalVisitorsToday || 1)) * 100);
                  return (
                    <div key={m.id}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8125rem', marginBottom: '6px' }}>
                        <span style={{ fontWeight: '600', color: 'var(--color-charcoal-900)' }}>{m.name}</span>
                        <span style={{ color: 'var(--color-charcoal-600)' }}>{m.visitorCountToday.toLocaleString()} khách ({percent}%)</span>
                      </div>
                      <div style={{ height: '8px', background: '#E2E8F0', borderRadius: '4px', overflow: 'hidden' }}>
                        <div style={{ width: `${percent}%`, height: '100%', background: 'linear-gradient(90deg, var(--color-burgundy-700), var(--color-gold-500))', borderRadius: '4px' }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Pending Actions & Audit Stream */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          {/* Curation Queue Alert Box */}
          <div className="card" style={{ padding: '20px', borderLeft: '4px solid var(--color-gold-500)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <ShieldCheck size={18} color="var(--color-gold-600)" />
                <h4 style={{ fontSize: '0.9375rem', fontWeight: '700' }}>Hàng Đợi Kiểm Duyệt</h4>
              </div>
              <span className="badge-status badge-pending">{pendingCuration} mục chờ duyệt</span>
            </div>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)', lineHeight: '1.5', marginBottom: '14px' }}>
              Có bài thuyết minh AI và bộ câu hỏi trắc nghiệm mới đệ trình đang chờ hội đồng thẩm định.
            </p>
            <button
              type="button"
              onClick={() => onNavigate('curation_queue')}
              className="btn btn-gold btn-sm"
              style={{ width: '100%' }}
            >
              Mở Trung Tâm Kiểm Duyệt
            </button>
          </div>

          {/* Recent System Audit Logs */}
          <div className="card" style={{ flex: 1 }}>
            <div className="card-header">
              <div className="card-title">
                <Clock size={16} color="var(--color-charcoal-700)" />
                <span>Nhật Ký Nghiệp Vụ Gần Đây</span>
              </div>
            </div>
            <div className="card-body" style={{ padding: '16px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                {auditLogs.slice(0, 4).map(log => (
                  <div key={log.id} style={{ fontSize: '0.8125rem', borderBottom: '1px solid #F1F5F9', paddingBottom: '10px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--color-charcoal-500)', fontSize: '0.7rem', marginBottom: '2px' }}>
                      <span>{log.role}</span>
                      <span>{log.timestamp}</span>
                    </div>
                    <div style={{ color: 'var(--color-charcoal-900)', fontWeight: '500', lineHeight: '1.4' }}>
                      {log.details}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
