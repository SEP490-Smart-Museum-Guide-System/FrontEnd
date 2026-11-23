import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/visitor_tokens.dart';
import '../core/theme/visitor_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/app_services.dart';

/// Dữ liệu của từng bước nhiệm vụ trong chuỗi hướng dẫn tương tác phong cách game.
class TutorialQuestStep {
  final GlobalKey targetKey;
  final String questBadge;
  final String title;
  final String description;
  final IconData icon;
  final double borderRadius;

  const TutorialQuestStep({
    required this.targetKey,
    required this.questBadge,
    required this.title,
    required this.description,
    required this.icon,
    this.borderRadius = VisitorRadius.md,
  });
}

class GameTutorialOverlay extends StatefulWidget {
  final String tourId;
  final List<TutorialQuestStep> steps;
  final VoidCallback onComplete;

  const GameTutorialOverlay({
    super.key,
    this.tourId = 'home',
    required this.steps,
    required this.onComplete,
  });

  static String prefKeyFor([String? email, String tourId = 'home']) {
    final e = email?.trim().toLowerCase() ?? '';
    return 'has_seen_game_tutorial_v1_${tourId}_$e';
  }

  static Future<bool> shouldShow([
    String? email,
    String tourId = 'home',
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(prefKeyFor(email, tourId)) ?? false);
  }

  static Future<void> markCompleted([
    String? email,
    String tourId = 'home',
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyFor(email, tourId), true);
  }

  /// Khởi chạy hướng dẫn tương tác chỉ thẳng vào mục UI
  static OverlayEntry? _activeEntry;

  static void start(
    BuildContext context, {
    String tourId = 'home',
    required List<TutorialQuestStep> steps,
    VoidCallback? onFinish,
  }) {
    if (_activeEntry != null) return;
    if (steps.isEmpty) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => GameTutorialOverlay(
        tourId: tourId,
        steps: steps,
        onComplete: () {
          try {
            if (_activeEntry == entry) {
              _activeEntry = null;
            }
            if (entry.mounted) {
              entry.remove();
            }
          } catch (e) {
            debugPrint('Error removing tutorial overlay entry: $e');
          }
          final email = AppServices.auth.user?.email;
          markCompleted(email, tourId);
          onFinish?.call();
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  @override
  State<GameTutorialOverlay> createState() => _GameTutorialOverlayState();
}

class _GameTutorialOverlayState extends State<GameTutorialOverlay>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Rect? _targetRect;

  late final AnimationController _pulseController;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resolveTargetPosition(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulseController.stop();
      _bounceController.stop();
      _pulseController.value = 0;
      _bounceController.value = 0;
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_bounceController.isAnimating) {
        _bounceController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _resolveTargetPosition() async {
    if (!mounted || _currentIndex >= widget.steps.length) return;

    final step = widget.steps[_currentIndex];
    final targetContext = step.targetKey.currentContext;

    if (targetContext != null) {
      try {
        await Scrollable.ensureVisible(
          targetContext,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      } catch (_) {}

      if (!mounted || !targetContext.mounted) return;

      final renderBox = targetContext.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _targetRect = Rect.fromLTWH(
            position.dx,
            position.dy,
            renderBox.size.width,
            renderBox.size.height,
          );
        });
        return;
      }
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _resolveTargetPosition();
    });
  }

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      setState(() {
        _currentIndex++;
        _targetRect = null;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resolveTargetPosition(),
      );
    } else {
      // Khi nhấn "Hoàn thành" ở bước cuối, đóng ngay lập tức
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final currentStep = widget.steps[_currentIndex];

    final target =
        _targetRect ??
        Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 80,
          height: 80,
        );

