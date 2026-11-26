import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/experience.dart';
import '../../models/museum.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import 'order_detail_screen.dart';

// ============================================================================
// 1. SERVICES HUB & ADAPTERS
// ============================================================================

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, this.museumName, this.museumId});
  final String? museumName, museumId;

  @override
  Widget build(BuildContext context) => ServicesHubScreen(
        initialTab: 0,
        museumName: museumName,
        museumId: museumId,
      );
}

class PurchasedServicesScreen extends StatelessWidget {
  const PurchasedServicesScreen({super.key});

  @override
  Widget build(BuildContext context) => const ServicesHubScreen(
        initialTab: 1,
      );
}

class ServicesHubScreen extends StatefulWidget {
  const ServicesHubScreen({
    super.key,
    this.initialTab = 0,
    this.museumName,
    this.museumId,
  });

  final int initialTab;
  final String? museumName, museumId;

  @override
  State<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends State<ServicesHubScreen> {
  late int _activeTab = widget.initialTab;
  String? _museumId;
  List<Museum> _museums = [];
  bool _loadingMuseums = true;
  Future<dynamic>? _products;
  Future<List<List<Map<String, dynamic>>>>? _passesOrdersData;
  Future<Map<String, dynamic>?>? _walletData;

  @override
  void initState() {
    super.initState();
    _museumId = widget.museumId;
    if (_activeTab == 0) {
      _initCatalogAndProducts();
    } else {
      _refreshPassesAndOrders();
    }
  }

  Future<void> _initCatalogAndProducts() async {
    try {
      if (AppServices.catalog.museums.isEmpty) {
        await AppServices.catalog.load();
      }
    } catch (_) {}

    var list = AppServices.catalog.museums;
    if (list.isEmpty) {
      try {
        final raw = await BackendApi.list('museums');
        list = raw.map(Museum.fromBackendJson).toList();
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _museums = list;
      _loadingMuseums = false;
      if (_museumId == null && _museums.isNotEmpty) {
        if (widget.museumName != null) {
          _museumId = _museums.where((m) => m.name == widget.museumName).firstOrNull?.id ?? _museums.first.id;
        } else {
          _museumId = _museums.first.id;
        }
      }
      if (_activeTab == 0 && _museumId != null) {
        _products = BackendApi.request('commerce/museums/$_museumId/products');
      }
    });
  }

  void _selectTab(int tab) {
    if (tab == _activeTab) return;
    setState(() => _activeTab = tab);
    if (tab == 0 && _products == null) {
      _initCatalogAndProducts();
    } else if (tab == 1 && _passesOrdersData == null) {
      _refreshPassesAndOrders();
    }
  }
  void _onSelectMuseum(String? id) {
    if (id == null || id == _museumId) return;
    setState(() {
      _museumId = id;
      _products = BackendApi.request('commerce/museums/$id/products');
    });
  }

  void _refreshPassesAndOrders() {
    setState(() {
      _passesOrdersData = Future.wait([
        BackendApi.list('commerce/orders/me'),
        BackendApi.list('commerce/passes/me'),
      ]);
      _walletData = BackendApi.request('commerce/wallet/me')
          .then((v) => v is Map<String, dynamic> ? v : Map<String, dynamic>.from(v as Map))
          .catchError((_) => <String, dynamic>{});
    });
  }

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
        museumId: _museumId ?? '1',
        product: product,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MuseumPage(
      back: true,
      title: _activeTab == 0 ? 'Vé & Gói dịch vụ' : 'Dịch vụ của tôi',
      eyebrow: 'Quản lý vé & đơn hàng',
      children: [
        // Tab Segmented Selector
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _activeTab == 0 ? AppColors.deepBurgundy : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Gói dịch vụ đang bán',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 0 ? AppColors.antiqueIvory : AppColors.darkBrown,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _activeTab == 1 ? AppColors.deepBurgundy : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Vé & Đơn của tôi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 1 ? AppColors.antiqueIvory : AppColors.darkBrown,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        KeyedSubtree(
          key: ValueKey<int>(_activeTab),
          child: _activeTab == 0 ? _buildShopTab() : _buildMyPassesTab(),
        ),
      ],
    );
  }

  Widget _buildShopTab() {
    if (_loadingMuseums) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.deepBurgundy),
              SizedBox(height: 12),
              Text('Đang tải danh sách bảo tàng…', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_museums.isEmpty) {
      return Column(
        children: [
          const Notice('Chưa có bảo tàng công khai trên hệ thống.'),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
            onPressed: _initCatalogAndProducts,
          ),
        ],
      );
    }

    final safeValue = _museumId != null && _museums.any((m) => m.id == _museumId) ? _museumId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Chọn bảo tàng'),
          items: _museums
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _onSelectMuseum,
        ),
        const SizedBox(height: 16),
        if (_products != null)
          FutureBuilder<dynamic>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.deepBurgundy)),
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
              final raw = snapshot.data;
              final products = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
              if (products.isEmpty) {
                return const EmptyState(
                  title: 'Chưa có gói dịch vụ',
                  message: 'Bảo tàng này chưa mở bán gói dịch vụ số hoặc vé tham quan nào.',
                );
              }
              return Column(
                children: products.map((p) {
                  final kindLabel = p['kind'] == 'digital'
                      ? 'Tư liệu số & Thuyết minh'
                      : (p['kind']?.toString() ?? 'Dịch vụ số');
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
                                '${p['price']} ${p['currency'] ?? 'VND'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepBurgundy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(p['name'] as String? ?? 'Gói dịch vụ', style: AppTextStyles.cardTitle),
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
                                        museumId: _museumId ?? '1',
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
      ],
    );
  }

  Widget _buildMyPassesTab() {
    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: _passesOrdersData,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.deepBurgundy)),
          );
        }
        if (snapshot.hasError) return Notice(snapshot.error.toString());
        final orders = snapshot.data![0], passes = snapshot.data![1];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ hiển thị số dư Ví điện tử SMGS
            FutureBuilder<Map<String, dynamic>?>(
              future: _walletData,
              builder: (ctx, snap) {
                final wallet = snap.data;
                final balances = wallet?['balances'] as List?;
                final vnd = balances?.firstWhere((b) => b['currency'] == 'VND', orElse: () => null);
                final amount = (vnd?['amount'] as num?)?.toDouble() ?? 0.0;
                final amountStr = amount.toStringAsFixed(0).replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (m) => '${m[1]}.',
                    );

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(VisitorRadius.lg),
                    border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.mutedGold.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.deepBurgundy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ví điện tử của tôi',
                              style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$amountStr VND',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBurgundy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Text(
                          'Ưu tiên trừ trước',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Header Thẻ tham quan & Nút Nhập mã nhóm tinh gọn
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SectionHeading('Thẻ tham quan hiện tại'),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.deepBurgundy,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.key_outlined, size: 15),
                  label: const Text(
                    'Nhập mã nhóm',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final accepted = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(builder: (_) => const RedeemPassScreen()),
                    );
                    if (accepted == true && mounted) _refreshPassesAndOrders();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (passes.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(VisitorRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 28, color: AppColors.mutedGold),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Bạn chưa có thẻ tham quan nào đang kích hoạt.',
                        style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final p in passes)
                _buildPassCard(p),

            const SizedBox(height: 24),

            // Header Lịch sử đơn hàng & Nút Tải lại tinh gọn
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SectionHeading('Lịch sử đơn hàng'),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: AppColors.deepBurgundy),
                  tooltip: 'Tải lại',
                  onPressed: _refreshPassesAndOrders,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (orders.isEmpty)
              const Notice('Bạn chưa thực hiện đơn đặt mua nào.')
            else
              for (final o in orders)
                _buildOrderCard(o),
          ],
        );
      },
    );
  }

  Widget _buildPassCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(
          color: p['isValid'] == true
              ? AppColors.mutedGold.withValues(alpha: 0.6)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 18,
                      color: p['isValid'] == true
                          ? AppColors.deepBurgundy
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'VÉ THAM QUAN ĐIỆN TỬ',
                      style: TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p['isValid'] == true ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: p['isValid'] == true ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    p['isValid'] == true ? 'Đang có hiệu lực' : 'Hết hiệu lực',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: p['isValid'] == true ? const Color(0xFF2E7D32) : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.border),
            Text(
              p['productName'] ?? 'Thẻ bảo tàng',
              style: const TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hết hạn: ${p['expiresAt'] ?? 'Không giới hạn'}',
              style: const TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.antiqueIvory,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                'Mã thẻ: #${p['id']}',
                style: const TextStyle(
                  fontFamily: AppTextStyles.sansFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.antiqueIvory,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: AppColors.deepBurgundy,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o['productName'] ?? 'Đơn hàng',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Mã đơn: #${o['id']} · ${backendStatus(o['status'])}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${o['amount']} ${o['currency']}',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBurgundy,
                  ),
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.border),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderDetailScreen(orderId: o['id'].toString()),
                    ),
                  );
                  if (mounted) _refreshPassesAndOrders();
                },
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Xem chi tiết & Hóa đơn', style: TextStyle(fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deepBurgundy,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. SERVICE CHECKOUT SCREEN: Bước 1 - Xác nhận đơn hàng & Tạo yêu cầu SePay
// ============================================================================
class ServiceCheckoutScreen extends StatefulWidget {
  const ServiceCheckoutScreen({
    super.key,
    required this.museumId,
    this.product = const {},
    this.offer,
  });

