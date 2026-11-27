import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/app_preferences.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';
import '../../services/visitor_experience_api.dart';
import '../museum/visit_progress_screen.dart';

class PublishedToursScreen extends StatefulWidget {
  const PublishedToursScreen({
    super.key,
    required this.museumId,
    this.maxMinutes,
  });
  final int museumId;
  final int? maxMinutes;

  @override
  State<PublishedToursScreen> createState() => _PublishedToursScreenState();
}

class _PublishedToursScreenState extends State<PublishedToursScreen> {
  int _selectedTab = 0;
  int _availableMinutes = 60;
  final Set<int> _selectedTopicIds = {};
  List<Map<String, dynamic>> _topics = [];
  bool _loadingTopics = false;
  bool _isRecommending = false;
  Map<String, dynamic>? _recommendationResult;
  String? _recommendError;
  bool _savingCurated = false;
  int? _savedTourVersionId;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _loadingTopics = true);
    try {
      final topics = await VisitorExperienceApi.getMuseumTopics(widget.museumId);
      if (mounted) setState(() => _topics = topics);
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _loadingTopics = false);
    }
  }

  Future<void> _onRecommend() async {
    setState(() {
      _isRecommending = true;
      _recommendError = null;
    });
    try {
      final res = await VisitorExperienceApi.recommendCuratedTour(
        museumId: widget.museumId,
        availableMinutes: _availableMinutes,
        topicIds: _selectedTopicIds.toList(),
      );
      if (mounted) {
        setState(() => _recommendationResult = res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _recommendError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isRecommending = false);
      }
    }
  }

  Future<void> _startRecommendedVisit(int tourId, {int? tourVersionId}) async {
    setState(() {
      _isRecommending = true;
      _recommendError = null;
    });
    try {
      // Tự động lưu vào lộ trình cá nhân đã lưu khi khách bấm Bắt đầu chuyến tham quan
      try {
        int? resolvedVersionId = tourVersionId;
        if (resolvedVersionId == null) {
          final verRes = await BackendApi.request('tours/$tourId/public-version');
          resolvedVersionId = verRes['id'] as int?;
        }
        if (resolvedVersionId != null) {
          await VisitorExperienceApi.saveRoute(
            tourVersionId: resolvedVersionId,
            availableMinutes: _availableMinutes,
            topicIds: _selectedTopicIds.toList(),
          );
          if (mounted) {
            setState(() => _savedTourVersionId = resolvedVersionId);
          }
        }
      } catch (_) {}

      final visit = await VisitorExperienceApi.startVisit(
        widget.museumId,
        tourId: tourId,
      );
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VisitProgressScreen(
              visitId: visit['id'] as int,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _recommendError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isRecommending = false);
    }
  }

  Future<void> _saveRecommendedRoute(int tourVersionId, int minutes, List<int>? topicIds) async {
    setState(() => _savingCurated = true);
    try {
      await VisitorExperienceApi.saveRoute(
        tourVersionId: tourVersionId,
        availableMinutes: minutes,
        topicIds: topicIds,
      );
      if (mounted) {
        final isEn = AppPreferences.instance.language == 'en';
        setState(() => _savedTourVersionId = tourVersionId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn
                ? 'Route saved to your personal list!'
                : 'Đã lưu lộ trình này vào danh sách của bạn!'),
            backgroundColor: AppColors.deepBurgundy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isEn = AppPreferences.instance.language == 'en';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Failed to save route: $e' : 'Lỗi khi lưu lộ trình: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingCurated = false);
    }
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.deepBurgundy : VisitorColors.surface2,
            borderRadius: BorderRadius.circular(VisitorRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.antiqueIvory : AppColors.darkBrown,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.antiqueIvory : AppColors.darkBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartMatchTab(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VisitorColors.surface2,
            borderRadius: BorderRadius.circular(VisitorRadius.md),
            border: Border.all(color: VisitorColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.deepBurgundy, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.isEn
                      ? 'Smart Match: Discover officially curated museum routes tailored to your schedule and favorite topics.'
                      : 'Gợi ý thông minh: Tìm và xếp hạng các tuyến tham quan chuẩn của bảo tàng phù hợp nhất với quỹ thời gian và chủ đề bạn yêu thích.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.darkBrown, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.isEn ? 'How much time do you have?' : 'Bạn có bao nhiêu thời gian?',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [30, 45, 60, 90, 120].map((v) {
            final isSel = _availableMinutes == v;
            return ChoiceChip(
              label: Text(l10n.isEn ? '$v mins' : '$v phút'),
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSel ? AppColors.antiqueIvory : AppColors.darkBrown,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: AppColors.antiqueIvory,
              selected: isSel,
              selectedColor: AppColors.deepBurgundy,
              backgroundColor: VisitorColors.surface2,
              onSelected: _isRecommending ? null : (_) => setState(() => _availableMinutes = v),
            );
          }).toList(),
        ),
        if (_loadingTopics) ...[
          const SizedBox(height: 14),
          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
        ] else if (_topics.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            l10n.isEn ? 'Interested topics (optional):' : 'Chủ đề quan tâm (tùy chọn):',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topics.map((t) {
              final id = t['id'] as int;
              final name = (t['name'] ?? '').toString();
              final isSel = _selectedTopicIds.contains(id);
              return FilterChip(
                label: Text(name),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSel ? AppColors.antiqueIvory : AppColors.darkBrown,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: AppColors.antiqueIvory,
                selected: isSel,
                selectedColor: AppColors.deepBurgundy,
                backgroundColor: VisitorColors.surface2,
                onSelected: _isRecommending ? null : (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTopicIds.add(id);
                    } else {
                      _selectedTopicIds.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: _isRecommending
              ? (l10n.isEn ? 'Evaluating tours…' : 'Đang tìm tour phù hợp…')
              : (l10n.isEn ? 'Find Best Matching Tour' : 'Gợi ý tour phù hợp nhất'),
          icon: Icons.psychology_outlined,
          onPressed: _isRecommending ? null : _onRecommend,
        ),
        if (_recommendError != null) ...[
          const SizedBox(height: 14),
          Notice(_recommendError!),
        ],
        if (_recommendationResult != null) ...[
          const SizedBox(height: 18),
          _buildRecommendationResultView(context, l10n),
        ],
      ],
    );
  }

  Widget _buildRecommendationResultView(BuildContext context, AppLocalizations l10n) {
    final recs = (_recommendationResult!['recommendations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final fallbackCode = _recommendationResult!['fallbackCode'] as String?;
    final fallbackExplanation = _recommendationResult!['fallbackExplanation'] as String?;
    final fallbackSuggestion = _recommendationResult!['fallbackSuggestion'] as Map<String, dynamic>?;

    if (recs.isNotEmpty) {
      final rec = recs.first;
      final tourId = rec['tourId'] as int;
      final tourVersionId = rec['tourVersionId'] as int;
      final totalScore = rec['totalScore'] is num ? (rec['totalScore'] as num).toDouble() : 1.0;
      final matchPercent = (totalScore * 100).toInt().clamp(0, 100);
      final explanation = (rec['explanation'] ?? '').toString();
      final artifactCount = (rec['artifactIds'] as List?)?.length ?? 0;
      final isSaved = _savedTourVersionId == tourVersionId;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VisitorColors.surface1,
          borderRadius: BorderRadius.circular(VisitorRadius.xl),
          border: Border.all(color: AppColors.mutedGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBurgundy.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.deepBurgundy,
                    borderRadius: BorderRadius.circular(VisitorRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.antiqueIvory),
                      const SizedBox(width: 4),
                      Text(
                        l10n.isEn ? 'Best Match: $matchPercent%' : 'Khớp $matchPercent%',
                        style: const TextStyle(
                          color: AppColors.antiqueIvory,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.isEn ? 'Recommended Route' : 'Đề xuất hàng đầu',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              rec['title'] ?? '',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if ((rec['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                rec['description'],
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkBrown.withOpacity(0.8)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppColors.darkBrown.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      l10n.isEn ? '${rec['estimatedMinutes']} mins' : '${rec['estimatedMinutes']} phút',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined, size: 14, color: AppColors.darkBrown.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      l10n.isEn ? '$artifactCount stops' : '$artifactCount điểm dừng',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VisitorColors.surface2,
                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.deepBurgundy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation,
                        style: AppTextStyles.caption.copyWith(color: AppColors.darkBrown),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.isEn ? 'Start Curated Tour' : 'Bắt đầu chuyến tham quan',
              icon: Icons.play_arrow_rounded,
              onPressed: _isRecommending
                  ? null
                  : () => _startRecommendedVisit(
                        tourId,
                        tourVersionId: tourVersionId,
                      ),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: l10n.isEn ? 'Tour Details' : 'Xem chi tiết',
              icon: Icons.visibility_outlined,
              onPressed: () => openPage(
                context,
                PublishedTourDetailScreen(
                  tourId: tourId,
                  selectedTopicIds: _selectedTopicIds.toList(),
                  availableMinutes: _availableMinutes,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback UI
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepBurgundy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(color: AppColors.deepBurgundy.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.deepBurgundy, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fallbackExplanation ??
                      (l10n.isEn
                          ? 'No curated tour matches this duration.'
                          : 'Chưa có tour có sẵn nào khớp với thời gian này.'),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepBurgundy,
                  ),
                ),
              ),
            ],
          ),
          if (fallbackSuggestion != null) ...[
            const SizedBox(height: 14),
            Text(
              l10n.isEn ? 'Closest museum tour available:' : 'Tour thay thế gần nhất của bảo tàng:',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => openPage(
                context,
                PublishedTourDetailScreen(tourId: fallbackSuggestion['tourId'] as int),
              ),
              borderRadius: BorderRadius.circular(VisitorRadius.md),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.deepBurgundy,
                        borderRadius: BorderRadius.circular(VisitorRadius.sm),
                      ),
                      child: const Icon(Icons.route_outlined, color: AppColors.antiqueIvory, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fallbackSuggestion['title'] ?? '',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n.isEn
                                ? '${fallbackSuggestion['estimatedMinutes']} mins • ${(fallbackSuggestion['artifactIds'] as List?)?.length ?? 0} stops'
                                : '${fallbackSuggestion['estimatedMinutes']} phút • ${(fallbackSuggestion['artifactIds'] as List?)?.length ?? 0} điểm dừng',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondaryText),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Bridge to AI Personalized Route
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.antiqueIvory,
              borderRadius: BorderRadius.circular(VisitorRadius.md),
              border: Border.all(color: AppColors.mutedGold),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.deepBurgundy, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.isEn ? 'Need a flexible route?' : 'Bạn cần thời gian linh hoạt hơn?',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.isEn
                      ? 'AI can build an itinerary from scratch to match your exact $_availableMinutes minutes schedule.'
                      : 'AI có thể tự động nhặt các hiện vật lẻ để ghép lộ trình vừa khít với $_availableMinutes phút của bạn.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.darkBrown),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.deepBurgundy),
                    label: Text(
                      l10n.isEn ? 'Create Custom AI Route' : 'Chuyển sang AI tạo lộ trình',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepBurgundy,
                      side: const BorderSide(color: AppColors.deepBurgundy),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final museumName = AppServices.catalog.museumName(widget.museumId.toString());

    return MuseumPage(
      back: true,
      title: l10n.isEn ? 'Curated Tours' : 'Các tuyến tham quan',
      subtitle: museumName,
      children: [
        Eyebrow(l10n.isEn ? 'THEMATIC EXPLORATION ROUTES' : 'TUYẾN KHÁM PHÁ CHỦ ĐỀ'),
        const SizedBox(height: 6),
        Text(l10n.isEn ? 'Available Curated Tours' : 'Tuyến tham quan có sẵn', style: AppTextStyles.pageTitle),
        if (widget.maxMinutes != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.isEn ? 'Filtered by max duration ${widget.maxMinutes} mins' : 'Lọc theo thời lượng tối đa ${widget.maxMinutes} phút',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.deepBurgundy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Tabs: Tất cả tuyến vs Gợi ý thông minh (WF-02) vs Lộ trình đã lưu (F05)
        Row(
          children: [
            _buildTabItem(0, l10n.isEn ? 'All Tours' : 'Tất cả tuyến', Icons.list_alt_rounded),
            const SizedBox(width: 8),
            _buildTabItem(1, l10n.isEn ? 'Smart Match' : 'Gợi ý phù hợp', Icons.auto_awesome_outlined),
            const SizedBox(width: 8),
            _buildTabItem(2, l10n.isEn ? 'Saved' : 'Đã lưu', Icons.bookmark_outline),
          ],
        ),
        const SizedBox(height: 16),

        if (_selectedTab == 0)
        BackendPanel(
          resourceKey: 'published-tours:${widget.museumId}:${widget.maxMinutes}',
          load: () => BackendApi.list('tours?museumId=${widget.museumId}'),
          builder: (data, reload) {
            final rows = (data as List)
                .cast<Map<String, dynamic>>()
                .where(
                  (t) =>
                      widget.maxMinutes == null ||
                      (t['estimatedMinutes'] as num) <= widget.maxMinutes!,
                )
                .toList();
            return Column(
              children: [
                if (rows.isEmpty)
                  Notice(l10n.isEn ? 'No matching curated tours found.' : 'Chưa có tuyến đã xuất bản phù hợp.')
                else
                  for (final tour in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => openPage(
                          context,
                          PublishedTourDetailScreen(tourId: tour['id'] as int),
                        ),
                        borderRadius: BorderRadius.circular(VisitorRadius.xl),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: VisitorColors.surface1,
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.deepBurgundy,
                                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                                ),
                                child: const Icon(
                                  Icons.route_outlined,
                                  color: AppColors.antiqueIvory,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tour['title'] ?? '',
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 13,
                                              color: AppColors.darkBrown
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.isEn ? '${tour['estimatedMinutes']} mins' : '${tour['estimatedMinutes']} phút',
                                              style:
                                                  AppTextStyles.caption.copyWith(
                                                color: AppColors.darkBrown
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.flag_outlined,
                                              size: 13,
                                              color: AppColors.darkBrown
                                                  .withOpacity(0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.isEn ? '${(tour['items'] as List).length} stops' : '${(tour['items'] as List).length} điểm dừng',
                                              style:
                                                  AppTextStyles.caption.copyWith(
                                                color: AppColors.darkBrown
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.darkBrown.withOpacity(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        )
        else if (_selectedTab == 1)
          _buildSmartMatchTab(context, l10n)
        else
          // Tab 2: Saved Routes (GET /api/tours/saved-routes)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: VisitorExperienceApi.getSavedRoutes(museumId: widget.museumId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ));
              }
              final saved = snapshot.data ?? [];
              if (saved.isEmpty) {
                return Column(
                  children: [
                    Notice(l10n.isEn
                        ? 'You have not saved any routes for this museum. Click "Save Route" when viewing a tour to remember.'
                        : 'Bạn chưa lưu lộ trình nào cho bảo tàng này. Khi xem chi tiết tuyến tham quan, bấm "Lưu lộ trình" để ghi nhớ.'),
                  ],
                );
              }
              return Column(
                children: [
                  for (final item in saved)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          final tourId = item['tourId'] as int?;
                          if (tourId != null) {
                            openPage(
                              context,
                              PublishedTourDetailScreen(
                                tourId: tourId,
                                savedRoute: item,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(VisitorRadius.xl),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: VisitorColors.surface1,
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.mutedGold,
                                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                                ),
                                child: const Icon(
                                  Icons.bookmark,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? (l10n.isEn ? 'Saved Route' : 'Lộ trình đã lưu'),
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          l10n.isEn ? '${item['estimatedMinutes'] ?? item['availableMinutes']} mins' : '${item['estimatedMinutes'] ?? item['availableMinutes']} phút',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.deepBurgundy,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          l10n.isEn ? '${(item['artifactIds'] as List?)?.length ?? 0} stops' : '${(item['artifactIds'] as List?)?.length ?? 0} trạm dừng',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.darkBrown.withOpacity(0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.mutedGold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (widget.maxMinutes != null)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () =>
                  openPage(context, PublishedToursScreen(museumId: widget.museumId)),
              child: Text(l10n.isEn ? 'View all available tours' : 'Xem tất cả tuyến tham quan'),
            ),
          ),
      ],
    );
  }
}

class PublishedTourDetailScreen extends StatefulWidget {
  const PublishedTourDetailScreen({
    super.key,
    required this.tourId,
    this.selectedTopicIds,
    this.availableMinutes,
    this.savedRoute,
  });
  final int tourId;
  final List<int>? selectedTopicIds;
  final int? availableMinutes;
  final Map<String, dynamic>? savedRoute;
  @override
  State<PublishedTourDetailScreen> createState() =>
      _PublishedTourDetailScreenState();
}

class _PublishedTourDetailScreenState extends State<PublishedTourDetailScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _autoSaveAndStartTour(Map<String, dynamic> tour) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final museumId = tour['museumId'] as int;
    try {
      final savedRouteId = widget.savedRoute?['id'] as int?;
      final Map<String, dynamic> visit;
      if (savedRouteId != null) {
        // Nếu mở từ Hành trình cá nhân đã lưu (đang ghim phiên bản cũ như v1),
        // bắt đầu chuyến tham quan theo đúng savedRouteId để giữ nguyên phiên bản v1 đã lưu!
        final res = await BackendApi.request(
          'visits',
          method: 'POST',
          body: {
            'museumId': museumId,
            'savedRouteId': savedRouteId,
          },
        );
        visit = Map<String, dynamic>.from(res as Map);
      } else {
        // Tự động lưu lộ trình vào Hành trình cá nhân đã lưu khi khách bấm Bắt đầu chuyến tham quan mới
        try {
          final versionRes = await BackendApi.request('tours/${widget.tourId}/public-version');
          final versionId = versionRes['id'] as int?;
          final minutes = widget.availableMinutes ??
              (tour['estimatedMinutes'] is num ? (tour['estimatedMinutes'] as num).toInt() : 60);
          if (versionId != null) {
            await VisitorExperienceApi.saveRoute(
              tourVersionId: versionId,
              availableMinutes: minutes,
              topicIds: widget.selectedTopicIds,
            );
          }
        } catch (_) {}

        visit = await VisitorExperienceApi.startVisit(
          museumId,
          tourId: widget.tourId,
        );
      }
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VisitProgressScreen(
              visitId: visit['id'] as int,
            ),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('đang có lượt tham quan') || msg.contains('409')) {
        try {
          final list = await BackendApi.list('visits/me?status=InProgress');
          final active = list.firstWhere(
            (v) => v['museumId'] == museumId,
            orElse: () => list.isNotEmpty ? list.first : <String, dynamic>{},
          );
          if (active.isNotEmpty && mounted) {
            final isEn = AppPreferences.instance.language == 'en';
            final activeId = active['id'] as int;
            final action = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VisitorRadius.xl)),
                title: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.deepBurgundy, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEn ? 'Active Visit in Progress' : 'Chuyến đi đang diễn ra',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  isEn
                      ? 'You already have an active visit #$activeId at this museum. This tour has been saved to your personal list. Would you like to view your current visit progress?'
                      : 'Lộ trình này đã được tự động lưu vào Hành trình cá nhân của bạn! Hiện bạn đang có chuyến tham quan #$activeId chưa kết thúc, bạn có muốn mở tiến độ chuyến đi đó không?',
                  style: AppTextStyles.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                    child: Text(isEn ? 'Close' : 'Đóng'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
                    onPressed: () => Navigator.pop(ctx, 'continue'),
                    child: Text(isEn ? 'View Current Visit' : 'Xem tiến độ chuyến đang đi'),
                  ),
                ],
              ),
            );
            if (mounted && action == 'continue') {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VisitProgressScreen(visitId: activeId),
                ),
              );
            }
            return;
          }
        } catch (_) {}
      }
      if (mounted) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MuseumPage(
    back: true,
    title: l10n.isEn ? 'Tour Details' : 'Tuyến tham quan',
    children: [
      if (_error != null) Notice(_error!),
      BackendPanel(
        resourceKey: 'tour:${widget.tourId}:${widget.savedRoute?['tourVersionId'] ?? 'latest'}',
        load: () => BackendApi.request('tours/${widget.tourId}'),
        builder: (data, reload) {
          final rawTour = Map<String, dynamic>.from(data as Map);
          final saved = widget.savedRoute;
          final Map<String, dynamic> tour;
          final List<Map<String, dynamic>> items;
          if (saved != null) {
            final savedArtIds = (saved['artifactIds'] as List?) ?? const [];
            items = [
              for (var i = 0; i < savedArtIds.length; i++)
                <String, dynamic>{
                  'artifactId': savedArtIds[i],
                  'orderNo': i + 1,
                },
            ];
            tour = {
              ...rawTour,
              if (saved['title'] != null) 'title': saved['title'],
              if (saved['description'] != null) 'description': saved['description'],
              if (saved['estimatedMinutes'] != null) 'estimatedMinutes': saved['estimatedMinutes'],
              'items': items,
            };
          } else {
            tour = rawTour;
            items = (tour['items'] as List).cast<Map<String, dynamic>>().toList()
              ..sort(
                (a, b) => (a['orderNo'] as int).compareTo(b['orderNo'] as int),
              );
          }
          final museumName =
              AppServices.catalog.museumName(tour['museumId'].toString());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Itinerary Header Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.deepBurgundy,
                  borderRadius: BorderRadius.circular(VisitorRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(VisitorRadius.xs),
                            border: Border.all(
                              color: AppColors.mutedGold,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 13,
                                color: AppColors.mutedGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.isEn ? 'FEATURED TOUR' : 'TUYẾN TIÊU BIỂU',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: AppColors.antiqueIvory,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tour['title'] ?? '',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 20,
                        color: AppColors.antiqueIvory,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (museumName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        museumName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.antiqueIvory.withOpacity(0.8),
                        ),
                      ),
                    ],
                    if (tour['description'] != null &&
                        (tour['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        tour['description'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.antiqueIvory.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),

                    // Metrics row
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: AppColors.mutedGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.isEn ? '${tour['estimatedMinutes']} mins' : '${tour['estimatedMinutes']} phút',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.antiqueIvory,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.museum_outlined,
                              size: 16,
                              color: AppColors.mutedGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${items.length} điểm dừng',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.antiqueIvory,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SectionHeading(l10n.isEn ? 'Tour Stops Route' : 'Lộ trình các điểm dừng'),
              const SizedBox(height: 12),

              // Connected Timeline
              for (var i = 0; i < items.length; i++) ...[
                () {
                  final item = items[i];
                  final artifact = AppServices.catalog.artifacts
                      .where((a) => a.id == item['artifactId'].toString())
                      .firstOrNull;
                  final artifactName =
                      artifact?.name ?? (l10n.isEn ? 'Artifact #${item['artifactId']}' : 'Hiện vật #${item['artifactId']}');
                  final location = artifact?.location ?? '';
                  final isLast = i == items.length - 1;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: VisitorColors.surface1,
                          borderRadius: BorderRadius.circular(VisitorRadius.lg),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.deepBurgundy,
                              ),
                              child: Center(
                                child: Text(
                                  '${item['orderNo'] ?? (i + 1)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.antiqueIvory,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artifactName,
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (location.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.room_outlined,
                                          size: 13,
                                          color: AppColors.darkBrown
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style:
                                                AppTextStyles.caption.copyWith(
                                              color: AppColors.darkBrown
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (artifact?.imageUrl.isNotEmpty == true) ...[
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(VisitorRadius.sm),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.antiqueIvory,
                                  child: Image.network(
                                    artifact!.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.museum_outlined,
                                      size: 24,
                                      color: AppColors.deepBurgundy,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(left: 28),
                                width: 2,
                                height: 24,
                                color: AppColors.mutedGold.withOpacity(0.5),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                l10n.isEn ? 'Proceed to next stop' : 'Di chuyển sang điểm tiếp theo',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.darkBrown.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }(),
              ],

              const SizedBox(height: 24),
              PrimaryButton(
                label: _busy ? (l10n.isEn ? 'Starting…' : 'Đang bắt đầu…') : (l10n.isEn ? 'Start Museum Tour' : 'Bắt đầu chuyến tham quan'),
                icon: Icons.play_arrow_rounded,
                onPressed: _busy ? null : () => _autoSaveAndStartTour(tour),
              ),
            ],
          );
        },
      ),
    ],
    );
  }
}
