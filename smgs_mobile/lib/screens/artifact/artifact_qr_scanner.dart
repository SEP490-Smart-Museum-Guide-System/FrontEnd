import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/artifact_scan_service.dart';
import '../../services/vision_api_service.dart';
import '../../services/discovery_api_service.dart';
import '../../models/artifact.dart';
import '../../widgets/museum_ui.dart';
import 'artifact_detail_screen.dart';

class ArtifactQrScanner extends StatefulWidget {
  const ArtifactQrScanner({super.key});
  @override
  State<ArtifactQrScanner> createState() => _ArtifactQrScannerState();
}

class _ArtifactQrScannerState extends State<ArtifactQrScanner> {
  final _input = TextEditingController();
  bool _camera = false, _busy = false;
  String? _error;

  // Mode: 'qr' or 'vision'
  String _activeMode = 'qr';
  VisionMatchResult? _visionResult;
  Artifact? _matchedArtifact;

  @override
  void dispose() {
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
      final data = await ArtifactScanService.scan(value);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MuseumPage(
            back: true,
            title: data['name'] as String,
            subtitle: data['museumName'] as String,
            children: [
              if (data['code'] != null) Text('Mã hiện vật: ${data['code']}'),
              if (data['galleryId'] != null)
                Text('Phòng trưng bày: ${data['galleryId']}'),
              if ((data['contents'] as List).isEmpty)
                const Notice('Hiện vật chưa có nội dung được xuất bản.'),
              for (final content in data['contents'] as List) ...[
                const SizedBox(height: 20),
                Text(
                  '${content['title']} (${content['languageCode']})',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  content['description'] as String,
                  style: AppTextStyles.bodyLarge,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Khám phá chi tiết hiện vật',
                icon: Icons.auto_awesome,
                onPressed: () {
                  final contentsList = data['contents'] as List? ?? [];
                  final firstContent = contentsList.isNotEmpty ? contentsList[0] as Map<String, dynamic> : null;
                  final a = Artifact(
                    id: data['id']?.toString() ?? '1',
                    name: data['name'] as String,
                    category: 'Hiện vật di sản',
                    museumId: data['museumId']?.toString() ?? '1',
                    imageUrl: 'assets/images/ngoc-lu-web.jpg',
                    period: 'Thời kỳ lịch sử',
                    location: data['galleryName'] as String? ?? 'Phòng trưng bày',
                    summary: firstContent?['title'] as String? ?? data['name'] as String,
                    story: firstContent?['description'] as String? ?? '',
                    aiGuide: 'Hỏi Trợ lý AI về ${data['name']}',
                    quizPrompt: 'Tìm hiểu về ${data['name']}',
                    modelUrl: null,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ArtifactDetailScreen(
                        artifact: a,
                        museumName: data['museumName'] as String? ?? 'Bảo tàng',
                      ),
                    ),
                  );
                },
              ),
            ],
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

  Future<void> _recognizeWithVision() async {
    setState(() {
      _busy = true;
      _error = null;
      _visionResult = null;
      _matchedArtifact = null;
    });

    try {
      // In mobile app, we can use a sample artifact test photo or prompt input
      // Send sample bytes to AI Vision endpoint (Port 8001)
      final sampleBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
        0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
        0x00, 0x7F, 0x00, 0xFF, 0xD9
      ]);

      final result = await VisionApiService.recognizeArtifact(sampleBytes);
      _visionResult = result;

      if (result.matched && result.artifactId != null) {
        // Fetch detailed artifact data from backend
        try {
          final detail = await DiscoveryApiService.fetchArtifactDetail(result.artifactId!);
          if (detail != null) {
            _matchedArtifact = Artifact.fromBackendJson(detail);
          }
        } catch (_) {}
      }
    } catch (e) {
      _error = 'Dịch vụ AI Vision (Port 8001): ${e.toString().replaceFirst('Exception: ', '')}';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Khám phá hiện vật',
    subtitle: _activeMode == 'qr'
        ? 'Quét mã QR đặt cạnh hiện vật tại tủ trưng bày.'
        : 'Chụp ảnh hiện vật để nhận diện thông minh qua AI Vision (Port 8001).',
    children: [
      // Mode selector
      Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 16),
                  SizedBox(width: 6),
                  Text('Quét mã QR'),
                ],
              ),
              selected: _activeMode == 'qr',
              onSelected: (_) => setState(() {
                _activeMode = 'qr';
                _error = null;
              }),
              checkmarkColor: AppColors.antiqueIvory,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: _activeMode == 'qr' ? AppColors.antiqueIvory : AppColors.darkBrown,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ChoiceChip(
              label: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_enhance, size: 16),
                  SizedBox(width: 6),
                  Text('Nhận diện AI Vision'),
                ],
              ),
              selected: _activeMode == 'vision',
              onSelected: (_) => setState(() {
                _activeMode = 'vision';
                _error = null;
              }),
              checkmarkColor: AppColors.antiqueIvory,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: _activeMode == 'vision' ? AppColors.antiqueIvory : AppColors.darkBrown,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Notice(_error!),

      if (_activeMode == 'qr') ...[
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
              errorBuilder: (context, error) => const Center(
                child: Notice(
                  'Không mở được camera. Hãy cấp quyền máy ảnh hoặc nhập mã bên dưới. Trên web, camera cần HTTPS hoặc localhost.',
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _camera ? 'Tắt camera' : 'Mở camera quét QR',
          icon: Icons.qr_code_scanner,
          onPressed: _busy ? null : () => setState(() => _camera = !_camera),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _input,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Mã QR hoặc URL trên mã QR',
          ),
          onSubmitted: _scan,
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Xem thông tin hiện vật',
          icon: Icons.search,
          onPressed: _busy ? null : () => _scan(_input.text),
        ),
      ] else ...[
        // AI Vision Mode
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
              PrimaryButton(
                label: 'Chụp ảnh & Nhận diện qua AI Vision',
                icon: Icons.camera_alt,
                onPressed: _busy ? null : _recognizeWithVision,
              ),
              const SizedBox(height: 12),
              const Notice(
                'Nếu độ tương đồng chưa đủ cao, hệ thống sẽ đề nghị xác nhận hoặc khuyến nghị quét mã QR cạnh hiện vật.',
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _visionResult!.matched ? Colors.green.shade100 : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _visionResult!.matched ? 'Khớp chính xác' : 'Cần xác nhận',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _visionResult!.matched ? Colors.green.shade800 : Colors.amber.shade900,
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
                  Text(
                    _matchedArtifact!.name,
                    style: AppTextStyles.cardTitle,
                  ),
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
