import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../models/artifact.dart';
import '../../services/artifact_scan_service.dart';
import '../../services/discovery_api_service.dart';
import '../../services/museum_presence_api.dart';
import '../../services/vision_api_service.dart';
import '../../services/visitor_experience_api.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/earned_badges.dart';
import '../../widgets/exploration_map_button.dart';
import '../artifact/artifact_detail_screen.dart';
import '../museum/visitor_directory_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.standalone = false});
  final bool standalone;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _previewKey = GlobalKey();
  late final MobileScannerController _controller;
  late final AnimationController _laserAnim;

  // Mode: 'qr' or 'ai'
  String _mode = 'qr';
  bool _torchOn = false;
  bool _busy = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _laserAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _laserAnim.repeat(reverse: true);
    } else {
      _laserAnim.value = 0.5;
    }
  }

  @override
  void dispose() {
    _laserAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_mode != 'qr' || _busy) return;
    for (final barcode in capture.barcodes) {
      final val = barcode.rawValue;
      if (val != null && val.trim().isNotEmpty) {
        _handleScannedValue(val.trim());
        break;
      }
    }
  }

  Future<void> _handleScannedValue(String rawValue) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusText = 'Đang tra cứu thông tin hiện vật…';
    });

    try {
      if (MuseumPresenceApi.isCheckpoint(rawValue)) {
        final result = await MuseumPresenceApi.scan(rawValue);
        if (!mounted) return;
        final activeMuseum = VisitorSession.activeVisit?['museumId'];
        final visitId = (activeMuseum != null && activeMuseum == result['museumId'])
            ? (VisitorSession.activeVisit?['id'] as int?)
            : null;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'VisitorDirectoryScreen'),
            builder: (_) => VisitorDirectoryScreen(
              museumId: result['museumId'],
              initialMapId: result['mapId'],
              museumName: 'Vị trí vừa xác nhận',
              visitId: visitId,
            ),
          ),
        );
        return;
      }

      final code = ArtifactScanService.extractCode(rawValue);
      final data = await ArtifactScanService.scan(code);
      if (!mounted) return;

      final artifact = Artifact.fromBackendJson(data);

      // Record rewards
      int? visitId;
      try {
        final visit = VisitorSession.activeVisit;
        visitId = visit?['museumId']?.toString() == artifact.museumId
            ? (visit?['id'] as int?)
            : null;
        final rewards = await ScanRequest(code, visitId: visitId).record();
        if (mounted) showExplorationRewards(context, rewards);
      } catch (_) {}

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'ArtifactDetailScreen'),
            builder: (_) => ArtifactDetailScreen(
              artifact: artifact,
              museumName: artifact.museumName ?? 'Bảo tàng',
              visitId: visitId,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.contains('Không tìm thấy')
              ? 'Không tìm thấy dữ liệu hiện vật tương ứng mã này.'
              : 'Lỗi tra cứu: $msg'),
          backgroundColor: AppColors.deepBurgundy,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusText = null;
        });
      }
    }
  }

  Future<void> _captureAndRecognizeAI() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusText = 'Đang phân tích đường nét hiện vật qua AI…';
    });

    try {
      Uint8List? imageBytes;
      // 1. Chụp tức thì khung hình camera ngay trong app (In-app snapshot)
      try {
        final boundary = _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          imageBytes = byteData?.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('In-app snapshot capture error: $e');
      }

      // Nếu chụp thành công ngay trong app -> Gửi phân tích luôn!
      if (imageBytes != null && imageBytes.isNotEmpty) {
        await _processImageBytes(imageBytes, 'in_app_capture.png');
        return;
      }

      // 2. Fallback sang camera máy nếu không lấy được frame
      final picked = await pickImageFromDevice(useCamera: true);
      if (picked == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      await _processImageBytes(picked.bytes, picked.filename);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chụp ảnh: $e'),
          backgroundColor: AppColors.deepBurgundy,
        ),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _statusText = 'Đang phân tích hình ảnh từ thư viện…';
    });

    try {
      final picked = await pickImageFromDevice(useCamera: false);
      if (picked == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      await _processImageBytes(picked.bytes, picked.filename);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: AppColors.deepBurgundy,
        ),
      );
      setState(() => _busy = false);
    }
  }

  Future<void> _processImageBytes(Uint8List bytes, String filename) async {
    try {
      final museumId = MuseumExploration.instance.museumId;
      final match = await VisionApiService.recognizeArtifact(
        bytes,
        filename: filename,
        museumId: museumId,
      );

      if (match.matched && match.artifactId != null) {
        final data = await DiscoveryApiService.fetchArtifactDetail(
          match.artifactId!,
        );
        final artifact = Artifact.fromBackendJson(data);

        // Record history and reward
        int? visitId;
        try {
          final visit = VisitorSession.activeVisit;
          visitId = visit?['museumId']?.toString() == artifact.museumId
              ? (visit?['id'] as int?)
              : null;
          final code = data['qrCode'] as String? ?? '';
          if (code.isNotEmpty) {
            final rewards = await ScanRequest(
              code,
              visitId: visitId,
              imageMatch: true,
            ).record();
            if (mounted) showExplorationRewards(context, rewards);
          }
        } catch (_) {}

        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'ArtifactDetailScreen'),
            builder: (_) => ArtifactDetailScreen(
              artifact: artifact,
              museumName: artifact.museumName ?? 'Bảo tàng',
              visitId: visitId,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa nhận diện được hiện vật này. Vui lòng căn góc chụp rõ nét hơn hoặc quét mã QR tại tủ kính.',
            ),
            backgroundColor: AppColors.deepBurgundy,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi phân tích AI: $msg'),
          backgroundColor: AppColors.deepBurgundy,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop =
        widget.standalone || (ModalRoute.of(context)?.canPop ?? false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Stream
          RepaintBoundary(
            key: _previewKey,
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_outlined,
                        color: AppColors.mutedGold,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.isEn
                            ? 'Camera is unavailable. Please grant camera permission or select a photo from gallery.'
                            : 'Chưa mở được máy ảnh. Vui lòng cấp quyền máy ảnh hoặc chọn ảnh từ thư viện để nhận diện.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.antiqueIvory,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepBurgundy,
                          foregroundColor: AppColors.antiqueIvory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: _pickFromGallery,
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 18),
                        label: Text(
                          l10n.isEn
                              ? 'Pick from Gallery'
                              : 'Chọn ảnh từ thư viện',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Viewfinder & Overlay Cutout
          SafeArea(
            child: Column(
              children: [
                // Top Control Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Torch toggle button
                      InkWell(
                        onTap: _toggleTorch,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(
                              color: _torchOn
                                  ? AppColors.mutedGold
                                  : Colors.white24,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            _torchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: _torchOn
                                ? AppColors.mutedGold
                                : AppColors.antiqueIvory,
                            size: 22,
                          ),
                        ),
                      ),

                      // Title
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            l10n.isEn
                                ? 'Scan & Recognition'
                                : 'Quét mã & Nhận diện',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: AppColors.antiqueIvory,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      // Close button if canPop
                      if (canPop)
                        InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.45),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.antiqueIvory,
                              size: 22,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 44),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Center Viewfinder Reticle
                _buildViewfinderReticle(),

                const SizedBox(height: 16),

                // Instruction hint
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _mode == 'qr'
                        ? (l10n.isEn
                            ? 'Point camera at the exhibit QR code'
                            : 'Hướng camera vào mã QR tại chân hiện vật')
                        : (l10n.isEn
                            ? 'Frame the artifact clearly and tap capture'
                            : 'Căn góc chụp rõ nét hiện vật cần nhận diện'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.antiqueIvory,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // 3. Floating Mode Switcher Pill [ Quét mã QR | Nhận diện AI ]
                _buildModeSwitcherPill(l10n),

                const SizedBox(height: 20),

                // 4. Bottom Thumb Control Bar
                _buildBottomThumbBar(),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // 5. Processing Busy Modal Overlay
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.72),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.mutedGold,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _statusText ?? 'Đang xử lý dữ liệu…',
                      style: const TextStyle(
                        color: AppColors.antiqueIvory,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewfinderReticle() {
    final boxSize = _mode == 'qr' ? 250.0 : 270.0;
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top-left bracket
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.mutedGold, width: 3.5),
                  left: BorderSide(color: AppColors.mutedGold, width: 3.5),
                ),
              ),
            ),
          ),
          // Top-right bracket
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.mutedGold, width: 3.5),
                  right: BorderSide(color: AppColors.mutedGold, width: 3.5),
                ),
              ),
            ),
          ),
          // Bottom-left bracket
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.mutedGold, width: 3.5),
                  left: BorderSide(color: AppColors.mutedGold, width: 3.5),
                ),
              ),
            ),
          ),
          // Bottom-right bracket
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.mutedGold, width: 3.5),
                  right: BorderSide(color: AppColors.mutedGold, width: 3.5),
                ),
              ),
            ),
          ),

          // Animated laser beam in QR mode
          if (_mode == 'qr')
            AnimatedBuilder(
              animation: _laserAnim,
              builder: (context, _) {
                final topOffset = 10 + (boxSize - 20) * _laserAnim.value;
                return Positioned(
                  top: topOffset,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.mutedGold.withValues(alpha: 0.1),
                          AppColors.mutedGold,
                          AppColors.mutedGold.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mutedGold.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Subtle center crosshairs
          if (_mode == 'ai')
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.mutedGold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mutedGold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcherPill(AppLocalizations l10n) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF161412).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.mutedGold.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPillTab(
              title: l10n.isEn ? 'QR Scanner' : 'Quét mã QR',
              icon: Icons.qr_code_scanner,
              isSelected: _mode == 'qr',
              onTap: () {
                if (_mode != 'qr') {
                  setState(() => _mode = 'qr');
                }
              },
            ),
            const SizedBox(width: 4),
            _buildPillTab(
              title: l10n.isEn ? 'AI Recognition' : 'Nhận diện AI',
              icon: Icons.auto_awesome,
              isSelected: _mode == 'ai',
              onTap: () {
                if (_mode != 'ai') {
                  setState(() => _mode = 'ai');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBurgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(
                  color: AppColors.mutedGold.withValues(alpha: 0.6),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? AppColors.antiqueIvory
                  : AppColors.antiqueIvory.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppColors.antiqueIvory
                    : AppColors.antiqueIvory.withValues(alpha: 0.6),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomThumbBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Photo Gallery Picker button
          InkWell(
            onTap: _pickFromGallery,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161412).withValues(alpha: 0.8),
                border: Border.all(
                  color: AppColors.mutedGold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.antiqueIvory,
                size: 22,
              ),
            ),
          ),

          // Center: AI Shutter Button (only active/visible in AI mode)
          if (_mode == 'ai')
            InkWell(
              onTap: _captureAndRecognizeAI,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.mutedGold,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mutedGold.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.deepBurgundy,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.antiqueIvory,
                      size: 28,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 72, height: 72),

          // Right: Balancing space
          const SizedBox(width: 50, height: 50),
        ],
      ),
    );
  }
}
