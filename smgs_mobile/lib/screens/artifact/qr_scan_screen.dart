import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../models/artifact.dart';
import '../../services/backend_api.dart';
import '../../services/vision_api_service.dart';
import '../../services/visitor_experience_api.dart';
import '../../widgets/museum_ui.dart';
import '../explore/explore_screen.dart';
import 'artifact_detail_screen.dart';
import 'artifact_qr_scanner.dart';
import 'daily_quiz_screen.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key, this.recognition = false, this.museumId = ''});
  final bool recognition;
  final String museumId;

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _busy = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  Artifact? _matchedArtifact;
  VisionMatchResult? _visionResult;
  String? _error;

  Future<void> _processImage(Uint8List bytes, String filename) async {
    setState(() {
      _busy = true;
      _error = null;
      _selectedImageBytes = bytes;
      _selectedImageName = filename;
      _matchedArtifact = null;
      _visionResult = null;
    });

    try {
      // 1. Gửi ảnh lên microservice AI Vision (Port 8001 / CLIP ViT-B/32)
      final match = await VisionApiService.recognizeArtifact(
        bytes,
        filename: filename,
      );

      _visionResult = match;

      if (match.matched && match.artifactId != null) {
        // 2. Tải thông tin hiện vật thật từ Backend API
        final data = await BackendApi.request('artifacts/${match.artifactId}');
        final artifact = Artifact.fromBackendJson(
          Map<String, dynamic>.from(data as Map),
        );

        // 3. Ghi nhận nhận diện thành công vào lịch sử để tích điểm & mở quiz
        try {
          final visitId = VisitorSession.activeVisit?['id'] as int?;
          final code = artifact.qrCode.isNotEmpty ? artifact.qrCode : 'artifact_${artifact.id}';
          await ScanRequest(code, visitId: visitId).record();
        } catch (_) {
          // Ghi nhận lịch sử không chặn hiển thị chi tiết hiện vật
        }

        if (mounted) {
          setState(() {
            _matchedArtifact = artifact;
            _busy = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = match.message ??
                'Không tìm thấy hiện vật phù hợp trong kho tư liệu AI. Hãy thử chụp góc nhìn khác hoặc chuyển sang Quét mã QR.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _pickFromCameraOrGallery({bool useCamera = false}) async {
    try {
      final picked = await pickImageFromDevice(useCamera: useCamera);
      if (picked != null && picked.bytes.isNotEmpty) {
        await _processImage(picked.bytes, picked.filename);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể mở thư viện/máy ảnh: ${e.toString()}');
      }
    }
  }

  Future<void> _testWithSampleImage() async {
    try {
      final byteData = await rootBundle.load('assets/images/ngoc-lu-web.jpg');
      final bytes = byteData.buffer.asUint8List();
      await _processImage(bytes, 'ngoc-lu-web.jpg');
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Không thể tải ảnh mẫu: ${e.toString()}');
      }
    }
  }

  void _openArtifact(Artifact a) {
    openPage(
      context,
      ArtifactDetailScreen(
        artifact: a,
        museumName: a.museumName.isNotEmpty ? a.museumName : 'Bảo tàng Lịch sử',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.recognition) {
      return const ArtifactQrScanner();
    }

    return MuseumPage(
      back: true,
      title: 'Nhận diện thị giác AI',
      eyebrow: 'Trí tuệ nhân tạo CLIP',
      subtitle: 'Chụp ảnh hiện vật để nhận diện tự động',
      children: [
        // Khung hiển thị ảnh chụp hoặc hướng dẫn
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.darkBrown,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mutedGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_selectedImageBytes != null)
                Image.memory(
                  _selectedImageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.antiqueIvory.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 38,
                        color: AppColors.antiqueIvory,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chụp ảnh hiện vật trưng bày',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.antiqueIvory,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI sẽ trích xuất vector 512 chiều để đối chiếu',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.antiqueIvory.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              if (_busy)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.mutedGold),
                      const SizedBox(height: 16),
                      Text(
                        'Đang phân tích vector thị giác…',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.antiqueIvory,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'So khớp đặc trưng CLIP ViT-B/32 với kho hiện vật',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.antiqueIvory.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Nút bấm tác vụ chụp / chọn ảnh
        if (!_busy && _matchedArtifact == null) ...[
          PrimaryButton(
            label: 'Chụp ảnh từ máy ảnh',
            icon: Icons.camera_alt_outlined,
            onPressed: () => _pickFromCameraOrGallery(useCamera: true),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Chọn ảnh từ thư viện thiết bị',
            icon: Icons.photo_library_outlined,
            onPressed: () => _pickFromCameraOrGallery(useCamera: false),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.deepBurgundy),
            onPressed: _testWithSampleImage,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text(
              'Thử nghiệm với ảnh Trống đồng mẫu',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],

        // Lỗi nhận diện
        if (_error != null && !_busy) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông báo nhận diện',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: AppTextStyles.caption.copyWith(color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Chuyển sang Quét mã QR',
            icon: Icons.qr_code_scanner,
            onPressed: () => openPage(context, const ArtifactQrScanner(direct: true)),
          ),
        ],

        // Kết quả nhận diện thành công
        if (_matchedArtifact != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E6B3E), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E6B3E).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E6B3E),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NHẬN DIỆN THÀNH CÔNG',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF2E6B3E),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    if (_visionResult != null && _visionResult!.similarity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E6B3E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(_visionResult!.similarity * 100).toStringAsFixed(1)}% tin cậy',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF2E6B3E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  _matchedArtifact!.name,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.darkBrown,
                    fontSize: 20,
                  ),
                ),
                if (_matchedArtifact!.museumName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _matchedArtifact!.museumName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                  ),
                ],
                if (_matchedArtifact!.summary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _matchedArtifact!.summary,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Xem hồ sơ hiện vật',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _openArtifact(_matchedArtifact!),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Làm Quiz thử tài',
            icon: Icons.quiz_outlined,
            onPressed: () => openPage(
              context,
              DailyQuizScreen(artifactId: _matchedArtifact!.id),
            ),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Chụp hiện vật khác',
            icon: Icons.refresh_rounded,
            onPressed: () => setState(() {
              _matchedArtifact = null;
              _selectedImageBytes = null;
              _visionResult = null;
              _error = null;
            }),
          ),
        ],

        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Tra cứu bộ sưu tập bảo tàng',
          icon: Icons.search_rounded,
          onPressed: () => openPage(
            context,
            ExploreScreen(standalone: true, museumId: widget.museumId),
          ),
        ),
      ],
    );
  }
}
