import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  MessageSquare,
  Star,
  User,
  Clock,
  Send,
  CheckCircle,
  Landmark,
  Layers,
  MessageCircle
} from 'lucide-react';

export default function ReviewManager() {
  const { reviews, replyToReview } = useApp();
  const [filterStatus, setFilterStatus] = useState('all'); // 'all' | 'pending_reply' | 'replied'
  const [replyingId, setReplyingId] = useState(null);
  const [replyText, setReplyText] = useState('');

  const filteredReviews = reviews.filter(r => {
    if (filterStatus !== 'all' && r.status !== filterStatus) return false;
    return true;
  });

  const handleSendReply = (reviewId) => {
    if (!replyText.trim()) return;
    replyToReview(reviewId, replyText);
    setReplyingId(null);
    setReplyText('');
  };

  const pendingCount = reviews.filter(r => r.status === 'pending_reply').length;
  const avgRating = (reviews.reduce((acc, curr) => acc + curr.rating, 0) / (reviews.length || 1)).toFixed(1);

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Đánh Giá & Phản Hồi Từ Khách Tham Quan
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Theo dõi trải nghiệm của khách tham quan di sản và gửi phản hồi đại diện chính thức từ Ban Quản lý Bảo tàng
          </p>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="stat-grid" style={{ marginBottom: '24px' }}>
        <div className="stat-card stat-card-gold">
          <div className="stat-icon-wrapper">
            <Star size={24} color="#EAB308" fill="#EAB308" />
          </div>
          <div>
            <div className="stat-value">{avgRating} / 5.0</div>
            <div className="stat-label">Điểm hài lòng trung bình</div>
          </div>
        </div>

        <div className="stat-card stat-card-burgundy">
          <div className="stat-icon-wrapper">
            <MessageSquare size={24} />
          </div>
          <div>
            <div className="stat-value">{reviews.length}</div>
            <div className="stat-label">Tổng số lượt đánh giá</div>
          </div>
        </div>

        <div className="stat-card stat-card-blue">
          <div className="stat-icon-wrapper">
            <MessageCircle size={24} />
          </div>
          <div>
            <div className="stat-value">{pendingCount}</div>
            <div className="stat-label">Đánh giá cần phản hồi</div>
          </div>
        </div>
      </div>

      {/* Filter tabs */}
      <div style={{ display: 'flex', gap: '10px', marginBottom: '20px' }}>
        {[
          { id: 'all', label: 'Tất cả đánh giá' },
          { id: 'pending_reply', label: `Chờ phản hồi (${pendingCount})` },
          { id: 'replied', label: 'Đã phản hồi' }
        ].map(tab => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setFilterStatus(tab.id)}
            className={`btn btn-sm ${filterStatus === tab.id ? 'btn-primary' : 'btn-secondary'}`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Reviews List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {filteredReviews.length > 0 ? (
          filteredReviews.map(rev => (
            <div key={rev.id} className="card" style={{ padding: '20px 24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{
                    width: '38px',
                    height: '38px',
                    borderRadius: '50%',
                    background: 'var(--color-paper-accent)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: '700',
                    color: 'var(--color-burgundy-800)',
                    fontSize: '0.875rem'
                  }}>
                    {rev.visitorName.charAt(0)}
                  </div>
                  <div>
                    <div style={{ fontWeight: '700', fontSize: '0.9375rem', color: 'var(--color-charcoal-900)' }}>
                      {rev.visitorName}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                      {rev.visitorEmail} • {rev.date}
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  {[...Array(5)].map((_, idx) => (
                    <Star
                      key={idx}
                      size={16}
                      color={idx < rev.rating ? '#EAB308' : '#CBD5E1'}
                      fill={idx < rev.rating ? '#EAB308' : 'none'}
                    />
                  ))}
                </div>
              </div>

              {/* Artifact association tag */}
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', background: '#F8F5EE', padding: '4px 10px', borderRadius: '6px', fontSize: '0.75rem', color: 'var(--color-burgundy-900)', fontWeight: '600', marginBottom: '12px' }}>
                <Layers size={13} /> Hiện vật: {rev.artifactName} ({rev.museumName})
              </div>

              {/* Visitor Comment */}
              <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-800)', lineHeight: '1.6', marginBottom: '16px' }}>
                "{rev.comment}"
              </p>

              {/* Official Museum Reply */}
              {rev.officialReply ? (
                <div style={{
                  background: 'var(--color-paper-accent)',
                  padding: '14px 18px',
                  borderRadius: '8px',
                  borderLeft: '4px solid var(--color-burgundy-700)',
                  marginTop: '8px'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '4px' }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: '700', color: 'var(--color-burgundy-900)', textTransform: 'uppercase' }}>
                      🏛 Phản hồi từ Ban Quản Lý Bảo Tàng:
                    </span>
                    <span style={{ fontSize: '0.7rem', color: 'var(--color-charcoal-500)' }}>
                      {rev.replyDate}
                    </span>
                  </div>
                  <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-800)', lineHeight: '1.5' }}>
                    {rev.officialReply}
                  </p>
                </div>
              ) : replyingId === rev.id ? (
                <div style={{ marginTop: '12px', background: '#FAF7F2', padding: '16px', borderRadius: '8px', border: '1px solid var(--color-paper-border)' }}>
                  <label className="form-label">Nội dung phản hồi đại diện cho Bảo tàng:</label>
                  <textarea
                    className="form-textarea"
                    rows={3}
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    placeholder="Kính gửi quý khách..."
                  />
                  <div style={{ display: 'flex', gap: '8px', marginTop: '10px' }}>
                    <button
                      type="button"
                      onClick={() => handleSendReply(rev.id)}
                      className="btn btn-primary btn-sm"
                    >
                      <Send size={14} /> Gửi phản hồi chính thức
                    </button>
                    <button
                      type="button"
                      onClick={() => setReplyingId(null)}
                      className="btn btn-secondary btn-sm"
                    >
                      Hủy
                    </button>
                  </div>
                </div>
              ) : (
                <div>
                  <button
                    type="button"
                    onClick={() => {
                      setReplyingId(rev.id);
                      setReplyText('');
                    }}
                    className="btn btn-secondary btn-sm"
                  >
                    <Send size={14} /> Trả lời phản hồi này
                  </button>
                </div>
              )}
            </div>
          ))
        ) : (
          <div className="card" style={{ padding: '40px', textAlign: 'center', color: 'var(--color-charcoal-500)' }}>
            Không tìm thấy đánh giá nào.
          </div>
        )}
      </div>
    </div>
  );
}
