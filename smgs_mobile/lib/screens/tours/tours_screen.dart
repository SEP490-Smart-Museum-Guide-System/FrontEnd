import 'personalized_tour_screen.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../data/visit_store.dart';
import '../artifact/artifact_detail_screen.dart';
import '../museum/visitor_indoor_map_screen.dart';
import '../../services/app_services.dart';
import '../../widgets/museum_route_map.dart';

class ToursScreen extends StatelessWidget {
  const ToursScreen({super.key, this.standalone = false, this.museumId = ''});
  final bool standalone;
  final String museumId;
  @override
  Widget build(BuildContext context) =>
      PersonalizedTourBuilder(standalone: standalone, museumId: museumId);
}

class TourRouteScreen extends StatefulWidget {
  const TourRouteScreen({
    super.key,
    required this.stops,
    required this.duration,
    required this.interest,
  });
  final List<Artifact> stops;
  final int duration;
  final String interest;
  @override
  State<TourRouteScreen> createState() => _TourRouteScreenState();
}

class _TourRouteScreenState extends State<TourRouteScreen> {
  bool _started = false, _done = false;
  bool _recorded = false;
  final List<String> _visited = [], _skipped = [];
  int _stop = 0;
  void _record(bool completed) {
    if (_recorded || !_started || widget.stops.isEmpty) return;
    _recorded = true;
    VisitStore.instance.finishTour(
      museumId: widget.stops.first.museumId,
      visited: _visited,
      skipped: _skipped,
      completed: completed,
    );
  }

