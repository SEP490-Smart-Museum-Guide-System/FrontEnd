import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _groupKey;

  Widget _buildStatusChip(String? rawStatus) {
    final status = rawStatus?.toLowerCase() ?? '';
    Color bg;
    Color fg;
    IconData icon;
    if (status == 'paid' || status == 'succeeded') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
    } else if (status == 'pending' || status == 'draft') {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
      icon = Icons.hourglass_top_rounded;
    } else if (status == 'failed' || status == 'abandoned') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
      icon = Icons.cancel_rounded;
    } else {
      bg = AppColors.antiqueIvory;
      fg = AppColors.darkBrown;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              backendStatus(rawStatus),
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(
    String key,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.darkBrown.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.darkBrown,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount, dynamic currency) {
    if (amount == null) return '0 ${currency ?? 'VND'}';
    if (amount is num) {
      final str = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '$str ${currency ?? 'VND'}';
    }
    return '$amount ${currency ?? 'VND'}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MuseumPage(
    back: true,
    title: l10n.orderDetailTitle,
    children: [
      if (_error != null) Notice(_error!),
      BackendPanel(
        resourceKey: 'my-order:${widget.orderId}',
        load: () async {
          final orders = await BackendApi.list('commerce/orders/me');
          final order = orders
              .where((o) => o['id'].toString() == widget.orderId)
              .firstOrNull;
          if (order == null) {
            throw const FormatException('Không tìm thấy đơn hàng của bạn.');
          }
          final transactions = await BackendApi.request(
            'commerce/orders/${widget.orderId}/transactions',
          );
          return [order, transactions];
        },
        builder: (data, reload) {
          final order = data[0] as Map<String, dynamic>;
          final transactions = data[1] as List;
          final isPaid = order['status'] == 'paid';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Digital Pass / Ticket Header Card
              Container(
                decoration: BoxDecoration(
                  color: VisitorColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top header banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.deepBurgundy,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.confirmation_number_outlined,
                                size: 16,
                                color: AppColors.mutedGold,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.isEn ? 'VISITOR PASS' : 'VÉ THAM QUAN',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.antiqueIvory,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildStatusChip(order['status']),
                        ],
                      ),
                    ),

                    // Main Pass Info Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['productName'] ?? 'Gói dịch vụ',
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                size: 14,
                                color: AppColors.darkBrown.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: SelectableText(
                                  l10n.isEn ? 'Order ID: ${order['id']}' : 'Mã đơn: ${order['id']}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.darkBrown.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // Metric summary with Wrap for ultra-narrow safety
                          Wrap(
                            spacing: 24,
                            runSpacing: 10,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TỔNG TIỀN',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.darkBrown.withOpacity(
                                        0.6,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatAmount(
                                      order['amount'],
                                      order['currency'],
                                    ),
                                    style: AppTextStyles.cardTitle.copyWith(
                                      color: AppColors.deepBurgundy,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SỐ LƯỢNG',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.darkBrown.withOpacity(
                                        0.6,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.group_outlined,
                                        size: 16,
                                        color: AppColors.darkBrown,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${order['seats']} người',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NGÀY THAM QUAN',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.darkBrown.withOpacity(
                                        0.6,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                        color: AppColors.darkBrown,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        order['visitDate'] != null ? order['visitDate'].toString() : 'Trong ngày',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (order['status'] == 'cancelled') ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF9A9A)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFC62828)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (order['refundedAmount'] != null && (order['refundedAmount'] as num) > 0)
                                          ? 'Đơn hàng đã được hủy. Đã hoàn ${_formatAmount(order['refundedAmount'], order['currency'])} vào ví của bạn.'
                                          : 'Đơn hàng đã được hủy (không có khoản hoàn vào ví theo chính sách thời hạn).',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Reload & Cancel action
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.antiqueIvory,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (order['status'] == 'pending')
                            TextButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hủy đơn hàng?'),
                                    content: const Text('Bạn có chắc muốn hủy đơn hàng này không? Tiền đã trừ từ ví (nếu có) sẽ được hoàn lại.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Không')),
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hủy đơn', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirmed == true && mounted) {
                                  try {
                                    final res = await BackendApi.request('commerce/orders/${widget.orderId}/cancel', method: 'POST');
                                    final msg = res is Map ? res['message']?.toString() ?? 'Đã hủy đơn hàng.' : 'Đã hủy đơn.';
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                      reload();
                                    }
                                  } catch (e) {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 15, color: Colors.red),
                              label: const Text('Hủy đơn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12)),
                            )
                          else
                            const SizedBox.shrink(),
                          TextButton.icon(
                            onPressed: reload,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            icon: const Icon(
                              Icons.sync_rounded,
                              size: 15,
                              color: AppColors.deepBurgundy,
                            ),
                            label: const Text(
                              'Cập nhật',
                              style: TextStyle(
                                color: AppColors.deepBurgundy,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Payment Transactions
              const SizedBox(height: 24),
              const SectionHeading('Các lần thanh toán'),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                const Notice('Chưa có yêu cầu thanh toán.')
              else
                ...transactions.map(
                  (t) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VisitorColors.surface1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                backendStatus(t['status']),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepBurgundy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(t['status']),
                          ],
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
                              '${t['createdAt']}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.darkBrown.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        if (t['reference'] != null) ...[
                          const SizedBox(height: 4),
                          SelectableText(
                            'Tham chiếu: ${t['reference']}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ],
                        if (t['failureReason'] != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 14,
                                  color: Color(0xFFC62828),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    t['failureReason'],
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFFC62828),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Invoice section
              if (isPaid) ...[
                const SizedBox(height: 24),
                const SectionHeading('Thông tin hóa đơn'),
                const SizedBox(height: 8),
                BackendPanel(
                  resourceKey: 'invoice:${widget.orderId}',
                  load: () => BackendApi.request(
                    'commerce/orders/${widget.orderId}/invoice',
                  ),
                  builder: (invoice, retry) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VisitorColors.surface1,
                      borderRadius: BorderRadius.circular(VisitorRadius.xl),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              size: 18,
                              color: AppColors.deepBurgundy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'HÓA ĐƠN ĐIỆN TỬ',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepBurgundy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SelectableText(
                              invoice['number'] ?? '',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.mutedGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _buildKeyValueRow('Khách hàng', invoice['buyerName'] ?? ''),
                        _buildKeyValueRow('Dịch vụ', invoice['productName'] ?? ''),
                        _buildKeyValueRow(
                          'Số tiền thanh toán',
                          _formatAmount(
                            invoice['amount'],
                            invoice['currency'],
                          ),
                          bold: true,
                          valueColor: AppColors.deepBurgundy,
                        ),
                        if (invoice['issuedAt'] != null)
                          _buildKeyValueRow(
                            'Ngày phát hành',
                            '${invoice['issuedAt']}',
                          ),
                      ],
                    ),
                  ),
                ),

                // Group Pass Key Generation & Sharing
                if ((order['seats'] as num) > 1) ...[
                  const SizedBox(height: 24),
                  const SectionHeading('Mã tham gia nhóm'),
                  const SizedBox(height: 6),
                  const Notice(
                    'Chỉ chia sẻ mã với người cùng nhóm. Tạo mã mới sẽ thay thế mã cũ; thành viên nhập mã trong mục Dịch vụ của tôi.',
                  ),
                  const SizedBox(height: 12),
                  if (_groupKey != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueIvory,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'MÃ TRUY CẬP HOẠT ĐỘNG',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepBurgundy,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: AppColors.deepBurgundy,
                                ),
                                tooltip: 'Sao chép mã',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: _groupKey!['key'] ?? '',
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đã sao chép mã tham gia!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          SelectableText(
                            _groupKey!['key'],
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepBurgundy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_add_alt_1_outlined,
                                size: 14,
                                color: AppColors.darkBrown,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Số lượt nhận còn lại: ${_groupKey!['remainingClaims']}',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: _busy ? 'Đang tạo mã…' : 'Tạo mã tham gia nhóm',
                    icon: Icons.key_rounded,
                    onPressed: _busy
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Tạo mã tham gia nhóm mới?'),
                                content: const Text(
                                  'Mã đã chia sẻ trước đó sẽ không còn dùng được.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Tạo mã'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !mounted || _busy) return;
                            setState(() {
                              _busy = true;
                              _error = null;
                            });
                            try {
                              final result = await BackendApi.request(
                                'commerce/orders/${widget.orderId}/group-key',
                                method: 'POST',
                                body: {},
                              );
                              if (mounted) {
                                setState(
                                  () => _groupKey = Map<String, dynamic>.from(
                                    result,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _error = e.toString());
                              }
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                  ),
                ],
              ],
            ],
          );
        },
      ),
    ],
  );
  }
}

