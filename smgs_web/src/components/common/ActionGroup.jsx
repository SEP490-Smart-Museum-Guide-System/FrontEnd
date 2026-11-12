import React, { useEffect, useId, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { MoreHorizontal } from 'lucide-react';

function actions(children) {
  return React.Children.toArray(children).flatMap(child =>
    child.type === React.Fragment ? actions(child.props.children) : [child]);
}

// Keep the main action visible; secondary actions remain keyboard accessible.
export default function ActionGroup({ children, label = 'Thao tác khác', visible = 1 }) {
  const items = actions(children);
  const trigger = useRef(null), panel = useRef(null);
  const [position, setPosition] = useState(null);
  const id = useId();
  const close = (restore = false) => { setPosition(null); if (restore) trigger.current?.focus(); };
  useEffect(() => {
    if (!position) return;
    panel.current?.querySelector('button:not(:disabled)')?.focus();
    const outside = e => { if (!panel.current?.contains(e.target) && !trigger.current?.contains(e.target)) close(); };
    const key = e => { if (e.key === 'Escape') { e.preventDefault(); close(true); } };
    const reposition = () => close();
    document.addEventListener('pointerdown', outside);
    document.addEventListener('keydown', key);
    window.addEventListener('resize', reposition);
    return () => {
      document.removeEventListener('pointerdown', outside);
      document.removeEventListener('keydown', key);
      window.removeEventListener('resize', reposition);
    };
  }, [position]);
  const named = child => child.props.title
    ? React.cloneElement(child, { 'aria-label': child.props['aria-label'] || child.props.title }) : child;
  return <div className="action-group">
    {items.slice(0, visible).map(named)}
    {items.length > visible && (
      <button
        ref={trigger}
        type="button"
        className="btn btn-secondary btn-sm action-trigger"
        aria-label={label}
        aria-expanded={!!position}
        aria-controls={position ? id : undefined}
        title={label}
        onClick={() => {
          if (position) return close();
          const rect = trigger.current.getBoundingClientRect();
          setPosition({
            right: Math.max(12, window.innerWidth - rect.right),
            ...(rect.bottom + 280 < window.innerHeight ? { top: rect.bottom + 6 } : { bottom: window.innerHeight - rect.top + 6 })
          });
        }}
      >
        <MoreHorizontal size={16} />
        <span className="action-trigger-label">Thao tác</span>
      </button>
    )}
    {position && createPortal(
      <div
        ref={panel}
        id={id}
        className="action-popover"
        role="group"
        aria-label={label}
        style={position}
        onBlur={e => {
          if (e.relatedTarget && !e.currentTarget.contains(e.relatedTarget) && e.relatedTarget !== trigger.current) close();
        }}
      >
        {items.slice(visible).map((child, index) =>
          React.cloneElement(child, {
            key: child.key || index,
            className: `action-option ${child.props.className || ''}`.replace(/\bbtn\b|\bbtn-[a-z0-9-]+\b/g, '').trim(),
            style: undefined,
            onClick: e => {
              child.props.onClick?.(e);
              close(true);
            },
            children: child.props.children || child.props.title,
          })
        )}
      </div>,
      document.body
    )}
  </div>;
}
