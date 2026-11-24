import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smgs_mobile/core/localization/app_localizations.dart';
import 'package:smgs_mobile/services/app_preferences.dart';
import 'package:smgs_mobile/services/token_manager.dart';
import 'package:smgs_mobile/models/museum.dart';
import 'package:smgs_mobile/models/artifact.dart';

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

      // Fallback Translation & Audio notes
      expect(vi.fallbackTranslationNote.contains('tiếng Việt'), isTrue);
      expect(en.fallbackTranslationNote.contains('English translation not yet available'), isTrue);
      expect(vi.fallbackAudioNote.contains('tiếng Việt'), isTrue);
      expect(en.fallbackAudioNote.contains('English narration not yet available'), isTrue);
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

  group('Accept-Language Header Tests', () {
    test('TokenManager.authHeaders emits correct Accept-Language based on active language', () {
      final prefs = AppPreferences.instance;

      prefs.setLanguage('vi', syncRemote: false);
      expect(TokenManager.authHeaders['Accept-Language'], 'vi');

      prefs.setLanguage('en', syncRemote: false);
      expect(TokenManager.authHeaders['Accept-Language'], 'en');

      // Reset
      prefs.setLanguage('vi', syncRemote: false);
      expect(TokenManager.authHeaders['Accept-Language'], 'vi');
    });
  });

  group('Dynamic Multilingual DTO Fallback Tests', () {
    test('Museum.fromBackendJson parses languageCode', () {
      final jsonEn = {
        'id': 1,
        'name': 'Vietnam National Museum of History',
        'address': '1 Trang Tien, Hanoi',
        'description': 'Description in English',
        'languageCode': 'en',
      };
      final museumEn = Museum.fromBackendJson(jsonEn);
      expect(museumEn.name, 'Vietnam National Museum of History');
      expect(museumEn.languageCode, 'en');

      final jsonVi = {
        'id': 2,
        'name': 'Bảo tàng Lịch sử Quốc gia',
        'address': '1 Tràng Tiền, Hà Nội',
        'description': 'Mô tả tiếng Việt',
        'languageCode': 'vi',
      };
      final museumVi = Museum.fromBackendJson(jsonVi);
      expect(museumVi.name, 'Bảo tàng Lịch sử Quốc gia');
      expect(museumVi.languageCode, 'vi');
    });

    test('Artifact.fromBackendJson matches content by preferred language and fallback to vi', () {
      final jsonWithBoth = {
        'id': 100,
        'name': 'Trống đồng Ngọc Lũ',
        'languageCode': 'vi',
        'contents': [
          {
            'languageCode': 'vi',
            'title': 'Trống đồng Ngọc Lũ',
            'description': 'Mô tả tiếng Việt về trống đồng'
          },
          {
            'languageCode': 'en',
            'title': 'Ngoc Lu Bronze Drum',
            'description': 'English description of the bronze drum'
          }
        ]
      };

      // When language is EN, selects English content
      AppPreferences.instance.setLanguage('en', syncRemote: false);
      final artifactEn = Artifact.fromBackendJson(jsonWithBoth);
      expect(artifactEn.summary, 'English description of the bronze drum');

      // When language is VI, selects Vietnamese content
      AppPreferences.instance.setLanguage('vi', syncRemote: false);
      final artifactVi = Artifact.fromBackendJson(jsonWithBoth);
      expect(artifactVi.summary, 'Mô tả tiếng Việt về trống đồng');

      // When English is missing, fallbacks to Vietnamese
      final jsonOnlyVi = {
        'id': 101,
        'name': 'Thạp đồng Đào Thịnh',
        'languageCode': 'vi',
        'contents': [
          {
            'languageCode': 'vi',
            'title': 'Thạp đồng Đào Thịnh',
            'description': 'Mô tả tiếng Việt duy nhất'
          }
        ]
      };
      AppPreferences.instance.setLanguage('en', syncRemote: false);
      final fallbackArtifact = Artifact.fromBackendJson(jsonOnlyVi);
      expect(fallbackArtifact.summary, 'Mô tả tiếng Việt duy nhất');
      expect(fallbackArtifact.languageCode, 'vi');

      // Reset
      AppPreferences.instance.setLanguage('vi', syncRemote: false);
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
