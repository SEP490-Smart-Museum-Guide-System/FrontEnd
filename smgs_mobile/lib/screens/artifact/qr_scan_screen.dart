import '../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../widgets/earned_badges.dart';
import 'package:flutter/services.dart';

import '../../core/utils/image_picker_helper.dart';
import '../../models/artifact.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import '../../services/vision_api_service.dart';
import '../../services/visitor_experience_api.dart';
import '../../widgets/museum_ui.dart';
import '../explore/explore_screen.dart';
import 'artifact_detail_screen.dart';
import 'artifact_qr_scanner.dart';
import 'daily_quiz_screen.dart';

typedef ArtifactVisionRecognizer =
    Future<VisionMatchResult> Function(
      Uint8List imageBytes, {
      String filename,
      int? museumId,
    });
typedef BackendArtifactLoader =
    Future<Map<String, dynamic>> Function(String artifactId);

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({
    super.key,
    this.recognition = false,
    this.museumId = '',
    this.recognizeArtifact = VisionApiService.recognizeArtifact,
    this.loadArtifact,
  });
  final bool recognition;
  final String museumId;
  final ArtifactVisionRecognizer recognizeArtifact;
  final BackendArtifactLoader? loadArtifact;

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _busy = false;
  Uint8List? _selectedImageBytes;
  Artifact? _matchedArtifact;
  String _matchedMuseum = '';
  VisionMatchResult? _visionResult;
  String? _error;

  Future<void> _processImage(Uint8List bytes, String filename) async {
    setState(() {
      _busy = true;
      _error = null;
      _selectedImageBytes = bytes;
      _matchedArtifact = null;
      _visionResult = null;
    });

    try {
      // 1. Gửi ảnh lên microservice AI Vision (Port 8001 / CLIP ViT-B/32)
      final match = await widget.recognizeArtifact(bytes, filename: filename);

      _visionResult = match;

      if (match.matched && match.artifactId != null) {
        // 2. Tải thông tin hiện vật thật từ Backend API
        final data = widget.loadArtifact != null
            ? await widget.loadArtifact!(match.artifactId.toString())
            : Map<String, dynamic>.from(
                await BackendApi.request('artifacts/${match.artifactId}')
                    as Map,
              );
        final artifact = Artifact.fromBackendJson(
          Map<String, dynamic>.from(data as Map),
        );

        // 3. Ghi nhận nhận diện thành công vào lịch sử để tích điểm & mở quiz
        try {
          final visit = VisitorSession.activeVisit;
          final visitId = visit?['museumId']?.toString() == artifact.museumId
              ? (visit?['id'] as int?)
              : null;
          final code = data['qrCode'] as String?;
          if (code != null && code.trim().isNotEmpty) {
            final rewards = await ScanRequest(
              code,
              visitId: visitId,
              imageMatch: true,
            ).record();
            if (mounted) showExplorationRewards(context, rewards);
          }
        } catch (_) {
          // Ghi nhận lịch sử không chặn hiển thị chi tiết hiện vật
        }

        if (mounted) {
          setState(() {
            _matchedArtifact = artifact;
            _matchedMuseum = AppServices.catalog.museumName(artifact.museumId);
            _busy = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _busy = false;
            _error =
                match.message ??
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
        setState(
          () => _error = 'Không thể mở thư viện/máy ảnh: ${e.toString()}',
        );
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
        museumName: _matchedMuseum.isNotEmpty ? _matchedMuseum : 'Bảo tàng',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.recognition) {
      return const ArtifactQrScanner();
    }

    final l10n = context.l10n;
    return MuseumPage(
      back: true,
      title: l10n.isEn ? 'AI Visual Recognition' : 'Nhận diện thị giác AI',
      eyebrow: l10n.isEn
          ? 'CLIP Artificial Intelligence'
          : 'Trí tuệ nhân tạo CLIP',
      subtitle: l10n.isEn
          ? 'Photograph artifact for automatic recognition'
          : 'Chụp ảnh hiện vật để nhận diện tự động',
      children: [
        // Khung hiển thị ảnh chụp hoặc hướng dẫn
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.darkBrown,
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
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
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.antiqueIvory.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.mutedGold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 34,
                            color: AppColors.antiqueIvory,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.isEn
                              ? 'Photograph exhibited artifact'
                              : 'Chụp ảnh hiện vật trưng bày',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.antiqueIvory,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.isEn
                              ? 'AI extracts 512-D vector for matching'
                              : 'AI sẽ trích xuất vector 512 chiều để đối chiếu',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.antiqueIvory.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_busy)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.mutedGold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.isEn
                            ? 'Analyzing visual vector…'
                            : 'Đang phân tích vector thị giác…',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.antiqueIvory,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.isEn
                            ? 'Matching CLIP ViT-B/32 features with artifact database'
                            : 'So khớp đặc trưng CLIP ViT-B/32 với kho hiện vật',
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
            label: l10n.isEn ? 'Take photo with camera' : 'Chụp ảnh từ máy ảnh',
            icon: Icons.camera_alt_outlined,
            onPressed: () => _pickFromCameraOrGallery(useCamera: true),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: l10n.isEn
                ? 'Choose photo from device gallery'
                : 'Chọn ảnh từ thư viện thiết bị',
            icon: Icons.photo_library_outlined,
            onPressed: () => _pickFromCameraOrGallery(useCamera: false),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deepBurgundy,
            ),
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
              borderRadius: BorderRadius.circular(VisitorRadius.md),
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
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.red.shade800,
                        ),
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
            onPressed: () =>
                openPage(context, const ArtifactQrScanner(direct: true)),
          ),
        ],

        // Kết quả nhận diện thành công
        if (_matchedArtifact != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: VisitorColors.surface1,
              borderRadius: BorderRadius.circular(VisitorRadius.xl),
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E6B3E),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'NHẬN DIỆN THÀNH CÔNG',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF2E6B3E),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_visionResult != null && _visionResult!.similarity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2E6B3E,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(VisitorRadius.xs),
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
                if (_matchedMuseum.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _matchedMuseum,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
                if (_matchedArtifact!.summary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _matchedArtifact!.summary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.charcoalBrown,
                    ),
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