    final placeCardBelow = target.top < screenSize.height * 0.45;
    final cardOffset = placeCardBelow
        ? (target.bottom + 68).clamp(20.0, screenSize.height - 280.0)
        : (screenSize.height - target.top + 20).clamp(
            20.0,
            screenSize.height - 280.0,
          );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 0. Bắt chạm toàn màn hình để ngăn bấm nhầm nội dung phía sau
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),

          // 0.1 Cho phép bấm trực tiếp vào vùng sáng (Spotlight Target) để chuyển bước tiếp theo
          if (_targetRect != null)
            Positioned.fromRect(
              rect: _targetRect!.inflate(10.0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _nextStep,
              ),
            ),

          // 1. Lớp phủ Spotlight Cutout mờ xung quanh mục tiêu
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return CustomPaint(
                size: screenSize,
                painter: _SpotlightPainter(
                  targetRect: target,
                  borderRadius: currentStep.borderRadius,
                  pulseValue: _pulseController.value,
                ),
              );
            },
          ),

          // 2. Mũi tên & Bàn tay chỉ dẫn chuyển động (Bouncing Pointer)
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, _) {
              final double pointerX = (target.center.dx - 22).clamp(
                16.0,
                screenSize.width - 60.0,
              );
              final double pointerY = placeCardBelow
                  ? target.bottom + 12 + _bounceAnimation.value
                  : target.top - 54 - _bounceAnimation.value;

              return Positioned(
                left: pointerX,
                top: pointerY,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.deepBurgundy,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mutedGold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mutedGold.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    placeCardBelow
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: AppColors.lightText,
                    size: 26,
                  ),
                ),
              );
            },
          ),

          // 3. Khung hội thoại Nhiệm vụ Game (Quest Card)
          Positioned(
            left: 20,
            right: 20,
            top: placeCardBelow
                ? (target.bottom + 68).clamp(20.0, screenSize.height - 280.0)
                : null,
            bottom: !placeCardBelow
                ? (screenSize.height - target.top + 20).clamp(
                    20.0,
                    screenSize.height - 280.0,
                  )
                : null,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: screenSize.height - cardOffset - 20,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueIvory,
                      borderRadius: BorderRadius.circular(VisitorRadius.xl),
                      border: Border.all(
                        color: AppColors.mutedGold.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentStep.questBadge,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.sansFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepBurgundy,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _skip,
                              child: const Text('Bỏ qua'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tiêu đề
                        Row(
                          children: [
                            Icon(
                              currentStep.icon,
                              color: AppColors.deepBurgundy,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentStep.title,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Mô tả chi tiết
                        Text(
                          currentStep.description,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Footer wraps when visitors enlarge their text.
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Step Indicators
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(widget.steps.length, (
                                idx,
                              ) {
                                final active = idx == _currentIndex;
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  width: active ? 22 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.deepBurgundy
                                        : AppColors.border,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),

                            // Nút hành động Tiếp tục
                            ElevatedButton.icon(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.deepBurgundy,
                                foregroundColor: AppColors.lightText,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                                ),
                              ),
                              icon: Icon(
                                _currentIndex == widget.steps.length - 1
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: Text(
                                _currentIndex == widget.steps.length - 1
                                    ? 'Hoàn thành'
                                    : 'Tiếp tục',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ nền tối làm mờ màn hình và đục khoét (cutout) làm nổi bật phần tử đích
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final double pulseValue;

  _SpotlightPainter({
    required this.targetRect,
    required this.borderRadius,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullScreenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final backgroundPath = Path()..addRect(fullScreenRect);

    final cutoutRect = targetRect.inflate(6.0);
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    final overlayPaint = Paint()..color = const Color(0xD418120E);
    canvas.drawPath(overlayPath, overlayPaint);

    final glowPaint = Paint()
      ..color = const Color(
        0xFFC5A059,
      ).withValues(alpha: 0.5 + 0.45 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + 1.5 * pulseValue;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect ||
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.borderRadius != borderRadius;
}

/// 1. Quản lý Tour nhiệm vụ trên màn hình chính HomeScreen
class HomeScreenTour {
  HomeScreenTour._();

  static final GlobalKey scanCardKey = GlobalKey();
  static final GlobalKey museumSectionKey = GlobalKey();
  static final GlobalKey collectionKey = GlobalKey();
  static final GlobalKey handbookBtnKey = GlobalKey();

  static List<TutorialQuestStep> getSteps() => [
    TutorialQuestStep(
      targetKey: scanCardKey,
      questBadge: 'Quét hiện vật',
      title: 'Khám phá một hiện vật',
      description: 'Chạm vào đây để mở chức năng quét QR hiện vật.',
      icon: Icons.qr_code_scanner,
      borderRadius: 16,
    ),
    if (AppServices.catalog.museums.isNotEmpty)
      TutorialQuestStep(
        targetKey: museumSectionKey,
        questBadge: 'Khám phá bảo tàng',
        title: 'Tìm bảo tàng muốn đến',
        description:
            'Xem các bảo tàng đang công khai. Mục Khám phá có tìm kiếm và thông tin chi tiết.',
        icon: Icons.museum_outlined,
        borderRadius: 16,
      ),
    TutorialQuestStep(
      targetKey: collectionKey,
      questBadge: 'Bộ sưu tập',
      title: 'Bảo tàng cá nhân',
      description: 'Mở bộ sưu tập những hiện vật bạn đã khám phá.',
      icon: Icons.collections_bookmark_outlined,
      borderRadius: 16,
    ),
    TutorialQuestStep(
      targetKey: handbookBtnKey,
      questBadge: 'Cẩm nang',
      title: 'Cẩm nang tham quan',
      description: 'Tra cứu cách dùng ứng dụng và hướng dẫn tham quan tại đây.',
      icon: Icons.menu_book_outlined,
      borderRadius: 12,
    ),
  ];

  static void start(BuildContext context, {VoidCallback? onFinish}) {
    GameTutorialOverlay.start(
      context,
      tourId: 'home',
      steps: getSteps(),
      onFinish: onFinish,
    );
  }
}

/// 2. Quản lý Tour nhiệm vụ cho màn hình Quét mã ScanScreen
class ScanScreenTour {
  ScanScreenTour._();

  static final GlobalKey qrTileKey = GlobalKey();
  static final GlobalKey aiVisionTileKey = GlobalKey();
  static final GlobalKey collectionTileKey = GlobalKey();

  static List<TutorialQuestStep> getSteps() => [
    TutorialQuestStep(
      targetKey: qrTileKey,
      questBadge: 'NHIỆM VỤ QUÉT MÃ · BƯỚC 1/3',
      title: 'Quét mã QR tại tủ kính',
      description:
          'Dùng camera điện thoại căn chuẩn mã QR đặt tại chân tủ trưng bày để mở ngay câu chuyện khảo cổ và mô hình 3D.',
      icon: Icons.qr_code_scanner_rounded,
      borderRadius: 14,
    ),
    TutorialQuestStep(
      targetKey: aiVisionTileKey,
      questBadge: 'NHIỆM VỤ QUÉT MÃ · BƯỚC 2/3',
      title: 'AI Vision nhận diện qua ảnh chụp',
      description:
          'Chụp ảnh hiện vật từ góc bạn đứng; AI Vision sẽ tự động nhận diện bảo vật mà không cần mã QR.',
      icon: Icons.camera_alt_rounded,
      borderRadius: 14,
    ),
    TutorialQuestStep(
      targetKey: collectionTileKey,
      questBadge: 'NHIỆM VỤ QUÉT MÃ · BƯỚC 3/3',
      title: 'Tra cứu bộ sưu tập từ xa',
      description:
          'Xem toàn bộ danh mục hiện vật theo chủ đề và niên đại khi bạn không ở gần tủ kính.',
      icon: Icons.view_list_rounded,
      borderRadius: 14,
    ),
  ];

  static void start(BuildContext context, {VoidCallback? onFinish}) {
    GameTutorialOverlay.start(
      context,
      tourId: 'scan',
      steps: getSteps(),
      onFinish: onFinish,
    );
  }
}

/// 3. Quản lý Tour nhiệm vụ cho màn hình Khám phá & Tìm kiếm ExploreScreen
class ExploreScreenTour {
  ExploreScreenTour._();

  static final GlobalKey searchBarKey = GlobalKey();
  static final GlobalKey modeToggleKey = GlobalKey();
  static final GlobalKey resultsKey = GlobalKey();

  static List<TutorialQuestStep> getSteps() => [
    TutorialQuestStep(
      targetKey: searchBarKey,
      questBadge: 'NHIỆM VỤ TRA CỨU · BƯỚC 1/3',
      title: 'Tìm kiếm hiện vật & bảo tàng',
      description:
          'Nhập tên bảo vật, triều đại lịch sử hoặc bảo tàng bạn muốn tra cứu để tìm nhanh thông tin.',
      icon: Icons.search_rounded,
      borderRadius: 12,
    ),
    TutorialQuestStep(
      targetKey: modeToggleKey,
      questBadge: 'NHIỆM VỤ TRA CỨU · BƯỚC 2/3',
      title: 'Lọc Hiện vật hoặc Bảo tàng',
      description:
          'Chuyển đổi linh hoạt giữa danh sách các bảo tàng liên kết hoặc kho hiện vật quốc gia.',
      icon: Icons.tune_rounded,
      borderRadius: 12,
    ),
    TutorialQuestStep(
      targetKey: resultsKey,
      questBadge: 'NHIỆM VỤ TRA CỨU · BƯỚC 3/3',
      title: 'Bản đồ Khám phá & Dẫn đường',
      description:
          'Xem bảo tàng trực quan trên bản đồ kèm chỉ đường, hoặc chạm vào từng thẻ để khám phá chi tiết.',
      icon: Icons.map_rounded,
      borderRadius: 12,
    ),
  ];

  static void start(BuildContext context, {VoidCallback? onFinish}) {
    GameTutorialOverlay.start(
      context,
      tourId: 'explore',
      steps: getSteps(),
      onFinish: onFinish,
    );
  }
}
