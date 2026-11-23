import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/visitor_colors.dart';
import '../../core/theme/visitor_tokens.dart';
import '../../models/notification_item.dart';
import '../../services/notification_controller.dart';
import '../profile/history_screen.dart';
import '../profile/order_detail_screen.dart';
import '../profile/support_refund_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationController _controller = NotificationController.instance;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _controller.loadNotifications(refresh: true, unreadOnly: _unreadOnly ? true : null);
  }

  void _switchTab(bool unreadOnly) {
    if (_unreadOnly == unreadOnly) return;
    setState(() {
      _unreadOnly = unreadOnly;
    });
    _controller.loadNotifications(refresh: true, unreadOnly: unreadOnly ? true : null);
  }

  String _formatTime(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'PAYMENT_SUCCEEDED':
        return Icons.confirmation_number_outlined;
      case 'FEEDBACK_RESPONDED':
        return Icons.rate_review_outlined;
      case 'COMPLAINT_STATUS_UPDATED':
      case 'COMPLAINT_CREATED':
        return Icons.support_agent_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'PAYMENT_SUCCEEDED':
        return const Color(0xFF2E6B3E);
      case 'FEEDBACK_RESPONDED':
        return VisitorColors.gold;
      case 'COMPLAINT_STATUS_UPDATED':
      case 'COMPLAINT_CREATED':
        return VisitorColors.burgundy;
      default:
        return VisitorColors.burgundy;
    }
  }

  void _handleDeepLink(NotificationItem item) {
    if (!item.isRead) {
      _controller.markAsRead(item.id);
    }

    if (item.type == 'PAYMENT_SUCCEEDED' && item.referenceId != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: item.referenceId!),
        ),
      );
    } else if (item.type == 'COMPLAINT_STATUS_UPDATED' ||
        item.type == 'COMPLAINT_CREATED') {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const SupportRefundScreen(),
        ),
      );
    } else if (item.type == 'FEEDBACK_RESPONDED') {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: VisitorColors.text,
        title: Text(
          l10n.notificationCenterTitle,
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 20,
            color: VisitorColors.text,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _controller.markAllAsRead(),
                child: Text(
                  l10n.markAllRead,
                  style: const TextStyle(
                    color: VisitorColors.burgundy,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Tabs (Surface-2, Radius-md 16px)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VisitorColors.surface2,
                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchTab(false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_unreadOnly ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(VisitorRadius.sm),
                            boxShadow: !_unreadOnly
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              l10n.tabAllNotifications,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    !_unreadOnly ? FontWeight.bold : FontWeight.w500,
                                color: !_unreadOnly
                                    ? VisitorColors.burgundy
                                    : VisitorColors.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _switchTab(true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _unreadOnly ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(VisitorRadius.sm),
                            boxShadow: _unreadOnly
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              l10n.tabUnreadOnly,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    _unreadOnly ? FontWeight.bold : FontWeight.w500,
                                color: _unreadOnly
                                    ? VisitorColors.burgundy
                                    : VisitorColors.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Notification List
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.isLoading && _controller.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: VisitorColors.burgundy),
                    );
                  }

                  final list = _unreadOnly
                      ? _controller.notifications.where((n) => !n.isRead).toList()
                      : _controller.notifications;

                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: VisitorColors.surface2,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_off_outlined,
                                size: 36,
                                color: VisitorColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _unreadOnly ? l10n.noUnreadNotifications : l10n.noNotifications,
                              style: AppTextStyles.cardTitle.copyWith(
                                color: VisitorColors.text,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _unreadOnly
                                  ? (l10n.isEn ? 'All caught up! Check back later.' : 'Bạn đã đọc tất cả thông báo!')
                                  : (l10n.isEn
                                      ? 'New notifications about your journeys will appear here.'
                                      : 'Các thông báo mới về hành trình và ưu đãi sẽ xuất hiện tại đây.'),
                              style: AppTextStyles.caption.copyWith(
                                color: VisitorColors.secondaryText,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: VisitorColors.burgundy,
                    onRefresh: () => _controller.loadNotifications(
                      refresh: true,
                      unreadOnly: _unreadOnly ? true : null,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Dismissible(
                          key: Key('notif-${item.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC0392B),
                              borderRadius: BorderRadius.circular(VisitorRadius.xl),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onDismissed: (_) {
                            _controller.deleteNotification(item.id);
                          },
                          child: InkWell(
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                            onTap: () => _handleDeepLink(item),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? VisitorColors.surface1
                                    : VisitorColors.surfaceBrand,
                                borderRadius: BorderRadius.circular(VisitorRadius.xl),
                                border: Border.all(
                                  color: item.isRead
                                      ? VisitorColors.border
                                      : VisitorColors.burgundy.withValues(alpha: 0.35),
                                  width: item.isRead ? 1 : 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Type
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(VisitorRadius.md),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getIcon(item.type),
                                      color: _getIconColor(item.type),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontFamily: AppTextStyles.sansFamily,
                                                  fontWeight: item.isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.bold,
                                                  fontSize: 14,
                                                  color: VisitorColors.text,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: VisitorColors.burgundy,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.body,
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.sansFamily,
                                            fontSize: 12.5,
                                            height: 1.4,
                                            color: VisitorColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatTime(item.createdAt, l10n),
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.sansFamily,
                                            fontSize: 11,
                                            color: VisitorColors.secondaryText.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
