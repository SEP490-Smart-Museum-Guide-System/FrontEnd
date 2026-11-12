import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Landmark,
  ShieldCheck,
  UserCheck,
  Headset,
  BookOpenCheck,
  Bell,
  LogOut,
  ChevronDown
} from 'lucide-react';

const roleMeta = {
  administrator: {
    label: 'Quản trị viên Hệ thống',
    shortLabel: 'Quản trị',
    icon: ShieldCheck,
    color: 'var(--color-charcoal-900)',
    badgeBg: '#EDE0CE',
    badgeText: '#4A3B33',
    accountDesc: 'Toàn quyền cấu hình hệ thống & phân quyền'
  },
  museumStaff: {
    label: 'Nhân viên Bảo tàng',
    shortLabel: 'Bảo tàng',
    icon: UserCheck,
    color: 'var(--color-burgundy-700)',
    badgeBg: '#F8EEEA',
    badgeText: '#6B2E2E',
    accountDesc: 'Quản lý không gian, hiện vật, tuyến tham quan và xưởng nội dung AI'
  },
  curator: {
    label: 'Giám tuyển Thẩm định',
    shortLabel: 'Giám tuyển',
    icon: BookOpenCheck,
    color: 'var(--color-gold-700)',
    badgeBg: '#F8F1E7',
    badgeText: '#775936',
    accountDesc: 'Thẩm định độc lập hiện vật, thuyết minh & quiz'
  },
  systemStaff: {
    label: 'Nhân viên Vận hành & Hỗ trợ',
    shortLabel: 'Hệ thống',
    icon: Headset,
    color: '#0369A1',
    badgeBg: '#F0F9FF',
    badgeText: '#0369A1',
    accountDesc: 'Hỗ trợ khách, xử lý hoàn tiền & giám sát AI'
  }
};

