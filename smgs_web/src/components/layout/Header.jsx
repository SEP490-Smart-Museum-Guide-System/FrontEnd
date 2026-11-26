import { createPortal } from 'react-dom';
import React, { useState, useRef, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import { useNotification } from '../../context/NotificationContext';
import NotificationCenter from './NotificationCenter';
import NotificationToast from '../common/NotificationToast';
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

export default function Header({ setSearchHost, accountHost }) {
  const {
    currentUser,
    currentRole,
    setActiveTab,
    currentMuseum,
    museums,
    selectedMuseumId,
    setSelectedMuseumId,
    setPendingNotificationTarget,
    logout
  } = useApp();

  const { unreadCount } = useNotification();

  const [isSwitchOpen, setIsSwitchOpen] = useState(false);
  const [isNotificationOpen, setIsNotificationOpen] = useState(false);

  const notifRef = useRef(null);
  const switchRef = useRef(null);

  // Xử lý đóng dropdown khi click ra ngoài
  useEffect(() => {
    function handleClickOutside(event) {
      if (notifRef.current && !notifRef.current.contains(event.target)) {
        setIsNotificationOpen(false);
      }
      if (switchRef.current && !switchRef.current.contains(event.target)) {
        setIsSwitchOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleNotificationNavigate = (notification) => {
    if (!notification) return;
    const { type, referenceType, referenceId, actionUrl, museumId } = notification;

    // Tự động chuyển sang bảo tàng của thông báo nếu thông báo gắn với museumId cụ thể
    if (museumId && ['museumStaff', 'curator', 'administrator'].includes(currentRole)) {
      const targetMuseum = museums.find((m) => Number(m.id) === Number(museumId));
      if (targetMuseum && Number(selectedMuseumId) !== Number(targetMuseum.id)) {
        setSelectedMuseumId(Number(targetMuseum.id));
      }
    }

    if (typeof setPendingNotificationTarget === 'function') {
      setPendingNotificationTarget({
        type,
        referenceType,
        referenceId,
        actionUrl,
        museumId,
        timestamp: Date.now()
      });
    }

    if (type === 'CONTENT_SUBMITTED' || type === 'TOUR_SUBMITTED') {
      setActiveTab('curation_queue');
    } else if (type === 'CONTENT_APPROVED' || type === 'CONTENT_REJECTED') {
      setActiveTab(currentRole === 'curator' ? 'curation_queue' : 'submission_status');
    } else if (type === 'TOUR_APPROVED' || type === 'TOUR_REJECTED') {
      setActiveTab(currentRole === 'curator' ? 'curation_queue' : 'tours');
    } else if (type === 'COMPLAINT_CREATED' || type === 'COMPLAINT_STATUS_UPDATED') {
      setActiveTab('support');
    } else if (type === 'PAYMENT_SUCCEEDED') {
      setActiveTab('transactions');
    } else if (type === 'FEEDBACK_RESPONDED') {
      setActiveTab('reviews');
    } else if (actionUrl) {
      if (actionUrl.includes('curation') || actionUrl.includes('artifact-contents')) {
        setActiveTab(currentRole === 'curator' ? 'curation_queue' : 'submission_status');
      } else if (actionUrl.includes('tours')) {
        setActiveTab(currentRole === 'curator' ? 'curation_queue' : 'tours');
      } else if (actionUrl.includes('complaint')) {
        setActiveTab('support');
      } else if (actionUrl.includes('order') || actionUrl.includes('commerce')) {
        setActiveTab('transactions');
      } else if (actionUrl.includes('feedback')) {
        setActiveTab('reviews');
      }
    }
  };

  const currentRoleInfo = roleMeta[currentRole] || roleMeta.administrator;

  const sidebarAccount = ['administrator', 'museumStaff', 'curator'].includes(currentRole);
  const accountMenu = (
        <div ref={switchRef} style={{ position: 'relative' }}>
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
            <div
              style={{
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
              }}
            >
              {currentUser?.name ? currentUser.name.charAt(0) : 'U'}
            </div>

            {/* User Info */}
            <div style={{ display: 'flex', flexDirection: 'column', textAlign: 'left', lineHeight: 1.25 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: '700', color: 'var(--color-charcoal-900)' }}>
                  {currentUser?.name || 'Tài khoản nghiệp vụ'}
                </span>
                <span
                  style={{
                    fontSize: '0.65rem',
                    padding: '2px 6px',
                    borderRadius: '4px',
                    background: currentRoleInfo.badgeBg,
                    color: currentRoleInfo.badgeText,
                    fontWeight: '700'
                  }}
                >
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
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                  marginBottom: '12px',
                  paddingBottom: '12px',
                  borderBottom: '1px solid var(--color-paper-border)'
                }}
              >
                <div
                  style={{
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
                  }}
                >
                  {currentUser?.name ? currentUser.name.charAt(0) : 'U'}
                </div>
                <div style={{ minWidth: 0, flex: 1 }}>
                  <strong
                    style={{
                      display: 'block',
                      fontSize: '0.9rem',
                      color: 'var(--color-charcoal-900)',
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis'
                    }}
                  >
                    {currentUser?.name}
                  </strong>
                  <span
                    style={{
                      display: 'block',
                      fontSize: '0.74rem',
                      color: 'var(--color-charcoal-500)',
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis'
                    }}
                  >
                    {currentUser?.email}
                  </span>
                </div>
              </div>
              <div style={{ marginBottom: '14px' }}>
                <span
                  style={{
                    display: 'inline-block',
                    fontSize: '0.72rem',
                    padding: '3px 8px',
                    borderRadius: '6px',
                    background: currentRoleInfo.badgeBg,
                    color: currentRoleInfo.badgeText,
                    fontWeight: '700'
                  }}
                >
                  {currentRoleInfo.label}
                </span>
                <p
                  style={{
                    fontSize: '0.74rem',
                    color: 'var(--color-charcoal-500)',
                    marginTop: '4px',
                    lineHeight: 1.4
                  }}
                >
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
  );

  return (
    <header className="topbar">
      {/* Real-time Floating Toast Alert */}
      {sidebarAccount && <div className="admin-search" ref={setSearchHost} />}
      <NotificationToast onNavigate={handleNotificationNavigate} />

      {/* TopBar Left: Scope & Museum Indicator */}
      {['museumStaff', 'curator'].includes(currentRole) && (
      <div className="topbar-left">
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '8px',
              background: 'var(--color-paper-accent)',
              border: '1px solid var(--color-paper-border)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--color-burgundy-700)'
            }}
          >
            <Landmark size={18} />
          </div>

          <div>
            <span className="museum-select-badge" style={{ fontWeight: '600', color: 'var(--color-burgundy-900)' }}>
              <select
                aria-label="Bảo tàng đang xem"
                value={selectedMuseumId ?? ''}
                onChange={(e) => setSelectedMuseumId(Number(e.target.value))}
              >
                <option value="" disabled>
                  Chọn bảo tàng
                </option>
                {museums.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.name}
                  </option>
                ))}
              </select>
            </span>
          </div>
        </div>
      </div>

      )}

      {/* TopBar Right: Notifications & User Identity */}
      <div className="topbar-right" style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '14px' }}>
        {/* Central Notification Bell for all logged-in roles */}
        <div ref={notifRef} style={{ position: 'relative' }}>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => setIsNotificationOpen(!isNotificationOpen)}
            style={{
              padding: '8px',
              borderRadius: '50%',
              width: '38px',
              height: '38px',
              position: 'relative'
            }}
            title={unreadCount > 0 ? `${unreadCount} thông báo chưa đọc` : 'Thông báo'}
            aria-label="Thông báo"
            aria-expanded={isNotificationOpen}
          >
            <Bell size={18} />
            {unreadCount > 0 && (
              <span
                style={{
                  position: 'absolute',
                  top: '-2px',
                  right: '-2px',
                  background: 'var(--color-burgundy-700)',
                  color: '#FFF',
                  fontSize: '0.65rem',
                  fontWeight: '700',
                  minWidth: '18px',
                  height: '18px',
                  padding: '0 4px',
                  borderRadius: '10px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  border: '2px solid #FFF',
                  boxShadow: '0 2px 4px rgba(0,0,0,0.15)'
                }}
              >
                {unreadCount > 99 ? '99+' : unreadCount}
              </span>
            )}
          </button>

          {/* Notification Dropdown Panel */}
          {isNotificationOpen && (
            <NotificationCenter
              onClose={() => setIsNotificationOpen(false)}
              onNavigate={handleNotificationNavigate}
            />
          )}
        </div>

        {/* Current User Identity Box with Account Switcher Dropdown */}
        {sidebarAccount && accountHost ? createPortal(<>
          {accountMenu}
          <button type="button" className="admin-signout" onClick={logout} title="Đăng xuất" aria-label="Đăng xuất"><LogOut size={16} /></button>
        </>, accountHost) : accountMenu}
      </div>
    </header>
  );
}
