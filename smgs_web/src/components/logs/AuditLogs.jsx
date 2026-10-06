import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  ShieldAlert,
  Clock,
  User,
  Settings,
  Key,
  Server,
  Save,
  CheckCircle,
  Database
} from 'lucide-react';

export default function AuditLogs() {
  const { auditLogs, showToast, logAction } = useApp();
  const [activeTab, setActiveTab] = useState('logs'); // 'logs' | 'settings'

  const [apiConfig, setApiConfig] = useState({
    geminiApiKey: 'AIzaSyD-•••••••••••••••••••••••••••••',
    aiModel: 'gemini-2.0-flash',
    ttsVoice: 'vi-VN-Standard-A (Nữ miền Bắc chuẩn)',
    paymentWebhook: 'https://api.smgs.vn/v1/payment/webhook',
    arModelStorage: 'Cloudflare R2 / AWS S3 Standard'
  });

  const handleSaveConfig = (e) => {
    e.preventDefault();
    logAction('SYSTEM_CONFIG_UPDATE', 'Cập nhật tham số cấu hình kết nối AI & Cổng thanh toán.');
    showToast('Đã lưu cấu hình hệ thống thành công!');
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Nhật Ký Kiểm Toán & Cài Đặt Hệ Thống
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Lưu vết toàn bộ thao tác thêm sửa xóa dữ liệu di sản và quản lý cấu hình kết nối AI / Thanh toán
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            type="button"
            onClick={() => setActiveTab('logs')}
            className={`btn ${activeTab === 'logs' ? 'btn-primary' : 'btn-secondary'}`}
          >
            <Clock size={16} /> Nhật ký kiểm toán ({auditLogs.length})
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('settings')}
            className={`btn ${activeTab === 'settings' ? 'btn-primary' : 'btn-secondary'}`}
          >
            <Settings size={16} /> Cấu Hình API & Bảo Mật
          </button>
        </div>
      </div>

      {activeTab === 'logs' ? (
        <div className="card">
          <div className="card-header" style={{ background: '#FAF7F2' }}>
            <div className="card-title">
              <ShieldAlert size={18} color="var(--color-burgundy-700)" />
              <span>Nhật ký thao tác hệ thống</span>
            </div>
          </div>

          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Thời gian</th>
                  <th>Người thực hiện</th>
                  <th>Vai trò</th>
                  <th>Mã hành động</th>
                  <th>Chi tiết sự kiện</th>
                </tr>
              </thead>
              <tbody>
                {auditLogs.map(log => (
                  <tr key={log.id}>
                    <td>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <Clock size={12} />
                        <span>{log.timestamp}</span>
                      </div>
                    </td>
                    <td>
                      <strong style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-900)' }}>{log.user}</strong>
                    </td>
                    <td>
                      <span className="badge-status badge-draft" style={{ fontSize: '0.7rem' }}>{log.role}</span>
                    </td>
                    <td>
                      <code style={{ fontSize: '0.75rem', color: 'var(--color-burgundy-800)', fontWeight: '700' }}>
                        {log.action}
                      </code>
                    </td>
                    <td>
                      <span style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-800)' }}>{log.details}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        /* Settings Tab */
        <div className="card" style={{ maxWidth: '800px', margin: '0 auto' }}>
          <div className="card-header" style={{ background: '#FAF7F2' }}>
            <div className="card-title">
              <Key size={18} color="var(--color-burgundy-700)" />
              <span>Cấu Hình Tích Hợp Trí Tuệ Nhân Tạo & Dịch Vụ Số</span>
            </div>
          </div>

          <form onSubmit={handleSaveConfig}>
            <div className="card-body" style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Google Gemini AI API Key (Phục vụ AI Studio & Chatbot)</label>
                <input
                  type="password"
                  className="form-input"
                  value={apiConfig.geminiApiKey}
                  onChange={(e) => setApiConfig(prev => ({ ...prev, geminiApiKey: e.target.value }))}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Mô hình AI mặc định</label>
                  <select
                    className="form-select"
                    value={apiConfig.aiModel}
                    onChange={(e) => setApiConfig(prev => ({ ...prev, aiModel: e.target.value }))}
                  >
                    <option value="gemini-2.0-flash">Gemini 2.0 Flash (Tốc độ cao, phản hồi dưới 1 giây)</option>
                    <option value="gemini-1.5-pro">Gemini 1.5 Pro (Học thuật sâu, khảo cổ)</option>
                  </select>
                </div>

                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Giọng đọc Audio Thuyết minh AI</label>
                  <select
                    className="form-select"
                    value={apiConfig.ttsVoice}
                    onChange={(e) => setApiConfig(prev => ({ ...prev, ttsVoice: e.target.value }))}
                  >
                    <option value="vi-VN-Standard-A">Nữ miền Bắc truyền cảm</option>
                    <option value="vi-VN-Standard-B">Nam miền Bắc trầm ấm</option>
                    <option value="vi-VN-Standard-C">Nữ miền Nam dịu dàng</option>
                  </select>
                </div>
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Webhook xác thực thanh toán (VNPay / MoMo)</label>
                <input
                  type="text"
                  className="form-input"
                  value={apiConfig.paymentWebhook}
                  onChange={(e) => setApiConfig(prev => ({ ...prev, paymentWebhook: e.target.value }))}
                />
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Kho lưu trữ Mô hình 3D AR (.glb)</label>
                <input
                  type="text"
                  className="form-input"
                  value={apiConfig.arModelStorage}
                  onChange={(e) => setApiConfig(prev => ({ ...prev, arModelStorage: e.target.value }))}
                />
              </div>
            </div>

            <div className="modal-footer" style={{ background: '#FAF7F2' }}>
              <button type="submit" className="btn btn-primary">
                <Save size={16} /> Lưu Cấu Hình Hệ Thống
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
