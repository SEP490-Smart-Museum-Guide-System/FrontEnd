import React, { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

export function useData(key, loader, initial = null) {
  const loadRef = useRef(loader); loadRef.current = loader;
  const [revision, setRevision] = useState(0);
  const [state, setState] = useState({ key: null, busy: true, data: initial, error: '' });
  useEffect(() => {
    const controller = new AbortController();
    setState({ key, busy: true, data: initial, error: '' });
    Promise.resolve().then(() => loadRef.current(controller.signal)).then(data => {
      if (!controller.signal.aborted) setState({ key, data, busy: false, error: '' });
    }).catch(e => { if (!controller.signal.aborted) setState({ key, data: initial, busy: false, error: e.message }); });
    return () => controller.abort();
  }, [key, revision]);
  return { ...(state.key === key ? state : { data: initial, busy: true, error: '' }), reload: () => setRevision(n => n + 1) };
}
export function useAction() {
  const lock = useRef(false), alive = useRef(true);
  const [busy, setBusy] = useState(false), [error, setError] = useState('');
  useEffect(() => { alive.current = true; return () => { alive.current = false; }; }, []);
  const run = async (request, after) => {
    if (lock.current) return false;
    lock.current = true; setBusy(true); setError('');
    try { const data = await request(); if (alive.current) await after?.(data); return true; }
    catch (e) { if (alive.current) setError(e.message); return false; }
    finally { lock.current = false; if (alive.current) setBusy(false); }
  };
  return { busy, error, run };
}
export function LoadState({ resource, children }) {
  if (resource.busy) return <p role="status">Đang tải dữ liệu…</p>;
  if (resource.error) return <div role="alert"><p>{resource.error}</p><button className="btn btn-secondary" onClick={resource.reload}>Thử lại</button></div>;
  return children;
}
export function Field({ label, children }) { return <label className="form-group"><span>{label}</span>{React.isValidElement(children) ? React.cloneElement(children, { 'aria-label': children.props['aria-label'] || label }) : children}</label>; }
export function Modal({ title, onClose, busy = false, children }) {
  return createPortal(<div className="modal-overlay" onClick={() => !busy && onClose()}><section className="modal-dialog business-modal" role="dialog" aria-modal="true" aria-label={title} onClick={e => e.stopPropagation()}>
    <div className="modal-header"><h3>{title}</h3><button type="button" disabled={busy} onClick={onClose}>Đóng</button></div><div className="modal-body">{children}</div>
  </section></div>, document.body);
}
export function ErrorNotice({ children }) { return children ? <p role="alert" className="business-error">{children}</p> : null; }
export function Empty({ children = 'Chưa có dữ liệu.' }) { return <p className="business-empty">{children}</p>; }
export function PageTitle({ children, description }) { return <div className="business-heading"><h2>{children}</h2><p>{description}</p></div>; }
export const roleLabels = { Admin: 'Quản trị viên', 'Museum Staff': 'Nhân viên bảo tàng', Staff: 'Nhân viên hệ thống', Curator: 'Giám tuyển', Visitor: 'Khách tham quan' };
export const statusLabels = { draft: 'Bản nháp', approved: 'Đã duyệt', rejected: 'Từ chối', published: 'Đã xuất bản', pending: 'Chờ xử lý', paid: 'Đã thanh toán', succeeded: 'Thành công', failed: 'Thất bại', in_progress: 'Đang thực hiện', completed: 'Hoàn thành' };
