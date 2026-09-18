import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/narration_player.dart';
import '../../services/app_services.dart';
import '../../models/experience.dart';
import '../../data/visit_store.dart';
import '../ai_guide/ai_guide_screen.dart';
import '../tours/tours_screen.dart';
import '../explore/explore_screen.dart';

void openDigitalService(
  BuildContext context,
  PremiumOffer offer,
  String museumId,
) {
  final artifact = AppServices.catalog.inMuseum(museumId).first;
  final Widget page = switch (offer.kind) {
    DigitalServiceKind.guide => AiGuideScreen(artifact: artifact),
    DigitalServiceKind.narration => NarrationScreen(artifact: artifact),
    DigitalServiceKind.tour => ToursScreen(
      standalone: true,
      museumId: museumId,
    ),
    DigitalServiceKind.exhibition => ExploreScreen(
      standalone: true,
      museumId: museumId,
    ),
  };
  openPage(context, page);
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.museumName, this.museumId});
  final String? museumName, museumId;
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late String _museumId =
      widget.museumId ??
      AppServices.catalog.museums
          .firstWhere(
            (m) => m.name == widget.museumName,
            orElse: () => AppServices.catalog.museums.first,
          )
          .id;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Hiểu sâu hơn,\ntrải nghiệm trọn vẹn.',
    eyebrow: 'Dịch vụ số theo ngày',
    subtitle: AppServices.catalog.museums
        .firstWhere((m) => m.id == _museumId)
        .name,
    children: [
      const Notice(
        'Dịch vụ số được cung cấp riêng. Bản trải nghiệm chỉ dùng giá minh họa và thanh toán mô phỏng.',
      ),
      const SizedBox(height: 20),
      if (widget.museumId == null && widget.museumName == null) ...[
        DropdownButtonFormField<String>(
          initialValue: _museumId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Chọn bảo tàng'),
          items: AppServices.catalog.museums
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(
                    m.name,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _museumId = v!),
        ),
        const SizedBox(height: 20),
      ],
      for (final offer in AppServices.premium.offers)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Panel(
            gold: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.mutedGold,
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Eyebrow('Dịch vụ nâng cao')),
                  ],
                ),
                const SizedBox(height: 16),
                Text(offer.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 12),
                Text(offer.description, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 18),
                Text(
                  '${vietnamesePrice(offer.price)} / ngày',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                const Text('Giá minh họa', style: AppTextStyles.caption),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Chọn dịch vụ',
                  icon: Icons.arrow_forward,
                  onPressed: () => openPage(
                    context,
                    ServiceCheckoutScreen(offer: offer, museumId: _museumId),
                  ),
                ),
              ],
            ),
          ),
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
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String? _method;
  bool _success = true, _busy = false;
  String? _error;
  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Chọn ngày sử dụng',
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pay() async {
    if (_busy ||
        _method == null ||
        VisitStore.instance.hasPurchase(
          widget.offer.id,
          widget.museumId,
          _date,
        )) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final success = await AppServices.payment.pay(simulateSuccess: _success);
      if (!mounted) return;
      if (success) {
        VisitStore.instance.activate(
          ServicePurchase(
            id: 'purchase-${DateTime.now().microsecondsSinceEpoch}',
            offer: widget.offer,
            museumId: widget.museumId,
            date: _date,
            method: _method!,
          ),
        );
      }
      setState(() => _busy = false);
      openPage(
        context,
        PaymentResultScreen(
          success: success,
          offer: widget.offer,
          museumId: widget.museumId,
          date: _date,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Chưa xử lý được thanh toán mô phỏng. Bạn hãy thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: VisitStore.instance,
    builder: (context, _) {
      final activated = VisitStore.instance.hasPurchase(
        widget.offer.id,
        widget.museumId,
        _date,
      );
      return MuseumPage(
        back: true,
        title: 'Dành riêng\ncho chuyến đi.',
        eyebrow: 'Xác nhận dịch vụ',
        subtitle: AppServices.catalog.museums
            .firstWhere((m) => m.id == widget.museumId)
            .name,
        children: [
          Panel(
            gold: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.offer.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                Text(widget.offer.description, style: AppTextStyles.bodyMedium),
                const Divider(),
                Text(
                  'Tổng cộng: ${vietnamesePrice(widget.offer.price)}',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Giá minh họa cho một ngày sử dụng.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SectionHeading('Ngày bạn muốn sử dụng'),
          SecondaryButton(
            label: vietnameseDate(_date),
            icon: Icons.calendar_today_outlined,
            onPressed: _busy ? null : _pickDate,
          ),
          const SectionHeading('Phương thức thanh toán'),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: ['VNPay', 'MoMo']
                .map(
                  (method) => ChoiceChip(
                    label: Text(method),
                    selected: _method == method,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _method = method),
                    checkmarkColor: AppColors.antiqueIvory,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      color: _method == method
                          ? AppColors.antiqueIvory
                          : AppColors.darkBrown,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Thử luồng thanh toán'),
                const SizedBox(height: 10),
                const Text(
                  'Chọn kết quả mô phỏng. Không có tiền được thu và không kết nối cổng thanh toán.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [true, false]
                      .map(
                        (value) => ChoiceChip(
                          label: Text(value ? 'Thành công' : 'Thất bại'),
                          selected: _success == value,
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _success = value),
                          checkmarkColor: AppColors.antiqueIvory,
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: _success == value
                                ? AppColors.antiqueIvory
                                : AppColors.darkBrown,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 16), Notice(_error!)],
          const SizedBox(height: 24),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
            ),
          if (activated)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Notice(
                'Dịch vụ đã được đăng ký cho ngày này trong bản trải nghiệm.',
              ),
            ),
          PrimaryButton(
            label: _busy
                ? 'Đang xử lý mô phỏng…'
                : activated
                ? 'Đã đăng ký ngày này'
                : 'Xác nhận thanh toán mô phỏng',
            icon: Icons.lock_outline,
            onPressed: _busy || _method == null || activated ? null : _pay,
          ),
          if (_method == null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Chọn VNPay hoặc MoMo để tiếp tục.',
                style: AppTextStyles.caption,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy đăng ký dịch vụ'),
          ),
        ],
      );
    },
  );
}

class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.offer,
    required this.museumId,
    required this.date,
  });
  final bool success;
  final PremiumOffer offer;
  final String museumId;
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    final today = DateUtils.isSameDay(date, DateTime.now());
    return MuseumPage(
      back: true,
      title: success ? 'Đã đăng ký dịch vụ' : 'Thanh toán chưa thành công',
      eyebrow: 'Kết quả mô phỏng',
      children: [
        Panel(
          gold: success,
          child: Column(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                size: 62,
                color: AppColors.deepBurgundy,
              ),
              const SizedBox(height: 20),
              Text(
                offer.name,
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'Ngày sử dụng: ${vietnameseDate(date)}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                success
                    ? 'Quyền sử dụng mẫu đã được ghi nhận cho bảo tàng và ngày đã chọn.'
                    : 'Giao dịch mô phỏng thất bại. Dịch vụ chưa được kích hoạt.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Notice('Đây là kết quả mô phỏng. Không có tiền được thu.'),
        const SizedBox(height: 24),
        if (success) ...[
          if (today)
            PrimaryButton(
              label: 'Bắt đầu sử dụng dịch vụ',
              icon: Icons.arrow_forward,
              onPressed: () => openDigitalService(context, offer, museumId),
            )
          else
            const Notice(
              'Dịch vụ được đăng ký cho một ngày khác. Xem lại ngày sử dụng trong sổ tay.',
            ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Xem dịch vụ đã đăng ký',
            icon: Icons.receipt_long_outlined,
            onPressed: () => openPage(context, const PurchasedServicesScreen()),
          ),
        ] else
          PrimaryButton(
            label: 'Thử thanh toán lại',
            icon: Icons.refresh,
            onPressed: () => Navigator.pop(context),
          ),
      ],
    );
  }
}

