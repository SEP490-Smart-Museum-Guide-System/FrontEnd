import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { backend, allPages } from '../../services/backend';
import { Field, Modal, PageTitle, LoadState, ErrorNotice, Empty, useData, useAction, roleLabels } from '../common/BusinessUI';

export default function UserManager() {
  const { reload: reloadApp } = useApp();
  const list = useData('accounts', signal => allPages('admin/accounts', { signal }), []);
  const roles = useData('roles', signal => backend('admin/roles', { signal }), []);
  const [query, setQuery] = useState(''), [role, setRole] = useState(''), [editing, setEditing] = useState(null), [allScopes, setAllScopes] = useState(false);
  const action = useAction('Đã cập nhật tài khoản và phân công.');
  const refresh = () => { list.reload(); reloadApp(); };
  const rows = list.data.filter(u => (!role || u.roles.includes(role)) && `${u.fullName} ${u.email} ${u.phoneNumber || ''}`.toLocaleLowerCase('vi').includes(query.toLocaleLowerCase('vi')));
  return <div><PageTitle description="Tài khoản, vai trò và phạm vi phụ trách được quản lý tại một nơi.">Người dùng & phân quyền</PageTitle>
    <div className="business-toolbar"><input className="form-input" aria-label="Tìm tài khoản" placeholder="Tìm tên, email, số điện thoại" value={query} onChange={e => setQuery(e.target.value)} />
      <select className="form-select" aria-label="Lọc vai trò" value={role} onChange={e => setRole(e.target.value)}><option value="">Tất cả vai trò</option>{roles.data.map(r => <option key={r} value={r}>{roleLabels[r] || r}</option>)}</select>
      <button className="btn btn-primary" disabled={roles.busy || !!roles.error} onClick={() => setEditing('new')}>Thêm tài khoản</button><button className="btn btn-secondary" onClick={list.reload}>Tải lại</button><button className="btn btn-secondary" onClick={() => setAllScopes(true)}>Danh sách phân công</button></div>
    <ErrorNotice>{action.error || roles.error}</ErrorNotice><LoadState resource={list}><div className="table-container card"><table className="data-table"><thead><tr><th>Thành viên</th><th>Vai trò</th><th>Phạm vi phụ trách</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{rows.map(u => <tr key={u.id}><td><strong>{u.fullName}</strong><div>{u.email}</div><small>{u.phoneNumber}</small></td><td>{u.roles.map(r => roleLabels[r] || r).join(', ')}</td><td>{u.assignments.length ? u.assignments.map(a => <p key={a.id}>{a.museumName}{a.galleryName ? ` · ${a.galleryName}` : ''}{a.artifactName ? ` · ${a.artifactName}` : ''}</p>) : 'Chưa phân công'}</td><td>{u.isActive ? 'Đang hoạt động' : 'Đã khóa'}</td><td><div className="business-actions"><button className="btn btn-secondary btn-sm" onClick={() => setEditing(u.id)}>Chi tiết & chỉnh sửa</button><button className="btn btn-secondary btn-sm" disabled={action.busy} onClick={() => action.run(() => backend(`admin/accounts/${u.id}/status`, { method: 'PATCH', body: { isActive: !u.isActive } }), refresh)}>{u.isActive ? 'Khóa' : 'Mở khóa'}</button></div></td></tr>)}</tbody></table>{!rows.length && <Empty>Không có tài khoản phù hợp.</Empty>}</div></LoadState>
    {allScopes && <GlobalAssignments users={list.data} onClose={() => setAllScopes(false)} onSaved={refresh} />}
    {editing && <AccountEditor key={editing} id={editing} roles={roles.data} onClose={() => setEditing(null)} onSaved={refresh} />}
  </div>;
}
function AccountEditor({ id, roles, onClose, onSaved }) {
  const detail = useData(id, signal => id === 'new' ? Promise.resolve({ fullName: '', email: '', phoneNumber: '', roles: [] }) : backend(`admin/accounts/${id}`, { signal }));
  return <Modal title={id === 'new' ? 'Tạo tài khoản' : 'Chi tiết tài khoản'} onClose={onClose}><LoadState resource={detail}>{detail.data && <AccountForms key={detail.data.id || id} account={detail.data} roles={roles} onClose={onClose} onSaved={() => { detail.reload(); onSaved(); }} />}</LoadState></Modal>;
}
function AccountForms({ account, roles, onClose, onSaved }) {
  const isNew = !account.id;
  const [form, setForm] = useState({ fullName: account.fullName, email: account.email, phoneNumber: account.phoneNumber || '', password: '' });
  const [role, setRole] = useState(account.roles[0] || roles.find(r => r === 'Museum Staff') || roles[0] || '');
  const action = useAction('Đã cập nhật tài khoản và phân công.');
  const change = e => setForm(p => ({ ...p, [e.target.name]: e.target.value }));
  async function save(e) {
    e.preventDefault();
    await action.run(() => backend(isNew ? 'admin/accounts' : `admin/accounts/${account.id}`, { method: isNew ? 'POST' : 'PUT', body: { fullName: form.fullName.trim(), email: form.email.trim(), phoneNumber: form.phoneNumber.trim() || null, ...(isNew ? { password: form.password, roles: [role] } : { newPassword: form.password || null }) } }), () => { onSaved(); if (isNew) onClose(); });
  }
  return <><ErrorNotice>{action.error}</ErrorNotice><form onSubmit={save}>
    <Field label="Họ và tên"><input className="form-input" name="fullName" required maxLength={200} value={form.fullName} onChange={change} /></Field>
    <Field label="Email"><input className="form-input" type="email" name="email" required maxLength={256} value={form.email} onChange={change} /></Field>
    <Field label="Số điện thoại"><input className="form-input" name="phoneNumber" maxLength={30} value={form.phoneNumber} onChange={change} /></Field>
    <Field label={isNew ? 'Mật khẩu ban đầu' : 'Mật khẩu mới (để trống để giữ nguyên)'}><input className="form-input" name="password" type="password" autoComplete="new-password" required={isNew} minLength={6} maxLength={100} value={form.password} onChange={change} /></Field>
    {isNew && <Field label="Vai trò"><select className="form-select" required value={role} onChange={e => setRole(e.target.value)}>{roles.map(r => <option key={r} value={r}>{roleLabels[r] || r}</option>)}</select></Field>}
    <button className="btn btn-primary" disabled={action.busy}>{action.busy ? 'Đang lưu…' : isNew ? 'Tạo tài khoản' : 'Lưu thông tin'}</button>
  </form>
  {!isNew && <><hr /><h4>Vai trò tài khoản</h4><p className="business-muted">Sau khi đổi vai trò, tài khoản cần đăng nhập lại để nhận phiên làm việc mới.</p><form onSubmit={e => { e.preventDefault(); action.run(() => backend(`admin/accounts/${account.id}/roles`, { method: 'PUT', body: { roles: [role] } }), onSaved); }}><Field label="Vai trò"><select className="form-select" value={role} onChange={e => setRole(e.target.value)}>{roles.map(r => <option key={r} value={r}>{roleLabels[r] || r}</option>)}</select></Field><button className="btn btn-secondary" disabled={action.busy || role === account.roles[0]}>Lưu vai trò</button></form><hr /><Assignments id={account.id} eligible={account.roles.some(r => ['Museum Staff', 'Curator', 'Staff', 'Admin'].includes(r))} onSaved={onSaved} /></>}
  </>;
}
function Assignments({ id, eligible, onSaved }) {
  const { museums, artifacts } = useApp();
  const list = useData(`assignments:${id}`, signal => backend(`admin/accounts/${id}/assignments`, { signal }), []);
  const [museumId, setMuseumId] = useState(''), [galleryId, setGalleryId] = useState(''), [artifactId, setArtifactId] = useState('');
  const galleries = useData(`galleries:${museumId}`, signal => museumId ? backend(`museums/${museumId}/galleries`, { signal }) : Promise.resolve([]), []);
  const action = useAction('Đã cập nhật tài khoản và phân công.');
  const refresh = () => { list.reload(); onSaved(); };
  return <><h4>Phạm vi phụ trách</h4><ErrorNotice>{action.error}</ErrorNotice><LoadState resource={list}>{!list.data.length && <Empty>Chưa có phân công.</Empty>}{list.data.map(a => <div className="business-actions" key={a.id}><span>{a.museumName}{a.galleryName ? ` · ${a.galleryName}` : ''}{a.artifactName ? ` · ${a.artifactName}` : ''}</span><button className="btn btn-secondary btn-sm" disabled={action.busy} onClick={() => { if (window.confirm('Thu hồi phân công này?')) action.run(() => backend(`admin/accounts/${id}/assignments/${a.id}`, { method: 'DELETE' }), refresh); }}>Thu hồi</button></div>)}</LoadState>
    {eligible ? <form onSubmit={e => { e.preventDefault(); action.run(() => backend(`admin/accounts/${id}/assignments`, { method: 'POST', body: { museumId: Number(museumId), galleryId: galleryId ? Number(galleryId) : null, artifactId: artifactId ? Number(artifactId) : null } }), refresh); }}>
      <Field label="Bảo tàng"><select className="form-select" required value={museumId} onChange={e => { setMuseumId(e.target.value); setGalleryId(''); setArtifactId(''); }}><option value="">Chọn bảo tàng</option>{museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}</select></Field>
      <Field label="Phòng trưng bày"><select className="form-select" value={galleryId} disabled={galleries.busy || !!galleries.error} onChange={e => { setGalleryId(e.target.value); setArtifactId(''); }}><option value="">Toàn bảo tàng</option>{galleries.data.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}</select></Field>
      <ErrorNotice>{galleries.error}</ErrorNotice><Field label="Hiện vật"><select className="form-select" value={artifactId} onChange={e => setArtifactId(e.target.value)}><option value="">Toàn phạm vi đã chọn</option>{artifacts.filter(a => String(a.museumId) === museumId && (!galleryId || String(a.galleryId) === galleryId)).map(a => <option key={a.id} value={a.id}>{a.name}</option>)}</select></Field>
      <button className="btn btn-primary" disabled={action.busy || !museumId || galleries.busy || !!galleries.error}>Thêm phân công</button>
    </form> : <p className="business-muted">Phân công bảo tàng áp dụng cho các tài khoản nghiệp vụ.</p>}
  </>;
}

