import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../widgets/museum_ui.dart';
import '../widgets/in_app_notification_banner.dart';

import '../screens/home/home_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/scan/scan_screen.dart';
import '../screens/tours/tours_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _scanPressed = false;
  final _pages = PageController();
  late final List<Widget> _screens = [
    HomeScreen(onExplore: () => _select(1), onScan: () => _select(2)),
    const ExploreScreen(),
    const ScanScreen(),
    const ToursScreen(),
    const ProfileScreen(),
  ];
  List<({String label, IconData icon})> _items(BuildContext context) {
    final l10n = context.l10n;
    return [
      (label: l10n.tabHome, icon: Icons.home_outlined),
      (label: l10n.tabExplore, icon: Icons.explore_outlined),
      (label: l10n.tabScan, icon: Icons.qr_code_scanner),
      (label: l10n.tabJourneys, icon: Icons.map_outlined),
      (label: l10n.tabProfile, icon: Icons.person_outline),
    ];
  }
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (reduceHeritageMotion(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: HeritageMotion.standard,
        curve: HeritageMotion.curve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    return NotificationBannerListener(
      child: Scaffold(
    body: PageView(
      controller: _pages,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        if (index != _selectedIndex) setState(() => _selectedIndex = index);
      },
      children: List.generate(
        _screens.length,
        (index) =>
            HeroMode(enabled: _selectedIndex == index, child: _screens[index]),
      ),
    ),
    bottomNavigationBar: ColoredBox(
      color: _selectedIndex == 0
          ? VisitorColors.background
          : Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          const Positioned.fill(
            top: 19,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 4)],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              key: const ValueKey('visitor-bottom-nav'),
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final active = _selectedIndex == i;
                  final scan = i == 2;
                  return Expanded(
                    child: Semantics(
                      key: ValueKey('visitor-tab:$i'),
                      selected: active,
                      button: true,
                      label: item.label,
                      child: ExcludeSemantics(
                        child: InkWell(
                          onTap: () => _select(i),
                          onHighlightChanged: scan
                              ? (pressed) =>
                                    setState(() => _scanPressed = pressed)
                              : null,
                          splashColor: VisitorColors.burgundy.withValues(
                            alpha: .06,
                          ),
                          highlightColor: VisitorColors.burgundy.withValues(
                            alpha: .04,
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: scan ? 3 : 36,
                              bottom: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: scan ? 54 : 24,
                                  child: Center(
                                    child: scan
                                        ? AnimatedScale(
                                            key: const ValueKey(
                                              'visitor-scan-press',
                                            ),
                                            scale: _scanPressed ? .96 : 1,
                                            duration:
                                                reduceHeritageMotion(context)
                                                ? Duration.zero
                                                : HeritageMotion.fast,
                                            curve: HeritageMotion.curve,
                                            child: Container(
                                              width: 54,
                                              height: 54,
                                              decoration: BoxDecoration(
                                                color: VisitorColors.burgundy,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x16000000),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_scanner,
                                                size: 24,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            item.icon,
                                            size: 22,
                                            color: active
                                                ? VisitorColors.text
                                                : VisitorColors.secondaryText,
                                          ),
                                  ),
                                ),
                                SizedBox(height: scan ? 10 : 2),
                                Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12,
                                    letterSpacing: 0,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: active
                                        ? VisitorColors.text
                                        : VisitorColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
