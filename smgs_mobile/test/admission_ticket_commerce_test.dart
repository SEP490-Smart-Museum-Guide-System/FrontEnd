import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smgs_mobile/screens/profile/order_detail_screen.dart';
import 'package:smgs_mobile/screens/profile/services_screen.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'support/fake_services.dart';
import 'widget_test.dart' show host;

void main() {
  setUp(() {
    AppServices.auth = MockAuthService();
    AppServices.catalog = MockCatalogService();
  });

  group('Admission Ticket & Combo Purchasing (ServicesScreen)', () {
    testWidgets('renders combo purchase view with admission tickets and optional digital guide', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await http.runWithClient(() async {
        await tester.pumpWidget(host(const ServicesScreen()));
        await tester.pumpAndSettle();

        expect(find.text('VÉ VÀO CỔNG BẢO TÀNG'), findsOneWidget);
        expect(find.text('Vé tham quan tiêu chuẩn'), findsOneWidget);
        expect(find.text('40.000 đ/người'), findsOneWidget);
        expect(find.text('GÓI THUYẾT MINH AI & 3D'), findsOneWidget);
        expect(find.text('TỔNG THANH TOÁN'), findsOneWidget);
        expect(find.text('Đặt vé ngay'), findsOneWidget);

        // Verify counter: starts at 1
        expect(find.text('1'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsOneWidget);

        // Subtotal: 2 * 40k = 80k + 50k = 130k
        expect(find.text('130.000 đ'), findsOneWidget);

        // Uncheck digital package: total becomes 80k
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(find.text('80.000 đ'), findsOneWidget);
      }, () => MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/api/museums')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': '1', 'name': 'Bảo tàng Lịch sử Quốc gia'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path.contains('/admission-offers')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 101, 'name': 'Vé tham quan tiêu chuẩn', 'price': 40000, 'isActive': true},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path.contains('/products')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 201,
                  'name': 'Gói thuyết minh AI & 3D',
                  'price': 50000,
                  'kind': 'digital',
                  'seats': 1,
                  'validityHours': 24,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(jsonEncode({'data': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }));
    });

    testWidgets('allows selecting different digital packages via dropdown when multiple exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await http.runWithClient(() async {
        await tester.pumpWidget(host(const ServicesScreen()));
        await tester.pumpAndSettle();

        // Starts with hihi (20.000 đ): 40.000 ticket + 20.000 digital = 60.000 đ
        expect(find.text('60.000 đ'), findsOneWidget);
        expect(find.text('Chọn gói thuyết minh & AI'), findsOneWidget);

        // Tap dropdown to pick Combo 3 người (50.000 đ)
        await tester.tap(find.text('Chọn gói thuyết minh & AI'));
        await tester.pumpAndSettle();

        final comboOption = find.text('Combo 3 người (3 người) · 50.000 đ').last;
        await tester.tap(comboOption);
        await tester.pumpAndSettle();

        // New total: 40.000 ticket + 50.000 digital = 90.000 đ
        expect(find.text('90.000 đ'), findsOneWidget);
      }, () => MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/api/museums')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': '1', 'name': 'Bảo tàng Lịch sử Quốc gia'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path.contains('/admission-offers')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 101, 'name': 'Vé tham quan tiêu chuẩn', 'price': 40000, 'isActive': true},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path.contains('/products')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 201,
                  'name': 'hihi',
                  'price': 20000,
                  'kind': 'digital',
                  'seats': 1,
                  'validityHours': 24,
                },
                {
                  'id': 202,
                  'name': 'Combo 3 người',
                  'price': 50000,
                  'kind': 'digital',
                  'seats': 3,
                  'validityHours': 24,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(jsonEncode({'data': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }));
    });
  });

  group('Admission Ticket QR & Boarding Pass (OrderDetailScreen)', () {
    testWidgets('displays Boarding Pass with QrImageView and item breakdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await http.runWithClient(() async {
        await tester.pumpWidget(host(const OrderDetailScreen(orderId: '99')));
        await tester.pumpAndSettle();

        expect(find.text('VÉ VÀO CỔNG ĐIỆN TỬ'), findsOneWidget);
        expect(find.text('Hợp lệ vào cổng'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.textContaining('TICK-MUSEUM-ABC123XYZ'), findsOneWidget);

        // Verify item breakdown and cancel button
        expect(find.text('CHI TIẾT MÓN TRONG ĐƠN'), findsOneWidget);
        expect(find.text('Hủy vé vào cổng'), findsOneWidget);
        expect(find.text('Hủy gói thuyết minh'), findsOneWidget);
      }, () => MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/commerce/orders/me')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 99,
                  'productName': 'Vé vào cổng + Gói thuyết minh AI',
                  'amount': 90000,
                  'currency': 'VND',
                  'status': 'paid',
                  'seats': 1,
                  'visitDate': '2026-12-10',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path.contains('/transactions')) {
          return http.Response(jsonEncode({'data': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        if (path.contains('/admission-ticket')) {
          return http.Response(
            jsonEncode({
              'data': {
                'code': 'TICK-MUSEUM-ABC123XYZ',
                'visitDate': '2026-12-10',
                'museumId': 1,
                'quantity': 1,
                'used': 0,
                'remaining': 1,
                'canCheckIn': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (path.contains('/items')) {
          return http.Response(
            jsonEncode({
              'data': {
                'ticketAmount': 40000,
                'digitalAmount': 50000,
                'ticketCancelledAt': null,
                'digitalCancelledAt': null,
                'ticketRefundedAmount': 0,
                'digitalRefundedAmount': 0,
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(jsonEncode({'data': []}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }));
    });
  });
}