function GlobalAssignments({ users, onClose, onSaved }) {
  const { museums } = useApp();
  const [museumId, setMuseum] = useState(''), [userId, setUser] = useState('');
  const query = new URLSearchParams({ ...(museumId ? { museumId } : {}), ...(userId ? { userId } : {}) }).toString();
  const data = useData(`all-assignments:${query}`, signal => backend(`admin/assignments${query ? `?${query}` : ''}`, { signal }), []);
  const action = useAction('Đã cập nhật tài khoản và phân công.');
  return <Modal title="Danh sách phân công toàn hệ thống" onClose={onClose} busy={action.busy}><div className="business-toolbar"><Field label="Lọc bảo tàng"><select className="form-select" value={museumId} onChange={e => setMuseum(e.target.value)}><option value="">Tất cả bảo tàng</option>{museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}</select></Field><Field label="Lọc tài khoản"><select className="form-select" value={userId} onChange={e => setUser(e.target.value)}><option value="">Tất cả tài khoản</option>{users.map(u => <option key={u.id} value={u.id}>{u.fullName} · {u.email}</option>)}</select></Field></div><ErrorNotice>{action.error}</ErrorNotice><LoadState resource={data}>{!data.data.length && <Empty>Chưa có phân công phù hợp.</Empty>}{data.data.map(a => <article className="card business-card" key={a.id}><strong>{a.userFullName}</strong><p>{a.userEmail}</p><p>{a.museumName}{a.galleryName ? ` · ${a.galleryName}` : ''}{a.artifactName ? ` · ${a.artifactName}` : ''}</p><button className="btn btn-secondary" disabled={action.busy} onClick={() => { if (window.confirm('Thu hồi phân công này?')) action.run(() => backend(`admin/assignments/${a.id}`, { method: 'DELETE' }), () => { data.reload(); onSaved(); }); }}>Thu hồi phân công</button></article>)}</LoadState></Modal>;
}
