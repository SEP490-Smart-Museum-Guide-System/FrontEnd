import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  CreditCard,
  DollarSign,
  TrendingUp,
  RefreshCcw,
  CheckCircle,
  Search,
  Tag,
  ShieldCheck
} from 'lucide-react';

export default function TransactionManager() {
  const { passPackages, transactions, refundTransaction } = useApp();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  const filteredTxns = transactions.filter(t => {
    if (statusFilter !== 'all' && t.status !== statusFilter) return false;
    if (searchTerm.trim()) {
      const q = searchTerm.toLowerCase();
      return t.id.toLowerCase().includes(q) || t.userEmail.toLowerCase().includes(q) || t.userName.toLowerCase().includes(q);
    }
    return true;
  });

  const totalRevenue = transactions
    .filter(t => t.status === 'completed')
    .reduce((acc, curr) => acc + curr.amount, 0);

  const completedCount = transactions.filter(t => t.status === 'completed').length;
  const refundedCount = transactions.filter(t => t.status === 'refunded').length;

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Gói Dịch Vụ Thuyết Minh Số & Nhật Ký Giao Dịch
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Quản lý các gói hướng dẫn số, theo dõi doanh thu và đối soát hoàn tiền
          </p>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="stat-grid" style={{ marginBottom: '28px' }}>
        <div className="stat-card stat-card-burgundy">
          <div className="stat-icon-wrapper">
            <DollarSign size={24} />
          </div>
          <div>
            <div className="stat-value">{totalRevenue.toLocaleString()} đ</div>
            <div className="stat-label">Tổng doanh thu gói hướng dẫn số</div>
          </div>
        </div>

        <div className="stat-card stat-card-green">
          <div className="stat-icon-wrapper">
            <CheckCircle size={24} />
          </div>
          <div>
            <div className="stat-value">{completedCount}</div>
            <div className="stat-label">Giao dịch thành công</div>
          </div>
        </div>

        <div className="stat-card stat-card-gold">
          <div className="stat-icon-wrapper">
            <TrendingUp size={24} />
          </div>
          <div>
            <div className="stat-value">2.570</div>
            <div className="stat-label">Lượt kích hoạt đang sử dụng</div>
          </div>
        </div>
      </div>

      {/* Pass Packages Grid */}
      <h3 style={{ fontSize: '1.125rem', fontWeight: '700', marginBottom: '16px', color: 'var(--color-charcoal-900)' }}>
        Danh Mục Gói Dịch Vụ Số
      </h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px', marginBottom: '36px' }}>
        {passPackages.map(pkg => (
          <div key={pkg.id} className="card" style={{ padding: '20px', borderTop: '4px solid var(--color-burgundy-700)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
              <h4 style={{ fontSize: '1.05rem', fontWeight: '700', color: 'var(--color-charcoal-950)' }}>
                {pkg.name}
              </h4>
              <span className="badge-status badge-active">Kích hoạt</span>
            </div>

            <div style={{ fontSize: '1.5rem', fontWeight: '700', color: 'var(--color-burgundy-800)', marginBottom: '12px' }}>
              {pkg.price.toLocaleString()} đ <span style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', fontWeight: 'normal' }}>/ {pkg.durationDays} ngày</span>
            </div>

            <ul style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', paddingLeft: '18px', lineHeight: '1.7', marginBottom: '16px' }}>
              {pkg.features.map((f, fIdx) => (
                <li key={fIdx}>{f}</li>
              ))}
            </ul>

            <div style={{ borderTop: '1px solid var(--color-paper-border)', paddingTop: '12px', fontSize: '0.75rem', color: 'var(--color-charcoal-500)', display: 'flex', justifyContent: 'space-between' }}>
              <span>Đang có {pkg.activePassesCount} lượt kích hoạt</span>
              <span style={{ color: 'var(--color-burgundy-700)', fontWeight: '600' }}>Cập nhật giá</span>
            </div>
          </div>
        ))}
      </div>

      {/* Transaction History Section */}
      <div className="card">
        <div className="card-header" style={{ background: '#FAF7F2' }}>
          <div className="card-title">
            <CreditCard size={18} color="var(--color-burgundy-700)" />
            <span>Lịch Sử Giao Dịch Thời Gian Thực</span>
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <input
              type="text"
              className="form-input"
              style={{ width: '240px', padding: '6px 12px', fontSize: '0.8125rem' }}
              placeholder="Tìm mã giao dịch, email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <select
              className="form-select"
              style={{ width: 'auto', padding: '6px 12px', fontSize: '0.8125rem' }}
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="completed">Thành công</option>
              <option value="refunded">Đã hoàn tiền</option>
            </select>
          </div>
        </div>

        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã GD</th>
                <th>Khách hàng</th>
                <th>Gói dịch vụ</th>
                <th>Số tiền</th>
                <th>Cổng thanh toán</th>
                <th>Thời gian</th>
                <th>Trạng thái</th>
                <th style={{ textAlign: 'right' }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredTxns.map(t => (
                <tr key={t.id}>
                  <td>
                    <code style={{ fontWeight: '700', color: 'var(--color-burgundy-800)' }}>{t.id}</code>
                  </td>
                  <td>
                    <div style={{ fontWeight: '600', color: 'var(--color-charcoal-900)' }}>{t.userName}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>{t.userEmail}</div>
                  </td>
                  <td>
                    <span style={{ fontSize: '0.8125rem', fontWeight: '500' }}>{t.packageName}</span>
                  </td>
                  <td>
                    <strong style={{ color: 'var(--color-charcoal-950)' }}>{t.amount.toLocaleString()} đ</strong>
                  </td>
                  <td>
                    <span style={{ background: '#F1F5F9', padding: '3px 8px', borderRadius: '4px', fontSize: '0.75rem', fontWeight: '600' }}>
                      {t.method}
                    </span>
                  </td>
                  <td>
                    <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>{t.timestamp}</span>
                  </td>
                  <td>
                    <span className={`badge-status badge-${t.status}`}>
                      {t.status === 'completed' ? 'Thành công' : 'Đã hoàn tiền'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    {t.status === 'completed' && (
                      <button
                        type="button"
                        onClick={() => {
                          if (window.confirm(`Xác nhận hoàn tiền cho giao dịch ${t.id} (${t.amount.toLocaleString()} đ)?`)) {
                            refundTransaction(t.id);
                          }
                        }}
                        className="btn btn-secondary btn-sm"
                        style={{ color: 'var(--color-danger)', fontSize: '0.75rem' }}
                      >
                        <RefreshCcw size={12} /> Hoàn tiền
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
