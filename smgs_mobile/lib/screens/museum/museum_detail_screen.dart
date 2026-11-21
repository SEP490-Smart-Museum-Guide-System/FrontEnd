import '../../services/visitor_experience_api.dart';
import 'visit_progress_screen.dart';
import 'visitor_directory_screen.dart';
import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../models/museum.dart';
import '../../models/artifact.dart';
import '../../services/discovery_api_service.dart';
import '../../widgets/route_preview_sheet.dart';
import '../../widgets/museum_arrival_panel.dart';

import '../artifact/artifact_discovery_screen.dart';
import '../explore/explore_screen.dart';
import '../tours/tours_screen.dart';
import '../profile/services_screen.dart';
import '../profile/profile_screen.dart';

class MuseumDetailScreen extends StatefulWidget {
  const MuseumDetailScreen({super.key, required this.museum, this.heroTag});
  final Museum museum;
  final Object? heroTag;

  @override
  State<MuseumDetailScreen> createState() => _MuseumDetailScreenState();
}

class _MuseumDetailScreenState extends State<MuseumDetailScreen> {
  late Museum _museum = widget.museum;
  String? _museumError;
  bool _startingVisit = false;
  List<Artifact>? _backendArtifacts;
  List<Map<String, dynamic>>? _feedbacks;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtifacts();
    _loadMuseum();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    final mId = int.tryParse(widget.museum.id);
    if (mId == null) return;
    try {
      final items = await VisitorExperienceApi.getMuseumFeedbacks(mId);
      if (mounted) {
        setState(() => _feedbacks = items);
      }
    } catch (_) {}
  }

  Future<void> _showEditFeedbackDialog(Map<String, dynamic> fb) async {
    final feedbackId = fb['id'] as int?;
    if (feedbackId == null) return;
    int rating = (fb['overallRating'] as num?)?.toInt() ?? 5;
    final controller = TextEditingController(text: fb['comment']?.toString() ?? '');
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chỉnh sửa đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Số sao đánh giá:', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.mutedGold,
                      size: 28,
                    ),
                    onPressed: () => setDialogState(() => rating = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Text('Nội dung nhận xét:', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhận xét của bạn về trải nghiệm...',
                  filled: true,
                  fillColor: AppColors.antiqueIvory,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await VisitorExperienceApi.updateFeedback(
                          feedbackId: feedbackId,
                          overallRating: rating,
                          comment: controller.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(ctx);
                        _loadFeedbacks();
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Đã cập nhật đánh giá thành công!')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
              child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMuseum() async {
    if (int.tryParse(widget.museum.id) == null) return;
    try {
      final museum = await DiscoveryApiService.fetchMuseumDetail(
        widget.museum.id,
      );
      if (mounted) {
        setState(() {
          _museum = museum;
          _museumError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _museumError = e.toString());
    }
  }

  Future<void> _loadArtifacts() async {
    final mId = int.tryParse(widget.museum.id);
    if (mId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final items = await DiscoveryApiService.fetchArtifacts(museumId: mId);
      if (mounted) {
        setState(() {
          _backendArtifacts = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    if (!context.mounted) return;
    RoutePreviewSheet.show(context, museum: _museum);
  }

  void _openIndoorMap(BuildContext context) {
    final id = int.tryParse(widget.museum.id);
    if (id == null) return;
    openPage(
      context,
      VisitorDirectoryScreen(museumId: id, museumName: _museum.name),
    );
  }

  Future<void> _startVisit() async {
    if (_startingVisit) return;
    setState(() => _startingVisit = true);
    try {
      final visit = await VisitorExperienceApi.startVisit(
        int.parse(widget.museum.id),
      );
      if (mounted) {
        openPage(context, VisitProgressScreen(visitId: visit['id'] as int));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _startingVisit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final museum = _museum;
    final artifacts = _backendArtifacts ?? <Artifact>[];

    return StoryScaffold(
      title: museum.name,
      heroTag: widget.heroTag,
      floatingActionButton: int.tryParse(museum.id) == null
          ? null
          : FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Mở bản đồ bảo tàng',
              onPressed: () => _openIndoorMap(context),
              child: const Icon(Icons.map_outlined),
            ),
      photo: MuseumPhoto(
        museumId: museum.id,
        imageUrl: museum.imageUrl,
        height: 300,
      ),
      children: [
        if (_museumError != null) ...[
          Notice(_museumError!),
          TextButton(
            onPressed: _loadMuseum,
            child: const Text('Thử tải lại thông tin bảo tàng'),
          ),
        ],
        if (_error != null) Notice(_error!),
        if (int.tryParse(museum.id) case final int museumId)
          MuseumArrivalPanel(museumId: museumId, museumName: museum.name),
        PrimaryButton(
          label: _startingVisit ? 'Đang bắt đầu…' : 'Bắt đầu lượt tham quan',
          onPressed: _startingVisit ? null : _startVisit,
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 22),
        Eyebrow(museum.category),
        const SizedBox(height: 10),
        Text(
          museum.name,
          style: AppTextStyles.display.copyWith(color: AppColors.deepBurgundy),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(museum.location, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
        const Divider(),
        Text(museum.shortIntro, style: AppTextStyles.bodyLarge),
        const SizedBox(height: 18),
        Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: AppColors.deepBurgundy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giờ tham quan tham khảo',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      museum.openingHours,
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vui lòng xác nhận lịch mở cửa với bảo tàng trước chuyến đi.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (artifacts.isNotEmpty) ...[
          PrimaryButton(
            label: 'Khám phá hiện vật',
            icon: Icons.explore_outlined,
            onPressed: () => openPage(
              context,
              ArtifactDiscoveryScreen(
                museum: museum,
                artifact: artifacts.first,
              ),
            ),
          ),
        ],
        const SectionHeading('Câu chuyện bảo tàng'),
        ScrollReveal(
          child: Text(museum.description, style: AppTextStyles.bodyLarge),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (artifacts.isNotEmpty) ...[
          SectionHeading(
            'Hiện vật tiêu biểu',
            action: 'Xem tất cả',
            onTap: () => openPage(
              context,
              ExploreScreen(standalone: true, museumId: museum.id),
            ),
          ),
          ...artifacts.map(
            (a) => ScrollReveal(child: ArtifactCard(artifact: a)),
          ),
        ],
        const SectionHeading('Chuẩn bị chuyến tham quan'),
        if (museum.hasCoordinates)
          ActionTile(
            title: 'Chỉ đường & Lộ trình đến bảo tàng',
            subtitle: 'Xem trước cự ly, thời gian và dẫn đường ngoài trời.',
            icon: Icons.directions_outlined,
            onTap: () => _openDirections(context),
          ),
        ActionTile(
          title: 'Sơ đồ bảo tàng & Tìm đường hiện vật',
          subtitle: 'Bản đồ trong nhà, quét QR xác định vị trí và dẫn đường.',
          icon: Icons.map_outlined,
          onTap: () => _openIndoorMap(context),
        ),
        ActionTile(
          title: 'Hành trình dành cho bạn',
          subtitle: 'Chọn thời gian và sở thích để bắt đầu.',
          icon: Icons.route_outlined,
          onTap: () => openPage(
            context,
            ToursScreen(standalone: true, museumId: museum.id),
          ),
        ),
        ActionTile(
          title: 'Vé & Hướng dẫn số',
          subtitle: 'Chọn vé vào cửa, Hướng dẫn số hoặc gói kết hợp.',
          icon: Icons.confirmation_number_outlined,
          onTap: () => openPage(
            context,
            ServicesScreen(museumName: museum.name, museumId: museum.id),
          ),
        ),
        ActionTile(
          title: 'Góp ý về bảo tàng',
          subtitle: 'Chia sẻ cảm nhận sau chuyến tham quan.',
          icon: Icons.rate_review_outlined,
          onTap: () => openPage(
            context,
            FeedbackScreen(
              targetType: 'museum',
              targetId: museum.id,
              targetName: museum.name,
            ),
          ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'ĐÁNH GIÁ TỪ KHÁCH THAM QUAN',
                style: TextStyle(
                  fontFamily: AppTextStyles.sansFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_feedbacks != null && _feedbacks!.isNotEmpty) ...[
              const Icon(Icons.star_rounded, color: AppColors.mutedGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '${(_feedbacks!.map((f) => (f['overallRating'] as num?)?.toDouble() ?? 5.0).reduce((a, b) => a + b) / _feedbacks!.length).toStringAsFixed(1)} / 5 (${_feedbacks!.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (_feedbacks == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_feedbacks!.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Chưa có đánh giá công khai nào cho bảo tàng này. Hãy hoàn tất chuyến đi để trở thành người đầu tiên để lại nhận xét!',
              style: TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 12.5,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._feedbacks!.map((fb) {
            final rating = (fb['overallRating'] as num?)?.toInt() ?? 5;
            final comment = fb['comment'] as String? ?? '';
            final staffResp = fb['staffResponse'] as Map<String, dynamic>?;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (idx) {
                          return Icon(
                            idx < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: idx < rating
                                ? AppColors.mutedGold
                                : Colors.grey.shade400,
                          );
                        }),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _showEditFeedbackDialog(fb),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueIvory,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 11, color: AppColors.deepBurgundy),
                              SizedBox(width: 3),
                              Text(
                                'Sửa',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepBurgundy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Khách tham quan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      comment,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 13,
                        color: AppColors.primaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (staffResp != null &&
                      (staffResp['content'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueIvory,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PHẢN HỒI TỪ BẢO TÀNG',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.deepBurgundy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            staffResp['content'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkBrown,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
