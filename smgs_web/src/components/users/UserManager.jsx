import React, { useState } from 'react';
import ActionGroup from '../common/ActionGroup';
import { useApp } from '../../context/AppContext';
import { backend, allPages } from '../../services/backend';
import { Field, Modal, PageTitle, LoadState, ErrorNotice, Empty, useData, useAction, roleLabels } from '../common/BusinessUI';
import {
  User,
  Mail,
  Phone,
  Lock,
  Shield,
  Building2,
  Landmark,
  Trash2,
  Plus,
  CheckCircle,
  AlertCircle,
  HelpCircle,
  Sparkles,
  Info
} from 'lucide-react';

const roleMeta = {
  Admin: { label: 'Quản trị viên', bg: '#EDE0CE', text: '#4A3B33', desc: 'Toàn quyền cấu hình bảo tàng, quản lý người dùng, phân quyền và nhật ký hệ thống.' },
  'Museum Staff': { label: 'Nhân viên bảo tàng', bg: '#F8EEEA', text: '#6B2E2E', desc: 'Quản lý hiện vật, mã QR, tuyến tham quan, xưởng AI Studio và cấu trúc bảo tàng phụ trách.' },
  Curator: { label: 'Giám tuyển', bg: '#F8F1E7', text: '#775936', desc: 'Thẩm định độc lập thông tin hiện vật, bản dịch, kịch bản thuyết minh và câu hỏi tương tác.' },
  Staff: { label: 'Nhân viên hệ thống', bg: '#F0F9FF', text: '#0369A1', desc: 'Hỗ trợ khách tham quan, xử lý khiếu nại, hoàn tiền và giám sát vận hành AI.' },
  Visitor: { label: 'Khách tham quan', bg: '#F1F5F9', text: '#475569', desc: 'Người dùng cuối khám phá di sản trên ứng dụng di động; không có phân công quản lý.' }
};