class RedeemPassScreen extends StatefulWidget {
  const RedeemPassScreen({super.key});
  @override
  State<RedeemPassScreen> createState() => _RedeemPassScreenState();
}

class _RedeemPassScreenState extends State<RedeemPassScreen> {
  final _key = TextEditingController(), _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Tham gia nhóm',
    children: [
      const Eyebrow('QUYỀN TRUY CẬP ĐỒNG HÀNH'),
      const SizedBox(height: 6),
      Text('Kích hoạt mã nhóm', style: AppTextStyles.pageTitle),
      const SizedBox(height: 8),
      const Notice(
        'Nhập mã do người mua gói nhóm chia sẻ để nhận quyền truy cập vào các tiện ích cao cấp của bảo tàng.',
      ),
      const SizedBox(height: 16),
      Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _key,
              maxLength: 64,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Mã tham gia nhóm',
                hintText: 'Dán mã 64 ký tự được chia sẻ vào đây…',
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.deepBurgundy,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) => value?.trim().length == 64
                  ? null
                  : 'Mã tham gia cần đủ 64 ký tự.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Notice(_error!),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: _busy ? 'Đang nhận quyền…' : 'Nhận quyền truy cập',
              icon: Icons.vpn_key_rounded,
              onPressed: _busy
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        await BackendApi.request(
                          'commerce/passes/redeem',
                          method: 'POST',
                          body: {'key': _key.text.trim()},
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) setState(() => _error = e.toString());
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
            ),
          ],
        ),
      ),
    ],
  );
}

