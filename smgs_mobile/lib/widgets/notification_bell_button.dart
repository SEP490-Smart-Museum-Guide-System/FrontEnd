import 'package:flutter/material.dart';
import '../core/theme/visitor_colors.dart';
import '../screens/notification/notification_center_screen.dart';
import '../services/notification_controller.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.color,
    this.size = 24.0,
  });

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final controller = NotificationController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final unread = controller.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Thông báo',
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              icon: Icon(
                unread > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                size: size,
                color: color ?? VisitorColors.text,
              ),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen(),
                  ),
                );
              },
            ),
            if (unread > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: VisitorColors.burgundy,
                    borderRadius: BorderRadius.circular(VisitorRadius.full),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
