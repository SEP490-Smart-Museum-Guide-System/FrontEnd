import 'package:flutter/material.dart';

import '../widgets/museum_ui.dart';
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
  void _select(int index) => setState(() => _selectedIndex = index);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _selectedIndex,
      children: List.generate(
        _screens.length,
        (index) =>
            HeroMode(enabled: _selectedIndex == index, child: _screens[index]),
      ),
    ),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.mutedGold)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final active = _selectedIndex == i;
            return Expanded(
              child: Semantics(
                selected: active,
                button: true,
                label: item.label,
                child: ExcludeSemantics(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _select(i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 82),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 3,
                                width: 28,
                                color: active
                                    ? AppColors.deepBurgundy
                                    : Colors.transparent,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: i == 2
                                      ? AppColors.deepBurgundy
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  item.icon,
                                  size: 23,
                                  color: i == 2
                                      ? AppColors.antiqueIvory
                                      : active
                                      ? AppColors.deepBurgundy
                                      : AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? AppColors.deepBurgundy
                                      : AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
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
  );
}
