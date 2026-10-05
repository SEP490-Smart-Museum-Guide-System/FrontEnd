import React from 'react';
import { useApp } from '../../context/AppContext';
import {
  Landmark,
  ShieldCheck,
  UserCheck,
  Headset,
  Bell
} from 'lucide-react';

export default function Header() {
  const {
    currentRole,
    setCurrentRole,
    setActiveTab,
    curationQueue,
    artifacts,
    currentMuseum
  } = useApp();

  const museumArtifactIds = new Set(artifacts.filter(item => item.museumId === currentMuseum.id).map(item => item.id));
  const pendingCurationCount = curationQueue.filter(c => c.status === 'pending' && museumArtifactIds.has(c.targetArtifactId)).length;

  const roleLabels = {
    administrator: { label: 'Quản trị viên', icon: ShieldCheck, badgeClass: 'role-badge-admin' },
    museumStaff: { label: 'Nhân viên bảo tàng', icon: UserCheck, badgeClass: 'role-badge-staff' },
    systemStaff: { label: 'Nhân viên hệ thống', icon: Headset, badgeClass: 'role-badge-system' }
  };

  const currentRoleInfo = roleLabels[currentRole] || roleLabels.administrator;

  return (
    <header className="topbar">
      <div className="topbar-left">
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Landmark size={18} color="var(--color-burgundy-700)" />
          {currentRole !== 'museumStaff' ? (
            <span className="museum-select-badge">Toàn hệ thống</span>
          ) : (
            <span className="museum-select-badge">{currentMuseum.name}</span>
          )}
        </div>
      </div>

      <div className="topbar-right">
        <div className="role-switcher" style={{ display: 'flex', alignItems: 'center', gap: '8px', background: 'var(--color-paper-accent)', padding: '4px 6px', borderRadius: '10px', border: '1px solid var(--color-paper-border)' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: '600', color: 'var(--color-charcoal-500)', padding: '0 6px' }}>Giao diện web:</span>
          <button
            type="button"
            onClick={() => setCurrentRole('administrator')}
            className={`btn btn-sm ${currentRole === 'administrator' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
          >
            <ShieldCheck size={14} /> Quản trị
          </button>
          <button
            type="button"
            onClick={() => setCurrentRole('museumStaff')}
            className={`btn btn-sm ${currentRole === 'museumStaff' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
          >
            <UserCheck size={14} /> Bảo tàng
          </button>
          <button
            type="button"
            onClick={() => setCurrentRole('systemStaff')}
            className={`btn btn-sm ${currentRole === 'systemStaff' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ padding: '4px 10px', fontSize: '0.75rem', borderRadius: '6px' }}
          >
            <Headset size={14} /> Hệ thống
          </button>
        </div>

        {currentRole === 'museumStaff' && <div className="topbar-alert" style={{ position: 'relative' }}>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => setActiveTab('curation_queue')}
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
        </div>}

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
              {currentRole === 'administrator' ? 'Q' : currentRole === 'systemStaff' ? 'H' : 'B'}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontSize: '0.8125rem', fontWeight: '600', color: 'var(--color-charcoal-900)' }}>
              {currentRole === 'administrator' ? 'Vũ Hải Đăng' : currentRole === 'systemStaff' ? 'Trần Minh Châu' : 'Nguyễn Mai Anh'}
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
