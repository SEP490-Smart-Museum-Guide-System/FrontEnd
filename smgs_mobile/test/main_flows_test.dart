import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/main.dart';
import 'package:smgs_mobile/data/visit_store.dart';
import 'package:smgs_mobile/data/mock/mock_artifacts.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/models/experience.dart';
import 'package:smgs_mobile/screens/auth/auth_screen.dart';
import 'package:smgs_mobile/screens/artifact/qr_scan_screen.dart';
import 'package:smgs_mobile/screens/artifact/artifact_detail_screen.dart';
import 'package:smgs_mobile/screens/profile/profile_screen.dart';
import 'package:smgs_mobile/screens/profile/history_screen.dart';
import 'package:smgs_mobile/screens/profile/services_screen.dart';
import 'package:smgs_mobile/screens/tours/tours_screen.dart';
import 'package:smgs_mobile/screens/explore/explore_screen.dart';
import 'package:smgs_mobile/screens/management/management_home_screen.dart';
import 'package:smgs_mobile/widgets/primary_button.dart';
import 'package:smgs_mobile/widgets/narration_player.dart';
import 'package:smgs_mobile/widgets/museum_route_map.dart';

import 'widget_test.dart' show host, tapText, screenSize;

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

void main() {
  setUp(() {
    VisitStore.instance.reset();
    AppServices.auth = MockAuthService();
  });

  testWidgets(
    'Splash, invalid login, sample login and logout form one complete flow',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const SMGSApp());
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await tapText(tester, 'Đăng nhập');
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
      await tapText(tester, 'Điền tài khoản mẫu');
      await tapText(tester, 'Đăng nhập');
      expect(find.text('Chạm vào\nmiền ký ức.'), findsOneWidget);
      expect(AppServices.auth.user!.name, 'Minh An');
      await tapText(tester, 'Cá nhân');
      await tapText(tester, 'Đăng xuất');
      expect(AppServices.auth.user, isNull);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Registration validates confirmation and recovery sends no email',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const SMGSApp());
      await tester.pumpAndSettle();
      await tapText(tester, 'Quên mật khẩu?');
      await tester.enterText(field('Email'), 'demo@example.com');
      await tapText(tester, 'Khôi phục mô phỏng');
      expect(find.textContaining('Không có thư nào được gửi'), findsOneWidget);
      await tapText(tester, 'Về đăng nhập');
      await tapText(tester, 'Tạo tài khoản mới');
      await tester.enterText(field('Tên của bạn'), 'Ngọc An');
      await tester.enterText(field('Email'), 'ngocan@example.com');
      await tester.enterText(field('Mật khẩu'), 'demo123');
      await tester.enterText(field('Nhập lại mật khẩu'), 'khac');
      await tapText(tester, 'Tạo tài khoản trải nghiệm');
      expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
      await tester.enterText(field('Nhập lại mật khẩu'), 'demo123');
      await tapText(tester, 'Tạo tài khoản trải nghiệm');
      expect(AppServices.auth.user!.name, 'Ngọc An');
      expect(find.text('Chạm vào\nmiền ký ức.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Sample accounts open curator and administrator workspaces', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(const SMGSApp());
    await tester.pumpAndSettle();

    await tester.enterText(field('Email'), 'curator@smgs.vn');
    await tester.enterText(field('Mật khẩu'), 'smgs123');
    await tapText(tester, 'Đăng nhập');
    expect(find.byType(ManagementHomeScreen), findsOneWidget);
    expect(
      tester
          .widget<ManagementHomeScreen>(find.byType(ManagementHomeScreen))
          .role,
      UserRole.curator,
    );
    AppServices.auth.logout();
    await tester.pumpAndSettle();

    await tester.enterText(field('Email'), 'admin@smgs.vn');
    await tester.enterText(field('Mật khẩu'), 'smgs123');
    await tapText(tester, 'Đăng nhập');
    expect(find.byType(ManagementHomeScreen), findsOneWidget);
    expect(
      tester
          .widget<ManagementHomeScreen>(find.byType(ManagementHomeScreen))
          .role,
      UserRole.administrator,
    );
  });

  testWidgets(
    'Administrator uses a wide web dashboard with working navigation',
    (tester) async {
      await screenSize(tester, const Size(1280, 800));
      await tester.pumpWidget(const SMGSApp());
      await tester.pumpAndSettle();
      await tester.enterText(field('Email'), 'admin@smgs.vn');
      await tester.enterText(field('Mật khẩu'), 'smgs123');
      await tapText(tester, 'Đăng nhập');

      expect(find.text('Cổng quản trị'), findsOneWidget);
      expect(find.text('Tổng quan hệ thống'), findsOneWidget);
      expect(find.text('Hệ thống ổn định'), findsOneWidget);
      await tester.tap(find.text('Người dùng').first);
      await tester.pumpAndSettle();
      expect(find.text('Danh sách làm việc'), findsOneWidget);
      expect(find.text('PHỤ TRÁCH'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Curator studio stays readable in a narrow browser', (tester) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(const SMGSApp());
    await tester.pumpAndSettle();
    await tester.enterText(field('Email'), 'curator@smgs.vn');
    await tester.enterText(field('Mật khẩu'), 'smgs123');
    await tapText(tester, 'Đăng nhập');
    expect(find.text('Kể câu chuyện\ndi sản thật hay.'), findsOneWidget);
    expect(find.text('Dòng chảy nội dung'), findsOneWidget);
  });

  testWidgets('QR and recognition handle match, no match and museum context', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      host(
        const QRScanScreen(recognition: true, museumId: 'museum_ho_chi_minh'),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Thử tình huống không tìm thấy');
    await tapText(tester, 'Nhận diện mô phỏng');
    expect(find.text('Chưa tìm thấy hiện vật'), findsOneWidget);
    await tapText(tester, 'Thử lại');
    await tapText(tester, 'Nhận diện mô phỏng');
    expect(find.text('Trang báo cách mạng'), findsOneWidget);
    await tapText(tester, 'Xem hiện vật');
    expect(
      tester
          .widget<ArtifactDetailScreen>(find.byType(ArtifactDetailScreen))
          .artifact
          .museumId,
      'museum_ho_chi_minh',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(host(const QRScanScreen()));
    await tester.pumpAndSettle();
    await tapText(tester, 'Bật đèn mô phỏng');
    expect(find.text('Tắt đèn mô phỏng'), findsOneWidget);
    await tapText(tester, 'Quét mã mô phỏng');
    expect(
      tester
          .widget<ArtifactDetailScreen>(find.byType(ArtifactDetailScreen))
          .artifact
          .id,
      'artifact_1',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Tour requires interests, supports multiple interests, skipping and early end',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(const ToursScreen()));
      await tester.pumpAndSettle();
      await tapText(tester, 'Lịch sử');
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      await tapText(tester, 'Nghệ thuật');
      await tapText(tester, 'Khoa học');
      await tapText(tester, 'Gợi ý hành trình');
      final route = tester.widget<TourRouteScreen>(
        find.byType(TourRouteScreen),
      );
      expect(route.interest, contains('Nghệ thuật'));
      expect(route.interest, contains('Khoa học'));
      await tapText(tester, 'Bắt đầu hành trình');
      expect(find.byType(MuseumRouteMap), findsOneWidget);
      await tapText(tester, 'Bỏ qua điểm này');
      await tapText(tester, 'Kết thúc sớm hành trình');
      final record = VisitStore.instance.history.single.tours.single;
      expect(record.skippedIds, hasLength(1));
      expect(record.completed, isFalse);
      expect(VisitStore.instance.completedTours, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'History groups a day and stores contextual, rating-required feedback',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      VisitStore.instance.visit(mockArtifacts[0]);
      VisitStore.instance.visit(mockArtifacts[1]);
      VisitStore.instance.recordQuiz('artifact_1', 2);
      expect(VisitStore.instance.history, hasLength(1));
      await tester.pumpWidget(host(const HistoryScreen()));
      await tester.pumpAndSettle();
      await tapText(tester, 'Bảo tàng Lịch sử Quốc gia');
      expect(find.byType(VisitDetailScreen), findsOneWidget);
      await tapText(tester, 'Góp ý chuyến tham quan');
      await tester.scrollUntilVisible(
        find.text('Ghi nhận góp ý'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      await tapText(tester, 'Hài lòng');
      await tapText(tester, 'Ghi nhận góp ý');
      expect(find.text('Cảm ơn bạn!'), findsOneWidget);
      expect(VisitStore.instance.feedback.single.targetType, 'visit');
      expect(
        VisitStore.instance.feedback.single.targetId,
        VisitStore.instance.history.single.id,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Payment failure preserves checkout; success activates only once and opens service',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(
          ServiceCheckoutScreen(
            offer: AppServices.premium.offers[1],
            museumId: 'museum_national',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'VNPay');
      await tapText(tester, 'Thất bại');
      await tapText(tester, 'Xác nhận thanh toán mô phỏng');
      expect(find.text('Thanh toán chưa thành công'), findsOneWidget);
      expect(VisitStore.instance.purchases, isEmpty);
      await tapText(tester, 'Thử thanh toán lại');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'VNPay'))
            .selected,
        isTrue,
      );
      await tapText(tester, 'Thành công');
      await tapText(tester, 'Xác nhận thanh toán mô phỏng');
      expect(find.text('Đã đăng ký dịch vụ'), findsOneWidget);
      expect(VisitStore.instance.purchases, hasLength(1));
      await tapText(tester, 'Bắt đầu sử dụng dịch vụ');
      expect(find.byType(NarrationScreen), findsOneWidget);
      await tapText(tester, 'Phát thử mô phỏng');
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Tạm dừng mô phỏng'), findsOneWidget);
      await tapText(tester, 'Tạm dừng mô phỏng');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Artifact filters combine and reset museum, gallery and exhibition',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(const ExploreScreen(initialArtifacts: true)),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Lọc bảo tàng, chuyên đề, phòng');
      await tapText(tester, 'Tất cả bảo tàng');
      await tapText(tester, 'Bảo tàng Hồ Chí Minh');
      await tapText(tester, 'Tất cả phòng');
      await tapText(tester, 'Phòng trưng bày 4');
      await tapText(tester, 'Lọc bảo tàng, chuyên đề, phòng');
      await tapText(tester, 'Tư liệu');
      expect(find.text('1 hiện vật được tìm thấy'), findsOneWidget);
      await tapText(tester, 'Xóa bộ lọc và từ khóa');
      expect(find.text('3 hiện vật được tìm thấy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('New screens fit 320px with larger text', (tester) async {
    await screenSize(tester, const Size(320, 640));
    for (final screen in <Widget>[
      const AuthScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
      const BadgesScreen(),
      const ServicesScreen(),
      const PurchasedServicesScreen(),
      ServiceCheckoutScreen(
        offer: AppServices.premium.offers.first,
        museumId: 'museum_national',
      ),
      PaymentResultScreen(
        success: true,
        offer: AppServices.premium.offers.first,
        museumId: 'museum_national',
        date: DateTime.now(),
      ),
      const QRScanScreen(recognition: true),
      NarrationScreen(artifact: mockArtifacts.first),
    ]) {
      await tester.pumpWidget(host(screen, scale: 1.3));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} initial',
      );
      final scroll = find.byType(Scrollable).first;
      for (var i = 0; i < 6; i++) {
        await tester.drag(scroll, const Offset(0, -380));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} scroll $i',
        );
      }
    }
  });

  test('Best quiz scores, badges and purchases cannot be duplicated', () {
    final store = VisitStore.instance;
    store.recordQuiz('artifact_1', 2);
    store.recordQuiz('artifact_1', 1);
    store.recordQuiz('artifact_1', 2);
    expect(store.points, 20);
    expect(store.badges, hasLength(1));
    final purchase = ServicePurchase(
      id: 'sample',
      offer: AppServices.premium.offers.first,
      museumId: 'museum_national',
      date: DateTime.now(),
      method: 'MoMo',
    );
    store.activate(purchase);
    store.activate(purchase);
    expect(store.purchases, hasLength(1));
    store.reset();
    expect(store.history, isEmpty);
    expect(store.purchases, isEmpty);
  });
}