export default function Header() {
  const {
    currentUser,
    currentRole,

    setActiveTab,
    curationQueue,
    artifacts,
    currentMuseum,
    museums, selectedMuseumId, setSelectedMuseumId,

    logout
  } = useApp();

  const [isSwitchOpen, setIsSwitchOpen] = useState(false);

  const museumArtifactIds = new Set(
    artifacts.filter(item => item.museumId === currentMuseum?.id).map(item => item.id)
  );
  const pendingCurationCount = curationQueue.filter(
    c => c.status === 'pending_review' && museumArtifactIds.has(c.targetArtifactId)
  ).length;

  const currentRoleInfo = roleMeta[currentRole] || roleMeta.administrator;


  return (
    <header className="topbar">
      {/* TopBar Left: Scope & Museum Indicator */}
      <div className="topbar-left">
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '32px',
            height: '32px',
            borderRadius: '8px',
            background: 'var(--color-paper-accent)',
            border: '1px solid var(--color-paper-border)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'var(--color-burgundy-700)'
          }}>
            <Landmark size={18} />
          </div>

          <div>
            {!['museumStaff', 'curator'].includes(currentRole) ? (
              <div>
                <span className="museum-select-badge" style={{ fontWeight: '600' }}>
                  HỆ THỐNG TOÀN QUỐC
                </span>
              </div>
            ) : (
              <div>
                <span className="museum-select-badge" style={{ fontWeight: '600', color: 'var(--color-burgundy-900)' }}>
                  <select aria-label="Bảo tàng đang xem" value={selectedMuseumId ?? ''} onChange={e => setSelectedMuseumId(Number(e.target.value))}>
                    <option value="" disabled>Chọn bảo tàng</option>
                    {museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
                  </select>
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* TopBar Right: Account Identity & Actions */}
      <div className="topbar-right" style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        {/* Pending Curation Notification for Curator / Staff */}
        {['museumStaff', 'curator'].includes(currentRole) && (
          <div style={{ position: 'relative' }}>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => setActiveTab(currentRole === 'curator' ? 'curation_queue' : 'submission_status')}
              style={{ padding: '8px', borderRadius: '50%', width: '38px', height: '38px' }}
              title={`${pendingCurationCount} mục đang chờ Giám tuyển thẩm định`}
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
        )}

        {/* Current User Identity Box with Account Switcher Dropdown */}
        <div style={{ position: 'relative' }}>
          <button
            type="button"
            onClick={() => setIsSwitchOpen(!isSwitchOpen)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '6px 14px 6px 8px',
              background: '#FFF',
              borderRadius: '28px',
              border: '1.5px solid var(--color-paper-border)',
              cursor: 'pointer',
              boxShadow: 'var(--shadow-sm)',
              transition: 'all var(--transition-fast)'
            }}
          >
            {/* User Avatar */}
            <div style={{
              width: '34px',
              height: '34px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, var(--color-burgundy-700), var(--color-gold-600))',
              color: '#FFF',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: '700',
              fontSize: '0.85rem'
            }}>
              {currentUser?.name ? currentUser.name.charAt(0) : 'U'}
            </div>

            {/* User Info */}
            <div style={{ display: 'flex', flexDirection: 'column', textAlign: 'left', lineHeight: 1.25 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: '700', color: 'var(--color-charcoal-900)' }}>
                  {currentUser?.name || 'Tài khoản nghiệp vụ'}
                </span>
                <span style={{
                  fontSize: '0.65rem',
                  padding: '2px 6px',
                  borderRadius: '4px',
                  background: currentRoleInfo.badgeBg,
                  color: currentRoleInfo.badgeText,
                  fontWeight: '700'
                }}>
                  {currentRoleInfo.shortLabel}
                </span>
              </div>
              <small style={{ fontSize: '0.72rem', color: 'var(--color-charcoal-500)' }}>
                {currentUser?.email || 'email@smgs.vn'}
              </small>
            </div>

            <ChevronDown size={14} color="var(--color-charcoal-400)" style={{ marginLeft: '4px' }} />
          </button>

          {isSwitchOpen && (
            <div
              role="menu"
              style={{
                position: 'absolute',
                top: 'calc(100% + 8px)',
                right: 0,
                zIndex: 1000,
                minWidth: '260px',
                background: '#fffdf9',
                padding: '16px',
                borderRadius: '12px',
                border: '1px solid var(--color-paper-border)',
                boxShadow: '0 16px 40px rgba(58, 38, 28, 0.16)',
                animation: 'menuAppear 140ms ease-out'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px', paddingBottom: '12px', borderBottom: '1px solid var(--color-paper-border)' }}>
                <div style={{
                  width: '38px',
                  height: '38px',
                  borderRadius: '50%',
                  background: 'linear-gradient(135deg, var(--color-burgundy-700), var(--color-gold-600))',
                  color: '#FFF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: '700',
                  fontSize: '0.95rem'
                }}>
                  {currentUser?.name ? currentUser.name.charAt(0) : 'U'}
                </div>
                <div style={{ minWidth: 0, flex: 1 }}>
                  <strong style={{ display: 'block', fontSize: '0.9rem', color: 'var(--color-charcoal-900)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {currentUser?.name}
                  </strong>
                  <span style={{ display: 'block', fontSize: '0.74rem', color: 'var(--color-charcoal-500)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {currentUser?.email}
                  </span>
                </div>
              </div>
              <div style={{ marginBottom: '14px' }}>
                <span style={{
                  display: 'inline-block',
                  fontSize: '0.72rem',
                  padding: '3px 8px',
                  borderRadius: '6px',
                  background: currentRoleInfo.badgeBg,
                  color: currentRoleInfo.badgeText,
                  fontWeight: '700'
                }}>
                  {currentRoleInfo.label}
                </span>
                <p style={{ fontSize: '0.74rem', color: 'var(--color-charcoal-500)', marginTop: '4px', lineHeight: 1.4 }}>
                  {currentRoleInfo.accountDesc}
                </p>
              </div>
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={logout}
                style={{ width: '100%', justifyContent: 'center', gap: '6px', color: 'var(--color-danger)' }}
              >
                <LogOut size={14} /> Đăng xuất tài khoản
              </button>
            </div>
          )}
        </div>

      </div>
    </header>
  );
}