class PurchasedServicesScreen extends StatelessWidget {
  const PurchasedServicesScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: VisitStore.instance,
    builder: (context, _) => MuseumPage(
      back: true,
      title: 'Dịch vụ của bạn',
      eyebrow: 'Sổ tay trải nghiệm',
      children: [
        if (VisitStore.instance.purchases.isEmpty) ...[
          const EmptyState(
            title: 'Chưa có dịch vụ nào',
            message: 'Những dịch vụ bạn đăng ký trong bản trải nghiệm sẽ xuất hiện ở đây.',
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Khám phá dịch vụ số',
            onPressed: () => openPage(context, const ServicesScreen()),
          ),
        ],
        for (final purchase in VisitStore.instance.purchases)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Panel(
              gold: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Đăng ký mô phỏng'),
                  const SizedBox(height: 12),
                  Text(purchase.offer.name, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 10),
                  Text(
                    AppServices.catalog.museums
                        .firstWhere((m) => m.id == purchase.museumId)
                        .name,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${vietnameseDate(purchase.date)} · ${vietnamesePrice(purchase.offer.price)} · ${purchase.method}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: purchase.isForDay(DateTime.now())
                        ? 'Sử dụng dịch vụ'
                        : purchase.date.isBefore(
                            DateUtils.dateOnly(DateTime.now()),
                          )
                        ? 'Đã hết ngày sử dụng'
                        : 'Chưa đến ngày sử dụng',
                    onPressed: purchase.isForDay(DateTime.now())
                        ? () => openDigitalService(
                            context,
                            purchase.offer,
                            purchase.museumId,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
