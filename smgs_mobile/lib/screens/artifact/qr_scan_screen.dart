import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../services/app_services.dart';
import '../../models/artifact.dart';
import '../../data/visit_store.dart';
import '../explore/explore_screen.dart';
import 'artifact_detail_screen.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({
    super.key,
    this.recognition = false,
    this.museumId = 'museum_national',
  });
  final bool recognition;
  final String museumId;
  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _busy = false, _done = false, _flash = false, _noMatch = false;
  Artifact? _match;
  String? _error;
  Future<void> _scan() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _done = false;
      _error = null;
    });
    try {
      final result = await AppServices.recognition.recognize(
        widget.museumId,
        match: !_noMatch,
      );
      if (!mounted) return;
      setState(() {
        _match = result;
        _busy = false;
        _done = true;
      });
      if (!widget.recognition && result != null) {
        VisitStore.instance.visit(result);
        _open(result);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error =
              'Chưa thể xử lý. Bạn hãy thử lại hoặc mở danh sách hiện vật.';
        });
      }
    }
  }

  void _open(Artifact a) => openPage(
    context,
    ArtifactDetailScreen(
      artifact: a,
      museumName: AppServices.catalog.museums
          .firstWhere((m) => m.id == a.museumId)
          .name,
    ),
  );
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: widget.recognition ? 'Nhận diện hiện vật' : 'Quét mã hiện vật',
    eyebrow: 'Khám phá tại bảo tàng',
    subtitle: AppServices.catalog.museums
        .firstWhere((m) => m.id == widget.museumId)
        .name,
    children: [
      AnimatedContainer(
        duration: reduceHeritageMotion(context)
            ? Duration.zero
            : HeritageMotion.standard,
        curve: HeritageMotion.curve,
        height: 260,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.darkBrown,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedContainer(
          duration: reduceHeritageMotion(context)
              ? Duration.zero
              : HeritageMotion.fast,
          decoration: BoxDecoration(
            border: Border.all(
              color: _flash ? AppColors.antiqueIvory : AppColors.mutedGold,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.recognition
                    ? Icons.camera_alt_outlined
                    : Icons.qr_code_scanner,
                size: 64,
                color: AppColors.antiqueIvory,
              ),
              const SizedBox(height: 20),
              Text(
                _busy ? 'Đang phân tích hiện vật…' : 'Khung mô phỏng',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.antiqueIvory,
                ),
                textAlign: TextAlign.center,
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Notice('Trải nghiệm mô phỏng trên web, không sử dụng máy ảnh.'),
      const SizedBox(height: 16),
      if (!widget.recognition)
        SecondaryButton(
          label: _flash ? 'Tắt đèn mô phỏng' : 'Bật đèn mô phỏng',
          icon: _flash ? Icons.flash_on : Icons.flash_off,
          onPressed: _busy ? null : () => setState(() => _flash = !_flash),
        ),
      if (widget.recognition && !_done)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Thử tình huống không tìm thấy',
            style: AppTextStyles.bodyMedium,
          ),
          value: _noMatch,
          onChanged: _busy ? null : (v) => setState(() => _noMatch = v),
        ),
      const SizedBox(height: 16),
      if (_error != null) ...[Notice(_error!), const SizedBox(height: 16)],
      if (_done && _match != null) ...[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Kết quả mẫu phù hợp'),
              const SizedBox(height: 12),
              Text(_match!.name, style: AppTextStyles.cardTitle),
              const SizedBox(height: 8),
              Text(_match!.location, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Xem hiện vật',
          icon: Icons.arrow_forward,
          onPressed: () => _open(_match!),
        ),
        const SizedBox(height: 12),
      ],
      if (_done && _match == null) ...[
        const EmptyState(
          title: 'Chưa tìm thấy hiện vật',
          message: 'Hãy thử lại hoặc tra cứu trong bộ sưu tập của bảo tàng.',
        ),
        const SizedBox(height: 16),
      ],
      if (!_done)
        PrimaryButton(
          label: _busy
              ? 'Đang xử lý…'
              : widget.recognition
              ? 'Nhận diện mô phỏng'
              : 'Quét mã mô phỏng',
          icon: widget.recognition
              ? Icons.camera_alt_outlined
              : Icons.qr_code_scanner,
          onPressed: _busy ? null : _scan,
        )
      else
        SecondaryButton(
          label: 'Thử lại',
          onPressed: () => setState(() {
            _done = false;
            _match = null;
            _noMatch = false;
          }),
        ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Tra cứu danh sách',
        icon: Icons.search_outlined,
        onPressed: () => openPage(
          context,
          ExploreScreen(standalone: true, museumId: widget.museumId),
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy và quay lại'),
      ),
    ],
  );
}
