import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/visitor_experience_api.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

class VisitCompleteFeedbackDialog extends StatefulWidget {
  const VisitCompleteFeedbackDialog({
    super.key,
    required this.visitId,
    this.museumName = 'Bảo tàng',
    this.scannedCount,
    this.onCompleted,
  });

  final int visitId;
  final String museumName;
  final int? scannedCount;
  final VoidCallback? onCompleted;

  static Future<void> show(
    BuildContext context, {
    required int visitId,
    String museumName = 'Bảo tàng',
    int? scannedCount,
    VoidCallback? onCompleted,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => VisitCompleteFeedbackDialog(
        visitId: visitId,
        museumName: museumName,
        scannedCount: scannedCount,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<VisitCompleteFeedbackDialog> createState() =>
      _VisitCompleteFeedbackDialogState();
}

class _VisitCompleteFeedbackDialogState
    extends State<VisitCompleteFeedbackDialog> {
  int _step = 0; // 0: Confirmation & Complete, 1: Feedback Form, 2: Thank You
  bool _busy = false;
  String? _error;

  int _overallRating = 5;
  int _contentRating = 5;
  int _tourRating = 5;
  int _chatbotRating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteVisit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await VisitorExperienceApi.completeVisit(widget.visitId);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 1; // Move to feedback form
      });
      widget.onCompleted?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Lỗi kết thúc chuyến đi: ${e.toString()}';
      });
    }
  }

  Future<void> _handleSubmitFeedback() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await VisitorExperienceApi.submitFeedback(
        visitId: widget.visitId,
        overallRating: _overallRating,
        contentRating: _contentRating,
        tourRating: _tourRating,
        chatbotRating: _chatbotRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 2; // Thank you screen
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Lỗi gửi đánh giá: ${e.toString()}';
      });
    }
  }

  Widget _buildStarRating({
    required String label,
    required int rating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isFilled = starNumber <= rating;
            return IconButton(
              iconSize: 32,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              icon: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? AppColors.mutedGold : Colors.grey.shade400,
              ),
              onPressed: () => onRatingChanged(starNumber),
            );
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.antiqueIvory,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 0
                ? _buildConfirmStep()
                : _step == 1
                    ? _buildFeedbackStep()
                    : _buildThankYouStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.mutedGold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.flag_rounded,
            size: 36,
            color: AppColors.deepBurgundy,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Kết thúc chuyến tham quan?',
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.darkBrown,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Hệ thống sẽ hoàn tất chuyến tham quan của bạn tại ${widget.museumName}, tổng kết các hiện vật đã khám phá và mở phần đánh giá trải nghiệm.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoalBrown),
          textAlign: TextAlign.center,
        ),
        if (widget.scannedCount != null && widget.scannedCount! > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF2E6B3E), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Đã khám phá ${widget.scannedCount} hiện vật',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Tiếp tục đi',
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: _busy ? 'Đang lưu…' : 'Kết thúc',
                icon: Icons.done_all_rounded,
                onPressed: _busy ? null : _handleCompleteVisit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: AppColors.deepBurgundy, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đánh giá trải nghiệm',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.darkBrown,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ý kiến của bạn giúp ${widget.museumName} nâng cao chất lượng phục vụ và hướng dẫn.',
            style: AppTextStyles.caption.copyWith(color: AppColors.charcoalBrown),
          ),
          const Divider(height: 28),
          _buildStarRating(
            label: 'Đánh giá chung chuyến tham quan *',
            rating: _overallRating,
            onRatingChanged: (v) => setState(() => _overallRating = v),
          ),
          _buildStarRating(
            label: 'Nội dung thuyết minh & Hiện vật',
            rating: _contentRating,
            onRatingChanged: (v) => setState(() => _contentRating = v),
          ),
          _buildStarRating(
            label: 'Sơ đồ & Dẫn đường trong bảo tàng',
            rating: _tourRating,
            onRatingChanged: (v) => setState(() => _tourRating = v),
          ),
          _buildStarRating(
            label: 'Hỗ trợ của Trợ lý AI Di sản',
            rating: _chatbotRating,
            onRatingChanged: (v) => setState(() => _chatbotRating = v),
          ),
          Text(
            'Nhận xét / Góp ý (tùy chọn)',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Cảm nhận của bạn về chuyến tham quan hôm nay...',
              hintStyle: AppTextStyles.caption,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Bỏ qua đánh giá'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _busy ? 'Đang gửi…' : 'Gửi đánh giá',
                  icon: Icons.send_rounded,
                  onPressed: _busy ? null : _handleSubmitFeedback,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF2E6B3E).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: 40,
            color: Color(0xFF2E6B3E),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cảm ơn bạn rất nhiều!',
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.darkBrown,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Đánh giá của bạn đã được gửi tới Ban quản lý ${widget.museumName}. Chúc bạn có thêm nhiều trải nghiệm văn hóa tuyệt vời!',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoalBrown),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Hoàn tất & Về trang chủ',
          icon: Icons.home_rounded,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
