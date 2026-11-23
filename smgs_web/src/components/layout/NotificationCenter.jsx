import React, { useState } from 'react';
import { useNotification } from '../../context/NotificationContext';
import {
  Bell,
  Check,
  CheckCheck,
  Trash2,
  BookOpenCheck,
  CheckCircle2,
  XCircle,
  CreditCard,
  MessageSquare,
  AlertTriangle,
  HelpCircle,
  Clock,
  ExternalLink
} from 'lucide-react';

function getNotificationIcon(type) {
  switch (type) {
    case 'CONTENT_SUBMITTED':
      return <BookOpenCheck size={18} color="var(--color-gold-700)" />;
    case 'CONTENT_APPROVED':
      return <CheckCircle2 size={18} color="#16a34a" />;
    case 'CONTENT_REJECTED':
      return <XCircle size={18} color="var(--color-burgundy-700)" />;
    case 'PAYMENT_SUCCEEDED':
      return <CreditCard size={18} color="#16a34a" />;
    case 'FEEDBACK_RESPONDED':
      return <MessageSquare size={18} color="#0284c7" />;
    case 'COMPLAINT_CREATED':
      return <AlertTriangle size={18} color="#d97706" />;
    case 'COMPLAINT_STATUS_UPDATED':
      return <HelpCircle size={18} color="#0284c7" />;
    default:
      return <Bell size={18} color="var(--color-burgundy-700)" />;
  }
}

function formatRelativeTime(dateStr) {
  if (!dateStr) return '';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return String(dateStr);
    const now = new Date();
    const diffSec = Math.floor((now - d) / 1000);
    if (diffSec < 60) return 'Vừa xong';
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) return `${diffMin} phút trước`;
    const diffHours = Math.floor(diffMin / 60);
    if (diffHours < 24) return `${diffHours} giờ trước`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 7) return `${diffDays} ngày trước`;
    return `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}/${d.getFullYear()}`;
  } catch {
    return String(dateStr);
  }
}