export default function UserManager() {
  const { reload: reloadApp } = useApp();
  const list = useData('accounts', signal => allPages('admin/accounts', { signal }), []);
  const roles = useData('roles', signal => backend('admin/roles', { signal }), []);
  const [query, setQuery] = useState('');
  const [role, setRole] = useState('');
  const [editing, setEditing] = useState(null);
  const [allScopes, setAllScopes] = useState(false);
  const action = useAction('Đã cập nhật tài khoản và phân công.');
  const refresh = () => { list.reload(); reloadApp(); };

  const rows = list.data.filter(u =>
    (!role || u.roles.includes(role)) &&
    `${u.fullName} ${u.email} ${u.phoneNumber || ''}`.toLocaleLowerCase('vi').includes(query.toLocaleLowerCase('vi'))
  );

  return (
    <div>
      <PageTitle description="Tài khoản, vai trò và phạm vi phụ trách được quản lý tại một nơi.">
        Người dùng & phân quyền
      </PageTitle>

      <div className="business-toolbar" style={{ justifyContent: 'space-between', gap: '12px' }}>
        <div style={{ display: 'flex', gap: '10px', flex: 1, minWidth: '280px', flexWrap: 'wrap' }}>
          <input
            className="form-input"
            style={{ flex: 1, minWidth: '200px' }}
            aria-label="Tìm tài khoản"
            placeholder="Tìm tên, email, số điện thoại..."
            value={query}
            onChange={e => setQuery(e.target.value)}
          />
          <select
            className="form-select form-select-sm"
            aria-label="Lọc vai trò"
            value={role}
            onChange={e => setRole(e.target.value)}
          >
            <option value="">Tất cả vai trò</option>
            {roles.data.map(r => (
              <option key={r} value={r}>{roleLabels[r] || r}</option>
            ))}
          </select>
        </div>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <button className="btn btn-primary" disabled={roles.busy || !!roles.error} onClick={() => setEditing('new')}>
            + Thêm tài khoản
          </button>
          <button className="btn btn-secondary" onClick={() => setAllScopes(true)}>
            Danh sách phân công
          </button>
          <button className="btn btn-secondary" onClick={list.reload} title="Tải lại dữ liệu">
            ↻
          </button>
        </div>
      </div>

      <ErrorNotice>{action.error || roles.error}</ErrorNotice>

      <LoadState resource={list}>
        <div className="table-container card">
          <table className="data-table">
            <thead>
              <tr>
                <th>Thành viên</th>
                <th>Vai trò</th>
                <th>Phạm vi phụ trách</th>
                <th>Trạng thái</th>
                <th style={{ textAlign: 'right' }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {rows.map(u => {
                const isVisitor = u.roles.includes('Visitor');
                const primaryRole = u.roles[0] || 'Visitor';
                const meta = roleMeta[primaryRole] || roleMeta.Visitor;
                return (
                  <tr key={u.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div
                          style={{
                            width: '36px',
                            height: '36px',
                            borderRadius: '50%',
                            background: isVisitor
                              ? '#E2E8F0'
                              : 'linear-gradient(135deg, var(--color-burgundy-700), var(--color-gold-600))',
                            color: isVisitor ? '#475569' : '#FFF',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: '700',
                            fontSize: '0.82rem',
                            flexShrink: 0
                          }}
                        >
                          {u.fullName?.charAt(0)?.toUpperCase() || 'U'}
                        </div>
                        <div>
                          <strong>{u.fullName}</strong>
                          <div style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-500)' }}>{u.email}</div>
                          {u.phoneNumber && <small style={{ color: 'var(--color-charcoal-400)' }}>{u.phoneNumber}</small>}
                        </div>
                      </div>
                    </td>
                    <td>
                      <span
                        style={{
                          display: 'inline-block',
                          fontSize: '0.72rem',
                          fontWeight: '700',
                          padding: '3px 9px',
                          borderRadius: '6px',
                          background: meta.bg,
                          color: meta.text
                        }}
                      >
                        {u.roles.map(r => roleLabels[r] || r).join(', ')}
                      </span>
                    </td>
                    <td>
                      {isVisitor ? (
                        <span style={{ color: 'var(--color-charcoal-400)', fontSize: '0.85rem' }}>—</span>
                      ) : u.assignments.length ? (
                        u.assignments.map(a => (
                          <p key={a.id} style={{ margin: '2px 0', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <Landmark size={12} color="var(--color-burgundy-700)" />
                            <span>
                              {a.museumName}
                              {a.galleryName ? ` · ${a.galleryName}` : ''}
                              {a.artifactName ? ` · ${a.artifactName}` : ''}
                            </span>
                          </p>
                        ))
                      ) : (
                        <span style={{ color: 'var(--color-charcoal-400)', fontSize: '0.8rem' }}>Chưa phân công</span>
                      )}
                    </td>
                    <td>
                      <span className={`badge-status ${u.isActive ? 'badge-published' : 'badge-danger'}`}>
                        {u.isActive ? 'Hoạt động' : 'Đã khóa'}
                      </span>
                    </td>
                    <td className="row-actions-cell">
                      <ActionGroup visible={1}>
                        <button type="button" className="btn btn-secondary btn-sm" onClick={() => setEditing(u.id)}>
                          Chi tiết & sửa
                        </button>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ color: u.isActive ? 'var(--color-danger)' : 'var(--color-success)' }}
                          disabled={action.busy}
                          onClick={() =>
                            action.run(
                              () => backend(`admin/accounts/${u.id}/status`, { method: 'PATCH', body: { isActive: !u.isActive } }),
                              refresh
                            )
                          }
                        >
                          {u.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
                        </button>
                      </ActionGroup>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {!rows.length && <Empty>Không có tài khoản phù hợp.</Empty>}
        </div>
      </LoadState>

      {allScopes && <GlobalAssignments users={list.data} onClose={() => setAllScopes(false)} onSaved={refresh} />}
      {editing && <AccountEditor key={editing} id={editing} roles={roles.data} onClose={() => setEditing(null)} onSaved={refresh} />}
    </div>
  );
}

function AccountEditor({ id, roles, onClose, onSaved }) {
  const detail = useData(id, signal =>
    id === 'new'
      ? Promise.resolve({ fullName: '', email: '', phoneNumber: '', roles: [] })
      : backend(`admin/accounts/${id}`, { signal })
  );

  return (
    <Modal title={id === 'new' ? 'Tạo tài khoản mới' : 'Chi tiết & Quản lý tài khoản'} onClose={onClose}>
      <LoadState resource={detail}>
        {detail.data && (
          <AccountForms
            key={detail.data.id || id}
            account={detail.data}
            roles={roles}
            onClose={onClose}
            onSaved={() => {
              detail.reload();
              onSaved();
            }}
          />
        )}
      </LoadState>
    </Modal>
  );
}

function AccountForms({ account, roles, onClose, onSaved }) {
  const isNew = !account.id;
  const isVisitor = account.roles?.includes('Visitor');

  // Form states
  const [form, setForm] = useState({
    fullName: account.fullName || '',
    email: account.email || '',
    phoneNumber: account.phoneNumber || '',
    password: ''
  });
  const [role, setRole] = useState(
    account.roles?.[0] || roles.find(r => r === 'Museum Staff') || roles[0] || ''
  );

  // Tabs for existing non-visitor accounts: 'info' | 'role' | 'assignments'
  const [activeTab, setActiveTab] = useState('info');

  const action = useAction('Đã cập nhật thông tin tài khoản.');
  const roleAction = useAction('Đã cập nhật vai trò tài khoản.');

  const change = e => setForm(p => ({ ...p, [e.target.name]: e.target.value }));

  async function saveInfo(e) {
    e.preventDefault();
    await action.run(
      () =>
        backend(isNew ? 'admin/accounts' : `admin/accounts/${account.id}`, {
          method: isNew ? 'POST' : 'PUT',
          body: {
            fullName: form.fullName.trim(),
            email: form.email.trim(),
            phoneNumber: form.phoneNumber.trim() || null,
            ...(isNew
              ? { password: form.password, roles: [role] }
              : { newPassword: form.password || null })
          }
        }),
      () => {
        onSaved();
        if (isNew) onClose();
      }
    );
  }

  async function saveRole(e) {
    e.preventDefault();
    await roleAction.run(
      () =>
        backend(`admin/accounts/${account.id}/roles`, {
          method: 'PUT',
          body: { roles: [role] }
        }),
      () => {
        onSaved();
      }
    );
  }

  const currentRoleMeta = roleMeta[account.roles?.[0] || role] || roleMeta.Visitor;
  const selectedRoleMeta = roleMeta[role] || roleMeta.Visitor;

  // New account form
  if (isNew) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
        <ErrorNotice>{action.error}</ErrorNotice>
        <form onSubmit={saveInfo} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px' }}>
            <Field label="Họ và tên *">
              <input
                className="form-input"
                name="fullName"
                required
                maxLength={200}
                placeholder="Nguyễn Văn A"
                value={form.fullName}
                onChange={change}
              />
            </Field>
            <Field label="Địa chỉ Email *">
              <input
                className="form-input"
                type="email"
                name="email"
                required
                maxLength={256}
                placeholder="name@smgs.vn"
                value={form.email}
                onChange={change}
              />
            </Field>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px' }}>
            <Field label="Số điện thoại">
              <input
                className="form-input"
                name="phoneNumber"
                maxLength={30}
                placeholder="0912 345 678"
                value={form.phoneNumber}
                onChange={change}
              />
            </Field>
            <Field label="Mật khẩu khởi tạo *">
              <input
                className="form-input"
                name="password"
                type="password"
                autoComplete="new-password"
                required
                minLength={6}
                maxLength={100}
                placeholder="Tối thiểu 6 ký tự"
                value={form.password}
                onChange={change}
              />
            </Field>
          </div>

          <Field label="Vai trò ban đầu">
            <select
              className="form-select"
              required
              value={role}
              onChange={e => setRole(e.target.value)}
            >
              {roles.map(r => (
                <option key={r} value={r}>
                  {roleLabels[r] || r}
                </option>
              ))}
            </select>
          </Field>

          <div
            style={{
              padding: '12px 14px',
              borderRadius: '8px',
              background: selectedRoleMeta.bg,
              color: selectedRoleMeta.text,
              fontSize: '0.8rem',
              lineHeight: 1.5
            }}
          >
            <strong>{selectedRoleMeta.label}:</strong> {selectedRoleMeta.desc}
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Hủy
            </button>
            <button className="btn btn-primary" disabled={action.busy}>
              {action.busy ? 'Đang tạo…' : 'Tạo tài khoản'}
            </button>
          </div>
        </form>
      </div>
    );
  }

  // Existing account editor
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
      {/* Identity Summary Banner */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '14px',
          padding: '16px',
          borderRadius: '12px',
          background: 'linear-gradient(135deg, #FAF6F0, #F3ECE1)',
          border: '1px solid var(--color-paper-border)'
        }}
      >
        <div
          style={{
            width: '48px',
            height: '48px',
            borderRadius: '50%',
            background: isVisitor
              ? '#CBD5E1'
              : 'linear-gradient(135deg, var(--color-burgundy-700), var(--color-gold-600))',
            color: isVisitor ? '#334155' : '#FFF',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: '700',
            fontSize: '1.15rem',
            flexShrink: 0,
            boxShadow: 'var(--shadow-sm)'
          }}
        >
          {account.fullName?.charAt(0)?.toUpperCase() || 'U'}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
            <h3 style={{ fontSize: '1.05rem', fontWeight: '700', color: 'var(--color-charcoal-900)', margin: 0 }}>
              {account.fullName}
            </h3>
            <span
              style={{
                fontSize: '0.7rem',
                fontWeight: '700',
                padding: '2px 8px',
                borderRadius: '6px',
                background: currentRoleMeta.bg,
                color: currentRoleMeta.text
              }}
            >
              {currentRoleMeta.label}
            </span>
            <span className={`badge-status ${account.isActive ? 'badge-published' : 'badge-danger'}`} style={{ fontSize: '0.7rem' }}>
              {account.isActive ? 'Hoạt động' : 'Đã khóa'}
            </span>
          </div>
          <p style={{ margin: '2px 0 0', fontSize: '0.8rem', color: 'var(--color-charcoal-600)' }}>
            {account.email} {account.phoneNumber ? `· ${account.phoneNumber}` : ''}
          </p>
        </div>
      </div>

      {/* Tabs Switcher for staff accounts */}
      {!isVisitor && (
        <div
          style={{
            display: 'flex',
            borderBottom: '1px solid var(--color-paper-border)',
            gap: '8px'
          }}
        >
          <button
            type="button"
            onClick={() => setActiveTab('info')}
            style={{
              padding: '10px 14px',
              fontSize: '0.84rem',
              fontWeight: '600',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              borderBottom: activeTab === 'info' ? '2px solid var(--color-burgundy-700)' : '2px solid transparent',
              color: activeTab === 'info' ? 'var(--color-burgundy-900)' : 'var(--color-charcoal-600)',
              background: 'transparent',
              borderTop: 'none',
              borderLeft: 'none',
              borderRight: 'none',
              cursor: 'pointer'
            }}
          >
            <User size={15} /> Thông tin cá nhân
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('role')}
            style={{
              padding: '10px 14px',
              fontSize: '0.84rem',
              fontWeight: '600',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              borderBottom: activeTab === 'role' ? '2px solid var(--color-burgundy-700)' : '2px solid transparent',
              color: activeTab === 'role' ? 'var(--color-burgundy-900)' : 'var(--color-charcoal-600)',
              background: 'transparent',
              borderTop: 'none',
              borderLeft: 'none',
              borderRight: 'none',
              cursor: 'pointer'
            }}
          >
            <Shield size={15} /> Vai trò & Quyền hạn
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('assignments')}
            style={{
              padding: '10px 14px',
              fontSize: '0.84rem',
              fontWeight: '600',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              borderBottom: activeTab === 'assignments' ? '2px solid var(--color-burgundy-700)' : '2px solid transparent',
              color: activeTab === 'assignments' ? 'var(--color-burgundy-900)' : 'var(--color-charcoal-600)',
              background: 'transparent',
              borderTop: 'none',
              borderLeft: 'none',
              borderRight: 'none',
              cursor: 'pointer'
            }}
          >
            <Building2 size={15} /> Phân công bảo tàng
          </button>
        </div>
      )}

      {/* Tab 1: Thông tin cá nhân (Always visible for Visitor, or when activeTab === 'info') */}
      {(isVisitor || activeTab === 'info') && (
        <form onSubmit={saveInfo} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <ErrorNotice>{action.error}</ErrorNotice>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px' }}>
            <Field label="Họ và tên">
              <input
                className="form-input"
                name="fullName"
                required
                maxLength={200}
                value={form.fullName}
                onChange={change}
              />
            </Field>
            <Field label="Địa chỉ Email">
              <input
                className="form-input"
                type="email"
                name="email"
                required
                maxLength={256}
                value={form.email}
                onChange={change}
              />
            </Field>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px' }}>
            <Field label="Số điện thoại">
              <input
                className="form-input"
                name="phoneNumber"
                maxLength={30}
                placeholder="Để trống nếu chưa có"
                value={form.phoneNumber}
                onChange={change}
              />
            </Field>
            <Field label="Mật khẩu mới (để trống nếu không đổi)">
              <input
                className="form-input"
                name="password"
                type="password"
                autoComplete="new-password"
                minLength={6}
                maxLength={100}
                placeholder="Nhập mật khẩu mới"
                value={form.password}
                onChange={change}
              />
            </Field>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '6px' }}>
            <button className="btn btn-primary" disabled={action.busy}>
              {action.busy ? 'Đang lưu…' : 'Lưu thông tin'}
            </button>
          </div>
        </form>
      )}

      {/* Tab 2: Vai trò & Quyền hạn (Only for non-visitor or when switching role) */}
      {!isVisitor && activeTab === 'role' && (
        <form onSubmit={saveRole} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <ErrorNotice>{roleAction.error}</ErrorNotice>

          <div style={{ background: '#FAF7F2', padding: '14px', borderRadius: '10px', border: '1px solid var(--color-paper-border)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.85rem', fontWeight: '600', color: 'var(--color-charcoal-800)', marginBottom: '8px' }}>
              <Shield size={16} color="var(--color-gold-600)" />
              Thay đổi vai trò tài khoản
            </div>
            <p style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-600)', margin: '0 0 12px', lineHeight: 1.4 }}>
              Sau khi cập nhật vai trò, người dùng cần đăng xuất và đăng nhập lại để nhận quyền hạn mới từ hệ thống.
            </p>

            <Field label="Chọn vai trò">
              <select
                className="form-select"
                value={role}
                onChange={e => setRole(e.target.value)}
              >
                {roles.map(r => (
                  <option key={r} value={r}>
                    {roleLabels[r] || r}
                  </option>
                ))}
              </select>
            </Field>

            <div
              style={{
                marginTop: '10px',
                padding: '10px 12px',
                borderRadius: '8px',
                background: selectedRoleMeta.bg,
                color: selectedRoleMeta.text,
                fontSize: '0.78rem',
                lineHeight: 1.4
              }}
            >
              <strong>{selectedRoleMeta.label}:</strong> {selectedRoleMeta.desc}
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button
              className="btn btn-primary"
              disabled={roleAction.busy || role === account.roles?.[0]}
            >
              {roleAction.busy ? 'Đang cập nhật…' : 'Cập nhật vai trò'}
            </button>
          </div>
        </form>
      )}

      {/* Tab 3: Phân công bảo tàng (NEVER rendered for Visitor) */}
      {!isVisitor && activeTab === 'assignments' && (
        <Assignments
          id={account.id}
          eligible={account.roles?.some(r => ['Museum Staff', 'Curator', 'Staff', 'Admin'].includes(r))}
          onSaved={onSaved}
        />
      )}
    </div>
  );
}

