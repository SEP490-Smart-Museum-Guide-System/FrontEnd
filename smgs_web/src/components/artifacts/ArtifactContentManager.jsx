import React, { useState } from 'react';
import { backend } from '../../services/backend';
import { useApp } from '../../context/AppContext';
import { Field, LoadState, ErrorNotice, Empty, useData, useAction, statusLabels } from '../common/BusinessUI';
import { FileText, Send, CheckCircle, Clock, Volume2, Sparkles, History } from 'lucide-react';

export default function ArtifactContentManager({ artifactId, canWrite, canReadVersions }) {
  const { showToast, reload: appReload } = useApp();
  const data = useData(`content-panel:${artifactId}`, signal => Promise.all([
    backend(`artifacts/${artifactId}/contents/published/all`, { signal }),
    canReadVersions ? backend(`artifacts/${artifactId}/contents/versions`, { signal }) : []
  ]), [[], []]);

  const [form, setForm] = useState({ title: '', description: '', narrationText: '', audioUrl: '' });
  const [successMsg, setSuccessMsg] = useState('');
  const action = useAction();

  const change = e => {
    setSuccessMsg('');
    setForm(p => ({ ...p, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSuccessMsg('');
    const ok = await action.run(
      () => backend(`artifacts/${artifactId}/contents/manual`, {
        method: 'POST',
        body: {
          ...form,
          title: form.title.trim(),
          description: form.description.trim(),
          languageCode: 'vi',
          narrationText: form.narrationText.trim() || null,
          audioUrl: form.audioUrl.trim() || null,
          isAiGenerated: false
        }
      }),
      () => {
        setForm({ title: '', description: '', narrationText: '', audioUrl: '' });
        setSuccessMsg('Đã đệ trình nội dung lên hàng đợi Giám tuyển thành công! Bản thảo đang ở trạng thái Chờ thẩm định.');
        showToast('Đã gửi nội dung lên hàng đợi thẩm định của Giám tuyển thành công!', 'success');
        data.reload();
        if (typeof appReload === 'function') appReload();
      }
    );
    if (!ok && action.error) {
      showToast(action.error, 'error');
    }
  };

  const publishedItems = data?.data?.[0] || [];
  const versionItems = data?.data?.[1] || [];

  return (
    <details
      className="card business-card"
      style={{
        padding: '16px 20px',
        marginBottom: '20px',
        background: '#FFFDF9',
        border: '1px solid var(--color-paper-border)',
        borderRadius: '12px',
        boxShadow: 'var(--shadow-sm)'
      }}
    >
      <summary style={{
        cursor: 'pointer',
        fontWeight: '600',
        fontSize: '0.925rem',
        color: 'var(--color-burgundy-900)',
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        userSelect: 'none',
        outline: 'none'
      }}>
        <FileText size={18} color="var(--color-burgundy-700)" />
        <span>Nội dung đã xuất bản & Soạn thảo thuyết minh</span>
        {publishedItems.length > 0 ? (
          <span style={{
            fontSize: '0.72rem',
            padding: '2px 8px',
            borderRadius: '10px',
            background: 'var(--color-success-bg, #DCFCE7)',
            color: 'var(--color-success, #166534)',
            marginLeft: 'auto',
            fontWeight: '600'
          }}>
            Đã có bài xuất bản
          </span>
        ) : (
          <span style={{
            fontSize: '0.72rem',
            padding: '2px 8px',
            borderRadius: '10px',
            background: 'var(--color-warning-bg, #FEF3C7)',
            color: 'var(--color-warning, #92400E)',
            marginLeft: 'auto',
            fontWeight: '600'
          }}>
            Chưa có bài xuất bản
          </span>
        )}
      </summary>

      <div style={{ marginTop: '16px', paddingTop: '14px', borderTop: '1px solid var(--color-paper-border)' }}>
        <LoadState resource={data}>
          {/* SECTION 1: PUBLISHED CONTENT */}
          <div style={{ marginBottom: '20px' }}>
            <h4 style={{ fontSize: '0.875rem', fontWeight: '700', color: 'var(--color-charcoal-900)', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Volume2 size={16} color="var(--color-burgundy-700)" />
              Nội dung đang công bố cho Khách tham quan:
            </h4>
            {!publishedItems.length ? (
              <div style={{ padding: '12px 16px', background: 'var(--color-paper-accent)', borderRadius: '8px', color: 'var(--color-charcoal-600)', fontSize: '0.85rem' }}>
                Hiện vật chưa có bài thuyết minh nào được Giám tuyển phê duyệt xuất bản. Hãy soạn thảo nội dung bên dưới và gửi kiểm duyệt.
              </div>
            ) : (
              publishedItems.map(c => (
                <article
                  key={c.id || c.languageCode}
                  style={{
                    padding: '12px 16px',
                    background: '#FFF',
                    borderRadius: '8px',
                    border: '1px solid var(--color-paper-border)',
                    marginBottom: '10px'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '6px' }}>
                    <strong style={{ fontSize: '0.9rem', color: 'var(--color-charcoal-900)' }}>{c.title}</strong>
                    <span style={{ fontSize: '0.72rem', padding: '1px 6px', borderRadius: '4px', background: 'var(--color-paper-accent)', fontWeight: '700' }}>
                      Ngôn ngữ: {c.languageCode?.toUpperCase()}
                    </span>
                  </div>
                  <p style={{ whiteSpace: 'pre-wrap', fontSize: '0.85rem', color: 'var(--color-charcoal-700)', lineHeight: 1.5, margin: '6px 0' }}>
                    {c.description}
                  </p>
                  {c.narrationText && (
                    <div style={{ marginTop: '8px', padding: '8px 12px', background: '#F8F5EE', borderRadius: '6px', borderLeft: '3px solid var(--color-burgundy-700)' }}>
                      <span style={{ fontSize: '0.75rem', fontWeight: '600', color: 'var(--color-burgundy-800)', display: 'block', marginBottom: '2px' }}>
                        Kịch bản đọc thuyết minh (TTS AI):
                      </span>
                      <p style={{ whiteSpace: 'pre-wrap', fontSize: '0.825rem', color: 'var(--color-charcoal-700)', margin: 0 }}>
                        {c.narrationText}
                      </p>
                    </div>
                  )}
                  {c.audioUrl && (
                    <div style={{ marginTop: '10px' }}>
                      <audio controls src={c.audioUrl} style={{ width: '100%', height: '36px' }} />
                    </div>
                  )}
                </article>
              ))
            )}
          </div>

          {/* SECTION 2: VERSION HISTORY */}
          {canReadVersions && versionItems.length > 0 && (
            <div style={{ marginBottom: '20px' }}>
              <h4 style={{ fontSize: '0.875rem', fontWeight: '700', color: 'var(--color-charcoal-900)', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <History size={16} color="var(--color-charcoal-600)" />
                Lịch sử phiên bản đệ trình ({versionItems.length}):
              </h4>
              <div style={{ display: 'grid', gap: '6px', maxHeight: '180px', overflowY: 'auto', paddingRight: '4px' }}>
                {versionItems.map(c => {
                  const isApproved = c.status === 'published';
                  const isPending = c.status === 'pending_review';
                  const statusBg = isApproved ? '#DCFCE7' : isPending ? '#FEF3C7' : '#FEE2E2';
                  const statusColor = isApproved ? '#166534' : isPending ? '#92400E' : '#991B1B';
                  return (
                    <div
                      key={c.id}
                      style={{
                        padding: '8px 12px',
                        background: '#FFF',
                        borderRadius: '6px',
                        border: '1px solid var(--color-paper-border)',
                        fontSize: '0.8rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        gap: '10px'
                      }}
                    >
                      <div>
                        <strong>{c.title}</strong>
                        <span style={{ color: 'var(--color-charcoal-500)', marginLeft: '8px' }}>
                          • {new Date(c.createdAt).toLocaleString('vi-VN')}
                        </span>
                        {c.reviewNote && (
                          <span style={{ color: 'var(--color-burgundy-700)', display: 'block', fontSize: '0.75rem', marginTop: '2px' }}>
                            Ý kiến giám tuyển: {c.reviewNote}
                          </span>
                        )}
                      </div>
                      <span style={{
                        padding: '2px 8px',
                        borderRadius: '10px',
                        fontSize: '0.7rem',
                        fontWeight: '600',
                        background: statusBg,
                        color: statusColor,
                        flexShrink: 0
                      }}>
                        {statusLabels[c.status] || (isPending ? 'Chờ thẩm định' : isApproved ? 'Đã xuất bản' : c.status)}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </LoadState>

        {/* SECTION 3: WRITE & SUBMIT FORM */}
        {canWrite && (
          <form
            onSubmit={handleSubmit}
            style={{
              marginTop: '16px',
              padding: '16px',
              background: '#FFF',
              borderRadius: '8px',
              border: '1.5px solid var(--color-gold-300)',
              boxShadow: 'var(--shadow-sm)'
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
              <Sparkles size={16} color="var(--color-burgundy-700)" />
              <h4 style={{ margin: 0, fontSize: '0.9rem', color: 'var(--color-burgundy-900)' }}>
                Soạn thảo phiên bản thuyết minh mới (Gửi Giám tuyển thẩm định)
              </h4>
            </div>

            {/* Success message banner */}
            {successMsg && (
              <div style={{
                padding: '10px 14px',
                background: '#F0FDF4',
                border: '1px solid #BBF7D0',
                borderRadius: '8px',
                color: '#166534',
                fontSize: '0.85rem',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                marginBottom: '14px'
              }}>
                <CheckCircle size={18} color="#16A34A" style={{ flexShrink: 0 }} />
                <span>{successMsg}</span>
              </div>
            )}

            {/* Error message banner */}
            <ErrorNotice>{action.error}</ErrorNotice>

            <Field label="Tiêu đề bài thuyết minh">
              <input
                className="form-input"
                name="title"
                required
                maxLength={300}
                placeholder="VD: Thạp đồng Đào Thịnh - Đỉnh cao nghệ thuật đúc đồng Đông Sơn"
                value={form.title}
                onChange={change}
              />
            </Field>

            <Field label="Nội dung giới thiệu chi tiết (Hiện trên App và Web)">
              <textarea
                className="form-input"
                name="description"
                required
                maxLength={100000}
                rows={5}
                placeholder="Nhập nội dung lịch sử, niên đại, xuất xứ, ý nghĩa khảo cổ và văn hóa của hiện vật..."
                value={form.description}
                onChange={change}
              />
            </Field>

            <Field label="Kịch bản thuyết minh giọng đọc AI (Dùng cho Audio Guide tự động)">
              <textarea
                className="form-input"
                name="narrationText"
                maxLength={100000}
                rows={3}
                placeholder="Kịch bản lời dẫn truyền cảm để hệ thống AI Voice thuyết minh tự động cho khách tham quan..."
                value={form.narrationText}
                onChange={change}
              />
            </Field>

            <Field label="Đường dẫn tệp Audio thu âm sẵn (Tùy chọn nếu có sẵn file MP3/WAV)">
              <input
                className="form-input"
                name="audioUrl"
                maxLength={1000}
                placeholder="https://.../narration.mp3"
                value={form.audioUrl}
                onChange={change}
              />
            </Field>

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px', marginTop: '14px' }}>
              <p style={{ margin: 0, fontSize: '0.78rem', color: 'var(--color-charcoal-500)', lineHeight: 1.4 }}>
                Nội dung sau khi gửi sẽ chuyển thành phiên bản mới trong Hàng đợi thẩm định của Giám tuyển.
              </p>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={action.busy}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '8px 18px',
                  borderRadius: '8px'
                }}
              >
                <Send size={15} />
                <span>{action.busy ? 'Đang gửi kiểm duyệt...' : 'Gửi kiểm duyệt'}</span>
              </button>
            </div>
          </form>
        )}
      </div>
    </details>
  );
}
