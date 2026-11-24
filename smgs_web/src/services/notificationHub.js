import * as signalR from '@microsoft/signalr';
import { getAuthToken } from './auth.js';

const apiBase = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');
const defaultHubUrl = apiBase.endsWith('/api')
  ? `${apiBase.slice(0, -4)}/hubs/notifications`
  : `${apiBase}/hubs/notifications`;

class NotificationHubService {
  constructor() {
    this.connection = null;
    this.isStarting = false;
    this.onReceiveNotificationHandlers = new Set();
    this.onUnreadCountChangedHandlers = new Set();
  }

  /**
   * Khởi tạo và kết nối tới SignalR Notification Hub.
   * @param {string} [customHubUrl] - URL hub tùy chỉnh (nếu có)
   */
  async start(customHubUrl) {
    if (this.connection && this.connection.state === signalR.HubConnectionState.Connected) {
      return;
    }
    if (this.isStarting) return;
    this.isStarting = true;

    const url = customHubUrl || defaultHubUrl;

    try {
      if (!this.connection) {
        this.connection = new signalR.HubConnectionBuilder()
          .withUrl(url, {
            accessTokenFactory: () => {
              const token = getAuthToken();
              return token || '';
            },
            skipNegotiation: false,
            transport: signalR.HttpTransportType.WebSockets | signalR.HttpTransportType.LongPolling
          })
          .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
          .configureLogging(signalR.LogLevel.Warning)
          .build();

        // 1. Nhận thông báo mới
        this.connection.on('ReceiveNotification', (notification) => {
          this.onReceiveNotificationHandlers.forEach((handler) => {
            try {
              handler(notification);
            } catch (err) {
              console.error('[SignalR] Lỗi xử lý ReceiveNotification handler:', err);
            }
          });
        });

        // 2. Nhận cập nhật số lượng thông báo chưa đọc
        this.connection.on('UnreadCountChanged', (payload) => {
          const count = typeof payload === 'number' ? payload : payload?.unreadCount;
          if (typeof count === 'number') {
            this.onUnreadCountChangedHandlers.forEach((handler) => {
              try {
                handler(count);
              } catch (err) {
                console.error('[SignalR] Lỗi xử lý UnreadCountChanged handler:', err);
              }
            });
          }
        });

        this.connection.onreconnected(() => {
          console.info('[SignalR Notification Hub] Đã kết nối lại thành công.');
        });
      }

      const token = getAuthToken();
      if (!token) {
        this.isStarting = false;
        return;
      }

      if (this.connection.state === signalR.HubConnectionState.Disconnected) {
        await this.connection.start();
        console.info('[SignalR Notification Hub] Đã kết nối thành công.');
      }
    } catch (error) {
      console.warn('[SignalR Notification Hub] Không thể kết nối (sẽ tự thử lại khi thao tác):', error?.message || error);
    } finally {
      this.isStarting = false;
    }
  }

  /**
   * Ngắt kết nối hub (khi user logout).
   */
  async stop() {
    if (this.connection) {
      try {
        await this.connection.stop();
      } catch (_) {
        // bỏ qua lỗi khi ngắt kết nối
      } finally {
        this.connection = null;
        this.isStarting = false;
      }
    }
  }

  /**
   * Đăng ký callback khi nhận thông báo mới.
   * @param {Function} handler
   * @returns {Function} Hàm hủy đăng ký
   */
  onReceiveNotification(handler) {
    this.onReceiveNotificationHandlers.add(handler);
    return () => {
      this.onReceiveNotificationHandlers.delete(handler);
    };
  }

  /**
   * Đăng ký callback khi số chưa đọc thay đổi.
   * @param {Function} handler
   * @returns {Function} Hàm hủy đăng ký
   */
  onUnreadCountChanged(handler) {
    this.onUnreadCountChangedHandlers.add(handler);
    return () => {
      this.onUnreadCountChangedHandlers.delete(handler);
    };
  }
}

export const notificationHub = new NotificationHubService();
