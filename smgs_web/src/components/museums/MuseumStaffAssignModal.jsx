import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { backend, allPages } from '../../services/backend';
import { useApp } from '../../context/AppContext';
import {
  Users,
  Search,
  UserPlus,
  Trash2,
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
  const [role, setRole] = useState('');
  const [searchError, setSearchError] = useState('');
  const [assignmentError, setAssignmentError] = useState('');

  const [assignments, setAssignments] = useState([]);
  const [isLoadingAssignments, setIsLoadingAssignments] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const mutationPending = useRef(false);

  // 1. Tải danh sách nhân viên hiện đang được phân công cho bảo tàng
  const loadAssignments = async () => {
    if (!museum?.id) return;
    setIsLoadingAssignments(true);
    setAssignmentError('');
    try {
      // API lấy danh sách phân công theo museumId
      const data = await backend(`admin/assignments?museumId=${museum.id}`);
      setAssignments(data.filter(a => a.galleryId == null && a.artifactId == null));
    } catch (err) {
      setAssignmentError(err.message || 'Không thể tải danh sách phân công.');
    } finally {
      setIsLoadingAssignments(false);
    }
  };

  useEffect(() => {
    loadAssignments();
  }, [museum?.id]);

  useEffect(() => {
    const controller = new AbortController();
    setIsSearching(true);
    setSearchError('');
    setSearchResults([]);
    const timeout = setTimeout(async () => {
      try {
        const roles = role ? [role] : ['Museum Staff', 'Curator'];
        const results = await Promise.all(roles.map(value => allPages(
          `admin/accounts?role=${encodeURIComponent(value)}&keyword=${encodeURIComponent(keyword.trim())}`,
          { signal: controller.signal }
        )));
        if (!controller.signal.aborted) {
          setSearchResults([...new Map(results.flat().map(staff => [staff.id, staff])).values()]);
        }
      } catch (err) {
        if (!controller.signal.aborted) setSearchError(err.message || 'Không thể tải danh sách nhân viên.');
      } finally {
        if (!controller.signal.aborted) setIsSearching(false);
      }
    }, keyword.trim() ? 350 : 0);
    return () => { clearTimeout(timeout); controller.abort(); };
  }, [keyword, role]);

  // 3. Thực hiện phân công nhân viên
  const handleAssign = async (staff) => {
    if (!museum?.id || mutationPending.current || isLoadingAssignments || assignmentError || assignments.some(a => a.userId === staff.id)) return;
    mutationPending.current = true;

    setIsSubmitting(true);
    try {
      await backend(`admin/accounts/${staff.id}/assignments`, {
        method: 'POST',
        body: { museumId: museum.id }
      });

      showToast(`Đã phân công ${staff.fullName || staff.email} cho bảo tàng thành công!`, 'success');

      await loadAssignments();
      onAssigned?.();
    } catch (err) {
      showToast(err.message || 'Không thể phân công nhân viên.', 'error');
    } finally {
      mutationPending.current = false;
      setIsSubmitting(false);
    }
  };

  // 4. Hủy phân công nhân viên
  const handleRevoke = async (assignmentId, staffName) => {
    if (mutationPending.current) return;
    if (!window.confirm(`Bạn có chắc chắn muốn hủy phân công của nhân viên "${staffName || 'này'}" khỏi bảo tàng?`)) return;

    mutationPending.current = true;
    setIsSubmitting(true);
    try {
      await backend(`admin/assignments/${assignmentId}`, { method: 'DELETE' });
      showToast('Đã hủy phân công nhân viên.', 'success');
      await loadAssignments();
      onAssigned?.();
    } catch (err) {
      showToast(err.message || 'Không thể hủy phân công.', 'error');
    } finally {
      mutationPending.current = false;
      setIsSubmitting(false);
    }
  };

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal-dialog"
        role="dialog" aria-modal="true" aria-label="Phân Công Nhân Viên Phụ Trách"
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
            <label htmlFor="staff-search" style={{ display: 'block', fontSize: '0.875rem', fontWeight: '600', color: 'var(--color-charcoal-800)', marginBottom: '8px' }}>
              Tìm kiếm nhân viên (theo Tên hoặc Email)
            </label>
            <div style={{ position: 'relative' }}>
              <input
                id="staff-search"
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

            <label htmlFor="staff-role" style={{ display: 'block', marginTop: 12 }}>Lọc theo role</label>
            <select id="staff-role" className="form-select" value={role} onChange={e => setRole(e.target.value)}>
              <option value="">Tất cả (Museum Staff và Curator)</option>
              <option value="Museum Staff">Museum Staff</option>
              <option value="Curator">Curator</option>
            </select>
          </div>
          <section aria-label="Danh sách nhân viên có thể phân công">
            <h4>Danh sách nhân viên có thể phân công ({searchResults.length})</h4>
            {isSearching ? <p role="status">Đang tải danh sách nhân viên...</p>
              : searchError ? <p role="alert">{searchError}</p>
              : searchResults.length === 0 ? <p>Không có nhân viên phù hợp.</p>
              : <div style={{ maxHeight: 260, overflowY: 'auto', marginTop: 10 }}>
                {searchResults.map(staff => {
                  const alreadyAssigned = assignments.some(a => a.userId === staff.id);
                  return <div key={staff.id} style={{ padding: '12px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, background: '#FFFFFF', borderBottom: '1px solid var(--color-paper-border)' }}>
                    <div style={{ minWidth: 0, overflowWrap: 'anywhere' }}>
                      <strong>{staff.fullName || 'Chưa cập nhật tên'}</strong>
                      <div style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)' }}><Mail size={12} /> {staff.email}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-burgundy-700)' }}>{staff.roles.join(', ')}</div>
                    </div>
                    <button type="button" className="btn btn-secondary btn-sm"
                      disabled={alreadyAssigned || isSubmitting || isLoadingAssignments || !!assignmentError}
                      onClick={() => handleAssign(staff)}>
                      <UserPlus size={14} /> {alreadyAssigned ? 'Đã phân công' : 'Phân công'}
                    </button>
                  </div>;
                })}
              </div>}
          </section>

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
            ) : assignmentError ? <p role="alert">{assignmentError} <button className="btn btn-secondary btn-sm" onClick={loadAssignments}>Thử lại</button></p> : assignments.length === 0 ? (
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
                  Chọn nhân viên trong danh sách phía trên để chỉ định nhân viên quản lý cấu trúc và nội dung.
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
                        {a.userFullName || a.userEmail || `Nhân viên #${a.userId?.substring(0, 8)}`}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                        {a.userEmail && <span>{a.userEmail} · </span>}
                        <span>{a.userRoles?.join(', ') || 'Chưa có role'} · </span>
                        Phân công lúc: {a.assignedAt ? new Date(a.assignedAt).toLocaleDateString('vi-VN') : 'Mặc định'}
                      </div>
                    </div>

                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      style={{ color: '#B91C1C', borderColor: '#FCA5A5' }}
                      title="Hủy phân công"
                      disabled={isSubmitting}
                      onClick={() => handleRevoke(a.id, a.userFullName || a.userEmail)}
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
