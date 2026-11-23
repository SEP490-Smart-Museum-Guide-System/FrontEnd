import { backend } from './backend.js';

/**
 * Service gọi REST API cho hệ thống Thông báo (Notification).
 * Tài liệu tham chiếu: NOTIFICATION_API_GUIDE.md
 */
export const notificationApi = {
  /**
   * Lấy danh sách thông báo phân trang của user hiện tại.
   * @param {Object} params
   * @param {boolean} [params.unreadOnly] - Chỉ lấy thông báo chưa đọc
   * @param {string} [params.type] - Lọc theo mã loại (CONTENT_SUBMITTED, v.v.)
   * @param {number} [params.page=1] - Số trang
   * @param {number} [params.pageSize=20] - Kích thước trang
   * @returns {Promise<{items: Array, page: number, pageSize: number, totalCount: number, totalPages: number}>}
   */
  async getNotifications({ unreadOnly, type, page = 1, pageSize = 20 } = {}) {
    const query = new URLSearchParams();
    if (typeof unreadOnly === 'boolean') query.append('unreadOnly', String(unreadOnly));
    if (type) query.append('type', type);
    if (page) query.append('page', String(page));
    if (pageSize) query.append('pageSize', String(pageSize));

    const qs = query.toString();
    const path = `notifications${qs ? `?${qs}` : ''}`;
    return await backend(path);
  },

  /**
   * Lấy số lượng thông báo chưa đọc (để hiển thị badge icon chuông).
   * @returns {Promise<{unreadCount: number}>}
   */
  async getUnreadCount() {
    return await backend('notifications/unread-count');
  },

  /**
   * Đánh dấu 1 thông báo là đã đọc.
   * @param {number|string} id - ID thông báo
   * @returns {Promise<Object>} Notification item sau khi cập nhật
   */
  async markAsRead(id) {
    return await backend(`notifications/${id}/read`, { method: 'PATCH' });
  },

  /**
   * Đánh dấu toàn bộ thông báo của user là đã đọc.
   * @returns {Promise<number>} Số lượng thông báo đã cập nhật
   */
  async markAllAsRead() {
    return await backend('notifications/read-all', { method: 'PATCH' });
  },

  /**
   * Xóa 1 thông báo theo ID.
   * @param {number|string} id - ID thông báo
   * @returns {Promise<null>}
   */
  async deleteNotification(id) {
    return await backend(`notifications/${id}`, { method: 'DELETE' });
  }
};
