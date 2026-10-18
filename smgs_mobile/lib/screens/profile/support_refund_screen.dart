import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../data/visit_store.dart';

class SupportRefundScreen extends StatefulWidget {
  const SupportRefundScreen({super.key});

  @override
  State<SupportRefundScreen> createState() => _SupportRefundScreenState();
}

class _SupportRefundScreenState extends State<SupportRefundScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'refund'; // 'refund', 'tech_issue', 'general'
  String _reason = 'museum_closed';
  int _refundPercent = 100;
  final _descController = TextEditingController();

  final Map<String, String> _categories = {
    'refund': 'Yêu cầu hoàn tiền (Vé / Combo / Dịch vụ số)',
    'tech_issue': 'Sự cố kỹ thuật (Không quét được QR / Lỗi AI)',
    'general': 'Khiếu nại & Đóng góp ý kiến',
  };

  final Map<String, String> _reasons = {
    'museum_closed': 'Bảo tàng tạm dừng hoạt động / Đóng cửa đột xuất',
    'network_error': 'Sự cố kết nối tại bảo tàng, không tải được thuyết minh',
    'wrong_date': 'Đặt nhầm ngày tham quan / Kế hoạch thay đổi',
    'other': 'Lý do cá nhân khác',
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    VisitStore.instance.submitSupportTicket(
      orderId: 'SMGS-20261017-01',
      category: _categories[_category]!,
      reason: _reasons[_reason]!,
      description: _descController.text.trim(),
      refundPercent: _refundPercent,
    );

    _descController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yêu cầu đã được gửi thành công tới Nhân viên hệ thống.'),
        backgroundColor: AppColors.deepBurgundy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VisitStore.instance,
      builder: (context, _) {
        final store = VisitStore.instance;
        final tickets = store.supportTickets;

        return MuseumPage(
          back: true,
          title: 'Hỗ trợ & Hoàn tiền',
          eyebrow: 'Quyền lợi khách tham quan',
          subtitle: 'Tiếp nhận khiếu nại & đối soát dịch vụ',
          children: [
            // Panel chính sách hoàn tiền
            Panel(
              gold: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.deepBurgundy, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'CHÍNH SÁCH BẢO VỆ KHÁCH HÀNG',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.deepBurgundy,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Theo quy chế hệ thống SMGS, mọi yêu cầu khiếu nại hoặc hoàn tiền do lỗi kỹ thuật / sự kiện bất khả kháng được Nhân viên hệ thống (System Staff) thẩm tra và hoàn trả tự động theo tỷ lệ quy định.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF2E6B3E), size: 16),
                      SizedBox(width: 6),
                      Text('Hoàn 100% nếu bảo tàng đóng cửa hoặc lỗi app', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF2E6B3E), size: 16),
                      SizedBox(width: 6),
                      Text('Hoàn 80% nếu yêu cầu hủy trước giờ mở cửa 24h', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form gửi yêu cầu mới
            const SectionHeading('Gửi yêu cầu hỗ trợ mới'),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chọn danh mục
                  const Text('Loại yêu cầu', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        items: _categories.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value, style: AppTextStyles.bodySmall),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Đơn hàng liên quan
                  const Text('Đơn hàng áp dụng', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.receipt_outlined, size: 20, color: AppColors.deepBurgundy),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Đơn gần nhất: SMGS-20261017-01', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Combo Vé cổng + Hướng dẫn số · 75.000 đ', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lý do hoàn tiền
                  const Text('Lý do yêu cầu', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _reason,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        items: _reasons.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value, style: AppTextStyles.bodySmall),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _reason = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tỷ lệ đề xuất
                  const Text('Tỷ lệ hoàn tiền đề xuất', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [100, 80, 50].map((percent) {
                      final selected = _refundPercent == percent;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected ? AppColors.deepBurgundy : AppColors.card,
                              foregroundColor: selected ? AppColors.antiqueIvory : AppColors.darkBrown,
                              side: BorderSide(
                                color: selected ? AppColors.deepBurgundy : AppColors.border,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => setState(() => _refundPercent = percent),
                            child: Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Mô tả chi tiết
                  const Text('Mô tả sự việc chi tiết', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Vui lòng mô tả thời gian, địa điểm và chi tiết khó khăn bạn gặp phải...',
                      hintStyle: AppTextStyles.caption,
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.deepBurgundy, width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Vui lòng nhập tối thiểu 10 ký tự mô tả lý do.'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'Gửi yêu cầu tới System Staff',
                    icon: Icons.send_outlined,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Lịch sử các yêu cầu đã gửi
            const SectionHeading('Lịch sử yêu cầu đã gửi'),
            if (tickets.isEmpty)
              const Panel(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Bạn chưa có yêu cầu khiếu nại hoặc hoàn tiền nào.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              )
            else
              for (final ticket in tickets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ticket.id,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.deepBurgundy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.mutedGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ticket.status,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.deepBurgundy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ticket.category, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text('Lý do: ${ticket.reason}', style: AppTextStyles.bodySmall),
                        Text('Đề xuất hoàn: ${ticket.refundPercent}%', style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueIvory,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ticket.description,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
