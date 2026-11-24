import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/core/localization/app_localizations.dart';
import 'package:smgs_mobile/services/app_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferences.instance.setLanguage('vi');
  });

  tearDown(() {
    AppPreferences.instance.setLanguage('vi');
  });

  group('AppLocalizations Unit Tests', () {
    test('Vietnamese and English instances provide valid non-empty strings', () {
      final vi = AppLocalizations(const Locale('vi'));
      final en = AppLocalizations(const Locale('en'));

      expect(vi.isEn, isFalse);
      expect(en.isEn, isTrue);

      // Common actions
      expect(vi.ok, 'Đồng ý');
      expect(en.ok, 'OK');
      expect(vi.cancel, 'Hủy');
      expect(en.cancel, 'Cancel');

      // Home
      expect(vi.featuredMuseums, 'Bảo tàng nổi bật');
      expect(en.featuredMuseums, 'Featured Museums');
      expect(vi.scanQrCode, 'Quét hiện vật');
      expect(en.scanQrCode, 'Scan Artifact');

      // Explore & Museum
      expect(vi.exploreTitle, 'Khám phá bảo tàng');
      expect(en.exploreTitle, 'Discover Museums');
      expect(vi.startExploreCTA, 'Bắt đầu khám phá');
      expect(en.startExploreCTA, 'Start Exploring');

      // Notifications
      expect(vi.notificationCenterTitle, 'Thông báo');
      expect(en.notificationCenterTitle, 'Notifications');
      expect(vi.markAllRead, 'Đánh dấu tất cả đã đọc');
      expect(en.markAllRead, 'Mark all as read');
      expect(vi.timeJustNow, 'Vừa xong');
      expect(en.timeJustNow, 'Just now');
      expect(vi.timeMinutesAgo(5), '5 phút trước');
      expect(en.timeMinutesAgo(5), '5m ago');

      // Profile & Settings
      expect(vi.sectionLanguage, 'Ngôn ngữ');
      expect(en.sectionLanguage, 'Language');
      expect(vi.prefLargeText, 'Cỡ chữ lớn');
      expect(en.prefLargeText, 'Large Text');

      // Bottom Navigation Tabs
      expect(vi.tabHome, 'Trang chủ');
      expect(en.tabHome, 'Home');
      expect(vi.tabExplore, 'Khám phá');
      expect(en.tabExplore, 'Explore');
      expect(vi.tabScan, 'Quét mã');
      expect(en.tabScan, 'Scan');
      expect(vi.tabJourneys, 'Hành trình');
      expect(en.tabJourneys, 'Journeys');
      expect(vi.tabProfile, 'Cá nhân');
      expect(en.tabProfile, 'Profile');
    });

    test('AppLocalizationsDelegate correctly supports vi and en', () {
      const delegate = AppLocalizationsDelegate();

      expect(delegate.isSupported(const Locale('vi')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
      expect(delegate.shouldReload(delegate), isFalse);
    });
  });

  group('AppPreferences Language State Tests', () {
    test('Changing language updates value and triggers notification', () {
      final prefs = AppPreferences.instance;
      prefs.setLanguage('vi');
      expect(prefs.language, 'vi');

      var notified = false;
      prefs.addListener(() {
        notified = true;
      });

      prefs.setLanguage('en');
      expect(prefs.language, 'en');
      expect(notified, isTrue);

      // Setting same language does not re-notify
      notified = false;
      prefs.setLanguage('en');
      expect(notified, isFalse);

      // Clean up
      prefs.setLanguage('vi');
    });
  });

  group('Widget Localization Integration Test', () {
    testWidgets('Widget translates dynamically based on active Locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.featuredMuseums),
                    Text(l10n.notificationCenterTitle),
                    Text(l10n.scanQrCode),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Featured Museums'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Scan Artifact'), findsOneWidget);

      // Now pump with Vietnamese
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.featuredMuseums),
                    Text(l10n.notificationCenterTitle),
                    Text(l10n.scanQrCode),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bảo tàng nổi bật'), findsOneWidget);
      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Quét hiện vật'), findsOneWidget);
    });
  });
}
