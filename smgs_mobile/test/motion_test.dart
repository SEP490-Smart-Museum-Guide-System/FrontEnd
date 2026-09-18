import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smgs_mobile/main.dart';
import 'package:smgs_mobile/services/app_services.dart';
import 'package:smgs_mobile/widgets/heritage_motion.dart';

import 'widget_test.dart' show tapText, screenSize;

void main() {
  setUp(() => AppServices.auth.guest());
  testWidgets(
    'Reveal follows a replaced scroll position after physics change',
    (tester) async {
      await screenSize(tester, const Size(390, 600));
      Widget page(ScrollPhysics physics) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            physics: physics,
            child: const Column(
              children: [
                SizedBox(height: 650),
                ScrollReveal(
                  child: SizedBox(
                    height: 150,
                    child: Text('Nội dung sau thay đổi cuộn'),
                  ),
                ),
                SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(page(const ClampingScrollPhysics()));
      await tester.pumpAndSettle();
      final state = tester.state<ScrollableState>(find.byType(Scrollable));
      final oldPosition = state.position;
      await tester.pumpWidget(page(const BouncingScrollPhysics()));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)),
        same(state),
      );
      expect(state.position, isNot(same(oldPosition)));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byType(ScrollReveal),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value,
        1,
      );
    },
  );
  testWidgets('Web semantics alone must not disable scroll animations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(accessibleNavigation: true, disableAnimations: false),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            children: const [
              ScrollReveal(child: Text('Câu chuyện đang mở')),
              ParallaxPhoto(
                height: 200,
                child: ColoredBox(color: Colors.brown),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(ScrollReveal),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, greaterThan(0));
    expect(fade.opacity.value, lessThan(1));
    expect(find.byType(Flow), findsOneWidget);
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Photo transition, pinned title and back navigation work from both tabs',
    (tester) async {
      await screenSize(tester, const Size(390, 844));
      await tester.pumpWidget(const SMGSApp());
      await tester.pumpAndSettle();
      for (final tab in ['Trang chủ', 'Khám phá']) {
        await tapText(tester, tab);
        await tester.dragUntilVisible(
          find.text('Bước vào bảo tàng').first,
          find.byType(Scrollable).first,
          const Offset(0, -220),
        );
        await tester.pumpAndSettle();
        // The home masthead stays pinned above the scrolling content.
        if (tester.getCenter(find.text('Bước vào bảo tàng').first).dy < 100) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 150),
          );
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Bước vào bảo tàng').first);
        await tester.pumpAndSettle();
        expect(find.byType(StoryScaffold), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -460));
        await tester.pumpAndSettle();
        final title = find.descendant(
          of: find.byType(SliverAppBar),
          matching: find.byType(Opacity),
        );
        expect(tester.widget<Opacity>(title.first).opacity, 1);
        expect(tester.getTopLeft(find.byType(BackButton)).dy, lessThan(60));
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(StoryScaffold), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('A section reveals on entry and stays visible when revisited', (
    tester,
  ) async {
    await screenSize(tester, const Size(390, 600));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: const [
                SizedBox(height: 650),
                ScrollReveal(
                  child: SizedBox(
                    height: 100,
                    child: Text('Câu chuyện di sản'),
                  ),
                ),
                SizedBox(height: 1600),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(ScrollReveal),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value,
      0,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(ScrollReveal),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value,
      1,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1100),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 1100),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(ScrollReveal),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reduced motion shows content immediately and disables parallax',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: const [
                ScrollReveal(child: Text('Nội dung luôn đọc được')),
                ParallaxPhoto(
                  height: 200,
                  child: ColoredBox(color: Colors.brown),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byType(ScrollReveal),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value,
        1,
      );
      expect(find.byType(Flow), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
