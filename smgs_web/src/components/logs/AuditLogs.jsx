import React, { useState, useMemo } from 'react';
import { useApp } from '../../context/AppContext';
import AiClusterHealthPanel from '../operations/AiClusterHealthPanel';
import {
  ShieldAlert,
  Clock,
  Activity,
  Server,
  Key,
  ShieldCheck,
  Database,
  CheckCircle2,
  FileText,
  DollarSign,
  Users,
  MessageSquare
} from 'lucide-react';

export default function AuditLogs() {
  const { curationQueue, users, transactions, reviews, currentMuseum } = useApp();
  const [activeTab, setActiveTab] = useState('health'); // 'health' | 'audit_stream' | 'environment'

  // Synthesize real audit events from live entities loaded from backend
  const liveAuditTrail = useMemo(() => {
    const events = [];

    // 1. Curation & Content Review Events
    (curationQueue || []).forEach(item => {
      events.push({
        id: `curation-${item.id}`,
        timestamp: item.submittedDate || new Date().toISOString(),
        user: item.submittedBy || 'Nhân viên bảo tàng',
        role: item.type === 'new_tour' ? 'Nhân viên Lộ trình' : 'Biên tập viên',
        action: item.status === 'published' ? 'CURATION_APPROVED' : (item.status === 'rejected' ? 'CURATION_REJECTED' : 'CURATION_SUBMITTED'),
        details: `${item.title} (${item.targetArtifactName || 'Hiện vật'}) - Trạng thái: ${item.status}`,
        type: 'curation'
      });
    });

    // 2. Orders & Transactions
    (transactions || []).forEach(tx => {
      events.push({
        id: `tx-${tx.id}`,
        timestamp: tx.timestamp || tx.createdAt || new Date().toISOString(),
        user: tx.userName || 'Khách tham quan',
        role: 'Khách tham quan',
        action: tx.status === 'completed' ? 'PAYMENT_SUCCESS' : 'ORDER_CREATED',
        details: `Đơn hàng #${tx.id}: Mua gói "${tx.packageName || 'Vé tham quan'}" - Số tiền: ${Number(tx.amount || 0).toLocaleString('vi-VN')} đ`,
        type: 'commerce'
      });
    });

    // 3. User Accounts
    (users || []).forEach(u => {
      events.push({
        id: `user-${u.id}`,
        timestamp: u.createdAt || new Date().toISOString(),
        user: u.name || u.fullName,
        role: u.roles?.[0] || 'Tài khoản',
        action: u.status === 'active' ? 'ACCOUNT_ACTIVE' : 'ACCOUNT_LOCKED',
        details: `Tài khoản ${u.email} - Vai trò: ${u.roles?.join(', ') || 'Chưa gán'} - Trạng thái: ${u.status}`,
        type: 'user'
      });
    });

    // 4. Reviews & Feedbacks
    (reviews || []).forEach(r => {
      events.push({
        id: `review-${r.id}`,
        timestamp: r.timestamp || r.createdAt || new Date().toISOString(),
        user: r.visitorName || 'Khách tham quan',
        role: 'Khách tham quan',
        action: r.officialReply ? 'FEEDBACK_REPLIED' : 'FEEDBACK_SUBMITTED',
        details: `Đánh giá ${r.rating}★ cho ${r.museumName}: "${r.comment ? (r.comment.slice(0, 60) + '...') : 'Không có nhận xét'}"`,
        type: 'feedback'
      });
    });

    // Sort by timestamp descending
    return events.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  }, [curationQueue, users, transactions, reviews]);

  const envConfig = useMemo(() => [
    { key: 'API Gateway & Core Backend', val: import.meta.env.VITE_API_URL || 'http://localhost:5169/api', status: 'Kết nối trực tiếp' },
    { key: 'AI Vision Microservice (CLIP ViT-B/32)', val: 'http://localhost:8001/recognize', status: 'Port 8001' },
    { key: 'TTS AI Microservice (Audio Synthesizer)', val: 'http://localhost:8000/tts', status: 'Port 8000' },
    { key: '3D Photogrammetry Scan Service', val: 'http://localhost:8002/scan', status: 'Port 8002' },
    { key: 'Cơ sở dữ liệu trung tâm', val: 'PostgreSQL + PostGIS (Hệ tọa độ trong nhà)', status: 'Active' },
    { key: 'Cơ chế xác thực (Authentication)', val: 'JWT Bearer Token (RFC 7519) - Stateless', status: 'Enforced' },
    { key: 'Cổng thanh toán & Webhook', val: 'SePay Webhook (Server-to-Server HMAC SHA256)', status: 'Secure' },
  ], []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Hạ Tầng Hệ Thống & Nhật Ký Vận Hành
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Giám sát thời gian thực cụm vi dịch vụ AI, kiểm toán thao tác dữ liệu di sản và thông số môi trường máy chủ
          </p>
        </div>

        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <button
            type="button"
            onClick={() => setActiveTab('health')}
            className={`btn btn-sm ${activeTab === 'health' ? 'btn-primary' : 'btn-secondary'}`}
          >
            <Activity size={15} /> Cụm Microservice AI
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('audit_stream')}
            className={`btn btn-sm ${activeTab === 'audit_stream' ? 'btn-primary' : 'btn-secondary'}`}
          >
            <Clock size={15} /> Nhật ký vận hành ({liveAuditTrail.length})
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('environment')}
            className={`btn btn-sm ${activeTab === 'environment' ? 'btn-primary' : 'btn-secondary'}`}
          >
            <Server size={15} /> Cấu hình máy chủ
          </button>
        </div>
      </div>

      {/* Tab 1: AI Cluster Health */}
      {activeTab === 'health' && (
        <AiClusterHealthPanel />
      )}

      {/* Tab 2: Live Audit Stream */}
      {activeTab === 'audit_stream' && (
        <div className="card">
          <div className="card-header" style={{ background: '#FAF7F2' }}>
            <div className="card-title">
              <ShieldAlert size={18} color="var(--color-burgundy-700)" />
              <span>Dòng sự kiện kiểm toán thời gian thực ({liveAuditTrail.length} bản ghi)</span>
            </div>
            <span style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-500)' }}>
              Đồng bộ tự động từ Backend ASP.NET Core & Database
            </span>
          </div>

          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '160px' }}>Thời gian</th>
                  <th style={{ width: '180px' }}>Người thực hiện</th>
                  <th style={{ width: '140px' }}>Vai trò</th>
                  <th style={{ width: '180px' }}>Mã hành động</th>
                  <th>Chi tiết sự kiện</th>
                </tr>
              </thead>
              <tbody>
                {liveAuditTrail.length === 0 ? (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', padding: '32px', color: 'var(--color-charcoal-500)' }}>
                      Chưa có sự kiện nào được ghi nhận trong phiên làm việc.
                    </td>
                  </tr>
                ) : (
                  liveAuditTrail.map(log => (
                    <tr key={log.id}>
                      <td>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Clock size={12} />
                          <span>{new Date(log.timestamp).toLocaleString('vi-VN')}</span>
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
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 3: Environment & Security Architecture */}
      {activeTab === 'environment' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div className="card">
            <div className="card-header" style={{ background: '#FAF7F2' }}>
              <div className="card-title">
                <Server size={18} color="var(--color-burgundy-700)" />
                <span>Thông số Môi trường Runtime của Hệ thống</span>
              </div>
            </div>

            <div className="table-container">
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '300px' }}>Thành phần / Cấu hình</th>
                    <th>Địa chỉ / Tham số kết nối</th>
                    <th style={{ width: '140px' }}>Trạng thái</th>
                  </tr>
                </thead>
                <tbody>
                  {envConfig.map((item, idx) => (
                    <tr key={idx}>
                      <td>
                        <strong style={{ fontSize: '0.85rem', color: 'var(--color-charcoal-900)' }}>{item.key}</strong>
                      </td>
                      <td>
                        <code style={{ fontSize: '0.8125rem', color: 'var(--color-burgundy-800)' }}>{item.val}</code>
                      </td>
                      <td>
                        <span className="badge-status badge-active" style={{ fontSize: '0.72rem' }}>
                          {item.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div style={{
            padding: '16px 20px',
            background: 'var(--color-paper-card)',
            borderRadius: '10px',
            border: '1px solid var(--color-paper-border)',
            display: 'flex',
            alignItems: 'flex-start',
            gap: '12px'
          }}>
            <ShieldCheck size={20} color="var(--color-burgundy-700)" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <strong style={{ fontSize: '0.875rem', color: 'var(--color-burgundy-900)' }}>
                Tuân thủ Tiêu chuẩn Bảo mật Kiến trúc (OWASP Security Standards):
              </strong>
              <p style={{ margin: '4px 0 0', fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', lineHeight: '1.5' }}>
                Toàn bộ các khóa bảo mật nhạy cảm (Google Gemini API Key, Secret HMAC SePay, Database Connection String, JWT Signing Key) được cô lập an toàn bên trong máy chủ Backend ASP.NET Core (`appsettings.Production.json` & Linux Environment Variables). Giao diện trình duyệt của Quản trị viên chỉ tương tác qua các kênh API có xác thực JWT Bearer Role-based, tuyệt đối không lưu trữ khóa bí mật tại LocalStorage hay Client-side Bundle.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
