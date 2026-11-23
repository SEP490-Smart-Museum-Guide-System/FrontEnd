import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/visitor_colors.dart';
import 'primary_button.dart';

/// Hiển thị Modal vinh danh di sản khi người dùng mở khóa huy hiệu mới.
void showEarnedBadges(BuildContext context, dynamic badges) {
  if (badges is! List || badges.isEmpty) return;

  final badgeList = badges.map((b) {
    if (b is Map) return Map<String, dynamic>.from(b);
    return {'name': b.toString()};
  }).toList();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HeritageBadgeCelebrationSheet(badges: badgeList),
    );
  });
}

class _HeritageBadgeCelebrationSheet extends StatelessWidget {
  const _HeritageBadgeCelebrationSheet({required this.badges});
  final List<Map<String, dynamic>> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(VisitorRadius.xxl)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.darkBrown.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(VisitorRadius.full),
            ),
          ),

          // Glowing badge medallion
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.mutedGold.withValues(alpha: 0.35),
                  AppColors.antiqueIvory,
                ],
              ),
              border: Border.all(color: AppColors.mutedGold, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.military_tech_rounded,
                size: 46,
                color: AppColors.deepBurgundy,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(
            'VINH DANH DI SẢN'.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 2.2,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badges.length > 1
                ? 'Bạn vừa mở khóa ${badges.length} huy hiệu mới!'
                : 'Bạn vừa mở khóa huy hiệu mới!',
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(
              fontSize: 22,
              color: AppColors.deepBurgundy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Thành tích của bạn được ghi nhận vào sổ vàng lưu niệm di sản bảo tàng.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 20),

          // Badges list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final b = badges[i];
                final name = b['name']?.toString() ?? 'Huy hiệu Di sản';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: VisitorColors.surface1,
                    borderRadius: BorderRadius.circular(VisitorRadius.xl),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.deepBurgundy,
                          borderRadius: BorderRadius.circular(VisitorRadius.md),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 26,
                          color: AppColors.antiqueIvory,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBrown,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+ Điểm vinh danh người khám phá',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(VisitorRadius.xs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Đã nhận',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Action button
          PrimaryButton(
            label: 'Tuyệt vời, tiếp tục hành trình',
            icon: Icons.explore_outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
