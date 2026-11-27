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
  final _pages = PageController();
  late final List<Widget> _screens = [
    HomeScreen(onExplore: () => _select(1)),
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
        extendBody: _selectedIndex == 0,
        body: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (index != _selectedIndex) setState(() => _selectedIndex = index);
          },
          children: List.generate(
            _screens.length,
            (index) => HeroMode(
              enabled: _selectedIndex == index,
              child: _screens[index],
            ),
          ),
        ),
        bottomNavigationBar: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Row(
              key: const ValueKey('visitor-bottom-nav'),
              children: List.generate(items.length, (index) {
                final item = items[index];
                final active = _selectedIndex == index;
                return Expanded(
                  child: Semantics(
                    key: ValueKey('visitor-tab:$index'),
                    selected: active,
                    button: true,
                    label: item.label,
                    child: ExcludeSemantics(
                      child: InkWell(
                        onTap: () => _select(index),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 22,
                                color: VisitorColors.burgundy,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 0,
                                  fontWeight: active
                                      ? FontWeight.w700
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
      ),
    );
  }
}
