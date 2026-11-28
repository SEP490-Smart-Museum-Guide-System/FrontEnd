import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
          Map<String, dynamic>? admissionTicket;
          try {
            final t = await BackendApi.request('commerce/orders/${widget.orderId}/admission-ticket');
            if (t is Map) admissionTicket = Map<String, dynamic>.from(t);
          } catch (_) {}
          Map<String, dynamic>? orderItems;
          try {
            final it = await BackendApi.request('commerce/orders/${widget.orderId}/items');
            if (it is Map) orderItems = Map<String, dynamic>.from(it);
          } catch (_) {}
          return [order, transactions, admissionTicket, orderItems];
        },
        builder: (data, reload) {
          final order = data[0] as Map<String, dynamic>;
          final transactions = data[1] as List;
          final admissionTicket = data.length > 2 ? data[2] as Map<String, dynamic>? : null;
          final orderItems = data.length > 3 ? data[3] as Map<String, dynamic>? : null;
          final isPaid = order['status'] == 'paid';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Thẻ Vé vào cổng Boarding Pass kèm mã QR
              if (admissionTicket != null && admissionTicket['code'] != null) ...[
                _buildAdmissionBoardingPass(context, admissionTicket, order, reload),
                const SizedBox(height: 16),
              ],

              // 2. Chi tiết từng món trong đơn & nút Hủy hoàn tiền
              if (orderItems != null && (orderItems['ticketAmount'] != null || orderItems['digitalAmount'] != null)) ...[
                _buildOrderItemsBreakdown(context, order, admissionTicket, orderItems, reload),
                const SizedBox(height: 16),
              ],

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
                  builder: (invoice, retry) {
                    if (invoice is! Map<String, dynamic> || invoice.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
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
                  );
                },
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

  Widget _buildAdmissionBoardingPass(
    BuildContext context,
    Map<String, dynamic> ticket,
    Map<String, dynamic> order,
    VoidCallback reload,
  ) {
    final code = ticket['code']?.toString() ?? '';
    final visitDate = ticket['visitDate']?.toString() ?? order['visitDate']?.toString() ?? '';
    final quantity = ticket['quantity'] ?? order['seats'] ?? 1;
    final used = ticket['used'] ?? 0;
    final remaining = ticket['remaining'] ?? (quantity - used);
    final canCheckIn = ticket['canCheckIn'] == true;
    final isCancelled = order['status'] == 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(color: AppColors.mutedGold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.deepBurgundy,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(VisitorRadius.xl - 1),
                topRight: Radius.circular(VisitorRadius.xl - 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.confirmation_number_rounded, color: AppColors.mutedGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'VÉ VÀO CỔNG ĐIỆN TỬ',
                      style: TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontWeight: FontWeight.bold,
                        color: AppColors.antiqueIvory,
                        fontSize: 13.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFFEBEE)
                        : (canCheckIn ? const Color(0xFFE8F5E9) : Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCancelled
                        ? 'Đã hủy'
                        : (canCheckIn ? 'Hợp lệ vào cổng' : 'Đã dùng hết'),
                    style: TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCancelled
                          ? const Color(0xFFC62828)
                          : (canCheckIn ? const Color(0xFF2E7D32) : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // QR Code Container
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                if (code.isNotEmpty && !isCancelled)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: QrImageView(
                      data: code,
                      version: QrVersions.auto,
                      size: 190.0,
                      backgroundColor: Colors.white,
                    ),
                  )
                else
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(
                      isCancelled ? 'Vé đã bị hủy' : 'Chưa có mã QR',
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                const SizedBox(height: 12),
                SelectableText(
                  'Mã vé: $code',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.darkBrown,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Xuất trình mã này tại cổng để nhân viên quét xác nhận',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),

          // Dashed Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                30,
                (index) => Expanded(
                  child: Container(
                    color: index % 2 == 0 ? AppColors.border : Colors.transparent,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Boarding pass footer stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPassStat('NGÀY THAM QUAN', visitDate),
                _buildPassStat('ĐÃ VÀO', '$used / $quantity'),
                _buildPassStat('CÒN LẠI', '$remaining lượt', isHighlight: remaining > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.deepBurgundy : AppColors.darkBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemsBreakdown(
    BuildContext context,
    Map<String, dynamic> order,
    Map<String, dynamic>? ticket,
    Map<String, dynamic> orderItems,
    VoidCallback reload,
  ) {
    final currency = order['currency'] ?? 'VND';
    final ticketAmount = orderItems['ticketAmount'];
    final digitalAmount = orderItems['digitalAmount'];
    final ticketCancelled = orderItems['ticketCancelledAt'] != null;
    final digitalCancelled = orderItems['digitalCancelledAt'] != null;
    final used = ticket?['used'] ?? 0;
    final isPaid = order['status'] == 'paid' || order['status'] == 'succeeded';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT MÓN TRONG ĐƠN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.deepBurgundy,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Line 1: Vé vào cổng
          if (ticketAmount != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 18, color: AppColors.deepBurgundy),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vé vào cổng (${order['seats'] ?? 1} người)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(
                        ticketCancelled
                            ? 'Đã hủy (${orderItems['ticketCancelledAt']}) · Hoàn ${_formatAmount(orderItems['ticketRefundedAmount'], currency)} vào ví'
                            : (used > 0 ? 'Đã check-in $used lượt (Không thể hủy)' : 'Chưa check-in'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: ticketCancelled ? const Color(0xFFC62828) : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(_formatAmount(ticketAmount, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              ],
            ),
            if (isPaid && !ticketCancelled && used == 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: () => _handleCancelItem(
                    isTicket: true,
                    amount: (ticketAmount as num).toDouble(),
                    currency: currency.toString(),
                    visitDateStr: ticket?['visitDate']?.toString() ?? order['visitDate']?.toString(),
                    reload: reload,
                  ),
                  child: const Text('Hủy vé vào cổng', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],

          // Line 2: Gói số
          if (digitalAmount != null && (digitalAmount as num) > 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.headphones_outlined, size: 18, color: AppColors.deepBurgundy),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gói thuyết minh AI & 3D', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(
                        digitalCancelled
                            ? 'Đã hủy gói số (${orderItems['digitalCancelledAt']}) · Hoàn ${_formatAmount(orderItems['digitalRefundedAmount'], currency)} vào ví'
                            : 'Đang hoạt động',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: digitalCancelled ? const Color(0xFFC62828) : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(_formatAmount(digitalAmount, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              ],
            ),
            if (isPaid && !digitalCancelled) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: () => _handleCancelItem(
                    isTicket: false,
                    amount: (digitalAmount as num).toDouble(),
                    currency: currency.toString(),
                    visitDateStr: null,
                    reload: reload,
                  ),
                  child: const Text('Hủy gói thuyết minh', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _handleCancelItem({
    required bool isTicket,
    required double amount,
    required String currency,
    String? visitDateStr,
    required VoidCallback reload,
  }) async {
    String refundNotice = '';
    if (isTicket && visitDateStr != null) {
      try {
        final visitDate = DateTime.parse(visitDateStr);
        final now = DateTime.now();
        final days = visitDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        if (days >= 3) {
          refundNotice = 'Hủy trước >= 3 ngày: Hoàn 100% (${_formatAmount(amount, currency)}) vào Ví SMGS.';
        } else if (days == 2) {
          refundNotice = 'Hủy trước đúng 2 ngày: Hoàn 50% (${_formatAmount(amount / 2, currency)}) vào Ví SMGS.';
        } else {
          refundNotice = 'Hủy trước <= 1 ngày: Hoàn 0% vào Ví SMGS theo chính sách.';
        }
      } catch (_) {
        refundNotice = 'Tiền hoàn sẽ được tính theo chính sách thời hạn và ghi có vào Ví SMGS.';
      }
    } else {
      refundNotice = 'Tiền hoàn của gói số sẽ được tính theo chính sách và ghi có vào Ví SMGS.';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.antiqueIvory,
        title: Text(isTicket ? 'Hủy vé vào cổng?' : 'Hủy gói thuyết minh?', style: AppTextStyles.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTicket
                  ? 'Bạn có chắc chắn muốn hủy vé vào cổng này không? Mã QR vào cổng sẽ bị vô hiệu hóa.'
                  : 'Bạn có chắc chắn muốn hủy gói thuyết minh này không? Quyền truy cập nội dung số và mã nhóm sẽ bị khóa.',
              style: const TextStyle(fontSize: 13, color: AppColors.darkBrown),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Text(
                'Chính sách hoàn tiền:\n$refundNotice',
                style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final endpoint = isTicket
          ? 'commerce/orders/${widget.orderId}/items/ticket/cancel'
          : 'commerce/orders/${widget.orderId}/items/digital/cancel';
      final res = await BackendApi.request(endpoint, method: 'POST', body: {});
      final msg = res is Map ? res['message']?.toString() ?? 'Đã hủy thành công.' : 'Đã hủy.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        reload();
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $err'), backgroundColor: AppColors.deepBurgundy),
        );
      }
    }
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
