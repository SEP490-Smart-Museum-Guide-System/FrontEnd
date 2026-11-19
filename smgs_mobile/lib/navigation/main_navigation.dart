import 'package:flutter/material.dart';

import '../widgets/museum_ui.dart';
import '../core/theme/visitor_colors.dart';
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
  static const _items = [
    (label: 'Trang chủ', icon: Icons.home_outlined),
    (label: 'Khám phá', icon: Icons.explore_outlined),
    (label: 'Quét mã', icon: Icons.qr_code_scanner),
    (label: 'Hành trình', icon: Icons.map_outlined),
    (label: 'Cá nhân', icon: Icons.person_outline),
  ];
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
  Widget build(BuildContext context) => Scaffold(
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
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Container(
          key: const ValueKey('visitor-bottom-nav'),
          decoration: BoxDecoration(
            color: VisitorColors.background,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: VisitorColors.background,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 54,
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
                                              color: VisitorColors.background,
                                            ),
                                          ),
                                        )
                                      : AnimatedContainer(
                                          duration:
                                              reduceHeritageMotion(context)
                                              ? Duration.zero
                                              : HeritageMotion.fast,
                                          curve: HeritageMotion.curve,
                                          width: 44,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? VisitorColors.brandSoft
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            size: 22,
                                            color: active
                                                ? VisitorColors.burgundy
                                                : VisitorColors.secondaryText,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  letterSpacing: 0,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: active
                                      ? VisitorColors.burgundy
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
    ),
  );
}