function Assignments({ id, eligible, onSaved }) {
  const { museums, artifacts } = useApp();
  const list = useData(`assignments:${id}`, signal => backend(`admin/accounts/${id}/assignments`, { signal }), []);
  const [museumId, setMuseumId] = useState('');
  const [galleryId, setGalleryId] = useState('');
  const [artifactId, setArtifactId] = useState('');
  const galleries = useData(
    `galleries:${museumId}`,
    signal => (museumId ? backend(`museums/${museumId}/galleries`, { signal }) : Promise.resolve([])),
    []
  );
  const action = useAction('Đã cập nhật phân công bảo tàng.');
  const refresh = () => {
    list.reload();
    onSaved();
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      <ErrorNotice>{action.error}</ErrorNotice>

      {/* Existing Assignments Section */}
      <div>
        <div style={{ fontSize: '0.85rem', fontWeight: '700', color: 'var(--color-burgundy-900)', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Landmark size={16} />
          Bảo tàng & Khu vực đang phụ trách ({list.data.length})
        </div>

        <LoadState resource={list}>
          {!list.data.length ? (
            <div style={{ padding: '16px', background: '#FAF7F2', borderRadius: '8px', border: '1px dashed var(--color-paper-border)', textAlign: 'center', color: 'var(--color-charcoal-500)', fontSize: '0.82rem' }}>
              Tài khoản này chưa được gán bảo tàng cụ thể. Hãy thêm phân công ở khung bên dưới.
            </div>
          ) : (
            <div style={{ display: 'grid', gap: '8px' }}>
              {list.data.map(a => (
                <div
                  key={a.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderRadius: '8px',
                    background: '#FFF',
                    border: '1px solid var(--color-paper-border)',
                    boxShadow: 'var(--shadow-sm)'
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ width: '28px', height: '28px', borderRadius: '6px', background: 'var(--color-burgundy-50)', color: 'var(--color-burgundy-700)', display: 'grid', placeItems: 'center' }}>
                      <Landmark size={14} />
                    </div>
                    <div>
                      <strong style={{ fontSize: '0.84rem', color: 'var(--color-charcoal-900)' }}>{a.museumName}</strong>
                      <div style={{ fontSize: '0.74rem', color: 'var(--color-charcoal-500)' }}>
                        {a.galleryName ? `Phòng: ${a.galleryName}` : 'Toàn bộ bảo tàng'}
                        {a.artifactName ? ` · Hiện vật: ${a.artifactName}` : ''}
                      </div>
                    </div>
                  </div>

                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    style={{ color: 'var(--color-danger)', borderColor: '#FCA5A5' }}
                    disabled={action.busy}
                    onClick={() => {
                      if (window.confirm(`Thu hồi phân công tại "${a.museumName}"?`)) {
                        action.run(() => backend(`admin/accounts/${id}/assignments/${a.id}`, { method: 'DELETE' }), refresh);
                      }
                    }}
                    title="Thu hồi phân công này"
                  >
                    <Trash2 size={13} /> Gỡ
                  </button>
                </div>
              ))}
            </div>
          )}
        </LoadState>
      </div>

      {/* Add Assignment Card */}
      {eligible ? (
        <form
          onSubmit={e => {
            e.preventDefault();
            action.run(
              () =>
                backend(`admin/accounts/${id}/assignments`, {
                  method: 'POST',
                  body: {
                    museumId: Number(museumId),
                    galleryId: galleryId ? Number(galleryId) : null,
                    artifactId: artifactId ? Number(artifactId) : null
                  }
                }),
              () => {
                setMuseumId('');
                setGalleryId('');
                setArtifactId('');
                refresh();
              }
            );
          }}
          style={{
            padding: '16px',
            borderRadius: '10px',
            background: '#FAF7F2',
            border: '1px solid var(--color-paper-border)',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px'
          }}
        >
          <div style={{ fontSize: '0.85rem', fontWeight: '700', color: 'var(--color-charcoal-800)', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Plus size={15} color="var(--color-burgundy-700)" />
            Gán thêm phạm vi phụ trách
          </div>

          <Field label="1. Chọn bảo tàng phụ trách *">
            <select
              className="form-select"
              required
              value={museumId}
              onChange={e => {
                setMuseumId(e.target.value);
                setGalleryId('');
                setArtifactId('');
              }}
            >
              <option value="">Chọn bảo tàng</option>
              {museums.map(m => (
                <option key={m.id} value={m.id}>
                  {m.name}
                </option>
              ))}
            </select>
          </Field>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px' }}>
            <Field label="2. Phòng trưng bày (tùy chọn)">
              <select
                className="form-select"
                value={galleryId}
                disabled={!museumId || galleries.busy || !!galleries.error}
                onChange={e => {
                  setGalleryId(e.target.value);
                  setArtifactId('');
                }}
              >
                <option value="">Toàn bảo tàng (Tất cả phòng)</option>
                {galleries.data.map(g => (
                  <option key={g.id} value={g.id}>
                    {g.name}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="3. Hiện vật cụ thể (tùy chọn)">
              <select
                className="form-select"
                value={artifactId}
                disabled={!museumId}
                onChange={e => setArtifactId(e.target.value)}
              >
                <option value="">Tất cả hiện vật trong phạm vi</option>
                {artifacts
                  .filter(a => String(a.museumId) === museumId && (!galleryId || String(a.galleryId) === galleryId))
                  .map(a => (
                    <option key={a.id} value={a.id}>
                      {a.name}
                    </option>
                  ))}
              </select>
            </Field>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '4px' }}>
            <button
              className="btn btn-primary btn-sm"
              disabled={action.busy || !museumId || galleries.busy || !!galleries.error}
            >
              <Plus size={14} /> Thêm phân công
            </button>
          </div>
        </form>
      ) : (
        <p className="business-muted">Phân công bảo tàng áp dụng cho các tài khoản nghiệp vụ.</p>
      )}
    </div>
  );
}

function GlobalAssignments({ users, onClose, onSaved }) {
  const { museums } = useApp();
  const [museumId, setMuseum] = useState('');
  const [userId, setUser] = useState('');
  const query = new URLSearchParams({ ...(museumId ? { museumId } : {}), ...(userId ? { userId } : {}) }).toString();
  const data = useData(`all-assignments:${query}`, signal => backend(`admin/assignments${query ? `?${query}` : ''}`, { signal }), []);
  const action = useAction('Đã cập nhật tài khoản và phân công.');

  return (
    <Modal title="Danh sách phân công toàn hệ thống" onClose={onClose} busy={action.busy}>
      <div className="business-toolbar" style={{ gap: '12px' }}>
        <Field label="Lọc bảo tàng">
          <select className="form-select" value={museumId} onChange={e => setMuseum(e.target.value)}>
            <option value="">Tất cả bảo tàng</option>
            {museums.map(m => (
              <option key={m.id} value={m.id}>
                {m.name}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Lọc tài khoản">
          <select className="form-select" value={userId} onChange={e => setUser(e.target.value)}>
            <option value="">Tất cả tài khoản</option>
            {users.map(u => (
              <option key={u.id} value={u.id}>
                {u.fullName} · {u.email}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <ErrorNotice>{action.error}</ErrorNotice>

      <LoadState resource={data}>
        {!data.data.length && <Empty>Chưa có phân công phù hợp.</Empty>}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '12px', marginTop: '12px' }}>
          {data.data.map(a => (
            <article className="card business-card" key={a.id} style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Landmark size={16} color="var(--color-burgundy-700)" />
                <strong style={{ fontSize: '0.9rem' }}>{a.userFullName}</strong>
              </div>
              <p style={{ margin: 0, fontSize: '0.78rem', color: 'var(--color-charcoal-500)' }}>{a.userEmail}</p>
              <div style={{ margin: '4px 0', padding: '6px 10px', borderRadius: '6px', background: '#F8F5EE', fontSize: '0.8rem', color: 'var(--color-charcoal-800)' }}>
                {a.museumName}
                {a.galleryName ? ` · ${a.galleryName}` : ''}
                {a.artifactName ? ` · ${a.artifactName}` : ''}
              </div>
              <button
                className="btn btn-secondary btn-sm"
                style={{ color: 'var(--color-danger)', borderColor: '#FCA5A5', marginTop: 'auto' }}
                disabled={action.busy}
                onClick={() => {
                  if (window.confirm('Thu hồi phân công này?')) {
                    action.run(() => backend(`admin/assignments/${a.id}`, { method: 'DELETE' }), () => {
                      data.reload();
                      onSaved();
                    });
                  }
                }}
              >
                <Trash2 size={13} /> Thu hồi phân công
              </button>
            </article>
          ))}
        </div>
      </LoadState>
    </Modal>
  );
}
