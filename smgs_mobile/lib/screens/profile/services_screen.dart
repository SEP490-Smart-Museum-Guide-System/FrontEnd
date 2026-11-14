import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import 'order_detail_screen.dart';

// ============================================================================
// 1. SERVICES SCREEN: Danh sách sản phẩm & dịch vụ bảo tàng
// ============================================================================
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.museumName, this.museumId});
  final String? museumName, museumId;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late String? _museumId = widget.museumId ??
      AppServices.catalog.museums.where((m) => m.name == widget.museumName).firstOrNull?.id ??
      AppServices.catalog.museums.firstOrNull?.id;

  late Future<dynamic>? _products = _museumId == null
      ? null
      : BackendApi.request('commerce/museums/$_museumId/products');

  void _onSelectProduct(Map<String, dynamic> product) {
    if (AppServices.auth.user == null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.antiqueIvory,
          title: const Text('Yêu cầu đăng nhập', style: AppTextStyles.cardTitle),
          content: const Text(
            'Vui lòng đăng nhập hoặc tạo tài khoản để đặt mua gói dịch vụ và nhận vé tham quan điện tử.',
            style: TextStyle(color: AppColors.darkBrown),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Để sau', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
              onPressed: () {
                Navigator.of(ctx).pop();
                // Navigate to login if available or prompt user
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập từ màn hình Tài khoản.')),
                );
              },
              child: const Text('Đồng ý', style: TextStyle(color: AppColors.antiqueIvory)),
            ),
          ],
        ),
      );
      return;
    }

    openPage(
      context,
      ServiceCheckoutScreen(
        museumId: _museumId!,
        product: product,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Vé & Dịch vụ số',
    eyebrow: 'Bảo tàng điện tử',
    children: [
      if (AppServices.catalog.museums.isEmpty)
        const Notice('Chưa có bảo tàng công khai trên hệ thống.')
      else
        DropdownButtonFormField<String>(
          initialValue: _museumId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Chọn bảo tàng'),
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
      const SizedBox(height: 16),
      if (_products != null)
        FutureBuilder<dynamic>(
          future: _products,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Notice('Không thể tải danh sách gói: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _products = BackendApi.request('commerce/museums/$_museumId/products');
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }
            final products = (snapshot.data as List).cast<Map<String, dynamic>>();
            if (products.isEmpty) {
              return const EmptyState(
                title: 'Chưa có gói dịch vụ',
                message: 'Bảo tàng chưa công khai gói vé hoặc dịch vụ thuyết minh nào.',
              );
            }
            return Column(
              children: products.map((p) {
                final kindLabel = switch (p['kind']) {
                  'admission' => 'Vé vào cổng',
                  'digital' => 'Tư liệu số & Thuyết minh',
                  'combo' => 'Gói Trọn gói (Vé + Thuyết minh)',
                  _ => p['kind'].toString(),
                };
                final seats = p['seats'] ?? 1;
                final validityHours = p['validityHours'] ?? 24;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.mutedGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.mutedGold),
                              ),
                              child: Text(
                                kindLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepBurgundy,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${p['price']} ${p['currency']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBurgundy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(p['name'] as String, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 6),
                        Text(
                          'Áp dụng: $seats người · Thời hạn: $validityHours giờ sau thanh toán',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (p['resourceIds'] != null && (p['resourceIds'] as List).isNotEmpty)
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.info_outline, size: 16),
                                  label: const Text('Quyền lợi', style: TextStyle(fontSize: 13)),
                                  onPressed: () => openPage(
                                    context,
                                    ResourceAccessScreen(
                                      museumId: _museumId!,
                                      resourceIds: (p['resourceIds'] as List).cast<int>(),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: 'Xem & Mua gói',
                                icon: Icons.shopping_bag_outlined,
                                onPressed: () => _onSelectProduct(p),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      const SizedBox(height: 12),
      Center(
        child: TextButton.icon(
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Xem danh sách vé & dịch vụ đã mua của tôi'),
          onPressed: () => openPage(context, const PurchasedServicesScreen()),
        ),
      ),
    ],
  );
}

// ============================================================================
// 2. SERVICE CHECKOUT SCREEN: Bước 1 - Xác nhận đơn hàng & Tạo yêu cầu SePay
// ============================================================================
class ServiceCheckoutScreen extends StatefulWidget {
  const ServiceCheckoutScreen({
    super.key,
    required this.museumId,
    required this.product,
  });

  final String museumId;
  final Map<String, dynamic> product;

  @override
  State<ServiceCheckoutScreen> createState() => _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends State<ServiceCheckoutScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: AppServices.auth.user?.name ?? 'Khách tham quan',
  );
  late final TextEditingController _emailController = TextEditingController(
    text: AppServices.auth.user?.email ?? '',
  );
  late final TextEditingController _phoneController = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _proceedToPayment() async {
    if (_busy) return;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên người mua.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // 1. Tạo đơn hàng mới
      final orderData = await BackendApi.request(
        'commerce/orders',
        method: 'POST',
        body: {
          'productId': widget.product['id'],
          'buyerName': _nameController.text.trim(),
          'buyerDetails': {
            'email': _emailController.text.trim(),
            if (_phoneController.text.trim().isNotEmpty)
              'phone': _phoneController.text.trim(),
          },
        },
      );
      final order = Map<String, dynamic>.from(orderData as Map);

      // 2. Khởi tạo thanh toán SePay VietQR
      final paymentData = await BackendApi.request(
        'commerce/orders/${order['id']}/payments/sepay',
        method: 'POST',
        body: {},
      );
      final payment = Map<String, dynamic>.from(paymentData as Map);

      if (!mounted) return;

      // 3. Điều hướng sang màn hình thanh toán VietQR chuyên biệt
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VietQRPaymentScreen(
            order: order,
            payment: payment,
            museumId: widget.museumId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final seats = p['seats'] ?? 1;
    final validityHours = p['validityHours'] ?? 24;

    return MuseumPage(
      back: true,
      title: 'Xác nhận đơn hàng',
      eyebrow: 'Bước 1/2',
      children: [
        if (_error != null) ...[
          Notice(_error!),
          const SizedBox(height: 12),
        ],
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppServices.catalog.museumName(widget.museumId),
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedGold),
              ),
              const SizedBox(height: 6),
              Text(p['name'] as String, style: AppTextStyles.sectionTitle),
              const Divider(height: 24),
              _buildDetailRow('Số người sử dụng:', '$seats người'),
              _buildDetailRow('Thời hạn dịch vụ:', '$validityHours giờ sau thanh toán'),
              _buildDetailRow(
                'Hình thức thanh toán:',
                'Chuyển khoản VietQR tự động (SePay)',
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${p['price']} ${p['currency']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepBurgundy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin người mua', style: AppTextStyles.cardTitle),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email nhận hóa đơn'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại (tùy chọn)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _busy ? 'Đang tạo mã VietQR…' : 'Tiến hành thanh toán VietQR SePay',
          icon: Icons.qr_code_2,
          onPressed: _busy ? null : _proceedToPayment,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. VIETQR PAYMENT SCREEN: Bước 2 - Quét mã SePay, Polling & Đếm ngược
// ============================================================================
class VietQRPaymentScreen extends StatefulWidget {
  const VietQRPaymentScreen({
    super.key,
    required this.order,
    required this.payment,
    required this.museumId,
  });

  final Map<String, dynamic> order;
  final Map<String, dynamic> payment;
  final String museumId;

  @override
  State<VietQRPaymentScreen> createState() => _VietQRPaymentScreenState();
}

class _VietQRPaymentScreenState extends State<VietQRPaymentScreen> {
  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _remainingSeconds = 900; // 15 phút đếm ngược
  bool _checking = false;
  String? _statusNotice;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startAutoPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _pollTimer?.cancel();
        _onTimeout();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _startAutoPolling() {
    // Tự động kiểm tra trạng thái mỗi 3 giây
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPaymentStatus(silent: true);
    });
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_checking) return;
    if (!silent) setState(() => _checking = true);

    try {
      final orderId = widget.order['id'].toString();
      final orders = await BackendApi.list('commerce/orders/me');
      final current = orders.firstWhere(
        (o) => o['id'].toString() == orderId,
        orElse: () => <String, dynamic>{},
      );

      if (current['status'] == 'paid') {
        _countdownTimer?.cancel();
        _pollTimer?.cancel();
        if (!mounted) return;

        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentSuccessScreen(
              order: current,
              museumId: widget.museumId,
            ),
          ),
        );
        return;
      }
    } catch (_) {
      // Bỏ qua lỗi mạng chập chờn khi polling ngầm
    } finally {
      if (mounted && !silent) {
        setState(() {
          _checking = false;
          _statusNotice = 'Chưa ghi nhận biến động số dư. Đang tiếp tục kiểm tra…';
        });
      }
    }
  }

  void _onTimeout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PaymentFailureScreen(
          reason: 'Mã thanh toán VietQR đã hết hạn sau 15 phút. Vui lòng tạo đơn mới.',
          museumId: widget.museumId,
        ),
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Backend trả về qrUrl (hoặc qrCodeUrl nếu có proxy)
    final rawQrUrl = (widget.payment['qrUrl'] ?? widget.payment['qrCodeUrl'] ?? '').toString();
    // Trên môi trường Web, proxy qua Vite /vietqr để vượt rào cản CORS của trình duyệt trên CanvasKit
    final qrUrl = (kIsWeb && rawQrUrl.startsWith('https://vietqr.app'))
        ? rawQrUrl.replaceFirst('https://vietqr.app', '/vietqr')
        : rawQrUrl;
    final bank = widget.payment['bank'] ?? 'TPBank';
    final accountNumber = widget.payment['accountNumber'] ?? '11140845389';
    final accountHolder = widget.payment['accountHolder'] ?? 'NGUYEN DANG KHOA';
    final amount = widget.payment['amount'] ?? widget.order['amount'];
    final currency = widget.payment['currency'] ?? widget.order['currency'] ?? 'VND';
    final transferContent = widget.payment['transferContent'] ?? 'SMGS';

    return MuseumPage(
      back: true,
      title: 'Cổng thanh toán VietQR',
      eyebrow: 'Bước 2/2',
      children: [
        // Đồng hồ đếm ngược
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _remainingSeconds < 180 ? Colors.red.shade100 : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _remainingSeconds < 180 ? Colors.red : AppColors.mutedGold,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: _remainingSeconds < 180 ? Colors.red : AppColors.deepBurgundy,
              ),
              const SizedBox(width: 8),
              Text(
                'Mã QR có hiệu lực trong: ',
                style: TextStyle(
                  fontSize: 13,
                  color: _remainingSeconds < 180 ? Colors.red.shade900 : AppColors.secondaryText,
                ),
              ),
              Text(
                _formatTimer(_remainingSeconds),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _remainingSeconds < 180 ? Colors.red : AppColors.deepBurgundy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Thẻ chứa mã QR SePay
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mutedGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkBrown.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepBurgundy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SEPAY · VIETQR TỰ ĐỘNG',
                  style: TextStyle(
                    color: AppColors.antiqueIvory,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: qrUrl.isNotEmpty
                    ? Image.network(
                        qrUrl,
                        height: 320,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            height: 250,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, _, _) => const Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(
                            Icons.qr_code_2,
                            size: 120,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      )
                    : const Icon(Icons.qr_code_2, size: 120, color: AppColors.darkBrown),
              ),
              const SizedBox(height: 16),
              _buildPaymentDetailRow('Ngân hàng:', bank as String),
              _buildPaymentDetailRow(
                'Số tài khoản:',
                accountNumber as String,
                copyable: true,
                onCopy: () => _copy(accountNumber, 'số tài khoản'),
              ),
              _buildPaymentDetailRow('Chủ tài khoản:', accountHolder as String),
              _buildPaymentDetailRow('Số tiền:', '$amount $currency'),
              _buildPaymentDetailRow(
                'Nội dung CK:',
                transferContent as String,
                highlight: true,
                copyable: true,
                onCopy: () => _copy(transferContent, 'nội dung chuyển khoản'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        const Notice(
          'Mở ứng dụng ngân hàng bất kỳ để quét mã QR, hoặc sao chép chính xác số tài khoản và nội dung chuyển khoản trên.',
        ),

        if (_statusNotice != null) ...[
          const SizedBox(height: 8),
          Text(
            _statusNotice!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedGold, fontStyle: FontStyle.italic),
          ),
        ],

        const SizedBox(height: 16),
        PrimaryButton(
          label: _checking ? 'Đang kiểm tra giao dịch…' : 'Tôi đã chuyển khoản - Kiểm tra ngay',
          icon: Icons.check_circle_outline,
          onPressed: _checking ? null : () => _checkPaymentStatus(silent: false),
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Hủy đơn hàng này',
          onPressed: () {
            final nav = Navigator.of(context);
            showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hủy thanh toán?'),
                content: const Text('Bạn có chắc chắn muốn hủy lượt thanh toán này không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Tiếp tục thanh toán'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Hủy', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ).then((confirmed) {
              if (confirmed == true && mounted) {
                nav.pop();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildPaymentDetailRow(
    String label,
    String value, {
    bool copyable = false,
    bool highlight = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 14 : 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight ? AppColors.deepBurgundy : AppColors.darkBrown,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: AppColors.deepBurgundy),
              tooltip: 'Sao chép',
              onPressed: onCopy,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. PAYMENT SUCCESS SCREEN: Thông báo thành công, Thẻ vé & Chia sẻ nhóm
// ============================================================================
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.order,
    required this.museumId,
  });

  final Map<String, dynamic> order;
  final String museumId;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  String? _groupKey;
  int? _remainingPasses;
  bool _loadingKey = false;
  String? _redeemMsg;

  @override
  void initState() {
    super.initState();
    final seats = widget.order['seats'] ?? 1;
    if (seats > 1) {
      _loadGroupKey();
    }
  }

  Future<void> _loadGroupKey() async {
    setState(() => _loadingKey = true);
    try {
      final res = await BackendApi.request(
        'commerce/orders/${widget.order['id']}/group-key',
        method: 'POST',
        body: {},
      );
      if (mounted) {
        setState(() {
          _groupKey = res['key'] as String?;
          _remainingPasses = res['remaining'] as int?;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingKey = false);
    }
  }

  Future<void> _redeemForSelf() async {
    if (_groupKey == null) return;
    try {
      await BackendApi.request(
        'commerce/passes/redeem',
        method: 'POST',
        body: {'key': _groupKey},
      );
      if (mounted) {
        setState(() => _redeemMsg = 'Đã kích hoạt vé thành công cho tài khoản của bạn!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _redeemMsg = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final seats = o['seats'] ?? 1;

    return MuseumPage(
      back: false,
      title: 'Thanh toán thành công',
      eyebrow: 'Chúc mừng',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade700),
              const SizedBox(height: 12),
              const Text(
                'GIAO DỊCH HOÀN TẤT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dịch vụ của bạn đã được kích hoạt trên toàn hệ thống bảo tàng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin gói dịch vụ', style: AppTextStyles.cardTitle),
              const Divider(height: 20),
              _row('Gói đã mua:', o['productName'] ?? 'Dịch vụ bảo tàng'),
              _row('Số tiền:', '${o['amount']} ${o['currency']}'),
              _row('Mã đơn hàng:', '${o['id']}'),
              _row('Thời hạn:', '${o['validityHours'] ?? 24} giờ'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nếu là gói nhóm nhiều người
        if (seats > 1) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, color: AppColors.deepBurgundy, size: 20),
                    const SizedBox(width: 8),
                    Text('Mã vé nhóm ($seats người)', style: AppTextStyles.cardTitle),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gói này bao gồm quyền tham quan cho nhiều người. Hãy chia sẻ mã nhóm này cho bạn bè đi cùng để họ kích hoạt vé:',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                if (_loadingKey)
                  const Center(child: CircularProgressIndicator())
                else if (_groupKey != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.mutedGold),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _groupKey!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.deepBurgundy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _groupKey!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã sao chép mã nhóm!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_remainingPasses != null) ...[
                    const SizedBox(height: 6),
                    Text('Còn lại: $_remainingPasses lượt nhận vé', style: AppTextStyles.caption),
                  ],
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                    label: const Text('Kích hoạt 1 vé cho tài khoản này ngay'),
                    onPressed: _redeemForSelf,
                  ),
                  if (_redeemMsg != null)
                    Text(
                      _redeemMsg!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _redeemMsg!.contains('thành công') ? Colors.green : Colors.red,
                      ),
                    ),
                ] else ...[
                  TextButton(
                    onPressed: _loadGroupKey,
                    child: const Text('Lấy lại mã nhóm'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        PrimaryButton(
          label: 'Xem vé & Dịch vụ của tôi',
          icon: Icons.confirmation_number_outlined,
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const PurchasedServicesScreen()),
          ),
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Quay về trang khám phá',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. PAYMENT FAILURE SCREEN: Thông báo hết hạn hoặc giao dịch thất bại
// ============================================================================
class PaymentFailureScreen extends StatelessWidget {
  const PaymentFailureScreen({
    super.key,
    required this.reason,
    required this.museumId,
  });

  final String reason;
  final String museumId;

  @override
  Widget build(BuildContext context) {
    return MuseumPage(
      back: true,
      title: 'Chưa hoàn tất thanh toán',
      eyebrow: 'Thông báo',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(
                'THANH TOÁN CHƯA THÀNH CÔNG',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Xem danh sách gói dịch vụ',
          icon: Icons.refresh,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Về trang chủ bảo tàng',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}

// ============================================================================
// 6. PURCHASED SERVICES SCREEN: Quản lý Thẻ vé & Lịch sử đơn hàng của khách
// ============================================================================
class PurchasedServicesScreen extends StatefulWidget {
  const PurchasedServicesScreen({super.key});

  @override
  State<PurchasedServicesScreen> createState() => _PurchasedServicesScreenState();
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
    eyebrow: 'Quản lý vé & Quyền truy cập',
    children: [
      Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Nhập mã tham gia nhóm',
              icon: Icons.key_outlined,
              onPressed: () async {
                final accepted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(builder: (_) => const RedeemPassScreen()),
                );
                if (accepted == true && mounted) setState(() => _data = _fetch());
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.deepBurgundy),
            tooltip: 'Tải lại',
            onPressed: () => setState(() => _data = _fetch()),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          final orders = snapshot.data![0], passes = snapshot.data![1];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeading('Thẻ tham quan & Quyền truy cập số'),
              if (passes.isEmpty)
                const Notice('Bạn chưa có thẻ tham quan nào đang kích hoạt.')
              else
                for (final p in passes)
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: p['isValid'] == true ? Colors.green.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p['isValid'] == true ? 'Đang có hiệu lực' : 'Đã hết hạn/Thu hồi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: p['isValid'] == true ? Colors.green.shade800 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(p['productName'] ?? 'Thẻ bảo tàng', style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text('Hết hạn lúc: ${p['expiresAt'] ?? 'Không giới hạn'}', style: AppTextStyles.caption),
                        SelectableText('Mã thẻ: ${p['id']}', style: AppTextStyles.caption),
                      ],
                    ),
                  ),

              const SizedBox(height: 20),
              const SectionHeading('Lịch sử đơn hàng'),
              if (orders.isEmpty)
                const Notice('Bạn chưa thực hiện đơn đặt mua nào.')
              else
                for (final o in orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(o['productName'] ?? 'Đơn hàng', style: AppTextStyles.cardTitle),
                              Text(
                                '${o['amount']} ${o['currency']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepBurgundy),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Trạng thái: ${backendStatus(o['status'])}', style: AppTextStyles.caption),
                          Text('Mã đơn: ${o['id']}', style: AppTextStyles.caption),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => OrderDetailScreen(orderId: o['id'].toString()),
                                ),
                              );
                              if (mounted) setState(() => _data = _fetch());
                            },
                            child: const Text('Xem chi tiết & Hóa đơn'),
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
