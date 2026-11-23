import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import 'notification_api_service.dart';
import 'notification_hub_service.dart';
import 'token_manager.dart';

class NotificationController extends ChangeNotifier {
  static final NotificationController instance = NotificationController._();

  NotificationController._() {
    _hubService.onReceiveNotification = _handleReceiveNotification;
    _hubService.onUnreadCountChanged = _handleUnreadCountChanged;
  }

  final NotificationHubService _hubService = NotificationHubService();
  final StreamController<NotificationItem> _newNotificationStream =
      StreamController<NotificationItem>.broadcast();

  Stream<NotificationItem> get onNewNotification => _newNotificationStream.stream;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentPage = 1;
  int _totalPages = 1;
  bool get hasMore => _currentPage < _totalPages;

  void _handleReceiveNotification(NotificationItem item) {
    if (!_notifications.any((n) => n.id == item.id)) {
      _notifications = [item, ..._notifications];
    }
    _unreadCount++;
    _newNotificationStream.add(item);
    notifyListeners();
  }

  void _handleUnreadCountChanged(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  Future<void> init() async {
    if (TokenManager.hasToken) {
      await refreshUnreadCount();
      await startHub();
    }
  }

  Future<void> startHub() async {
    if (TokenManager.hasToken) {
      await _hubService.start();
    }
  }

  Future<void> stopHub() async {
    await _hubService.stop();
  }

  Future<void> refreshUnreadCount() async {
    if (!TokenManager.hasToken) {
      _unreadCount = 0;
      notifyListeners();
      return;
    }
    try {
      final count = await NotificationApiService.getUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadNotifications({
    bool refresh = false,
    bool? unreadOnly,
  }) async {
    if (!TokenManager.hasToken) {
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    if (refresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final pageData = await NotificationApiService.getNotifications(
        unreadOnly: unreadOnly,
        page: _currentPage,
        pageSize: 20,
      );

      if (refresh || _currentPage == 1) {
        _notifications = pageData.items;
      } else {
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newItems = pageData.items.where((n) => !existingIds.contains(n.id));
        _notifications = [..._notifications, ...newItems];
      }

      _currentPage = pageData.page;
      _totalPages = pageData.totalPages;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore({bool? unreadOnly}) async {
    if (_isLoading || !hasMore) return;
    _currentPage++;
    await loadNotifications(refresh: false, unreadOnly: unreadOnly);
  }

  Future<void> markAsRead(int id) async {
    try {
      await NotificationApiService.markAsRead(id);
      _notifications = _notifications.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true, readAt: DateTime.now());
        }
        return item;
      }).toList();
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationApiService.markAllAsRead();
      _notifications = _notifications.map((item) {
        return item.copyWith(isRead: true, readAt: DateTime.now());
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteNotification(int id) async {
    try {
      await NotificationApiService.deleteNotification(id);
      final target = _notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => NotificationItem(
          id: -1,
          type: '',
          title: '',
          body: '',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      );
      if (!target.isRead && _unreadCount > 0) {
        _unreadCount--;
      }
      _notifications = _notifications.where((n) => n.id != id).toList();
      notifyListeners();
    } catch (_) {}
  }

  void resetOnLogout() {
    _notifications = [];
    _unreadCount = 0;
    stopHub();
    notifyListeners();
  }
}
