import React from 'react';
import { useApp } from '../../context/AppContext';
import {
  Landmark,
  ShieldCheck,
  UserCheck,
  Sparkles,
  Search,
  Bell,
  ChevronDown,
  User
} from 'lucide-react';

export default function Header() {
  const {
    currentRole,
    setCurrentRole,
    museums,
    selectedMuseumId,
    setSelectedMuseumId,
    currentMuseum,
    curationQueue
  } = useApp();

  const pendingCurationCount = curationQueue.filter(c => c.status === 'pending').length;

  const roleLabels = {
    administrator: { label: 'Quản trị viên (Admin)', icon: ShieldCheck, badgeClass: 'role-badge-admin' },
    museumStaff: { label: 'Nhân viên Bảo tàng (Staff)', icon: UserCheck, badgeClass: 'role-badge-staff' },
    curator: { label: 'Kiểm duyệt viên (Curator)', icon: Sparkles, badgeClass: 'role-badge-curator' }
  };

  const currentRoleInfo = roleLabels[currentRole] || roleLabels.administrator;
  const RoleIcon = currentRoleInfo.icon;

  return (
    <header className="topbar">
      <div className="topbar-left">
        {/* Museum Selector */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Landmark size={18} color="var(--color-burgundy-700)" />
          <select
            value={selectedMuseumId}
            onChange={(e) => setSelectedMuseumId(e.target.value)}
            className="form-select"
            style={{
              padding: '6px 12px',
              fontSize: '0.85rem',
              fontWeight: '600',
              borderColor: 'var(--color-paper-border)',
              background: 'var(--color-paper-accent)',
              cursor: 'pointer',
              maxWidth: '260px'
            }}
          >
            {museums.map(m => (
              <option key={m.id} value={m.id}>
                {m.name} ({m.code})
              </option>
            ))}
          </select>
        </div>

        {/* Global Search Hint */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          background: '#F5F2EB',
          padding: '6px 14px',
          borderRadius: '8px',
          border: '1px solid var(--color-paper-border)',
          color: 'var(--color-charcoal-500)',
          fontSize: '0.8125rem',
          minWidth: '220px'
        }}>
          <Search size={15} />
          <span>Tìm nhanh hiện vật, mã QR...</span>
        </div>
      </div>

      <div className="topbar-right">
        {/* Role Switcher with instant click */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#F8F5EE', padding: '4px 6px', borderRadius: '10px', border: '1px solid var(--color-paper-border)' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: '600', color: 'var(--color-charcoal-500)', padding: '0 6px' }}>Vai trò:</span>
          <button
            type="button"
            onClick={() => setCurrentRole('administrator')}
            className={`btn btn-sm ${currentRole === 'administrator' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
          >
            <ShieldCheck size={14} /> Admin
          </button>
          <button
            type="button"
            onClick={() => setCurrentRole('museumStaff')}
            className={`btn btn-sm ${currentRole === 'museumStaff' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
          >
            <UserCheck size={14} /> Staff
          </button>
          <button
            type="button"
            onClick={() => setCurrentRole('curator')}
            className={`btn btn-sm ${currentRole === 'curator' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
          >
            <Sparkles size={14} /> Curator
          </button>
        </div>

        {/* Notification bell */}
        <div style={{ position: 'relative' }}>
          <button
            type="button"
            className="btn btn-secondary"
            style={{ padding: '8px', borderRadius: '50%', width: '38px', height: '38px' }}
            title={`${pendingCurationCount} mục đang chờ duyệt`}
          >
            <Bell size={18} />
            {pendingCurationCount > 0 && (
              <span style={{
                position: 'absolute',
                top: '-2px',
                right: '-2px',
                background: 'var(--color-burgundy-600)',
                color: '#FFF',
                fontSize: '0.65rem',
                fontWeight: '700',
                width: '18px',
                height: '18px',
                borderRadius: '50%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                border: '2px solid #FFF'
              }}>
                {pendingCurationCount}
              </span>
            )}
          </button>
        </div>

        {/* User profile avatar */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          padding: '4px 12px 4px 6px',
          background: '#FFF',
          borderRadius: '24px',
          border: '1px solid var(--color-paper-border)'
        }}>
          <div style={{
            width: '32px',
            height: '32px',
            borderRadius: '50%',
            background: 'linear-gradient(135deg, var(--color-burgundy-700), var(--color-gold-600))',
            color: '#FFF',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: '700',
            fontSize: '0.85rem'
          }}>
            {currentRole === 'administrator' ? 'A' : currentRole === 'curator' ? 'C' : 'S'}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontSize: '0.8125rem', fontWeight: '600', color: 'var(--color-charcoal-900)' }}>
              {currentRole === 'administrator' ? 'Vũ Hải Đăng' : currentRole === 'curator' ? 'TS. Trần Văn Phong' : 'Nguyễn Mai Anh'}
            </span>
            <span style={{ fontSize: '0.675rem', color: 'var(--color-burgundy-700)', fontWeight: '600' }}>
              {currentRoleInfo.label}
            </span>
          </div>
        </div>
      </div>
    </header>
  );
}
