import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  CheckSquare,
  Sparkles,
  Check,
  X,
  AlertCircle,
  FileText,
  Clock,
  User,
  Eye,
  MessageSquare,
  ArrowRight,
  ShieldCheck
} from 'lucide-react';

export default function CurationCenter() {
  const {
    curationQueue,
    artifacts,
    currentMuseum,
    approveCurationItem,
    rejectCurationItem,
    requestRevisionCurationItem
  } = useApp();

  const [filterStatus, setFilterStatus] = useState('pending'); // all | pending | approved | revision_requested | rejected
  const [selectedItem, setSelectedItem] = useState(null);
  const [reviewNote, setReviewNote] = useState('');
  const [actionType, setActionType] = useState(null); // 'revision' | 'reject'

  const museumQueue = curationQueue.filter(item => artifacts.find(artifact => artifact.id === item.targetArtifactId)?.museumId === currentMuseum.id);
  const filteredQueue = museumQueue.filter(item => {
    if (filterStatus !== 'all' && item.status !== filterStatus) return false;
    return true;
  });

  const pendingCount = museumQueue.filter(c => c.status === 'pending').length;
  const approvedCount = museumQueue.filter(c => c.status === 'approved').length;
  const revisionCount = museumQueue.filter(c => c.status === 'revision_requested').length;

  const handleApprove = (id) => {
    approveCurationItem(id, reviewNote || 'Đã kiểm duyệt và chuẩn hóa theo tiêu chuẩn bảo tàng.');
    setSelectedItem(null);
    setReviewNote('');
    setActionType(null);
  };

  const handleReject = (id) => {
    if (!reviewNote.trim()) {
      alert('Vui lòng nhập lý do từ chối để thông báo lại cho nhân viên');
      return;
    }
    rejectCurationItem(id, reviewNote);
    setSelectedItem(null);
    setReviewNote('');
    setActionType(null);
  };

  const handleRequestRevision = (id) => {
    if (!reviewNote.trim()) {
      alert('Vui lòng nhập hướng dẫn chỉnh sửa để nhân viên hiệu đính');
      return;
    }
    requestRevisionCurationItem(id, reviewNote);
    setSelectedItem(null);
    setReviewNote('');
    setActionType(null);
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Kiểm Tra & Xuất Bản Nội Dung AI
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Nhân viên bảo tàng kiểm tra thuyết minh, câu hỏi và tư liệu AI của bảo tàng mình trước khi xuất bản.
          </p>
        </div>
      </div>

      {/* Metric Tabs */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '24px', flexWrap: 'wrap' }}>
        {[
          { id: 'pending', label: 'Chờ kiểm duyệt', count: pendingCount, color: 'var(--color-warning)' },
          { id: 'approved', label: 'Đã xuất bản', count: approvedCount, color: 'var(--color-success)' },
          { id: 'revision_requested', label: 'Yêu cầu hiệu chỉnh', count: revisionCount, color: 'var(--color-burgundy-700)' },
          { id: 'all', label: 'Tất cả mục', count: museumQueue.length, color: 'var(--color-charcoal-700)' }
        ].map(tab => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setFilterStatus(tab.id)}
            style={{
              padding: '12px 20px',
              borderRadius: '10px',
              background: filterStatus === tab.id ? '#FFFFFF' : 'var(--color-paper-accent)',
              border: filterStatus === tab.id ? '2px solid var(--color-burgundy-700)' : '1px solid var(--color-paper-border)',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              fontWeight: '600',
              fontSize: '0.875rem',
              color: filterStatus === tab.id ? 'var(--color-burgundy-900)' : 'var(--color-charcoal-700)',
              boxShadow: filterStatus === tab.id ? 'var(--shadow-sm)' : 'none',
              transition: 'all var(--transition-fast)'
            }}
          >
            <span>{tab.label}</span>
            <span style={{
              background: tab.color,
              color: '#FFF',
              fontSize: '0.75rem',
              padding: '2px 8px',
              borderRadius: '999px',
              fontWeight: '700'
            }}>
              {tab.count}
            </span>
          </button>
        ))}
      </div>

      {/* Queue List */}
      <div className="card">
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Tiêu đề mục kiểm duyệt</th>
                <th>Hiện vật liên quan</th>
                <th>Người đệ trình</th>
                <th>Thời gian</th>
                <th>Mức độ ưu tiên</th>
                <th>Trạng thái</th>
                <th style={{ textAlign: 'right' }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredQueue.length > 0 ? (
                filteredQueue.map(item => (
                  <tr key={item.id}>
                    <td>
                      <div style={{ fontWeight: '600', color: 'var(--color-charcoal-900)', fontSize: '0.9375rem' }}>
                        {item.title}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', marginTop: '2px' }}>
                        {item.changesSummary}
                      </div>
                    </td>

                    <td>
                      <span style={{ fontWeight: '600', color: 'var(--color-burgundy-800)', fontSize: '0.8125rem' }}>
                        {item.targetArtifactName}
                      </span>
                    </td>

                    <td>
                      <div style={{ fontSize: '0.8125rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <User size={14} color="var(--color-charcoal-400)" />
                        <span>{item.submittedBy}</span>
                      </div>
                    </td>

                    <td>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <Clock size={12} />
                        <span>{item.submittedDate}</span>
                      </div>
                    </td>

                    <td>
                      <span style={{
                        fontSize: '0.7rem',
                        fontWeight: '700',
                        padding: '3px 8px',
                        borderRadius: '4px',
                        textTransform: 'uppercase',
                        background: item.priority === 'high' ? '#FEE2E2' : '#FEF3C7',
                        color: item.priority === 'high' ? '#991B1B' : '#92400E'
                      }}>
                        {item.priority === 'high' ? 'Ưu tiên cao' : 'Tiêu chuẩn'}
                      </span>
                    </td>

                    <td>
                      <span className={`badge-status badge-${item.status}`}>
                        {item.status === 'pending' ? 'Chờ duyệt' : item.status === 'approved' ? 'Đã duyệt' : item.status === 'revision_requested' ? 'Yêu cầu sửa' : 'Từ chối'}
                      </span>
                    </td>

                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '8px' }}>
                        <button
                          type="button"
                          onClick={() => {
                            setSelectedItem(item);
                            setReviewNote('');
                            setActionType(null);
                          }}
                          className="btn btn-primary btn-sm"
                        >
                          <Eye size={14} /> Thẩm định & So sánh
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '40px', color: 'var(--color-charcoal-500)' }}>
                    Không có mục kiểm duyệt nào ở trạng thái này.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Review & Diff Comparison Modal */}
      {selectedItem && (
        <div className="modal-overlay" onClick={() => setSelectedItem(null)}>
          <div className="modal-dialog" style={{ maxWidth: '1000px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '8px',
                  background: 'var(--color-burgundy-100)',
                  color: 'var(--color-burgundy-700)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <ShieldCheck size={20} />
                </div>
                <div>
                  <h3 className="modal-title font-serif">{selectedItem.title}</h3>
                  <p style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                    Hiện vật: <strong>{selectedItem.targetArtifactName}</strong> • Người gửi: {selectedItem.submittedBy}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedItem(null)}
                className="btn btn-secondary btn-sm"
                style={{ borderRadius: '50%', padding: '6px' }}
              >
                <X size={18} />
              </button>
            </div>

            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Summary of proposed changes */}
              <div style={{ background: '#FAF7F2', padding: '14px 18px', borderRadius: '8px', borderLeft: '4px solid var(--color-gold-500)' }}>
                <div style={{ fontWeight: '700', fontSize: '0.8125rem', color: 'var(--color-burgundy-900)', marginBottom: '4px' }}>
                  📌 Ghi chú đề xuất từ Nhân viên:
                </div>
                <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)' }}>
                  {selectedItem.changesSummary}
                </p>
              </div>

              {/* Side by Side Diff Box */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                {/* Left: Current Baseline */}
                <div style={{ border: '1px solid var(--color-paper-border)', borderRadius: '10px', overflow: 'hidden' }}>
                  <div style={{ background: '#F5F5F5', padding: '10px 14px', fontWeight: '600', fontSize: '0.8125rem', borderBottom: '1px solid var(--color-paper-border)', color: 'var(--color-charcoal-600)' }}>
                    Bản hiện tại trên hệ thống
                  </div>
                  <div style={{ padding: '16px', fontSize: '0.8125rem', lineHeight: '1.7', color: 'var(--color-charcoal-600)', background: '#FAFAFA', maxHeight: '320px', overflowY: 'auto' }}>
                    {selectedItem.currentVersion || 'Chưa có dữ liệu'}
                  </div>
                </div>

                {/* Right: Proposed New Revision */}
                <div style={{ border: '1.5px solid var(--color-gold-500)', borderRadius: '10px', overflow: 'hidden' }}>
                  <div style={{ background: 'var(--color-gold-50)', padding: '10px 14px', fontWeight: '700', fontSize: '0.8125rem', borderBottom: '1px solid var(--color-gold-300)', color: 'var(--color-gold-700)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Sparkles size={14} /> Nội dung mới đệ trình (Đã qua xưởng nội dung AI)
                  </div>
                  <div style={{ padding: '16px', fontSize: '0.8125rem', lineHeight: '1.7', color: 'var(--color-charcoal-900)', background: '#FFFFFF', maxHeight: '320px', overflowY: 'auto', whiteSpace: 'pre-line' }}>
                    {selectedItem.proposedContent}
                  </div>
                </div>
              </div>

              {/* Action Form for Feedback if rejecting or requesting revision */}
              {actionType && (
                <div style={{ background: '#FFFDF9', padding: '16px', borderRadius: '8px', border: '1px solid var(--color-paper-border)' }}>
                  <label className="form-label">
                    {actionType === 'revision' ? 'Góp ý chi tiết yêu cầu nhân viên chỉnh sửa:' : 'Lý do từ chối phê duyệt:'}
                  </label>
                  <textarea
                    className="form-textarea"
                    rows={3}
                    value={reviewNote}
                    onChange={(e) => setReviewNote(e.target.value)}
                    placeholder={actionType === 'revision' ? 'Ví dụ: Cần bổ sung thêm thông tin về chim Lạc và làm rõ niên đại...' : 'Ví dụ: Thông tin chưa được kiểm chứng khảo cổ...'}
                  />
                  <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
                    <button
                      type="button"
                      onClick={() => actionType === 'revision' ? handleRequestRevision(selectedItem.id) : handleReject(selectedItem.id)}
                      className={`btn ${actionType === 'revision' ? 'btn-primary' : 'btn-danger'} btn-sm`}
                    >
                      Xác nhận gửi phản hồi
                    </button>
                    <button
                      type="button"
                      onClick={() => setActionType(null)}
                      className="btn btn-secondary btn-sm"
                    >
                      Hủy thao tác
                    </button>
                  </div>
                </div>
              )}
            </div>

            <div className="modal-footer" style={{ justifyContent: 'space-between' }}>
              <button
                type="button"
                onClick={() => setSelectedItem(null)}
                className="btn btn-secondary"
              >
                Đóng
              </button>

              <div style={{ display: 'flex', gap: '10px' }}>
                <button
                  type="button"
                  onClick={() => setActionType('reject')}
                  className="btn btn-secondary btn-sm"
                  style={{ color: 'var(--color-danger)' }}
                >
                  <X size={14} /> Từ chối
                </button>
                <button
                  type="button"
                  onClick={() => setActionType('revision')}
                  className="btn btn-secondary btn-sm"
                  style={{ color: 'var(--color-warning)' }}
                >
                  <MessageSquare size={14} /> Yêu cầu sửa đổi
                </button>
                <button
                  type="button"
                  onClick={() => handleApprove(selectedItem.id)}
                  className="btn btn-primary"
                >
                  <Check size={16} /> Phê duyệt & Xuất bản ngay
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
