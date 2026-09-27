import React from 'react';
import { useApp } from '../../context/AppContext';
import { CheckCircle, AlertTriangle, Info, X } from 'lucide-react';

export default function ToastContainer() {
  const { toasts } = useApp();

  if (!toasts || toasts.length === 0) return null;

  return (
    <div className="toast-container">
      {toasts.map(toast => (
        <div
          key={toast.id}
          className={`toast ${toast.type === 'warning' ? 'toast-warning' : toast.type === 'info' ? 'toast-info' : 'toast-success'}`}
        >
          {toast.type === 'warning' ? (
            <AlertTriangle size={18} color="var(--color-warning)" />
          ) : toast.type === 'info' ? (
            <Info size={18} color="var(--color-info)" />
          ) : (
            <CheckCircle size={18} color="var(--color-success)" />
          )}
          <span style={{ fontSize: '0.875rem', fontWeight: '500', color: 'var(--color-charcoal-900)' }}>
            {toast.message}
          </span>
        </div>
      ))}
    </div>
  );
}
