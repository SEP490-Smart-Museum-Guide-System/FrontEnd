import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smgs_mobile/main.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/models/experience.dart';
import 'package:smgs_mobile/screens/home/home_screen.dart';
import 'package:smgs_mobile/core/theme/app_theme.dart';
import 'package:smgs_mobile/data/mock/mock_artifacts.dart';
import 'package:smgs_mobile/data/visit_store.dart';
import 'package:smgs_mobile/screens/explore/explore_screen.dart';
import 'package:smgs_mobile/screens/artifact/artifact_detail_screen.dart';
import 'package:smgs_mobile/screens/artifact/quiz_screen.dart';
import 'package:smgs_mobile/screens/artifact/qr_scan_screen.dart';
import 'package:smgs_mobile/screens/ai_guide/ai_guide_screen.dart';
import 'package:smgs_mobile/screens/tours/tours_screen.dart';
import 'package:smgs_mobile/screens/profile/profile_screen.dart';
import 'package:smgs_mobile/screens/profile/services_screen.dart';

Widget host(Widget child, {double scale = 1}) => MaterialApp(
  locale: const Locale('vi'),
  supportedLocales: const [Locale('vi')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: AppTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);
Future<void> screenSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> tapText(WidgetTester tester, String label) async {
  final matches = find.text(label);
  if (matches.evaluate().isEmpty) {
    final scrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      matches,
      250,
      scrollable: scrollable,
      maxScrolls: 30,
    );
  }
  final target = matches.last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppServices.auth = MockAuthService(
      initialUser: const VisitorUser(
        name: 'Người dùng thử',
        email: 'nguoidung@smgs.vn',
      ),
    );
    final s = VisitStore.instance;
    s.reset();
  });
  testWidgets('Vietnamese home and all five navigation tabs render at 360px', (
    tester,
  ) async {
    await screenSize(tester, const Size(360, 800));
    await tester.pumpWidget(const SMGSApp());
    await tester.pumpAndSettle();
    expect(find.text('Chạm vào\nmiền ký ức.'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    for (final label in [
      'Khám phá',
      'Quét mã',
      'Hành trình',
      'Cá nhân',
      'Trang chủ',
    ]) {
      await tapText(tester, label);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'Search accepts Vietnamese without accents and handles empty results',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(host(const ExploreScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ho chi minh');
      await tester.pumpAndSettle();
      expect(find.text('Bảo tàng Hồ Chí Minh'), findsOneWidget);
      expect(find.text('Bảo tàng Lịch sử Quốc gia'), findsNothing);
      await tester.enterText(find.byType(TextField), 'khong co hien vat');
      await tester.pumpAndSettle();
      expect(find.text('Chưa tìm thấy kết quả'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Artifact visit and bookmark are reflected in session state', (
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
    expect(VisitStore.instance.viewed.single.id, 'artifact_1');
    expect(VisitStore.instance.history, isEmpty);
    await tester.tap(find.byTooltip('Lưu hiện vật'));
    await tester.pumpAndSettle();
    expect(VisitStore.instance.saved, contains('artifact_1'));
    await tester.tap(find.byTooltip('Bỏ lưu hiện vật'));
    await tester.pumpAndSettle();
    expect(VisitStore.instance.saved, isEmpty);
  });
  testWidgets('Quiz gates submission, scores once and records result', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(host(QuizScreen(artifact: mockArtifacts.first)));
    await tester.pumpAndSettle();
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Trả lời'),
    );
    expect(button.onPressed, isNull);
    await tapText(tester, 'Văn hóa Đông Sơn');
    await tapText(tester, 'Trả lời');
    expect(find.text('Chính xác!'), findsOneWidget);
    await tapText(tester, 'Câu tiếp theo');
    await tapText(tester, 'Giúp tìm hiểu đời sống và lịch sử');
    await tapText(tester, 'Trả lời');
    await tapText(tester, 'Xem kết quả');
    expect(find.text('2 / 2'), findsOneWidget);
    expect(VisitStore.instance.quizScores['artifact_1'], 2);
  });
  testWidgets(
    'Guide answers suggested questions and does not invent freeform answers',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(AiGuideScreen(artifact: mockArtifacts.first)),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Hiện vật thuộc thời kỳ nào?');
      expect(
        find.text('Hiện vật được giới thiệu trong bối cảnh: Văn hóa Đông Sơn.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextField),
        'Ai đã tìm thấy hiện vật?',
      );
      await tester.tap(find.byTooltip('Gửi câu hỏi'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Mình chưa có câu trả lời được kiểm chứng'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Tour uses one museum and completes each stop', (tester) async {
    await screenSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      host(
        TourRouteScreen(
          stops: mockArtifacts.take(2).toList(),
          duration: 60,
          interest: 'Lịch sử',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Bắt đầu hành trình');
    await tapText(tester, 'Đến điểm tiếp theo');
    expect(find.text('Ấn triện hoàng cung'), findsOneWidget);
    await tapText(tester, 'Hoàn thành hành trình');
    expect(find.text('Hành trình đáng nhớ'), findsOneWidget);
    expect(VisitStore.instance.completedTours, 1);
  });
  testWidgets(
    'Narrow screens with larger text remain scrollable without overflow',
    (tester) async {
      await screenSize(tester, const Size(320, 640));
      for (final screen in <Widget>[
        HomeScreen(onExplore: () {}, onScan: () {}),
        const ExploreScreen(),
        const QRScanScreen(),
        const ToursScreen(),
        const ProfileScreen(),
        const ServicesScreen(),
        const FeedbackScreen(),
        ArtifactDetailScreen(
          artifact: mockArtifacts.first,
          museumName: 'Bảo tàng Lịch sử Quốc gia',
        ),
        AiGuideScreen(artifact: mockArtifacts.first),
        QuizScreen(artifact: mockArtifacts.first),
      ]) {
        await tester.pumpWidget(host(screen, scale: 1.3));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Initial layout: ${screen.runtimeType}',
        );
        final scroll = find.byType(Scrollable).first;
        await tester.drag(scroll, const Offset(0, -1600));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Scrolled layout: ${screen.runtimeType}',
        );
      }
    },
  );
}
