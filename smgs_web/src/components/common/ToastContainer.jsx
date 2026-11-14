import React from 'react';
import { createPortal } from 'react-dom';
import { useApp } from '../../context/AppContext';
import { CheckCircle, AlertTriangle, AlertCircle, Info, X } from 'lucide-react';

export default function ToastContainer() {
  const { toasts, dismissToast } = useApp();



  return createPortal(
    <div className="toast-container" aria-label="Thông báo thao tác" aria-live="polite" aria-relevant="additions">
      {toasts.map(toast => {
        const isError = toast.type === 'error';
        const isWarning = toast.type === 'warning';
        const isInfo = toast.type === 'info';
        const className = `toast ${isError ? 'toast-error' : isWarning ? 'toast-warning' : isInfo ? 'toast-info' : 'toast-success'}`;
        return (
          <div key={toast.id} className={className} role={isError ? "alert" : "status"}>
            {isError ? (
              <AlertCircle size={20} color="var(--color-danger, #DC2626)" style={{ flexShrink: 0 }} />
            ) : isWarning ? (
              <AlertTriangle size={20} color="var(--color-warning, #D97706)" style={{ flexShrink: 0 }} />
            ) : isInfo ? (
              <Info size={20} color="var(--color-info, #2563EB)" style={{ flexShrink: 0 }} />
            ) : (
              <CheckCircle size={20} color="var(--color-success, #16A34A)" style={{ flexShrink: 0 }} />
            )}
            <span style={{ fontSize: '0.875rem', fontWeight: '500', color: 'var(--color-charcoal-900)', flex: 1, lineHeight: 1.4 }}>
              {toast.message}
            </span>
            <button type="button" className="toast-close" aria-label="Đóng thông báo" onClick={() => dismissToast(toast.id)}><X size={18} /></button>
          </div>
        );
      })}
    </div>, document.body
  );
}
