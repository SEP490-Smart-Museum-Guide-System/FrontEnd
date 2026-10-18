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
  ChevronDown,
  Check
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
    accountDesc: 'Quản lý không gian, hiện vật, tour & AI Studio'
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
    loginAccount,
    setActiveTab,
    curationQueue,
    artifacts,
    currentMuseum,
    users,
    logout
  } = useApp();

  const [isSwitchOpen, setIsSwitchOpen] = useState(false);

  const museumArtifactIds = new Set(
    artifacts.filter(item => item.museumId === currentMuseum.id).map(item => item.id)
  );
  const pendingCurationCount = curationQueue.filter(
    c => c.status === 'pending_review' && museumArtifactIds.has(c.targetArtifactId)
  ).length;

  const currentRoleInfo = roleMeta[currentRole] || roleMeta.administrator;

  // 4 standard staff/admin accounts
  const staffAccounts = users.filter(u => ['administrator', 'curator', 'museumStaff', 'systemStaff'].includes(u.role));

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
                  {currentMuseum.name}
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

          {/* Account Switcher Dropdown Modal */}
          {isSwitchOpen && (
            <>
              <div
                style={{ position: 'fixed', inset: 0, zIndex: 90 }}
                onClick={() => setIsSwitchOpen(false)}
              />
              <div style={{
                position: 'absolute',
                top: 'calc(100% + 8px)',
                right: 0,
                width: '360px',
                background: '#FFF',
                borderRadius: '12px',
                border: '1px solid var(--color-paper-border)',
                boxShadow: 'var(--shadow-xl)',
                zIndex: 100,
                padding: '12px',
                display: 'grid',
                gap: '8px'
              }}>
                <div style={{
                  padding: '6px 8px 10px',
                  borderBottom: '1px solid var(--color-paper-border)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between'
                }}>
                  <div>
                    <strong style={{ fontSize: '0.85rem', color: 'var(--color-charcoal-900)' }}>
                      Tài khoản 4 Vai trò Nghiệp vụ
                    </strong>
                    <p style={{ margin: '2px 0 0', fontSize: '0.72rem', color: 'var(--color-charcoal-500)' }}>
                      Mỗi vai trò sở hữu tài khoản và quyền hạn độc lập
                    </p>
                  </div>
                </div>

                <div style={{ display: 'grid', gap: '6px', maxHeight: '340px', overflowY: 'auto' }}>
                  {staffAccounts.map(account => {
                    const isCurrent = currentUser?.email === account.email;
                    const rInfo = roleMeta[account.role] || roleMeta.administrator;
                    const AccIcon = rInfo.icon;

                    return (
                      <button
                        key={account.id}
                        type="button"
                        onClick={() => {
                          loginAccount(account);
                          setIsSwitchOpen(false);
                        }}
                        style={{
                          display: 'flex',
                          alignItems: 'flex-start',
                          gap: '10px',
                          padding: '10px 12px',
                          borderRadius: '8px',
                          border: isCurrent ? '1.5px solid var(--color-gold-500)' : '1px solid var(--color-paper-border)',
                          background: isCurrent ? '#FFFDF8' : 'var(--color-paper-card)',
                          textAlign: 'left',
                          cursor: 'pointer',
                          transition: 'all var(--transition-fast)'
                        }}
                      >
                        <div style={{
                          width: '32px',
                          height: '32px',
                          borderRadius: '6px',
                          background: isCurrent ? 'var(--color-burgundy-700)' : 'var(--color-paper-accent)',
                          color: isCurrent ? '#FFF' : 'var(--color-charcoal-700)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          flexShrink: 0
                        }}>
                          <AccIcon size={16} />
                        </div>

                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                            <strong style={{ fontSize: '0.825rem', color: 'var(--color-charcoal-900)' }}>
                              {account.name}
                            </strong>
                            {isCurrent && <Check size={14} color="var(--color-success)" />}
                          </div>
                          <div style={{ fontSize: '0.72rem', color: 'var(--color-burgundy-700)', fontWeight: '600' }}>
                            {rInfo.label}
                          </div>
                          <div style={{ fontSize: '0.7rem', color: 'var(--color-charcoal-500)', marginTop: '2px' }}>
                            {account.email} · {rInfo.accountDesc}
                          </div>
                        </div>
                      </button>
                    );
                  })}
                </div>

                <div style={{
                  paddingTop: '8px',
                  borderTop: '1px solid var(--color-paper-border)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <small style={{ fontSize: '0.7rem', color: 'var(--color-charcoal-500)' }}>
                    Mật khẩu mặc định: <strong>smgs123</strong>
                  </small>
                  <button
                    type="button"
                    className="btn btn-secondary btn-sm"
                    style={{ fontSize: '0.75rem', padding: '4px 8px' }}
                    onClick={() => {
                      setIsSwitchOpen(false);
                      logout();
                    }}
                  >
                    <LogOut size={13} /> Đăng xuất ra màn hình chính
                  </button>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Quick Logout Button */}
        <button
          type="button"
          className="btn btn-secondary btn-sm topbar-logout"
          onClick={logout}
          title="Đăng xuất khỏi hệ thống"
        >
          <LogOut size={15} /> <span>Đăng xuất</span>
        </button>
      </div>
    </header>
  );
}
