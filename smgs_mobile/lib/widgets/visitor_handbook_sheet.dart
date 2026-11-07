import 'game_tutorial_overlay.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'visitor_onboarding_dialog.dart';

class VisitorHandbookSheet extends StatelessWidget {
  const VisitorHandbookSheet({super.key});

  /// Mở Cẩm nang tra cứu dạng BottomSheet từ bất kỳ đâu.
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VisitorHandbookSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.antiqueIvory,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.mutedGold.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Thanh kéo nhỏ (Handle bar)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedGold.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Tiêu đề Cẩm nang
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.deepBurgundy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.lightText,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CẨM NANG THAM QUAN',
                              style: TextStyle(
                                fontFamily: AppTextStyles.sansFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: AppColors.mutedGold,
                              ),
                            ),
                            Text(
                              'Sổ tay hướng dẫn khách',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.secondaryText,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.border, height: 1),

              // Nội dung cuộn
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // --- PHẦN 1: 3 BƯỚC KHÁM PHÁ CÔNG NGHỆ ---
                    _buildSectionHeader(
                      context,
                      icon: Icons.lightbulb_outline_rounded,
                      title: '1. Khám phá cùng Công nghệ SMGS',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Quét mã QR tại tủ kính hiện vật',
                      content:
                          'Chạm vào nút Quét QR trên thanh tìm kiếm để mở nhanh hồ sơ chi tiết, câu chuyện khảo cổ và mô hình 3D.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.headphones_rounded,
                      title: 'Thuyết minh âm thanh sống động',
                      content:
                          'Nên cắm tai nghe cá nhân khi tham quan. Bạn có thể tăng giảm tốc độ đọc (0.75x, 1.0x, 1.25x) phù hợp thói quen.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.map_outlined,
                      title: 'Định vị & Chỉ đường trong nhà',
                      content:
                          'Mở mục "Bản đồ trong bảo tàng", chọn vị trí bạn đang đứng để sơ đồ tự vẽ đường đi ngắn nhất tới hiện vật bạn muốn xem.',
                    ),

                    const SizedBox(height: 24),

                    // --- PHẦN 2: QUY ĐỊNH & VĂN HÓA BẢO TÀNG ---
                    _buildSectionHeader(
                      context,
                      icon: Icons.shield_outlined,
                      title: '2. Văn hóa & Quy định Tham quan',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.pan_tool_outlined,
                      title: 'Không chạm tay vào hiện vật',
                      content:
                          'Giữ khoảng cách tối thiểu 0.5m với tủ trưng bày. Mồ hôi và vi khuẩn tay người có thể gây oxy hóa di sản ngàn năm.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.flash_off_rounded,
                      title: 'Tắt đèn Flash khi chụp ảnh',
                      content:
                          'Được phép chụp ảnh lưu niệm nhưng vui lòng tắt đèn Flash máy ảnh để bảo tồn chất liệu màu của cổ vật.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.volume_mute_rounded,
                      title: 'Giữ trật tự chung',
                      content:
                          'Vui lòng chuyển điện thoại sang chế độ rung và nói khẽ để giữ không gian chiêm nghiệm văn hóa cho mọi người.',
                    ),

                    const SizedBox(height: 24),

                    // --- PHẦN 3: TIỆN ÍCH & TRỢ GIÚP ---
                    _buildSectionHeader(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: '3. Tiện ích & Hỗ trợ Khẩn cấp',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'Tủ gửi đồ miễn phí',
                      content:
                          'Quầy gửi ba lô, hành lý cồng kềnh miễn phí nằm ngay sảnh đón tiếp Tầng 1 (liên hệ quầy Lễ tân nhận thẻ tủ).',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.accessible_rounded,
                      title: 'Hỗ trợ người khuyết tật',
                      content:
                          'Bảo tàng có bố trí thang máy và đường dốc hỗ trợ xe lăn tiếp cận mọi tầng và phòng trưng bày chính.',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      icon: Icons.phone_in_talk_rounded,
                      title: 'Đường dây nóng hỗ trợ',
                      content:
                          'Khi cần trợ giúp y tế hoặc hỗ trợ an ninh khẩn cấp, vui lòng liên hệ Ban Quản lý: 024.3825.2853.',
                    ),

                    const SizedBox(height: 28),

                    // Nút bật hướng dẫn tương tác chỉ tay
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        HomeScreenTour.start(context);
                      },
                      icon: const Icon(Icons.touch_app_rounded, size: 18),
                      label: const Text(
                        'Bật hướng dẫn chỉ tay tương tác (Game Quest)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBurgundy,
                        foregroundColor: AppColors.lightText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nút xem lại Onboarding 3 bước
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        VisitorOnboardingDialog.show(context);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Xem lại tóm tắt cẩm nang 3 bước',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepBurgundy,
                        side: BorderSide(
                          color: AppColors.deepBurgundy.withOpacity(0.5),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.deepBurgundy),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.deepBurgundy,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mutedGold.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mutedGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: AppColors.deepBurgundy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
