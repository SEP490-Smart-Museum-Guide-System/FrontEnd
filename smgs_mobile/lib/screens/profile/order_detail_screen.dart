import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Chi tiết đơn hàng',
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(order['productName'], style: AppTextStyles.pageTitle),
              SelectableText('Mã đơn: ${order['id']}'),
              Text('${order['amount']} ${order['currency']}'),
              Text(backendStatus(order['status'])),
              Text('Số người: ${order['seats']}'),
              TextButton(
                onPressed: reload,
                child: const Text('Cập nhật trạng thái'),
              ),
              const SectionHeading('Các lần thanh toán'),
              if (transactions.isEmpty)
                const Notice('Chưa có yêu cầu thanh toán.'),
              for (final t in transactions)
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        backendStatus(t['status']),
                        style: AppTextStyles.sectionTitle,
                      ),
                      Text('${t['createdAt']}'),
                      if (t['reference'] != null)
                        SelectableText('Tham chiếu: ${t['reference']}'),
                      if (t['failureReason'] != null) Text(t['failureReason']),
                    ],
                  ),
                ),
              if (order['status'] == 'paid') ...[
                const SectionHeading('Thông tin hóa đơn'),
                BackendPanel(
                  resourceKey: 'invoice:${widget.orderId}',
                  load: () => BackendApi.request(
                    'commerce/orders/${widget.orderId}/invoice',
                  ),
                  builder: (invoice, retry) => Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(invoice['number']),
                        Text(invoice['buyerName']),
                        Text(invoice['productName']),
                        Text('${invoice['amount']} ${invoice['currency']}'),
                        Text('${invoice['issuedAt']}'),
                      ],
                    ),
                  ),
                ),
                if ((order['seats'] as num) > 1) ...[
                  const SectionHeading('Mã tham gia nhóm'),
                  const Notice(
                    'Chỉ chia sẻ mã với người cùng nhóm. Tạo mã mới sẽ thay thế mã cũ; thành viên nhập mã trong mục Dịch vụ của tôi.',
                  ),
                  if (_groupKey != null) ...[
                    SelectableText(
                      _groupKey!['key'],
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Số lượt nhận còn lại: ${_groupKey!['remainingClaims']}',
                    ),
                  ],
                  PrimaryButton(
                    label: _busy ? 'Đang tạo mã…' : 'Tạo mã tham gia nhóm',
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
      const Notice(
        'Nhập mã do người mua gói nhóm chia sẻ để nhận quyền truy cập.',
      ),
      Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _key,
              maxLength: 64,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mã tham gia nhóm'),
              validator: (value) => value?.trim().length == 64
                  ? null
                  : 'Mã tham gia cần đủ 64 ký tự.',
            ),
            if (_error != null) Notice(_error!),
            PrimaryButton(
              label: _busy ? 'Đang nhận quyền…' : 'Nhận quyền truy cập',
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
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'], style: AppTextStyles.sectionTitle),
                        Text(
                          r['accessLevel'] == 'premium'
                              ? 'Nội dung trả phí'
                              : 'Nội dung miễn phí',
                        ),
                        BackendPanel(
                          resourceKey: 'access:${r['id']}',
                          load: () => BackendApi.request(
                            'commerce/resources/${r['id']}/access',
                          ),
                          builder: (access, retry) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                access['allowed'] == true
                                    ? 'Bạn có quyền truy cập'
                                    : 'Bạn chưa có quyền truy cập',
                              ),
                              TextButton(
                                onPressed: retry,
                                child: const Text('Kiểm tra lại quyền'),
                              ),
                            ],
                          ),
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
