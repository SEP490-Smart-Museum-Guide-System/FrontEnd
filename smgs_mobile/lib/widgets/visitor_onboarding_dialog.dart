import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/app_services.dart';

class VisitorOnboardingDialog extends StatefulWidget {
  const VisitorOnboardingDialog({super.key});

  /// Tạo khoá lưu trữ phân biệt theo từng tài khoản khách tham quan.
  static String prefKeyFor([String? email]) {
    if (email == null || email.trim().isEmpty) return 'has_seen_visitor_onboarding_v1';
    return 'has_seen_visitor_onboarding_v1_${email.trim().toLowerCase()}';
  }

  /// Kiểm tra xem khách tham quan (theo email) đã từng xem hướng dẫn nhập môn chưa.
  static Future<bool> shouldShow([String? email]) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(prefKeyFor(email)) ?? false);
  }

  /// Đánh dấu đã hoàn thành hoặc bỏ qua hướng dẫn cho tài khoản hiện tại.
  static Future<void> markCompleted([String? email]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyFor(email), true);
  }

  /// Hiển thị popup onboarding cho khách tham quan.
  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) => const VisitorOnboardingDialog(),
    );
  }

  @override
  State<VisitorOnboardingDialog> createState() => _VisitorOnboardingDialogState();
}

class _VisitorOnboardingDialogState extends State<VisitorOnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      badge: 'BƯỚC 1: TƯƠNG TÁC',
      title: 'Quét mã & Nhận diện',
      description:
          'Chạm biểu tượng Quét mã QR tại chân tủ kính hoặc dùng AI Vision để mở hồ sơ lịch sử và hình ảnh 3D chỉ trong 1 giây.',
      icon: Icons.qr_code_scanner_rounded,
    ),
    _OnboardingStep(
      badge: 'BƯỚC 2: LẮNG NGHE',
      title: 'Thuyết minh Âm thanh AI',
      description:
          'Lắng nghe câu chuyện khảo cổ sống động được AI tổng hợp từ kịch bản chuẩn mực của Giám tuyển; dễ dàng điều chỉnh tốc độ đọc.',
      icon: Icons.headphones_rounded,
    ),
    _OnboardingStep(
      badge: 'BƯỚC 3: KHÁM PHÁ',
      title: 'Sơ đồ Tầng & Chỉ đường',
      description:
          'Không lo lạc lối giữa các gian trưng bày. Bản đồ số tự động tính toán lộ trình ngắn nhất đưa bạn đến vị trí chính xác của hiện vật.',
      icon: Icons.explore_rounded,
    ),
  ];

  Future<void> _complete() async {
    final email = AppServices.auth.user?.email;
    await VisitorOnboardingDialog.markCompleted(email);
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.antiqueIvory,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.mutedGold.withOpacity(0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header với Huy hiệu và Nút Bỏ qua
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mutedGold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.mutedGold.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          'SMGS - HƯỚNG DẪN NHẬP MÔN',
                          style: TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: AppColors.deepBurgundy,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _complete,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondaryText,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Bỏ qua', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                // Carousel PageView 3 Bước
                SizedBox(
                  height: 310,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Biểu tượng Heritage Viền Vàng
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.card,
                                border: Border.all(
                                  color: AppColors.mutedGold,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.mutedGold.withOpacity(0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                step.icon,
                                size: 40,
                                color: AppColors.deepBurgundy,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Huy hiệu bước nhỏ
                            Text(
                              step.badge,
                              style: TextStyle(
                                fontFamily: AppTextStyles.sansFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: AppColors.mutedGold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Tiêu đề Serif
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBrown,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Mô tả chi tiết
                            Text(
                              step.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTextStyles.sansFamily,
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Thanh điều khiển & Chỉ số trang bên dưới
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // Chỉ thị Dot Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_steps.length, (index) {
                          final isActive = index == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.deepBurgundy : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      // Nút hành động chính
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepBurgundy,
                            foregroundColor: AppColors.lightText,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == _steps.length - 1
                                    ? 'Bắt đầu khám phá'
                                    : 'Tiếp tục',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentIndex == _steps.length - 1
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String badge;
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingStep({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
  });
}
