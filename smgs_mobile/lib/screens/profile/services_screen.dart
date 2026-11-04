import 'order_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import '../../models/experience.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.museumName, this.museumId});
  final String? museumName, museumId;
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late String? _museumId =
      widget.museumId ??
      AppServices.catalog.museums
          .where((m) => m.name == widget.museumName)
          .firstOrNull
          ?.id ??
      AppServices.catalog.museums.firstOrNull?.id;
  late Future<dynamic>? _products = _museumId == null
      ? null
      : BackendApi.request('commerce/museums/$_museumId/products');
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Vé & Hướng dẫn số',
    eyebrow: 'Dịch vụ bảo tàng',
    children: [
      if (AppServices.catalog.museums.isEmpty)
        const Notice('Chưa có bảo tàng công khai.')
      else
        DropdownButtonFormField<String>(
          initialValue: _museumId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Bảo tàng'),
          items: AppServices.catalog.museums
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (id) => setState(() {
            _museumId = id;
            _products = BackendApi.request('commerce/museums/$id/products');
          }),
        ),
      const SizedBox(height: 20),
      if (_products != null)
        FutureBuilder<dynamic>(
          future: _products,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Notice(snapshot.error.toString()),
                  TextButton(
                    onPressed: () => setState(
                      () => _products = BackendApi.request(
                        'commerce/museums/$_museumId/products',
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }
            final products = (snapshot.data as List)
                .cast<Map<String, dynamic>>();
            if (products.isEmpty) {
              return const EmptyState(
                title: 'Chưa có gói dịch vụ',
                message: 'Bảo tàng chưa công khai sản phẩm trên hệ thống.',
              );
            }
            return Column(
              children: products
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] as String,
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 10),
                            Text('${p['price']} ${p['currency']}'),
                            TextButton(
                              onPressed: () => openPage(
                                context,
                                ResourceAccessScreen(
                                  museumId: _museumId!,
                                  resourceIds: (p['resourceIds'] as List)
                                      .cast<int>(),
                                ),
                              ),
                              child: const Text(
                                'Xem nội dung và quyền truy cập',
                              ),
                            ),
                            Text(
                              '${p['seats']} người · ${p['validityHours'] ?? 'Chưa cấu hình'} giờ',
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Xem và tạo đơn hàng',
                              onPressed: () => openPage(
                                context,
                                ServiceCheckoutScreen(
                                  offer: PremiumOffer(
                                    id: p['id'].toString(),
                                    name: p['name'],
                                    description: p['kind'],
                                    price: (p['price'] as num).toInt(),
                                    kind: DigitalServiceKind.guide,
                                  ),
                                  museumId: _museumId!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      TextButton(
        onPressed: () => openPage(context, const PurchasedServicesScreen()),
        child: const Text('Xem đơn hàng và quyền truy cập của tôi'),
      ),
    ],
  );
}

class ServiceCheckoutScreen extends StatefulWidget {
  const ServiceCheckoutScreen({
    super.key,
    required this.offer,
    required this.museumId,
  });
  final PremiumOffer offer;
  final String museumId;
  @override
  State<ServiceCheckoutScreen> createState() => _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends State<ServiceCheckoutScreen> {
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _order, _payment;
  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order =
          _order ??
          Map<String, dynamic>.from(
            await BackendApi.request(
              'commerce/orders',
              method: 'POST',
              body: {
                'productId': int.parse(widget.offer.id),
                'buyerName': AppServices.auth.user!.name,
                'buyerDetails': {'email': AppServices.auth.user!.email},
              },
            ),
          );
      if (!mounted) return;
      setState(() => _order = order);
      final payment = Map<String, dynamic>.from(
        await BackendApi.request(
          'commerce/orders/${order['id']}/payments',
          method: 'POST',
          body: {},
        ),
      );
      if (mounted) setState(() => _payment = payment);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: widget.offer.name,
    eyebrow: 'Xác nhận đơn hàng',
    children: [
      Text(AppServices.catalog.museumName(widget.museumId)),
      const SizedBox(height: 16),
      const Notice(
        'Giá và thời hạn được máy chủ xác nhận khi tạo đơn. Quyền truy cập chỉ được cấp sau khi máy chủ xác nhận thanh toán.',
      ),
      if (_error != null) Notice(_error!),
      if (_order != null) ...[
        Text('Mã đơn: ${_order!['id']}'),
        TextButton(
          onPressed: () => openPage(
            context,
            OrderDetailScreen(orderId: _order!['id'].toString()),
          ),
          child: const Text('Chi tiết giao dịch và hóa đơn'),
        ),
        Text('Tổng tiền: ${_order!['amount']} ${_order!['currency']}'),
        Text('Trạng thái: ${_order!['status']}'),
      ],
      if (_payment != null)
        Notice(
          'Yêu cầu thanh toán: ${_payment!['status']}. Chờ xác nhận từ hệ thống; ứng dụng chưa kích hoạt dịch vụ.',
        ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: _busy
            ? 'Đang gửi…'
            : _order == null
            ? 'Tạo đơn và yêu cầu thanh toán'
            : 'Thử lại yêu cầu thanh toán',
        onPressed: _busy || _payment != null ? null : _submit,
      ),
      TextButton(
        onPressed: () => openPage(context, const PurchasedServicesScreen()),
        child: const Text('Kiểm tra trạng thái đơn hàng'),
      ),
    ],
  );
}

class PurchasedServicesScreen extends StatefulWidget {
  const PurchasedServicesScreen({super.key});
  @override
  State<PurchasedServicesScreen> createState() =>
      _PurchasedServicesScreenState();
}

class _PurchasedServicesScreenState extends State<PurchasedServicesScreen> {
  Future<List<List<Map<String, dynamic>>>> _fetch() => Future.wait([
    BackendApi.list('commerce/orders/me'),
    BackendApi.list('commerce/passes/me'),
  ]);
  late Future<List<List<Map<String, dynamic>>>> _data = _fetch();
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Dịch vụ của tôi',
    children: [
      TextButton(
        onPressed: () async {
          final accepted = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(builder: (_) => const RedeemPassScreen()),
          );
          if (accepted == true && mounted) setState(() => _data = _fetch());
        },
        child: const Text('Nhập mã tham gia nhóm'),
      ),
      TextButton(
        onPressed: () => setState(() => _data = _fetch()),
        child: const Text('Cập nhật trạng thái'),
      ),
      FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          final orders = snapshot.data![0], passes = snapshot.data![1];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeading('Quyền truy cập'),
              if (passes.isEmpty)
                const Notice('Chưa có quyền truy cập được cấp.'),
              for (final p in passes)
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['productName'], style: AppTextStyles.sectionTitle),
                      Text(
                        p['isValid'] == true
                            ? 'Đang có hiệu lực'
                            : 'Không còn hiệu lực',
                      ),
                      Text('Hết hạn: ${p['expiresAt'] ?? 'Không giới hạn'}'),
                      SelectableText('Mã quyền truy cập: ${p['id']}'),
                    ],
                  ),
                ),
              const SectionHeading('Đơn hàng'),
              if (orders.isEmpty) const Notice('Bạn chưa có đơn hàng.'),
              for (final o in orders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o['productName'],
                          style: AppTextStyles.sectionTitle,
                        ),
                        Text('${o['amount']} ${o['currency']}'),
                        Text('Trạng thái: ${o['status']}'),
                        Text('Mã đơn: ${o['id']}'),
                        TextButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => OrderDetailScreen(
                                  orderId: o['id'].toString(),
                                ),
                              ),
                            );
                            if (mounted) setState(() => _data = _fetch());
                          },
                          child: const Text('Chi tiết giao dịch và hóa đơn'),
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