class ResourceAccessScreen extends StatelessWidget {
  const ResourceAccessScreen({
    super.key,
    required this.museumId,
    required this.resourceIds,
  });
  final String museumId;
  final List<int> resourceIds;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Nội dung của gói',
    children: [
      const Eyebrow('DỊCH VỤ & TÀI NGUYÊN'),
      const SizedBox(height: 6),
      Text('Tài nguyên thuộc gói', style: AppTextStyles.pageTitle),
      const SizedBox(height: 16),
      BackendPanel(
        resourceKey: 'resources:$museumId',
        load: () => BackendApi.request('commerce/museums/$museumId/resources'),
        builder: (data, reload) {
          final rows = (data as List)
              .cast<Map<String, dynamic>>()
              .where((r) => resourceIds.contains(r['id']))
              .toList();
          return Column(
            children: [
              if (rows.isEmpty) const Notice('Chưa có nội dung của gói.'),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VisitorColors.surface1,
                      borderRadius: BorderRadius.circular(VisitorRadius.xl),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r['name'],
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: r['accessLevel'] == 'premium'
                                    ? AppColors.mutedGold.withOpacity(0.2)
                                    : AppColors.antiqueIvory,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: r['accessLevel'] == 'premium'
                                      ? AppColors.mutedGold
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                r['accessLevel'] == 'premium'
                                    ? 'Trả phí'
                                    : 'Miễn phí',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: r['accessLevel'] == 'premium'
                                      ? AppColors.deepBurgundy
                                      : AppColors.darkBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        BackendPanel(
                          resourceKey: 'access:${r['id']}',
                          load: () => BackendApi.request(
                            'commerce/resources/${r['id']}/access',
                          ),
                          builder: (access, retry) {
                            final allowed = access['allowed'] == true;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      allowed
                                          ? Icons.check_circle_rounded
                                          : Icons.lock_outline_rounded,
                                      size: 16,
                                      color: allowed
                                          ? const Color(0xFF2E7D32)
                                          : AppColors.darkBrown.withOpacity(
                                              0.6,
                                            ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        allowed
                                            ? 'Bạn có quyền truy cập'
                                            : 'Bạn chưa có quyền truy cập',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: allowed
                                              ? const Color(0xFF2E7D32)
                                              : AppColors.darkBrown.withOpacity(
                                                  0.7,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: retry,
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text('Kiểm tra lại quyền'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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
