import '../core/localization/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/visitor_colors.dart';
import '../models/notification_item.dart';
import '../models/experience.dart';
import '../services/notification_controller.dart';
import '../screens/profile/order_detail_screen.dart';
import '../screens/profile/support_refund_screen.dart';
import '../screens/profile/history_screen.dart';

class NotificationBannerListener extends StatefulWidget {
  const NotificationBannerListener({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationBannerListener> createState() =>
      _NotificationBannerListenerState();
}

class _NotificationBannerListenerState extends State<NotificationBannerListener>
    with SingleTickerProviderStateMixin {
  StreamSubscription<NotificationItem>? _sub;
  NotificationItem? _currentBanner;
  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _sub = NotificationController.instance.onNewNotification.listen(_showBanner);
  }

  void _showBanner(NotificationItem item) {
    if (!mounted) return;
    _dismissTimer?.cancel();
    setState(() {
      _currentBanner = item;
    });
    _animController.forward(from: 0.0);
    _dismissTimer = Timer(const Duration(seconds: 4), _hideBanner);
  }

  void _hideBanner() {
    if (!mounted) return;
    _dismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentBanner = null;
        });
      }
    });
  }

  void _handleBannerTap() {
    if (_currentBanner == null) return;
    final item = _currentBanner!;
    _hideBanner();

    NotificationController.instance.markAsRead(item.id);

    if (item.type == 'PAYMENT_SUCCEEDED' && item.referenceId != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: item.referenceId!),
        ),
      );
    } else if (item.type == 'COMPLAINT_STATUS_UPDATED' ||
        item.type == 'COMPLAINT_CREATED') {
      final complaintId = item.referenceId != null
          ? int.tryParse(item.referenceId!)
          : null;
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => complaintId != null
              ? ComplaintDetailScreen(id: complaintId)
              : const SupportRefundScreen(),
        ),
      );
    } else if (item.type == 'FEEDBACK_RESPONDED') {
      final visitId = item.referenceId != null
          ? int.tryParse(item.referenceId!)
          : null;
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => visitId != null
              ? VisitDetailScreen(
                  visit: VisitRecord(
                    id: visitId.toString(),
                    museumId: (item.museumId ?? 1).toString(),
                    date: item.createdAt,
                  ),
                )
              : const HistoryScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentBanner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: GestureDetector(
                    onTap: _handleBannerTap,
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta != null &&
                          details.primaryDelta! < -6) {
                        _hideBanner();
                      }
                    },
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(VisitorRadius.xl),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(VisitorRadius.xl),
                          border: Border.all(
                            color: VisitorColors.burgundy.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: VisitorColors.surfaceBrand,
                                borderRadius:
                                    BorderRadius.circular(VisitorRadius.sm),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                size: 20,
                                color: VisitorColors.burgundy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentBanner!.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: VisitorColors.text,
                                      fontFamily: AppTextStyles.sansFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentBanner!.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: VisitorColors.secondaryText,
                                      fontFamily: AppTextStyles.sansFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: context.l10n.close,
                              color: VisitorColors.secondaryText,
                              onPressed: _hideBanner,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
