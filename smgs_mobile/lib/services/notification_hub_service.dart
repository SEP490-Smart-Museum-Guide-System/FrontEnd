import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../core/network/api_config.dart';
import '../models/notification_item.dart';
import 'token_manager.dart';

class NotificationHubService {
  HubConnection? _connection;
  bool _isStarting = false;

  void Function(NotificationItem)? onReceiveNotification;
  void Function(int)? onUnreadCountChanged;

  String get _hubUrl {
    final host = ApiConfig.customHost.trim().isNotEmpty
        ? ApiConfig.customHost.trim()
        : ApiConfig.defaultHost;
    return '$host/hubs/notifications';
  }

  Future<void> start() async {
    if (_connection?.state == HubConnectionState.Connected) return;
    if (_isStarting) return;
    _isStarting = true;

    try {
      final token = TokenManager.token;
      if (token == null || token.isEmpty) {
        _isStarting = false;
        return;
      }

      _connection ??= HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => TokenManager.token ?? '',
            ),
          )
          .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
          .build();

      _connection!.on('ReceiveNotification', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          try {
            final raw = arguments.first;
            if (raw is Map) {
              final item = NotificationItem.fromJson(
                Map<String, dynamic>.from(raw),
              );
              onReceiveNotification?.call(item);
            }
          } catch (_) {}
        }
      });

      _connection!.on('UnreadCountChanged', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          try {
            final raw = arguments.first;
            int count = 0;
            if (raw is num) {
              count = raw.toInt();
            } else if (raw is Map && raw['unreadCount'] is num) {
              count = (raw['unreadCount'] as num).toInt();
            }
            onUnreadCountChanged?.call(count);
          } catch (_) {}
        }
      });

      if (_connection!.state == HubConnectionState.Disconnected) {
        await _connection!.start();
      }
    } catch (_) {
      // Hub failure is non-fatal; REST fallback remains active.
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stop() async {
    try {
      if (_connection != null) {
        await _connection!.stop();
      }
    } catch (_) {
    } finally {
      _connection = null;
      _isStarting = false;
    }
  }
}
