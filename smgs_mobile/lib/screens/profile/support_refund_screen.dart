import '../../core/localization/app_localizations.dart';
import '../../widgets/backend_panel.dart';
import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../services/backend_api.dart';

class SupportRefundScreen extends StatefulWidget {
  const SupportRefundScreen({super.key});
  @override
  State<SupportRefundScreen> createState() => _SupportRefundScreenState();
}

class _SupportRefundScreenState extends State<SupportRefundScreen> {
  final _subject = TextEditingController(), _body = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  late Future<List<Map<String, dynamic>>> _tickets = BackendApi.list(
    'complaints/me',
  );

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BackendApi.request(
        'complaints',
        method: 'POST',
        body: {'subject': _subject.text.trim(), 'body': _body.text.trim()},
      );
      if (!mounted) return;
      _subject.clear();
      _body.clear();
      setState(() => _tickets = BackendApi.list('complaints/me'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu tới hệ thống.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildStatusBadge(dynamic rawStatus) {
    final status = rawStatus?.toString().toLowerCase() ?? '';
    Color bg;
    Color fg;
    IconData icon;
    if (status == 'resolved' || status == 'completed') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
    } else if (status == 'open' || status == 'pending') {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
      icon = Icons.hourglass_top_rounded;
    } else {
      bg = AppColors.antiqueIvory;
      fg = AppColors.darkBrown;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VisitorRadius.full),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            backendStatus(rawStatus),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MuseumPage(
    back: true,
    title: l10n.isEn ? 'Support & Inquiries' : 'Hỗ trợ & khiếu nại',
    children: [
      Eyebrow(l10n.isEn ? 'CUSTOMER CARE & SUPPORT' : 'TRUNG TÂM CSKH & HỖ TRỢ'),
      const SizedBox(height: 6),
      Text(l10n.isEn ? 'Submit Feedback & Inquiries' : 'Gửi phản ánh & khiếu nại', style: AppTextStyles.pageTitle),
      const SizedBox(height: 10),
      Notice(
        l10n.isEn
            ? 'You can submit issues regarding services or passes. Submissions are reviewed by staff; automated instant refunds are not supported.'
            : 'Bạn có thể gửi vấn đề về dịch vụ hoặc đơn hàng. Việc gửi yêu cầu không tự động hoàn tiền; hệ thống chưa hỗ trợ hoàn tiền trực tiếp.',
      ),
      const SizedBox(height: 20),

      // Creation Form Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.isEn ? 'Create Support Request' : 'Tạo yêu cầu hỗ trợ mới',
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _subject,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: l10n.isEn ? 'Subject' : 'Tiêu đề vấn đề',
                  hintText: l10n.isEn ? 'Summary of issue or question...' : 'Tóm tắt sự cố hoặc thắc mắc…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VisitorRadius.md),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? (l10n.isEn ? 'Enter subject' : 'Nhập tiêu đề') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                maxLength: 5000,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.isEn ? 'Details and Order ID (if any)' : 'Nội dung và mã đơn hàng (nếu có)',
                  hintText: l10n.isEn ? 'Detailed description to assist fast review...' : 'Mô tả chi tiết để nhân viên kiểm tra nhanh nhất…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VisitorRadius.md),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? (l10n.isEn ? 'Enter details' : 'Nhập nội dung') : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Notice(_error!),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: _busy
                    ? (l10n.isEn ? 'Sending...' : 'Đang gửi…')
                    : (l10n.isEn ? 'Submit Request' : 'Gửi yêu cầu hỗ trợ'),
                icon: Icons.send_rounded,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 28),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SectionHeading('Yêu cầu đã gửi'),
          TextButton.icon(
            onPressed: () =>
                setState(() => _tickets = BackendApi.list('complaints/me')),
            icon: const Icon(
              Icons.sync_rounded,
              size: 15,
              color: AppColors.deepBurgundy,
            ),
            label: const Text(
              'Tải lại',
              style: TextStyle(
                color: AppColors.deepBurgundy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      FutureBuilder<List<Map<String, dynamic>>>(
        future: _tickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Notice('Bạn chưa gửi yêu cầu hỗ trợ nào.');
          }
          return Column(
            children: snapshot.data!
                .map(
                  (t) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(VisitorRadius.xl),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#REQ-${t['id']}',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedGold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            _buildStatusBadge(t['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t['subject'] ?? '',
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.darkBrown.withOpacity(0.8),
                          ),
                        ),
                        if (t['resolutionNote'] != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF81C784),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t['resolutionNote'],
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => openPage(
                                context,
                                ComplaintDetailScreen(id: t['id'] as int),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.deepBurgundy,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 15,
                                color: AppColors.deepBurgundy,
                              ),
                              label: const Text(
                                'Xem quá trình xử lý',
                                style: TextStyle(
                                  color: AppColors.deepBurgundy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
  }
}

class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key, required this.id});
  final int id;

  Widget _buildStepNode({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    final color = isDone
        ? const Color(0xFF2E7D32)
        : (isActive ? AppColors.deepBurgundy : AppColors.darkBrown.withOpacity(0.3));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFFE8F5E9)
                    : (isActive ? AppColors.antiqueIvory : Colors.transparent),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: isDone
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      )
                    : (isActive
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.deepBurgundy,
                            ),
                          )
                        : null),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone
                    ? const Color(0xFF81C784)
                    : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDone || isActive
                      ? AppColors.darkBrown
                      : AppColors.darkBrown.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.darkBrown.withOpacity(0.65),
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Chi tiết yêu cầu',
    children: [
      const Eyebrow('TIẾN TRÌNH XỬ LÝ KHIẾU NẠI'),
      const SizedBox(height: 6),
      Text('Tiến độ giải quyết', style: AppTextStyles.pageTitle),
      const SizedBox(height: 16),
      BackendPanel(
        resourceKey: 'complaint:$id',
        load: () => BackendApi.request('complaints/me/$id'),
        builder: (data, reload) {
          final isResolved =
              data['status'] == 'Resolved' || data['status'] == 'completed';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#REQ-$id',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.mutedGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isResolved
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFF57F17),
                            ),
                          ),
                          child: Text(
                            backendStatus(data['status']),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isResolved
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFF57F17),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['subject'] ?? '',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.darkBrown.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gửi lúc: ${data['createdAt'] ?? ''}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.darkBrown.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const SectionHeading('Quy trình xử lý'),
              const SizedBox(height: 12),

              // Stepper Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildStepNode(
                      title: '1. Đã tiếp nhận yêu cầu',
                      subtitle: 'Hệ thống đã ghi nhận phản ánh của bạn.',
                      isDone: true,
                      isActive: false,
                    ),
                    _buildStepNode(
                      title: '2. Nhân viên CSKH kiểm tra & xác minh',
                      subtitle:
                          'Đội ngũ phụ trách đang đối soát thông tin đơn hàng.',
                      isDone: isResolved,
                      isActive: !isResolved,
                    ),
                    _buildStepNode(
                      title: '3. Phản hồi & giải quyết khiếu nại',
                      subtitle: isResolved
                          ? 'Đã có kết luận giải quyết từ ban quản lý.'
                          : 'Đang chờ xử lý hoàn tất.',
                      isDone: isResolved,
                      isActive: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const SectionHeading('Nội dung phản ánh gốc'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.antiqueIvory,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  data['body'] ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.darkBrown,
                    height: 1.5,
                  ),
                ),
              ),

              if (data['resolutionNote'] != null) ...[
                const SizedBox(height: 24),
                const SectionHeading('Kết luận phản hồi từ bảo tàng'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PHẢN HỒI CHÍNH THỨC',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B5E20),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['resolutionNote'],
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF1B5E20),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: reload,
                  icon: const Icon(
                    Icons.sync_rounded,
                    size: 16,
                    color: AppColors.deepBurgundy,
                  ),
                  label: const Text(
                    'Cập nhật tiến độ',
                    style: TextStyle(
                      color: AppColors.deepBurgundy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}
