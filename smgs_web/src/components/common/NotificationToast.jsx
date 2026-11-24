import React from 'react';
import { useNotification } from '../../context/NotificationContext';
import {
  Bell,
  X,
  BookOpenCheck,
  CheckCircle2,
  XCircle,
  CreditCard,
  MessageSquare,
  AlertTriangle,
  HelpCircle
} from 'lucide-react';

function getToastIcon(type) {
  switch (type) {
    case 'CONTENT_SUBMITTED':
      return <BookOpenCheck size={20} color="var(--color-gold-700)" />;
    case 'CONTENT_APPROVED':
      return <CheckCircle2 size={20} color="#16a34a" />;
    case 'CONTENT_REJECTED':
      return <XCircle size={20} color="var(--color-burgundy-700)" />;
    case 'PAYMENT_SUCCEEDED':
      return <CreditCard size={20} color="#16a34a" />;
    case 'FEEDBACK_RESPONDED':
      return <MessageSquare size={20} color="#0284c7" />;
    case 'COMPLAINT_CREATED':
      return <AlertTriangle size={20} color="#d97706" />;
    case 'COMPLAINT_STATUS_UPDATED':
      return <HelpCircle size={20} color="#0284c7" />;
    default:
      return <Bell size={20} color="var(--color-burgundy-700)" />;
  }
}

export default function NotificationToast({ onNavigate }) {
  const { activeToast, dismissToast, markAsRead } = useNotification();

  if (!activeToast) return null;

  const handleClick = async () => {
    try {
      await markAsRead(activeToast.id);
    } catch (_) {}
    if (onNavigate) {
      onNavigate(activeToast);
    }
    dismissToast();
  };

  return (
    <div
      role="alert"
      aria-live="assertive"
      style={{
        position: 'fixed',
        top: '74px',
        right: '24px',
        zIndex: 9999,
        width: '360px',
        maxWidth: '90vw',
        background: '#FFFDF9',
        borderRadius: '14px',
        border: '1.5px solid var(--color-burgundy-700)',
        boxShadow: '0 20px 40px rgba(58, 38, 28, 0.22)',
        padding: '14px 16px',
        display: 'flex',
        alignItems: 'flex-start',
        gap: '12px',
        cursor: 'pointer',
        animation: 'menuAppear 180ms ease-out'
      }}
      onClick={handleClick}
    >
      {/* Icon */}
      <div
        style={{
          width: '38px',
          height: '38px',
          borderRadius: '10px',
          background: 'var(--color-paper-accent)',
          border: '1px solid var(--color-paper-border)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0
        }}
      >
        {getToastIcon(activeToast.type)}
      </div>

      {/* Content */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '2px' }}>
          <span
            style={{
              fontSize: '0.68rem',
              fontWeight: '700',
              textTransform: 'uppercase',
              letterSpacing: '0.6px',
              color: 'var(--color-burgundy-700)'
            }}
          >
            Thông báo mới
          </span>
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              dismissToast();
            }}
            style={{
              background: 'none',
              border: 'none',
              color: 'var(--color-charcoal-400)',
              cursor: 'pointer',
              padding: '2px'
            }}
            title="Đóng"
          >
            <X size={15} />
          </button>
        </div>

        <h4
          style={{
            fontSize: '0.86rem',
            fontWeight: '700',
            color: 'var(--color-charcoal-900)',
            margin: '0 0 3px 0',
            lineHeight: 1.3
          }}
        >
          {activeToast.title}
        </h4>

        <p
          style={{
            fontSize: '0.78rem',
            color: 'var(--color-charcoal-600)',
            margin: 0,
            lineHeight: 1.35,
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            overflow: 'hidden'
          }}
        >
          {activeToast.body}
        </p>
      </div>
    </div>
  );
}
