import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { useApp } from './AppContext';
import { notificationApi } from '../services/notificationApi';
import { notificationHub } from '../services/notificationHub';

const NotificationContext = createContext(null);

export function NotificationProvider({ children }) {
  const { isAuthenticated, currentUser } = useApp();

  const [unreadCount, setUnreadCount] = useState(0);
  const [notifications, setNotifications] = useState([]);
  const [pagination, setPagination] = useState({ page: 1, pageSize: 20, totalCount: 0, totalPages: 1 });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [activeToast, setActiveToast] = useState(null);
  const toastTimeoutRef = useRef(null);

  // 1. Fetch danh sách thông báo
  const fetchNotifications = useCallback(async ({ unreadOnly, type, page = 1, pageSize = 20, append = false } = {}) => {
    if (!isAuthenticated) return;
    setLoading(true);
    setError(null);
    try {
      const data = await notificationApi.getNotifications({ unreadOnly, type, page, pageSize });
      if (data) {
        setNotifications((prev) => (append ? [...prev, ...(data.items || [])] : data.items || []));
        setPagination({
          page: data.page || 1,
          pageSize: data.pageSize || 20,
          totalCount: data.totalCount || 0,
          totalPages: data.totalPages || 1
        });
      }
    } catch (err) {
      console.warn('[NotificationContext] Lỗi tải thông báo:', err?.message || err);
      setError(err?.message || 'Không thể tải danh sách thông báo.');
    } finally {
      setLoading(false);
    }
  }, [isAuthenticated]);

  // 2. Fetch số lượng chưa đọc
  const fetchUnreadCount = useCallback(async () => {
    if (!isAuthenticated) return;
    try {
      const res = await notificationApi.getUnreadCount();
      if (res && typeof res.unreadCount === 'number') {
        setUnreadCount(res.unreadCount);
      }
    } catch (err) {
      console.warn('[NotificationContext] Lỗi tải unreadCount:', err?.message || err);
    }
  }, [isAuthenticated]);

  // 3. Đánh dấu 1 thông báo là đã đọc
  const markAsRead = useCallback(async (id) => {
    try {
      const updated = await notificationApi.markAsRead(id);
      setNotifications((prev) =>
        prev.map((item) => (item.id === id ? { ...item, isRead: true, readAt: updated?.readAt || new Date().toISOString() } : item))
      );
      setUnreadCount((prev) => Math.max(0, prev - 1));
      return updated;
    } catch (err) {
      console.error('[NotificationContext] Lỗi đánh dấu đã đọc:', err);
      throw err;
    }
  }, []);

  // 4. Đánh dấu tất cả là đã đọc
  const markAllAsRead = useCallback(async () => {
    try {
      const count = await notificationApi.markAllAsRead();
      setNotifications((prev) => prev.map((item) => ({ ...item, isRead: true, readAt: new Date().toISOString() })));
      setUnreadCount(0);
      return count;
    } catch (err) {
      console.error('[NotificationContext] Lỗi đánh dấu tất cả đã đọc:', err);
      throw err;
    }
  }, []);

  // 5. Xóa 1 thông báo
  const deleteNotification = useCallback(async (id) => {
    try {
      await notificationApi.deleteNotification(id);
      setNotifications((prev) => {
        const target = prev.find((item) => item.id === id);
        if (target && !target.isRead) {
          setUnreadCount((c) => Math.max(0, c - 1));
        }
        return prev.filter((item) => item.id !== id);
      });
    } catch (err) {
      console.error('[NotificationContext] Lỗi xóa thông báo:', err);
      throw err;
    }
  }, []);

  // 6. Tắt toast nổi
  const dismissToast = useCallback(() => {
    if (toastTimeoutRef.current) {
      clearTimeout(toastTimeoutRef.current);
      toastTimeoutRef.current = null;
    }
    setActiveToast(null);
  }, []);

  // 7. Hiển thị Toast với tự động ẩn sau 5 giây
  const showNotificationToast = useCallback((notification) => {
    if (toastTimeoutRef.current) {
      clearTimeout(toastTimeoutRef.current);
    }
    setActiveToast(notification);
    toastTimeoutRef.current = setTimeout(() => {
      setActiveToast(null);
      toastTimeoutRef.current = null;
    }, 5000);
  }, []);

  // 8. Đồng bộ vòng đời SignalR Hub theo Authentication
  useEffect(() => {
    if (!isAuthenticated) {
      setNotifications([]);
      setUnreadCount(0);
      dismissToast();
      notificationHub.stop();
      return;
    }

    // Tải dữ liệu ban đầu
    fetchUnreadCount();
    fetchNotifications({ page: 1, pageSize: 20 });

    // Khởi động SignalR hub
    notificationHub.start();

    // Lắng nghe sự kiện ReceiveNotification
    const unsubReceive = notificationHub.onReceiveNotification((notification) => {
      if (!notification) return;

      // Chèn vào đầu danh sách nếu chưa có
      setNotifications((prev) => {
        if (prev.some((n) => n.id === notification.id)) return prev;
        return [notification, ...prev];
      });

      // Tăng unread count tạm thời nếu backend chưa bắn UnreadCountChanged
      setUnreadCount((c) => c + 1);

      // Hiển thị Toast nổi
      showNotificationToast(notification);
    });

    // Lắng nghe sự kiện UnreadCountChanged
    const unsubUnread = notificationHub.onUnreadCountChanged((count) => {
      setUnreadCount(count);
    });

    return () => {
      unsubReceive();
      unsubUnread();
      if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    };
  }, [isAuthenticated, currentUser?.id, fetchUnreadCount, fetchNotifications, showNotificationToast, dismissToast]);

  const value = {
    unreadCount,
    notifications,
    pagination,
    loading,
    error,
    activeToast,
    dismissToast,
    fetchNotifications,
    fetchUnreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification
  };

  return <NotificationContext.Provider value={value}>{children}</NotificationContext.Provider>;
}

export function useNotification() {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotification must be used within a NotificationProvider');
  }
  return context;
}
