import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/visitor_colors.dart';
import '../services/backend_api.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

void showExplorationRewards(BuildContext context, dynamic result) {
  if (result is! Map) return;
  final points = result['pointsAwarded'];
  final badges = result['newBadges'];
  final hasBadges = badges is List && badges.isNotEmpty;
  final awardedPoints = points is int ? points : 0;
  final isQrScan = result.containsKey('recognitionId');

  if (isQrScan) {
    if (awardedPoints > 0) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.deepBurgundy,
          content: Text('🎉 Đã ghi nhận trạm dừng trong Tour! Bạn nhận được +$awardedPoints điểm.'),
        ),
      );
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Đã mở thông tin hiện vật. (Chỉ cộng điểm khi quét hiện vật thuộc Tour đang đi)'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    if (hasBadges) {
      showEarnedBadges(context, badges);
    }
    return;
  }

  if (awardedPoints > 0 || hasBadges) {
    final badgeList = hasBadges
        ? badges.map((b) {
            if (b is Map) return Map<String, dynamic>.from(b);
            return {'name': b.toString()};
          }).toList()
        : const <Map<String, dynamic>>[];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _TourRewardSuccessSheet(
          pointsAwarded: awardedPoints,
          badges: badgeList,
        ),
      );
    });
  }
}

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
      builder: (ctx) => _TourRewardSuccessSheet(
        pointsAwarded: 0,
        badges: badgeList,
      ),
    );
  });
}

/// Hiển thị Phiếu Đổi Quà Lưu Niệm Tại Quầy Bảo Tàng (không cần BE kho quà riêng, lấy trực tiếp số dư điểm & huy hiệu thực tế từ API gamification/me).
void showCounterSouvenirPass(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CounterSouvenirPassSheet(),
  );
}

class _TourRewardSuccessSheet extends StatelessWidget {
  const _TourRewardSuccessSheet({
    required this.pointsAwarded,
    required this.badges,
  });
  final int pointsAwarded;
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
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.darkBrown.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(VisitorRadius.full),
            ),
          ),
          Container(
            width: 76,
            height: 76,
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
                size: 44,
                color: AppColors.deepBurgundy,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'HOÀN THÀNH HÀNH TRÌNH DI SẢN',
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 1.8,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pointsAwarded > 0
                ? 'Chúc mừng! Bạn nhận được +$pointsAwarded điểm thưởng'
                : 'Bạn vừa mở khóa huy hiệu di sản mới!',
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(
              fontSize: 20,
              color: AppColors.deepBurgundy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Điểm tích lũy từ việc đi theo Tour và trả lời Quiz dùng để đổi Voucher hoặc nhận Quà lưu niệm tại Quầy Lễ tân Bảo tàng.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: badges.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final b = badges[i];
                  final name = b['name']?.toString() ?? 'Huy hiệu Di sản';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: VisitorColors.surface1,
                      borderRadius: BorderRadius.circular(VisitorRadius.xl),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.deepBurgundy,
                            borderRadius: BorderRadius.circular(VisitorRadius.md),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 22,
                            color: AppColors.antiqueIvory,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              Text(
                                'Huy hiệu chinh phục hành trình văn hóa',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.mutedGold,
                                  fontWeight: FontWeight.w600,
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
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Mở phiếu đổi quà lưu niệm tại quầy',
            icon: Icons.card_giftcard_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              showCounterSouvenirPass(context);
            },
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _CounterSouvenirPassSheet extends StatefulWidget {
  const _CounterSouvenirPassSheet();

  @override
  State<_CounterSouvenirPassSheet> createState() => _CounterSouvenirPassSheetState();
}

class _CounterSouvenirPassSheetState extends State<_CounterSouvenirPassSheet> {
  bool _loading = true;
  int _points = 0;
  int _badgesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadGamification();
  }

  Future<void> _loadGamification() async {
    try {
      final res = await BackendApi.request('gamification/me');
      if (mounted && res is Map) {
        setState(() {
          _points = (res['points'] as num?)?.toInt() ?? 0;
          _badgesCount = (res['badges'] as List?)?.length ?? 0;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final giftTiers = [
      {
        'title': 'Bookmark Trống đồng Đông Sơn',
        'desc': 'Quà lưu niệm văn hóa khi hoàn thành 1 Tour hoặc đạt 30 điểm',
        'requiredPoints': 30,
        'icon': Icons.bookmark_added_rounded,
      },
      {
        'title': 'Bộ Bưu thiếp Di sản Lý – Trần',
        'desc': 'Dành cho khách tích lũy điểm trạm dừng & trả lời đúng Quiz',
        'requiredPoints': 60,
        'icon': Icons.collections_bookmark_rounded,
      },
      {
        'title': 'Móc khóa Bảo vật Quốc gia Mạ Đồng',
        'desc': 'Quà đặc biệt cho khách chinh phục nhiều hành trình chuyên đề',
        'requiredPoints': 100,
        'icon': Icons.workspace_premium_rounded,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(VisitorRadius.xxl)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.darkBrown.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(VisitorRadius.full),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.deepBurgundy,
                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.antiqueIvory,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHIẾU ĐỔI QUÀ LƯU NIỆM TẠI QUẦY',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.deepBurgundy,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Đặc quyền khách tham gia Hành trình & Quiz',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VisitorColors.surface1,
              borderRadius: BorderRadius.circular(VisitorRadius.xl),
              border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.5)),
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$_points',
                            style: AppTextStyles.display.copyWith(
                              fontSize: 24,
                              color: AppColors.deepBurgundy,
                            ),
                          ),
                          Text(
                            'Điểm tích lũy hiện có',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: VisitorColors.borderSubtle,
                      ),
                      Column(
                        children: [
                          Text(
                            '$_badgesCount',
                            style: AppTextStyles.display.copyWith(
                              fontSize: 24,
                              color: AppColors.mutedGold,
                            ),
                          ),
                          Text(
                            'Huy hiệu đã đạt',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            'Danh mục quà lưu niệm đổi tại Quầy Lễ tân Bảo tàng:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 8),
          for (final tier in giftTiers) ...[
            () {
              final req = tier['requiredPoints'] as int;
              final unlocked = _points >= req;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked ? const Color(0xFFF0FDF4) : VisitorColors.surface1,
                  borderRadius: BorderRadius.circular(VisitorRadius.lg),
                  border: Border.all(
                    color: unlocked ? const Color(0xFF86EFAC) : VisitorColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tier['icon'] as IconData,
                      color: unlocked ? const Color(0xFF15803D) : AppColors.deepBurgundy,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier['title'] as String,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBrown,
                            ),
                          ),
                          Text(
                            tier['desc'] as String,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: unlocked ? const Color(0xFF15803D) : VisitorColors.surface2,
                        borderRadius: BorderRadius.circular(VisitorRadius.full),
                      ),
                      child: Text(
                        unlocked ? 'Đủ điểm đổi' : '$req điểm',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: unlocked ? Colors.white : AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }(),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(VisitorRadius.md),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 22, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đưa màn hình này tại Quầy Lưu Niệm Bảo Tàng để nhân viên đối chiếu điểm hoặc đổi sang Voucher trên ứng dụng.',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Đã hiểu',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
