import '../models/notification_item.dart';
import 'backend_api.dart';

class NotificationApiService {
  /// Lấy danh sách thông báo phân trang của Visitor hiện tại.
  static Future<NotificationPageData> getNotifications({
    bool? unreadOnly,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String>[];
    if (unreadOnly != null) query.add('unreadOnly=$unreadOnly');
    if (type != null && type.isNotEmpty) query.add('type=$type');
    query.add('page=$page');
    query.add('pageSize=$pageSize');

    final path = 'notifications?${query.join('&')}';
    final data = await BackendApi.request(path);
    if (data is Map<String, dynamic>) {
      return NotificationPageData.fromJson(data);
    } else if (data is Map) {
      return NotificationPageData.fromJson(Map<String, dynamic>.from(data));
    }
    throw const FormatException('Dữ liệu thông báo trả về không hợp lệ.');
  }

  /// Lấy số lượng thông báo chưa đọc.
  static Future<int> getUnreadCount() async {
    final data = await BackendApi.request('notifications/unread-count');
    if (data is Map && data.containsKey('unreadCount')) {
      return (data['unreadCount'] as num).toInt();
    }
    return 0;
  }

  /// Đánh dấu 1 thông báo là đã đọc.
  static Future<NotificationItem?> markAsRead(int id) async {
    final data = await BackendApi.request(
      'notifications/$id/read',
      method: 'PATCH',
    );
    if (data is Map) {
      return NotificationItem.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// Đánh dấu tất cả thông báo của visitor là đã đọc.
  static Future<int> markAllAsRead() async {
    final data = await BackendApi.request(
      'notifications/read-all',
      method: 'PATCH',
    );
    if (data is num) return data.toInt();
    return 0;
  }

  /// Xóa 1 thông báo.
  static Future<void> deleteNotification(int id) async {
    await BackendApi.request(
      'notifications/$id',
      method: 'DELETE',
    );
  }
}