  void _advance({bool skip = false}) {
    (skip ? _skipped : _visited).add(widget.stops[_stop].id);
    if (_stop == widget.stops.length - 1) {
      _record(true);
      setState(() => _done = true);
    } else {
      setState(() => _stop++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.stops.isEmpty) {
      return MuseumPage(
        back: true,
        title: l10n.isEn ? 'No Route Available' : 'Chưa có lộ trình',
        children: [
          EmptyState(
            title: l10n.isEn ? 'Please choose another museum' : 'Hãy chọn lại bảo tàng',
            message: l10n.isEn
                ? 'The collection currently has no matching stops.'
                : 'Bộ sưu tập hiện chưa có điểm dừng phù hợp.',
          ),
        ],
      );
    }
    final a = widget.stops[_stop];
    final museum = AppServices.catalog.museums
        .where((m) => m.id == a.museumId)
        .firstOrNull;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_done) _record(false);
      },
      child: MuseumPage(
        key: ValueKey('$_started-$_done-$_stop'),
        back: true,
        title: _done
            ? (l10n.isEn ? 'Memorable Journey' : 'Hành trình đáng nhớ')
            : _started
            ? (l10n.isEn ? 'Exploring Stop' : 'Dừng chân khám phá')
            : (l10n.isEn ? 'Vietnamese Imprints' : 'Dấu ấn Việt Nam'),
        eyebrow: _done
            ? (l10n.isEn ? 'Completed' : 'Đã hoàn thành')
            : _started
            ? (l10n.isEn
                ? 'Stop ${_stop + 1} / ${widget.stops.length}'
                : 'Điểm dừng ${_stop + 1} / ${widget.stops.length}')
            : (l10n.isEn ? 'Suggested Journey' : 'Hành trình gợi ý'),
        subtitle: (museum?.name ?? (l10n.isEn ? 'Museum' : 'Bảo tàng')),
        children: [
          if (_done) ...[
            Panel(
              gold: true,
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 48,
                    color: AppColors.mutedGold,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.isEn
                        ? 'Thank you for exploring our cultural heritage.'
                        : 'Cảm ơn bạn đã dành thời gian cho di sản.',
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.isEn
                        ? 'Visited ${_visited.length} stops · Skipped ${_skipped.length} stops'
                        : 'Đã ghé ${_visited.length} điểm · Bỏ qua ${_skipped.length} điểm',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.isEn ? 'Return' : 'Trở về',
              onPressed: () => Navigator.pop(context),
            ),
          ] else if (!_started) ...[
            MuseumPhoto(museumId: a.museumId, height: 185),
            const SizedBox(height: 20),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.isEn
                        ? '${widget.duration} minutes of exploration'
                        : '${widget.duration} phút dành cho khám phá',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.isEn
                        ? '${widget.stops.length} stops · Theme: ${widget.interest.toLowerCase()}'
                        : '${widget.stops.length} điểm dừng · Chủ đề ${widget.interest.toLowerCase()}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            SectionHeading(
              l10n.isEn ? 'Your Journey Stops' : 'Những điểm dừng của bạn',
            ),
            MuseumRouteMap(stops: widget.stops, current: 0),
            const SizedBox(height: 20),
            ...widget.stops.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.mutedGold),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${e.key + 1}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value.name, style: AppTextStyles.sectionTitle),
                          Text(
                            e.value.location,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: l10n.isEn ? 'Begin Journey' : 'Bắt đầu hành trình',
              icon: Icons.arrow_forward,
              onPressed: () => setState(() => _started = true),
            ),
          ] else ...[
            LinearProgressIndicator(
              value: (_stop + 1) / widget.stops.length,
              minHeight: 4,
            ),
            const SizedBox(height: 24),
            MuseumRouteMap(
              stops: widget.stops,
              current: _stop,
              visited: _visited,
              skipped: _skipped,
            ),
            const SizedBox(height: 20),
            // Stop details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VisitorColors.surface1,
                borderRadius: BorderRadius.circular(VisitorRadius.xl),
                border: Border.all(
                  color: AppColors.mutedGold.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBurgundy.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.deepBurgundy,
                          borderRadius: BorderRadius.circular(VisitorRadius.full),
                        ),
                        child: Text(
                          l10n.isEn
                              ? 'Stop ${_stop + 1}/${widget.stops.length}'
                              : 'Trạm ${_stop + 1}/${widget.stops.length}',
                          style: const TextStyle(
                            color: AppColors.antiqueIvory,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.room_outlined,
                              size: 13,
                              color: AppColors.deepBurgundy,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                a.location,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.deepBurgundy,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a.name,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.summary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.darkBrown.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => openPage(
                      context,
                      ArtifactDetailScreen(
                        artifact: a,
                        museumName: (museum?.name ?? (l10n.isEn ? 'Museum' : 'Bảo tàng')),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(VisitorRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_stories_outlined,
                            size: 15,
                            color: AppColors.deepBurgundy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.isEn ? 'Read full artifact story' : 'Xem câu chuyện & thuyết minh',
                            style: const TextStyle(
                              color: AppColors.deepBurgundy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: AppColors.deepBurgundy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_stop < widget.stops.length - 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: VisitorColors.surface2,
                  borderRadius: BorderRadius.circular(VisitorRadius.lg),
                  border: Border.all(
                    color: AppColors.mutedGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      size: 16,
                      color: AppColors.deepBurgundy,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: l10n.isEn ? 'Next stop: ' : 'Điểm tiếp theo: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.darkBrown,
                          ),
                          children: [
                            TextSpan(
                              text: '${widget.stops[_stop + 1].name} (${widget.stops[_stop + 1].location})',
                              style: const TextStyle(fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Primary Navigation Button
            PrimaryButton(
              label: _stop == widget.stops.length - 1
                  ? (l10n.isEn ? 'Complete Journey' : 'Hoàn thành hành trình')
                  : (l10n.isEn ? 'Proceed to Next Stop' : 'Đến điểm tiếp theo'),
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _advance(),
            ),

            const SizedBox(height: 10),

            // Ergonomic Quick Utility Bar
            Row(
              children: [
                // Open Indoor Map
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkBrown,
                      side: BorderSide(color: AppColors.mutedGold.withValues(alpha: 0.4)),
                      backgroundColor: VisitorColors.surface2,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VisitorRadius.md),
                      ),
                    ),
                    onPressed: () {
                      final parsedMuseumId = int.tryParse(a.museumId) ?? 1;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VisitorIndoorMapScreen(
                            mapId: parsedMuseumId,
                            museumName: museum?.name ?? (l10n.isEn ? 'Museum' : 'Bảo tàng'),
                            targetArtifactId: int.tryParse(a.id),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF2E7D32)),
                    label: Text(
                      l10n.isEn ? 'Floor Map' : 'Sơ đồ tầng',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Skip stop
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkBrown,
                      side: BorderSide(color: AppColors.mutedGold.withValues(alpha: 0.4)),
                      backgroundColor: VisitorColors.surface2,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VisitorRadius.md),
                      ),
                    ),
                    onPressed: () => _advance(skip: true),
                    icon: const Icon(Icons.skip_next_outlined, size: 16, color: AppColors.deepBurgundy),
                    label: Text(
                      l10n.isEn ? 'Skip' : 'Bỏ qua',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // End early
                InkWell(
                  onTap: () {
                    _record(false);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: VisitorColors.surface2,
                      borderRadius: BorderRadius.circular(VisitorRadius.md),
                      border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      l10n.isEn ? 'Exit' : 'Dừng',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