  final String museumId;
  final Map<String, dynamic> product;
  final dynamic offer;

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

  DateTime _visitDate = DateTime.now();
  double _walletBalance = 0.0;
  bool _loadingWallet = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _order, _payment;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final res = await BackendApi.request('commerce/wallet/me');
      if (!mounted || res is! Map) return;
      final balances = res['balances'] as List?;
      final vnd = balances?.firstWhere((b) => b['currency'] == 'VND', orElse: () => null);
      if (vnd != null && mounted) {
        setState(() {
          _walletBalance = (vnd['amount'] as num?)?.toDouble() ?? 0.0;
          _loadingWallet = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingWallet = false);
    }
  }

  Map<String, dynamic> get _effectiveProduct {
    if (widget.product.isNotEmpty) return widget.product;
    final item = widget.offer;
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    if (item is PremiumOffer) {
      return {
        'id': item.id,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'currency': 'VND',
        'kind': 'digital',
      };
    }
    return const {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _proceedToPayment() async {
    if (_busy) return;
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (AppServices.auth.user?.name ?? 'Khách tham quan');
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (AppServices.auth.user?.email ?? '');

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final p = _effectiveProduct;
      final rawId = p['id'];
      final productId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? rawId;
      final visitDateStr = "${_visitDate.year.toString().padLeft(4, '0')}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}";

      // 1. Tạo đơn hàng mới (hoặc tái sử dụng đơn chưa hoàn tất thanh toán)
      final order = _order ??
          Map<String, dynamic>.from(
            await BackendApi.request(
              'commerce/orders',
              method: 'POST',
              body: {
                'productId': productId,
                'visitDate': visitDateStr,
                'buyerName': name,
                'buyerDetails': {
                  'email': email,
                  if (_phoneController.text.trim().isNotEmpty)
                    'phone': _phoneController.text.trim(),
                },
              },
            ) as Map,
          );
      if (!mounted) return;
      setState(() => _order = order);

      // 2. Khởi tạo thanh toán ưu tiên ví SePay
      final paymentData = await BackendApi.request(
        'commerce/orders/${order['id']}/payments/sepay',
        method: 'POST',
        body: {},
      );
      final payment = Map<String, dynamic>.from(paymentData as Map);

      if (!mounted) return;
      setState(() => _payment = payment);

      // 3. Xử lý trường hợp đã thanh toán xong bằng ví (paidFromWallet: true hoặc status: 'succeeded')
      final isPaidFromWallet = payment['paidFromWallet'] == true ||
          (payment['status'] == 'succeeded' &&
              (payment['qrUrl'] == null || payment['qrUrl'].toString().isEmpty));

      if (isPaidFromWallet) {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentSuccessScreen(
              order: {
                ...order,
                'status': 'paid',
              },
              museumId: widget.museumId,
            ),
          ),
        );
        return;
      }

      // 4. Điều hướng sang màn hình thanh toán VietQR chuyên biệt nếu có qrUrl
      final qr = (payment['qrUrl'] ?? payment['qrCodeUrl'] ?? '').toString();
      if (qr.isNotEmpty) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => VietQRPaymentScreen(
              order: order,
              payment: payment,
              museumId: widget.museumId,
            ),
          ),
        );
      }
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
    final p = _effectiveProduct;
    final seats = p['seats'] ?? 1;
    final validityHours = p['validityHours'] ?? 24;

    return MuseumPage(
      back: true,
      title: 'Xác nhận đơn hàng',
      eyebrow: 'Bước 1/2',
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppServices.catalog.museumName(widget.museumId),
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedGold),
              ),
              const SizedBox(height: 6),
              Text(p['name']?.toString() ?? 'Dịch vụ bảo tàng', style: AppTextStyles.sectionTitle),
              const Divider(height: 24),
              _buildDetailRow('Số người sử dụng:', '$seats người'),
              _buildDetailRow('Thời hạn dịch vụ:', '$validityHours giờ sau thanh toán'),
              const SizedBox(height: 10),

              // Bộ chọn ngày tham quan
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _visitDate.isBefore(now) ? now : _visitDate,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: now.add(const Duration(days: 365)),
                    helpText: 'CHỌN NGÀY THAM QUAN',
                    cancelText: 'HỦY',
                    confirmText: 'CHỌN NGÀY',
                  );
                  if (picked != null && mounted) {
                    setState(() => _visitDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.antiqueIvory,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.mutedGold),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.deepBurgundy),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ngày tham quan:', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                            const SizedBox(height: 2),
                            Text(
                              '${_visitDate.day.toString().padLeft(2, '0')}/${_visitDate.month.toString().padLeft(2, '0')}/${_visitDate.year}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text('Đổi ngày', textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepBurgundy)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.deepBurgundy),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _buildDetailRow(
                'Hình thức thanh toán:',
                'Ưu tiên Ví · VietQR tự động (SePay)',
              ),
              const Divider(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${p['price'] ?? 0} ${p['currency'] ?? 'VND'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepBurgundy,
                    ),
                  ),
                ],
              ),

              // Banner thông tin Ví nếu có số dư
              if (_walletBalance > 0)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFAED581)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 22, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                const Text('Số dư ví khả dụng:', style: TextStyle(fontSize: 12, color: Color(0xFF33691E))),
                                Text(
                                  '${_walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} VND',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _walletBalance >= (p['price'] ?? 0)
                                  ? '✓ Ví của bạn đủ để thanh toán 100% đơn hàng ngay lập tức!'
                                  : '✓ Hệ thống sẽ tự động trừ ví trước, chỉ cần quét mã QR cho số tiền còn thiếu.',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
        const SizedBox(height: 16),
        if (_error != null) ...[
          Notice(_error!),
          const SizedBox(height: 12),
        ],
        if (_payment != null) ...[
          Notice(
            'Yêu cầu thanh toán: ${_payment!['status']}. Chờ xác nhận từ hệ thống; ứng dụng chưa kích hoạt dịch vụ.',
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          label: _busy
              ? 'Đang gửi…'
              : _walletBalance >= (p['price'] ?? 0)
                  ? 'Thanh toán ngay bằng ví'
                  : _order == null
                      ? 'Tạo đơn và yêu cầu thanh toán'
                      : 'Thử lại yêu cầu thanh toán',
          icon: _walletBalance >= (p['price'] ?? 0) ? Icons.account_balance_wallet_outlined : Icons.qr_code_2,
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
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
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
    String qrUrl = rawQrUrl;
    if (kIsWeb && rawQrUrl.startsWith('https://vietqr.app')) {
      final proxied = rawQrUrl.replaceFirst('https://vietqr.app', '/vietqr');
      qrUrl = Uri.base.resolve(proxied).toString();
    }
    final bank = widget.payment['bank'] ?? 'TPBank';
    final accountNumber = widget.payment['accountNumber'] ?? '11140845389';
    final transferContent = widget.payment['transferContent'] ?? 'SMGS';

    final orderAmount = (widget.order['amount'] as num?)?.toDouble() ?? 0.0;
    final dueAmount = (widget.payment['amount'] as num?)?.toDouble() ?? orderAmount;
    final currency = widget.payment['currency']?.toString() ?? widget.order['currency']?.toString() ?? 'VND';
    final walletPaid = orderAmount > dueAmount ? (orderAmount - dueAmount) : 0.0;

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

        if (walletPaid > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng đơn hàng:', style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText)),
                    Text('${orderAmount.toStringAsFixed(0)} $currency', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đã khấu trừ từ ví:', style: TextStyle(fontSize: 12.5, color: Color(0xFF2E7D32))),
                    Text('-${walletPaid.toStringAsFixed(0)} $currency', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cần chuyển khoản VietQR:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.deepBurgundy)),
                    Text('${dueAmount.toStringAsFixed(0)} $currency', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.deepBurgundy)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Thẻ chứa mã QR SePay (Phương án 1: Giữ Poster VietQR + 2 nút Quick-Copy 1 chạm)
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
                borderRadius: BorderRadius.circular(VisitorRadius.md),
                child: qrUrl.isNotEmpty
                    ? Image.network(
                        qrUrl,
                        height: 330,
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
              const SizedBox(height: 14),

              // Dẫn hướng sao chép nhanh
              Row(
                children: [
                  Icon(Icons.touch_app_outlined, size: 15, color: AppColors.mutedGold),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Chạm để sao chép nhanh thông tin thanh toán:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick-Copy Pill: Số tiền
              _buildQuickCopyPill(
                icon: Icons.payments_outlined,
                label: 'Số tiền chuyển khoản',
                value: '${dueAmount.toStringAsFixed(0)} $currency',
                onCopy: () => _copy(dueAmount.toStringAsFixed(0), 'số tiền chuyển khoản'),
              ),

              // Quick-Copy Pill: STK
              _buildQuickCopyPill(
                icon: Icons.credit_card_outlined,
                label: 'Số tài khoản ($bank)',
                value: accountNumber as String,
                onCopy: () => _copy(accountNumber, 'số tài khoản'),
              ),

              // Quick-Copy Pill: Nội dung CK (Bắt buộc chính xác)
              _buildQuickCopyPill(
                icon: Icons.receipt_long_outlined,
                label: 'Nội dung chuyển khoản (bắt buộc chính xác)',
                value: transferContent as String,
                highlight: true,
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
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hủy đơn hàng?'),
                content: const Text(
                  'Bạn có chắc chắn muốn hủy đơn hàng này không? Bất kỳ khoản tiền nào đã cấn trừ từ ví cho đơn hàng này sẽ được hoàn trả lại vào ví của bạn.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Tiếp tục thanh toán'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ).then((confirmed) async {
              if (confirmed == true && mounted) {
                final orderId = widget.order['id'].toString();
                try {
                  final res = await BackendApi.request(
                    'commerce/orders/$orderId/cancel',
                    method: 'POST',
                  );
                  final msg = res is Map ? res['message']?.toString() ?? 'Đã hủy đơn hàng.' : 'Đã hủy đơn hàng.';
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg)));
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text('Không thể hủy đơn: $e')));
                }
                nav.pop();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuickCopyPill({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(VisitorRadius.md),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? AppColors.antiqueIvory : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(VisitorRadius.md),
          border: Border.all(
            color: highlight ? AppColors.mutedGold : Colors.grey.shade300,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: highlight ? AppColors.deepBurgundy : AppColors.darkBrown,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: highlight ? 'monospace' : null,
                      color: highlight ? AppColors.deepBurgundy : AppColors.darkBrown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: highlight
                    ? AppColors.deepBurgundy
                    : AppColors.darkBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: highlight ? AppColors.antiqueIvory : AppColors.darkBrown,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sao chép',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: highlight ? AppColors.antiqueIvory : AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
