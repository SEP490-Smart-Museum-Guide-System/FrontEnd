import React from 'react';
import { createRoot } from 'react-dom/client';

function openDialog({
  message,
  title,
  confirmText,
  cancelText,
  destructive = false,
}) {
  return new Promise(resolve => {
    const host = document.createElement('div');
    host.dataset.smgsDialog = 'true';
    document.body.appendChild(host);
    const root = createRoot(host);
    let closed = false;

    const close = result => {
      if (closed) return;
      closed = true;
      window.removeEventListener('keydown', onKeyDown);
      root.unmount();
      host.remove();
      resolve(result);
    };
    const onKeyDown = event => {
      if (event.key === 'Escape' && cancelText) close(false);
    };
    window.addEventListener('keydown', onKeyDown);

    root.render(
      <div className="modal-overlay" onMouseDown={event => {
        if (event.target === event.currentTarget && cancelText) close(false);
      }}>
        <section
          className="modal-dialog"
          role="alertdialog"
          aria-modal="true"
          aria-label={title}
          style={{ maxWidth: '480px', width: '95vw' }}
          onMouseDown={event => event.stopPropagation()}
        >
          <div className="modal-header">
            <h3 className="modal-title font-serif" style={destructive ? { color: '#991B1B' } : undefined}>
              {title}
            </h3>
          </div>
          <div className="modal-body" style={{ padding: '20px 24px' }}>
            <p style={{ lineHeight: '1.6', whiteSpace: 'pre-line', margin: 0 }}>{message}</p>
          </div>
          <div className="modal-footer">
            {cancelText && (
              <button type="button" className="btn btn-secondary" autoFocus onClick={() => close(false)}>
                {cancelText}
              </button>
            )}
            <button
              type="button"
              className="btn btn-primary"
              style={destructive ? { background: '#B91C1C', borderColor: '#B91C1C' } : undefined}
              autoFocus={!cancelText}
              onClick={() => close(true)}
            >
              {confirmText}
            </button>
          </div>
        </section>
      </div>,
    );
  });
}

export function confirmAppDialog(message, options = {}) {
  return openDialog({
    message,
    title: options.title || 'Xác nhận',
    confirmText: options.confirmText || 'Xác nhận',
    cancelText: options.cancelText || 'Hủy',
    destructive: options.destructive,
  });
}

export function alertAppDialog(message, options = {}) {
  return openDialog({
    message,
    title: options.title || 'Thông báo',
    confirmText: options.confirmText || 'Đã hiểu',
    cancelText: null,
    destructive: options.destructive,
  });
}
