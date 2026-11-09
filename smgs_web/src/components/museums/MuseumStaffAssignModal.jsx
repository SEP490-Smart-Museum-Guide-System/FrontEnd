import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { backend } from '../../services/backend';
import { useApp } from '../../context/AppContext';
import {
  Users,
  Search,
  UserPlus,
  Trash2,
  Check,
  AlertCircle,
  X,
  ShieldCheck,
  Mail,
  Loader2
} from 'lucide-react';

export default function MuseumStaffAssignModal({ museum, onClose, onAssigned }) {
  const { showToast } = useApp();
  const [keyword, setKeyword] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [selectedStaff, setSelectedStaff] = useState(null);

  const [assignments, setAssignments] = useState([]);
  const [isLoadingAssignments, setIsLoadingAssignments] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const searchTimeout = useRef(null);

  // 1. Tải danh sách nhân viên hiện đang được phân công cho bảo tàng
  const loadAssignments = async () => {
    if (!museum?.id) return;
    setIsLoadingAssignments(true);
    try {
      // API lấy danh sách phân công theo museumId
      const data = await backend(`admin/assignments?museumId=${museum.id}`);
      setAssignments(Array.isArray(data) ? data : []);
    } catch {
      // Nếu API trả về lỗi hoặc chưa có dữ liệu, gán mảng rỗng
      setAssignments([]);
    } finally {
      setIsLoadingAssignments(false);
    }
  };

  useEffect(() => {
    loadAssignments();
  }, [museum?.id]);

  // 2. Tìm kiếm nhân viên theo tên hoặc email
  useEffect(() => {
    if (searchTimeout.current) clearTimeout(searchTimeout.current);

    const term = keyword.trim();
    if (!term) {
      setSearchResults([]);
      setIsSearching(false);
      return;
    }

    setIsSearching(true);
    searchTimeout.current = setTimeout(async () => {
      try {
        // Tìm kiếm các tài khoản có vai trò museum_staff hoặc staff
        const res = await backend(`admin/accounts?role=museum_staff&keyword=${encodeURIComponent(term)}&pageSize=10`);
        const items = Array.isArray(res) ? res : res?.items || [];
        setSearchResults(items);
      } catch {
        // Dự phòng tìm kiếm toàn bộ tài khoản
        try {
          const res = await backend(`admin/accounts?keyword=${encodeURIComponent(term)}&pageSize=10`);
          const items = Array.isArray(res) ? res : res?.items || [];
          setSearchResults(items);
        } catch {
          setSearchResults([]);
        }
      } finally {
        setIsSearching(false);
      }
    }, 350);

    return () => {
      if (searchTimeout.current) clearTimeout(searchTimeout.current);
    };
  }, [keyword]);

  // 3. Thực hiện phân công nhân viên
  const handleAssign = async () => {
    if (!selectedStaff || !museum?.id || isSubmitting) return;

    setIsSubmitting(true);
    try {
      await backend(`museums/${museum.id}/indoor-staff`, {
        method: 'POST',
        body: { userId: selectedStaff.id }
      });

      showToast(`Đã phân công ${selectedStaff.fullName || selectedStaff.email} cho bảo tàng thành công!`, 'success');
      setSelectedStaff(null);
      setKeyword('');
      setSearchResults([]);
      await loadAssignments();
      onAssigned?.();
    } catch (err) {
      showToast(err.message || 'Không thể phân công nhân viên.', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  // 4. Hủy phân công nhân viên
  const handleRevoke = async (assignmentId, staffName) => {
    if (!window.confirm(`Bạn có chắc chắn muốn hủy phân công của nhân viên "${staffName || 'này'}" khỏi bảo tàng?`)) return;

    try {
      await backend(`admin/assignments/${assignmentId}`, { method: 'DELETE' });
      showToast('Đã hủy phân công nhân viên.', 'success');
      await loadAssignments();
      onAssigned?.();
    } catch (err) {
      showToast(err.message || 'Không thể hủy phân công.', 'error');
    }
  };

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal-dialog"
        style={{ maxWidth: '640px', width: '95vw', maxHeight: '90vh', display: 'flex', flexDirection: 'column' }}
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="modal-header" style={{ borderBottom: '1px solid var(--color-paper-border)', padding: '16px 20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: '8px',
                background: 'var(--color-burgundy-50, #FDF2F2)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              <Users size={20} color="var(--color-burgundy-700)" />
            </div>
            <div>
              <h3 className="modal-title font-serif" style={{ fontSize: '1.25rem', margin: 0 }}>
                Phân Công Nhân Viên Phụ Trách
              </h3>
              <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', margin: '2px 0 0 0' }}>
                Bảo tàng: <strong>{museum?.name}</strong>
              </p>
            </div>
          </div>
          <button type="button" className="btn btn-secondary btn-sm" onClick={onClose}>
            <X size={16} />
          </button>
        </div>

        {/* Body */}
        <div className="modal-body" style={{ padding: '20px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {/* Phần 1: Tìm kiếm & Chọn nhân viên */}
          <div style={{ background: 'var(--color-paper-accent, #FAF8F5)', padding: '16px', borderRadius: '10px', border: '1px solid var(--color-paper-border)' }}>
            <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '600', color: 'var(--color-charcoal-800)', marginBottom: '8px' }}>
              Tìm kiếm nhân viên (theo Tên hoặc Email)
            </label>
            <div style={{ position: 'relative' }}>
              <input
                className="form-input"
                style={{ paddingLeft: '38px', paddingRight: isSearching ? '38px' : '14px' }}
                placeholder="Nhập tên hoặc email nhân viên bảo tàng..."
                value={keyword}
                onChange={e => setKeyword(e.target.value)}
              />
              <Search
                size={18}
                color="var(--color-charcoal-400)"
                style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }}
              />
              {isSearching && (
                <Loader2
                  size={18}
                  className="spin"
                  color="var(--color-burgundy-700)"
                  style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)' }}
                />
              )}
            </div>

            {/* Danh sách kết quả tìm kiếm */}
            {searchResults.length > 0 && (
              <div
                style={{
                  marginTop: '10px',
                  maxHeight: '180px',
                  overflowY: 'auto',
                  background: '#FFFFFF',
                  borderRadius: '8px',
                  border: '1px solid var(--color-paper-border)',
                  boxShadow: 'var(--shadow-sm)'
                }}
              >
                {searchResults.map(staff => {
                  const isSelected = selectedStaff?.id === staff.id;
                  const alreadyAssigned = assignments.some(a => a.userId === staff.id);
                  return (
                    <div
                      key={staff.id}
                      onClick={() => !alreadyAssigned && setSelectedStaff(staff)}
                      style={{
                        padding: '10px 14px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        cursor: alreadyAssigned ? 'not-allowed' : 'pointer',
                        background: isSelected ? 'var(--color-burgundy-50, #FDF2F2)' : '#FFFFFF',
                        borderBottom: '1px solid #F1F5F9',
                        opacity: alreadyAssigned ? 0.6 : 1,
                        transition: 'background 0.15s ease'
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div
                          style={{
                            width: 32,
                            height: 32,
                            borderRadius: '50%',
                            background: 'var(--color-paper-border, #E2E8F0)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: '600',
                            fontSize: '0.8125rem',
                            color: 'var(--color-burgundy-900)'
                          }}
                        >
                          {(staff.fullName || staff.email || '?').charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--color-charcoal-900)' }}>
                            {staff.fullName || 'Chưa cập nhật tên'}
                          </div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <Mail size={12} /> {staff.email}
                          </div>
                        </div>
                      </div>

                      <div>
                        {alreadyAssigned ? (
                          <span style={{ fontSize: '0.75rem', padding: '3px 8px', borderRadius: '4px', background: '#DCFCE7', color: '#166534', fontWeight: '500' }}>
                            Đang phụ trách
                          </span>
                        ) : isSelected ? (
                          <span style={{ fontSize: '0.75rem', padding: '3px 8px', borderRadius: '4px', background: 'var(--color-burgundy-700)', color: '#FFFFFF', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <Check size={12} /> Đã chọn
                          </span>
                        ) : (
                          <button
                            type="button"
                            className="btn btn-secondary btn-sm"
                            style={{ padding: '4px 10px', fontSize: '0.75rem' }}
                            onClick={e => { e.stopPropagation(); setSelectedStaff(staff); }}
                          >
                            Chọn
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            {/* Thông báo đã chọn và Nút xác nhận phân công */}
            {selectedStaff && (
              <div
                style={{
                  marginTop: '12px',
                  padding: '12px 14px',
                  borderRadius: '8px',
                  background: '#FFFFFF',
                  border: '1.5px solid var(--color-burgundy-600)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  flexWrap: 'wrap',
                  gap: '10px'
                }}
              >
                <div>
                  <div style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)' }}>Tài khoản được chọn:</div>
                  <strong style={{ fontSize: '0.9375rem', color: 'var(--color-burgundy-900)' }}>
                    {selectedStaff.fullName || selectedStaff.email}
                  </strong>
                  <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', marginLeft: '8px' }}>
                    ({selectedStaff.email})
                  </span>
                </div>
                <button
                  type="button"
                  className="btn btn-primary btn-sm"
                  disabled={isSubmitting}
                  onClick={handleAssign}
                  style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
                >
                  <UserPlus size={15} />
                  {isSubmitting ? 'Đang phân công...' : 'Xác nhận phân công'}
                </button>
              </div>
            )}
          </div>

          {/* Phần 2: Danh sách nhân viên hiện đang phụ trách bảo tàng */}
          <div>
            <h4 style={{ fontSize: '0.9375rem', fontWeight: '700', color: 'var(--color-burgundy-900)', marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <ShieldCheck size={18} color="var(--color-gold-600)" />
              Danh sách nhân viên đang phụ trách ({assignments.length})
            </h4>

            {isLoadingAssignments ? (
              <div style={{ padding: '24px', textAlign: 'center', color: 'var(--color-charcoal-500)' }}>
                <Loader2 size={24} className="spin" style={{ margin: '0 auto 8px auto' }} />
                <p style={{ fontSize: '0.875rem' }}>Đang tải danh sách phân công...</p>
              </div>
            ) : assignments.length === 0 ? (
              <div
                style={{
                  padding: '24px',
                  textAlign: 'center',
                  background: '#FFFFFF',
                  borderRadius: '8px',
                  border: '1px dashed var(--color-paper-border)',
                  color: 'var(--color-charcoal-500)',
                  fontSize: '0.875rem'
                }}
              >
                <AlertCircle size={24} color="var(--color-charcoal-400)" style={{ margin: '0 auto 8px auto', display: 'block' }} />
                Chưa có nhân viên nào được phân công cho bảo tàng này.
                <p style={{ fontSize: '0.75rem', marginTop: '4px', color: 'var(--color-charcoal-400)' }}>
                  Hãy dùng ô tìm kiếm phía trên để chỉ định nhân viên quản lý cấu trúc và nội dung.
                </p>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {assignments.map(a => (
                  <div
                    key={a.id}
                    style={{
                      padding: '12px 16px',
                      background: '#FFFFFF',
                      borderRadius: '8px',
                      border: '1px solid var(--color-paper-border)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between'
                    }}
                  >
                    <div>
                      <div style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--color-charcoal-900)' }}>
                        {a.userName || a.userEmail || `Nhân viên #${a.userId?.substring(0, 8)}`}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                        {a.userEmail && <span>{a.userEmail} · </span>}
                        Phân công lúc: {a.assignedAt ? new Date(a.assignedAt).toLocaleDateString('vi-VN') : 'Mặc định'}
                      </div>
                    </div>

                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      style={{ color: '#B91C1C', borderColor: '#FCA5A5' }}
                      title="Hủy phân công"
                      onClick={() => handleRevoke(a.id, a.userName || a.userEmail)}
                    >
                      <Trash2 size={14} /> Gỡ
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="modal-footer" style={{ borderTop: '1px solid var(--color-paper-border)', padding: '12px 20px' }}>
          <button type="button" className="btn btn-secondary" onClick={onClose}>
            Đóng
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}
