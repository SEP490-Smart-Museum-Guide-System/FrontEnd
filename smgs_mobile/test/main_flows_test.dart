import 'support/api_widgets.dart';
import 'support/fake_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/main.dart';
import 'package:smgs_mobile/data/visit_store.dart';
import 'package:smgs_mobile/data/mock/mock_artifacts.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/screens/auth/auth_screen.dart';
import 'package:smgs_mobile/screens/artifact/qr_scan_screen.dart';
import 'package:smgs_mobile/screens/artifact/artifact_detail_screen.dart';
import 'package:smgs_mobile/screens/artifact/artifact_3d_screen.dart';
import 'package:smgs_mobile/screens/profile/profile_screen.dart';
import 'package:smgs_mobile/screens/profile/history_screen.dart';
import 'package:smgs_mobile/screens/profile/services_screen.dart';
import 'package:smgs_mobile/screens/tours/tours_screen.dart';
import 'package:smgs_mobile/screens/explore/explore_screen.dart';
import 'package:smgs_mobile/widgets/narration_player.dart';

import 'widget_test.dart' show host, tapText, screenSize;

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

void main() {
  setUp(() {
    VisitStore.instance.reset();
    AppServices.auth = MockAuthService();
    AppServices.catalog = MockCatalogService();
    AppServices.recognition = MockRecognitionService(AppServices.catalog);
    AppServices.tours = MockTourService(AppServices.catalog);
  });

  apiTestWidgets(
    'Splash, invalid login, visitor login and logout form one complete flow',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const SMGSApp());
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Tiếp tục với vai trò khách'), findsNothing);
      await tapText(tester, 'Đăng nhập');
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
      await tester.enterText(field('Email'), 'khach@smgs.vn');
      await tester.enterText(field('Mật khẩu'), 'smgs123');
      await tapText(tester, 'Đăng nhập');
      expect(find.text('Chạm vào\nmiền ký ức.'), findsOneWidget);
      expect(AppServices.auth.user!.name, 'Minh An');
      await tapText(tester, 'Cá nhân');
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tapText(tester, 'Đăng xuất');
      expect(AppServices.auth.user, isNull);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  apiTestWidgets(
    'Registration validates password confirmation and opens the visitor workspace',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const SMGSApp());
      await tester.pumpAndSettle();
      await tapText(tester, 'Tạo tài khoản mới');
      await tester.enterText(field('Tên của bạn'), 'Ngọc An');
      await tester.enterText(field('Email'), 'ngocan@example.com');
      await tester.enterText(field('Mật khẩu'), 'demo123');
      await tester.enterText(field('Nhập lại mật khẩu'), 'khac');
      await tapText(tester, 'Đăng ký tài khoản');
      expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
      await tester.enterText(field('Nhập lại mật khẩu'), 'demo123');
      await tapText(tester, 'Đăng ký tài khoản');
      expect(AppServices.auth.user!.name, 'Ngọc An');
      expect(find.text('Chạm vào\nmiền ký ức.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  apiTestWidgets('Mobile only opens visitor workspace', (tester) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(const SMGSApp());
    await tester.pumpAndSettle();
    expect(find.text('Kiểm duyệt viên'), findsNothing);
    expect(find.textContaining('dùng cổng web'), findsOneWidget);
    await tester.enterText(field('Email'), 'admin@smgs.vn');
    await tester.enterText(field('Mật khẩu'), 'smgs123');
    await tapText(tester, 'Đăng nhập');
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(
      find.textContaining('Email hoặc mật khẩu chưa đúng'),
      findsOneWidget,
    );
    await tester.enterText(field('Email'), 'khach@smgs.vn');
    await tapText(tester, 'Đăng nhập');
    expect(find.text('Chạm vào\nmiền ký ức.'), findsOneWidget);
  });
  apiTestWidgets(
    'QR and recognition handle match, no match and museum context',
    (tester) async {
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
      expect(VisitStore.instance.history, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(host(const QRScanScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Mở camera quét QR'), findsOneWidget);
      expect(find.text('Mã QR hoặc URL trên mã QR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  apiTestWidgets('Narration separates duration from level of detail', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      host(NarrationScreen(artifact: mockArtifacts.first)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tiếng Việt'), findsOneWidget);
    await tapText(tester, 'Văn bản');
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Văn bản'))
          .selected,
      isTrue,
    );
    await tapText(tester, 'Dài');
    await tapText(tester, 'Chuyên sâu');
    expect(find.text('Dài · Chuyên sâu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  apiTestWidgets('Artifact with a model opens the simulated 3D viewer', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      host(
        ArtifactDetailScreen(
          artifact: mockArtifacts.first,
          museumName: 'Bảo tàng Lịch sử Quốc gia',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Xem mô hình 3D');
    expect(find.byType(Artifact3DScreen), findsOneWidget);
    expect(find.text('Kéo ngang để xoay'), findsOneWidget);
    expect(find.text('Đặt lại góc nhìn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  apiTestWidgets('Products do not fall back to sample offers on API error', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(host(const ServicesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Vé vào cửa bảo tàng'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('Chưa có dữ liệu kiểm thử'), findsOneWidget);
  });

  apiTestWidgets(
    'Unavailable museum data never creates a local sample itinerary',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(const ToursScreen()));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Cá nhân hóa là lựa chọn thêm.'),
        findsOneWidget,
      );
      expect(find.text('Xem tour có sẵn'), findsOneWidget);
      expect(find.text('Tham quan tự do'), findsOneWidget);
      await tapText(tester, 'Gợi ý theo sở thích');
      expect(find.byType(TourRouteScreen), findsNothing);
      expect(VisitStore.instance.history, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  apiTestWidgets('History never replaces an API failure with local visits', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    VisitStore.instance.visit(mockArtifacts.first);
    await tester.pumpWidget(host(const HistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Bảo tàng Lịch sử Quốc gia'), findsNothing);
    expect(find.textContaining('Chưa có dữ liệu kiểm thử'), findsOneWidget);
  });

  apiTestWidgets(
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

  apiTestWidgets('New screens fit 320px with larger text', (tester) async {
    await screenSize(tester, const Size(320, 640));
    for (final screen in <Widget>[
      const AuthScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
      const BadgesScreen(),
      const ServicesScreen(),
      const PurchasedServicesScreen(),
      ServiceCheckoutScreen(
        offer: MockPremiumCatalog().offers.first,
        museumId: 'museum_national',
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

  test('Best sample quiz scores and badges cannot be duplicated', () {
    final store = VisitStore.instance;
    store.recordQuiz('artifact_1', 2);
    store.recordQuiz('artifact_1', 1);
    store.recordQuiz('artifact_1', 2);
    expect(store.points, 20);
    expect(store.badges, hasLength(1));
    store.reset();
    expect(store.history, isEmpty);
  });
}
