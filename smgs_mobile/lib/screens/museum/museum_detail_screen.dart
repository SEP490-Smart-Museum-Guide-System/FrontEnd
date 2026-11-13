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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtifacts();
    _loadMuseum();
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
      ],
    );
  }
}
