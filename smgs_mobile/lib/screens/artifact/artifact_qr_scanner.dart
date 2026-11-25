import '../../core/localization/app_localizations.dart';
import 'qr_scan_screen.dart';
import '../../widgets/exploration_map_button.dart';
import '../../widgets/earned_badges.dart';
import '../../services/visitor_experience_api.dart';
import '../../services/museum_presence_api.dart';
import '../museum/visitor_directory_screen.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';
import '../../widgets/backend_panel.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../services/artifact_scan_service.dart';
import '../../services/vision_api_service.dart';
import '../../services/discovery_api_service.dart';
import '../../models/artifact.dart';
import '../../widgets/museum_ui.dart';
import 'artifact_detail_screen.dart';

class ArtifactQrScanner extends StatefulWidget {
  const ArtifactQrScanner({
    super.key,
    this.visitId,
    this.direct = false,
    this.standalone = false,
  });
  final int? visitId;
  final bool direct;
  final bool standalone;
  @override
  State<ArtifactQrScanner> createState() => _ArtifactQrScannerState();
}

class _ArtifactQrScannerState extends State<ArtifactQrScanner>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  late bool _camera = widget.direct;
  bool _busy = false;
  String? _error;
  late int? _visitId =
      widget.visitId ??
      (widget.standalone ? null : VisitorSession.activeVisit?['id'] as int?);
  ScanRequest? _scanRequest;

  // Mode: 'qr' or 'vision'
  String _activeMode = 'qr';
  VisionMatchResult? _visionResult;
  Artifact? _matchedArtifact;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  late final AnimationController _scannerAnim;

  @override
  void initState() {
    super.initState();
    _scannerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _scannerAnim.repeat(reverse: true);
    } else {
      _scannerAnim.value = 0.5;
    }
  }

  @override
  void dispose() {
    _scannerAnim.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _scan(String value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _camera = false;
      _error = null;
    });
    try {
      if (MuseumPresenceApi.isCheckpoint(value)) {
        final result = await MuseumPresenceApi.scan(value);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'VisitorDirectoryScreen'),
            builder: (_) => VisitorDirectoryScreen(
              museumId: result['museumId'],
              initialMapId: result['mapId'],
              museumName: 'Vị trí vừa xác nhận',
              visitId:
                  VisitorSession.activeVisit?['museumId'] == result['museumId']
                  ? _visitId
                  : null,
            ),
          ),
        );
        return;
      }
      final code = ArtifactScanService.extractCode(value);
      if (_scanRequest?.code != code || _scanRequest?.visitId != _visitId) {
        _scanRequest = ScanRequest(code, visitId: _visitId);
      }
      final request = _scanRequest!;
      final data = await ArtifactScanService.scan(code);
      final exploration = MuseumExploration.instance;
      final scannedMuseum = int.tryParse(data['museumId'].toString());
      if (!mounted) return;
      if (exploration.museumId != null &&
          scannedMuseum != null &&
          exploration.museumId != scannedMuseum) {
        final change = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('QR thuộc bảo tàng khác'),
            content: Text(
              'Chuyển sang khám phá ${data['museumName'] ?? 'bảo tàng này'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Chuyển bảo tàng'),
              ),
            ],
          ),
        );
        if (!mounted || change != true) return;
        await exploration.select(scannedMuseum);
      }
      final recognition = await request.record();
      _scanRequest = null;
      if (mounted) showExplorationRewards(context, recognition);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArtifactDetailScreen(
            artifact: Artifact.fromBackendJson(data),
            museumName: data['museumName'] as String? ?? 'Bảo tàng',
          ),
        ),
      );
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Máy chủ phản hồi chậm. Vui lòng thử lại.');
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runVisionRecognition(
    Uint8List imageBytes,
    String filename,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
      _visionResult = null;
      _matchedArtifact = null;
      _selectedImageBytes = imageBytes;
      _selectedImageName = filename;
    });

    try {
      final result = await VisionApiService.recognizeArtifact(
        imageBytes,
        filename: filename,
      );
      _visionResult = result;

      if (result.matched && result.artifactId != null) {
        // Fetch detailed artifact data from backend
        try {
          final detail = await DiscoveryApiService.fetchArtifactDetail(
            result.artifactId!,
          );
          _matchedArtifact = Artifact.fromBackendJson(detail);
        } catch (_) {}
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _error = msg.startsWith('Dịch vụ AI')
          ? msg
          : 'Dịch vụ AI Vision (Port 8001): $msg';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final picked = await pickImageFromDevice(useCamera: true);
      if (picked != null) {
        await _runVisionRecognition(picked.bytes, picked.filename);
      }
    } catch (e) {
      setState(() => _error = 'Không thể mở máy ảnh: $e');
    }
  }

  Future<void> _pickAndRecognize() async {
    try {
      final picked = await pickImageFromDevice(useCamera: false);
      if (picked != null) {
        await _runVisionRecognition(picked.bytes, picked.filename);
      }
    } catch (e) {
      setState(() => _error = 'Không thể mở bộ chọn ảnh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MuseumPage(
    back: true,
    title: widget.direct ? 'Quét mã hiện vật' : 'Khám phá hiện vật',
    subtitle: _activeMode == 'qr'
        ? 'Quét mã QR đặt cạnh hiện vật tại tủ trưng bày.'
        : 'Chụp ảnh hiện vật để nhận diện thông minh qua AI Vision (Port 8001).',
    children: [
      if (!widget.direct) ...[
        BackendPanel(
          resourceKey: 'scan-active-visits',
          load: () async {
            try {
              return await BackendApi.list('visits/me?status=InProgress');
            } catch (_) {
              return <Map<String, dynamic>>[];
            }
          },
          builder: (data, reload) {
            final visits = (data as List).cast<Map<String, dynamic>>();
            final selected = visits.any((v) => v['id'] == _visitId)
                ? _visitId
                : null;
            return Column(
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey(selected),
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Gắn lượt quét với chuyến tham quan',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Quét độc lập'),
                    ),
                    ...visits.map(
                      (v) => DropdownMenuItem<int>(
                        value: v['id'] as int,
                        child: Text(
                          '${AppServices.catalog.museumName(v['museumId'].toString())} · #${v['id']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (id) => setState(() {
                          _visitId = id;
                          _scanRequest = null;
                        }),
                ),
                TextButton(
                  onPressed: reload,
                  child: const Text('Cập nhật lượt tham quan'),
                ),
              ],
            );
          },
        ),
        // Mode selector
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                showCheckmark: false,
                selectedColor: AppColors.deepBurgundy,
                backgroundColor: AppColors.card,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.isEn ? 'QR Scanner' : 'Quét mã QR',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                selected: _activeMode == 'qr',
                onSelected: (_) => setState(() {
                  _activeMode = 'qr';
                  _error = null;
                }),
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _activeMode == 'qr'
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                showCheckmark: false,
                selectedColor: AppColors.deepBurgundy,
                backgroundColor: AppColors.card,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_enhance, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.isEn ? 'AI Recognition' : 'Nhận diện AI',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                selected: _activeMode == 'vision',
                onSelected: (_) => setState(() {
                  _activeMode = 'vision';
                  _error = null;
                }),
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _activeMode == 'vision'
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],

      if (_busy && _activeMode == 'qr') const LinearProgressIndicator(),
      if (_error != null) Notice(_error!),

      if (_activeMode == 'qr') ...[
        if (widget.standalone)
          TextButton.icon(
            onPressed: _busy
                ? null
                : () {
                    setState(() => _camera = false);
                    openPage(
                      context,
                      QRScanScreen(
                        recognition: true,
                        museumId:
                            MuseumExploration.instance.museumId?.toString() ??
                            '',
                      ),
                    );
                  },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Nhận diện bằng hình ảnh'),
          ),
        if (_camera)
          SizedBox(
            height: 280,
            child: MobileScanner(
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) {
                    _scan(barcode.rawValue!);
                    break;
                  }
                }
              },
              errorBuilder: (context, error) => Center(
                child: Notice(
                  widget.direct
                      ? 'Không mở được camera. Hãy cấp quyền máy ảnh. Trên web, camera cần HTTPS hoặc localhost.'
                      : 'Không mở được camera. Hãy cấp quyền máy ảnh hoặc nhập mã bên dưới. Trên web, camera cần HTTPS hoặc localhost.',
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _camera ? (l10n.isEn ? 'Close camera' : 'Tắt camera') : (l10n.isEn ? 'Open camera to scan QR' : 'Mở camera quét QR'),
          icon: Icons.qr_code_scanner,
          onPressed: _busy ? null : () => setState(() => _camera = !_camera),
        ),
        if (!widget.direct) ...[
          const SizedBox(height: 20),
          TextField(
            controller: _input,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: l10n.isEn ? 'QR code or URL on QR' : 'Mã QR hoặc URL trên mã QR',
            ),
            onSubmitted: _scan,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: l10n.isEn ? 'View artifact details' : 'Xem thông tin hiện vật',
            icon: Icons.search,
            onPressed: _busy ? null : () => _scan(_input.text),
          ),
        ],
      ] else ...[
        // AI Vision Mode
        if (_busy) ...[_buildCyberViewfinder(), const SizedBox(height: 14)],
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Mô hình CLIP ViT-B/32 ONNX'),
              const SizedBox(height: 8),
              const Text(
                'Nhận diện hiện vật từ ảnh chụp góc tự do thông qua so khớp vector 512 chiều với kho ảnh tham chiếu đã index.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_selectedImageBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.antiqueIvory,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.parchmentBorder),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedImageName ?? 'Ảnh đã chọn',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${(_selectedImageBytes!.length / 1024).toStringAsFixed(1)} KB · Gửi sang AI Vision (Port 8001)',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              PrimaryButton(
                label: _busy ? 'Đang phân tích vector…' : 'Chụp ảnh qua Camera',
                icon: Icons.camera_alt_outlined,
                onPressed: _busy ? null : _captureFromCamera,
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Chọn ảnh từ thư viện thiết bị',
                icon: Icons.photo_library_outlined,
                onPressed: _busy ? null : _pickAndRecognize,
              ),
              const SizedBox(height: 12),
              const Notice(
                'Giơ camera về phía hiện vật tại tủ trưng bày để chụp và nhận diện thông minh, hoặc tải ảnh có sẵn từ thư viện.',
              ),
            ],
          ),
        ),

        if (_visionResult != null) ...[
          const SizedBox(height: 16),
          Panel(
            gold: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Eyebrow('Kết quả phân tích thị giác'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _visionResult!.matched
                            ? Colors.green.shade100
                            : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _visionResult!.matched
                            ? 'Khớp chính xác'
                            : 'Cần xác nhận',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _visionResult!.matched
                              ? Colors.green.shade800
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Độ tương đồng cosine: ${(_visionResult!.similarity * 100).toStringAsFixed(1)}% · Khoảng cách lề: ${_visionResult!.margin.toStringAsFixed(2)}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 14),

                if (_matchedArtifact != null) ...[
                  Text(_matchedArtifact!.name, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    '${_matchedArtifact!.period} · ${_matchedArtifact!.location}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Xem hồ sơ & Nghe thuyết minh',
                    icon: Icons.headphones,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ArtifactDetailScreen(
                            artifact: _matchedArtifact!,
                            museumName: 'Bảo tàng SMGS',
                          ),
                        ),
                      );
                    },
                  ),
                ] else if (_visionResult!.matched) ...[
                  Text('Đã tìm thấy hiện vật #${_visionResult!.artifactId}'),
                ] else ...[
                  const Text(
                    'Chưa tìm thấy hiện vật tương đồng vượt ngưỡng nhận diện. Vui lòng thử chụp lại góc sáng hơn hoặc quét mã QR.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    ],
  );
  }

  Widget _buildCyberViewfinder() {
    return AnimatedBuilder(
      animation: _scannerAnim,
      builder: (context, _) {
        final animVal = _scannerAnim.value;
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF161412),
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
            border: Border.all(
              color: AppColors.mutedGold.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: CustomPaint(painter: _GridPatternPainter()),
                  ),
                ),
                const Positioned(
                  top: 10,
                  left: 10,
                  child: _CornerBracket(topLeft: true),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: _CornerBracket(topRight: true),
                ),
                const Positioned(
                  bottom: 10,
                  left: 10,
                  child: _CornerBracket(bottomLeft: true),
                ),
                const Positioned(
                  bottom: 10,
                  right: 10,
                  child: _CornerBracket(bottomRight: true),
                ),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.mutedGold.withValues(
                          alpha: 0.3 + 0.4 * animVal,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.filter_center_focus,
                        size: 38,
                        color: AppColors.mutedGold.withValues(
                          alpha: 0.6 + 0.4 * animVal,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18 + animVal * 180,
                  left: 14,
                  right: 14,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.mutedGold.withValues(alpha: 0.7),
                          Colors.amber.shade200,
                          AppColors.mutedGold.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mutedGold.withValues(alpha: 0.9),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.mutedGold.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: AppColors.mutedGold,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'AI VISION · CLIP ViT-B/32 ONNX',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppColors.antiqueIvory,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.mutedGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.mutedGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            animVal < 0.5
                                ? 'Đang trích xuất đặc trưng vector 512 chiều…'
                                : 'Đang so khớp Cosine Similarity kho hiện vật…',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.antiqueIvory,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    const thickness = 2.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BracketPainter(
          color: AppColors.mutedGold,
          thickness: thickness,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({
    required this.color,
    required this.thickness,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Color color;
  final double thickness;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (bottomRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mutedGold
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