export default function NotificationCenter({ onClose, onNavigate }) {
  const {
    unreadCount,
    notifications,
    pagination,
    loading,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    fetchNotifications
  } = useNotification();

  const [activeTab, setActiveTab] = useState('all'); // 'all' | 'unread'
  const [markingAll, setMarkingAll] = useState(false);

  const displayedNotifications = activeTab === 'unread'
    ? notifications.filter((n) => !n.isRead)
    : notifications;

  const handleMarkAll = async () => {
    if (unreadCount === 0 || markingAll) return;
    setMarkingAll(true);
    try {
      await markAllAsRead();
    } finally {
      setMarkingAll(false);
    }
  };

  const handleItemClick = async (item) => {
    if (!item.isRead) {
      try {
        await markAsRead(item.id);
      } catch (_) {}
    }
    if (onNavigate) {
      onNavigate(item);
    }
    if (onClose) {
      onClose();
    }
  };

  const handleDelete = async (e, id) => {
    e.stopPropagation();
    try {
      await deleteNotification(id);
    } catch (_) {}
  };

  const handleLoadMore = () => {
    if (pagination.page < pagination.totalPages && !loading) {
      fetchNotifications({
        page: pagination.page + 1,
        pageSize: pagination.pageSize,
        append: true
      });
    }
  };

  return (
    <div
      role="dialog"
      aria-label="Trung tâm thông báo"
      style={{
        position: 'absolute',
        top: 'calc(100% + 10px)',
        right: 0,
        zIndex: 1050,
        width: '380px',
        maxWidth: '92vw',
        background: '#FFFDF9',
        borderRadius: '16px',
        border: '1px solid var(--color-paper-border)',
        boxShadow: '0 16px 48px rgba(58, 38, 28, 0.18)',
        display: 'flex',
        flexDirection: 'column',
        maxHeight: '520px',
        overflow: 'hidden',
        animation: 'menuAppear 150ms ease-out'
      }}
    >
      {/* Header */}
      <div
        style={{
          padding: '14px 16px 10px',
          borderBottom: '1px solid var(--color-paper-border)',
          background: '#FFF'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: '700', color: 'var(--color-charcoal-900)', margin: 0 }}>
              Thông báo
            </h3>
            {unreadCount > 0 && (
              <span
                style={{
                  fontSize: '0.72rem',
                  fontWeight: '700',
                  padding: '2px 7px',
                  borderRadius: '10px',
                  background: 'var(--color-burgundy-700)',
                  color: '#FFF'
                }}
              >
                {unreadCount} mới
              </span>
            )}
          </div>

          {unreadCount > 0 && (
            <button
              type="button"
              onClick={handleMarkAll}
              disabled={markingAll}
              style={{
                background: 'none',
                border: 'none',
                fontSize: '0.76rem',
                color: 'var(--color-burgundy-700)',
                cursor: 'pointer',
                fontWeight: '600',
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
                padding: '4px 6px',
                borderRadius: '6px'
              }}
              title="Đánh dấu tất cả là đã đọc"
            >
              <CheckCheck size={14} />
              {markingAll ? 'Đang cập nhật…' : 'Đọc tất cả'}
            </button>
          )}
        </div>

        {/* Filter Tabs */}
        <div style={{ display: 'flex', gap: '6px' }}>
          <button
            type="button"
            onClick={() => setActiveTab('all')}
            style={{
              flex: 1,
              padding: '6px 10px',
              fontSize: '0.78rem',
              fontWeight: activeTab === 'all' ? '700' : '500',
              borderRadius: '8px',
              border: 'none',
              background: activeTab === 'all' ? 'var(--color-paper-accent)' : 'transparent',
              color: activeTab === 'all' ? 'var(--color-burgundy-700)' : 'var(--color-charcoal-600)',
              cursor: 'pointer',
              transition: 'all var(--transition-fast)'
            }}
          >
            Tất cả ({notifications.length})
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('unread')}
            style={{
              flex: 1,
              padding: '6px 10px',
              fontSize: '0.78rem',
              fontWeight: activeTab === 'unread' ? '700' : '500',
              borderRadius: '8px',
              border: 'none',
              background: activeTab === 'unread' ? 'var(--color-paper-accent)' : 'transparent',
              color: activeTab === 'unread' ? 'var(--color-burgundy-700)' : 'var(--color-charcoal-600)',
              cursor: 'pointer',
              transition: 'all var(--transition-fast)'
            }}
          >
            Chưa đọc ({unreadCount})
          </button>
        </div>
      </div>

      {/* List Body */}
      <div
        style={{
          flex: 1,
          overflowY: 'auto',
          padding: '6px 0'
        }}
      >
        {displayedNotifications.length === 0 ? (
          <div style={{ padding: '40px 20px', textAlign: 'center', color: 'var(--color-charcoal-500)' }}>
            <Bell size={32} style={{ margin: '0 auto 10px', opacity: 0.3 }} />
            <p style={{ fontSize: '0.86rem', margin: 0, fontWeight: '500' }}>
              {activeTab === 'unread' ? 'Bạn không có thông báo chưa đọc nào.' : 'Chưa có thông báo nào.'}
            </p>
          </div>
        ) : (
          displayedNotifications.map((item) => (
            <div
              key={item.id}
              onClick={() => handleItemClick(item)}
              style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: '12px',
                padding: '12px 16px',
                cursor: 'pointer',
                background: item.isRead ? 'transparent' : 'rgba(107, 46, 46, 0.04)',
                borderBottom: '1px solid var(--color-paper-border)',
                transition: 'background var(--transition-fast)',
                position: 'relative'
              }}
              onMouseEnter={(e) => (e.currentTarget.style.background = 'rgba(107, 46, 46, 0.08)')}
              onMouseLeave={(e) =>
                (e.currentTarget.style.background = item.isRead ? 'transparent' : 'rgba(107, 46, 46, 0.04)')
              }
            >
              {/* Icon Container */}
              <div
                style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: '10px',
                  background: '#FFF',
                  border: '1px solid var(--color-paper-border)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0
                }}
              >
                {getNotificationIcon(item.type)}
              </div>

              {/* Text content */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '6px' }}>
                  <h4
                    style={{
                      fontSize: '0.84rem',
                      fontWeight: item.isRead ? '600' : '700',
                      color: 'var(--color-charcoal-900)',
                      margin: '0 0 2px 0',
                      lineHeight: 1.3
                    }}
                  >
                    {item.title}
                  </h4>
                  {!item.isRead && (
                    <span
                      style={{
                        width: '7px',
                        height: '7px',
                        borderRadius: '50%',
                        background: 'var(--color-burgundy-700)',
                        flexShrink: 0
                      }}
                      title="Chưa đọc"
                    />
                  )}
                </div>

                <p
                  style={{
                    fontSize: '0.76rem',
                    color: 'var(--color-charcoal-600)',
                    margin: '0 0 6px 0',
                    lineHeight: 1.35,
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                    overflow: 'hidden'
                  }}
                >
                  {item.body}
                </p>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: '0.7rem', color: 'var(--color-charcoal-500)', display: 'flex', alignItems: 'center', gap: '3px' }}>
                    <Clock size={11} /> {formatRelativeTime(item.createdAt)}
                  </span>

                  <button
                    type="button"
                    onClick={(e) => handleDelete(e, item.id)}
                    style={{
                      background: 'none',
                      border: 'none',
                      padding: '2px 4px',
                      color: 'var(--color-charcoal-400)',
                      cursor: 'pointer',
                      borderRadius: '4px'
                    }}
                    title="Xóa thông báo"
                    onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--color-danger)')}
                    onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--color-charcoal-400)')}
                  >
                    <Trash2 size={13} />
                  </button>
                </div>
              </div>
            </div>
          ))
        )}

        {/* Load more button */}
        {pagination.page < pagination.totalPages && (
          <div style={{ padding: '8px 16px', textAlign: 'center' }}>
            <button
              type="button"
              onClick={handleLoadMore}
              disabled={loading}
              className="btn btn-secondary btn-sm"
              style={{ width: '100%', fontSize: '0.76rem', padding: '6px' }}
            >
              {loading ? 'Đang tải thêm…' : 'Xem các thông báo cũ hơn'}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
