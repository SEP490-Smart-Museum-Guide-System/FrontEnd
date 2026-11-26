import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Globe, CheckCircle, AlertCircle, X, Loader2 } from 'lucide-react';
import { getArtifactTranslationApi, updateArtifactTranslationApi } from '../../services/artifactApi';

export default function ArtifactTranslationModal({ artifact, onClose, onSuccess, showToast }) {
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [isTranslated, setIsTranslated] = useState(false);
  const [name, setName] = useState('');

  useEffect(() => {
    let active = true;
    async function load() {
      if (!artifact?.id) return;
      setLoading(true);
      setError('');
      try {
        const data = await getArtifactTranslationApi(artifact.id, 'en');
        if (active && data) {
          setIsTranslated(Boolean(data.isTranslated));
          setName(data.name || '');
        }
      } catch (err) {
        if (active) setError(err.message || 'Không thể tải bản dịch tên hiện vật.');
      } finally {
        if (active) setLoading(false);
      }
    }
    load();
    return () => { active = false; };
  }, [artifact?.id]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Vui lòng nhập tên hiện vật bằng tiếng Anh.');
      return;
    }
    setSubmitting(true);
    setError('');
    try {
      await updateArtifactTranslationApi(artifact.id, 'en', name.trim());
      if (showToast) showToast('Đã lưu bản dịch tên tiếng Anh cho hiện vật thành công!');
      if (onSuccess) onSuccess();
      onClose();
    } catch (err) {
      setError(err.message || 'Không thể lưu tên tiếng Anh.');
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
          background: '#ffffff', borderRadius: '16px', maxWidth: '520px', width: '100%',
          display: 'flex', flexDirection: 'column', boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -6px rgba(0,0,0,0.1)',
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
                Dịch tên hiện vật (English Name)
              </h3>
              <p style={{ margin: 0, fontSize: '13px', color: '#64748B' }}>
                {artifact?.name || 'Hiện vật'}
              </p>
            </div>
          </div>
          <button aria-label="Đóng" className="dialog-icon-close"
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
        <div style={{ padding: '24px' }}>
          {loading ? (
            <div style={{ padding: '30px 0', textAlign: 'center', color: '#64748B' }}>
              <Loader2 size={26} className="animate-spin" style={{ margin: '0 auto 10px' }} />
              <p style={{ fontSize: '14px', margin: 0 }}>Đang tải bản dịch tên hiện vật...</p>
            </div>
          ) : (
            <form id="artifact-translation-form" onSubmit={handleSubmit}>
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
                      Hiện vật đã có tên tiếng Anh chính thức hiển thị cho khách quốc tế.
                    </span>
                  ) : (
                    <span style={{ color: '#B45309' }}>
                      <strong>Chưa có bản dịch tiếng Anh:</strong> Ô bên dưới đang hiển thị tên tiếng Việt dự phòng. Hãy nhập tên tiếng Anh tương ứng và nhấn Lưu.
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

              {/* Form Input */}
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
                  Tên hiện vật bằng tiếng Anh (English Name) <span style={{ color: '#DC2626' }}>*</span>
                </label>
                <input
                  type="text"
                  required
                  autoFocus
                  value={name}
                  onChange={e => setName(e.target.value)}
                  placeholder="e.g. Dong Son Bronze Drum"
                  style={{
                    width: '100%', padding: '10px 12px', borderRadius: '8px',
                    border: '1px solid #CBD5E1', fontSize: '14px', boxSizing: 'border-box'
                  }}
                />
                <p style={{ margin: '6px 0 0', fontSize: '12px', color: '#64748B' }}>
                  Lưu ý: Để dịch bài thuyết minh và mô tả dài, vui lòng sử dụng tab "Thuyết minh & Duyệt nội dung" để gửi Giám tuyển thẩm định.
                </p>
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
            form="artifact-translation-form"
            className="btn btn-primary btn-sm"
            disabled={loading || submitting}
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            {submitting && <Loader2 size={14} className="animate-spin" />}
            Lưu tên tiếng Anh
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}
