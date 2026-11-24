import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Globe, CheckCircle, AlertCircle, X, Loader2 } from 'lucide-react';
import { getMuseumTranslationApi, updateMuseumTranslationApi } from '../../services/museumApi';

export default function MuseumTranslationModal({ museum, onClose, onSuccess, showToast }) {
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [isTranslated, setIsTranslated] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    address: '',
    openingHours: '',
    description: '',
  });

  useEffect(() => {
    let active = true;
    async function load() {
      if (!museum?.id) return;
      setLoading(true);
      setError('');
      try {
        const data = await getMuseumTranslationApi(museum.id, 'en');
        if (active && data) {
          setIsTranslated(Boolean(data.isTranslated));
          setFormData({
            name: data.name || '',
            address: data.address || '',
            openingHours: data.openingHours || '',
            description: data.description || '',
          });
        }
      } catch (err) {
        if (active) setError(err.message || 'Không thể tải bản dịch.');
      } finally {
        if (active) setLoading(false);
      }
    }
    load();
    return () => { active = false; };
  }, [museum?.id]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      setError('Vui lòng nhập tên bảo tàng bằng tiếng Anh.');
      return;
    }
    setSubmitting(true);
    setError('');
    try {
      await updateMuseumTranslationApi(museum.id, 'en', formData);
      if (showToast) showToast('Đã lưu bản dịch tiếng Anh cho bảo tàng thành công!');
      if (onSuccess) onSuccess();
      onClose();
    } catch (err) {
      setError(err.message || 'Không thể lưu bản dịch tiếng Anh.');
    } finally {
      setSubmitting(false);
    }
  };

  return createPortal(
    <div className="modal-backdrop" onClick={onClose} style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(4px)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: '16px'
    }}>
      <div
        className="modal-card"
        onClick={e => e.stopPropagation()}
        style={{
          background: '#ffffff', borderRadius: '16px', maxWidth: '640px', width: '100%',
          maxHeight: '90vh', display: 'flex', flexDirection: 'column', boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -6px rgba(0,0,0,0.1)',
          overflow: 'hidden'
        }}
      >
        {/* Header */}
        <div style={{
          padding: '20px 24px', borderBottom: '1px solid #E2E8F0',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '36px', height: '36px', borderRadius: '10px',
              backgroundColor: '#EFF6FF', color: '#2563EB',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <Globe size={20} />
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 600, color: '#0F172A' }}>
                Bản dịch tiếng Anh (English Translation)
              </h3>
              <p style={{ margin: 0, fontSize: '13px', color: '#64748B' }}>
                {museum?.name || 'Bảo tàng'}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: 'none', border: 'none', cursor: 'pointer',
              color: '#94A3B8', padding: '6px', borderRadius: '6px'
            }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Content */}
        <div style={{ padding: '24px', overflowY: 'auto', flex: 1 }}>
          {loading ? (
            <div style={{ padding: '40px 0', textAlign: 'center', color: '#64748B' }}>
              <Loader2 size={28} className="animate-spin" style={{ margin: '0 auto 12px' }} />
              <p style={{ fontSize: '14px', margin: 0 }}>Đang tải thông tin bản dịch...</p>
            </div>
          ) : (
            <form id="museum-translation-form" onSubmit={handleSubmit}>
              {/* Status Banner */}
              <div style={{
                padding: '12px 16px', borderRadius: '10px', marginBottom: '20px',
                display: 'flex', alignItems: 'flex-start', gap: '12px',
                backgroundColor: isTranslated ? '#F0FDF4' : '#FFFBEB',
                border: `1px solid ${isTranslated ? '#BBF7D0' : '#FDE68A'}`
              }}>
                {isTranslated ? (
                  <CheckCircle size={18} color="#16A34A" style={{ marginTop: '2px', flexShrink: 0 }} />
                ) : (
                  <AlertCircle size={18} color="#D97706" style={{ marginTop: '2px', flexShrink: 0 }} />
                )}
                <div style={{ fontSize: '13px', lineHeight: '1.5' }}>
                  {isTranslated ? (
                    <span style={{ color: '#15803D', fontWeight: 500 }}>
                      Bảo tàng đã có bản dịch tiếng Anh chính thức. Khách quốc tế sẽ thấy các thông tin dưới đây.
                    </span>
                  ) : (
                    <span style={{ color: '#B45309' }}>
                      <strong>Chưa có bản dịch tiếng Anh:</strong> Dữ liệu bên dưới đang hiển thị nội dung gốc tiếng Việt dự phòng. Hãy nhập bản dịch tiếng Anh để phục vụ khách quốc tế.
                    </span>
                  )}
                </div>
              </div>

              {error && (
                <div style={{
                  padding: '10px 14px', borderRadius: '8px', marginBottom: '16px',
                  backgroundColor: '#FEF2F2', border: '1px solid #FECACA', color: '#DC2626',
                  fontSize: '13px'
                }}>
                  {error}
                </div>
              )}

              {/* Form Fields */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
                    Tên bảo tàng (English Name) <span style={{ color: '#DC2626' }}>*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Vietnam National Museum of History"
                    style={{
                      width: '100%', padding: '10px 12px', borderRadius: '8px',
                      border: '1px solid #CBD5E1', fontSize: '14px', boxSizing: 'border-box'
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
                    Địa chỉ (English Address)
                  </label>
                  <input
                    type="text"
                    value={formData.address}
                    onChange={e => setFormData({ ...formData, address: e.target.value })}
                    placeholder="e.g. 1 Trang Tien Street, Hoan Kiem District, Hanoi"
                    style={{
                      width: '100%', padding: '10px 12px', borderRadius: '8px',
                      border: '1px solid #CBD5E1', fontSize: '14px', boxSizing: 'border-box'
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
                    Giờ mở cửa (English Opening Hours)
                  </label>
                  <input
                    type="text"
                    value={formData.openingHours}
                    onChange={e => setFormData({ ...formData, openingHours: e.target.value })}
                    placeholder="e.g. Daily: 8:00 AM - 5:00 PM"
                    style={{
                      width: '100%', padding: '10px 12px', borderRadius: '8px',
                      border: '1px solid #CBD5E1', fontSize: '14px', boxSizing: 'border-box'
                    }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
                    Mô tả giới thiệu (English Description)
                  </label>
                  <textarea
                    rows={4}
                    value={formData.description}
                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Write an introduction about the museum in English..."
                    style={{
                      width: '100%', padding: '10px 12px', borderRadius: '8px',
                      border: '1px solid #CBD5E1', fontSize: '14px', boxSizing: 'border-box',
                      resize: 'vertical'
                    }}
                  />
                </div>
              </div>
            </form>
          )}
        </div>

        {/* Footer */}
        <div style={{
          padding: '16px 24px', borderTop: '1px solid #E2E8F0',
          display: 'flex', justifyContent: 'flex-end', gap: '10px', backgroundColor: '#F8FAFC'
        }}>
          <button
            type="button"
            className="btn btn-secondary btn-sm"
            onClick={onClose}
            disabled={submitting}
          >
            Hủy
          </button>
          <button
            type="submit"
            form="museum-translation-form"
            className="btn btn-primary btn-sm"
            disabled={loading || submitting}
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            {submitting && <Loader2 size={14} className="animate-spin" />}
            Lưu bản dịch tiếng Anh
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}
