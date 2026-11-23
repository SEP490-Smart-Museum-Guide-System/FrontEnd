import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/models/notification_item.dart';
import 'package:smgs_mobile/screens/notification/notification_center_screen.dart';
import 'package:smgs_mobile/widgets/notification_bell_button.dart';

void main() {
  test('NotificationItem parsing and copyWith work properly', () {
    final json = {
      'id': 15,
      'recipientId': 'user-123',
      'museumId': 1,
      'type': 'PAYMENT_SUCCEEDED',
      'title': 'Thanh toán thành công',
      'body': 'Đơn hàng vé tham quan đã thanh toán thành công.',
      'referenceType': 'PurchaseOrder',
      'referenceId': 'order-abc',
      'actionUrl': '/commerce/orders/order-abc/invoice',
      'isRead': false,
      'readAt': null,
      'createdAt': '2026-11-22T06:20:00Z',
    };

    final item = NotificationItem.fromJson(json);
    expect(item.id, 15);
    expect(item.type, 'PAYMENT_SUCCEEDED');
    expect(item.isRead, isFalse);
    expect(item.referenceId, 'order-abc');

    final updated = item.copyWith(isRead: true);
    expect(updated.isRead, isTrue);
    expect(updated.id, 15);
  });

  test('NotificationPageData parses items correctly', () {
    final json = {
      'items': [
        {
          'id': 1,
          'type': 'COMPLAINT_STATUS_UPDATED',
          'title': 'Cập nhật khiếu nại',
          'body': 'Nhân viên đã tiếp nhận khiếu nại.',
          'isRead': true,
          'createdAt': '2026-11-22T08:00:00Z',
        }
      ],
      'page': 1,
      'pageSize': 20,
      'totalCount': 1,
      'totalPages': 1,
    };

    final page = NotificationPageData.fromJson(json);
    expect(page.items.length, 1);
    expect(page.items.first.title, 'Cập nhật khiếu nại');
    expect(page.totalCount, 1);
  });

  testWidgets('NotificationCenterScreen renders empty state cleanly at 360px', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(360 * 2, 740 * 2);
    tester.binding.window.devicePixelRatioTestValue = 2.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationCenterScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Chưa đọc'), findsOneWidget);
  });

  testWidgets('NotificationBellButton displays bell icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationBellButton(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotificationBellButton), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);
  });
}
