import 'personalized_tour_screen.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../data/visit_store.dart';
import '../artifact/artifact_detail_screen.dart';
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
            const SizedBox(height: 24),
            Text(a.name, style: AppTextStyles.pageTitle),
            const SizedBox(height: 12),
            Text(
              a.location,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.deepBurgundy,
              ),
            ),
            const SizedBox(height: 14),
            Text(a.summary, style: AppTextStyles.bodyLarge),
            const SizedBox(height: 22),
            Notice(
              l10n.isEn
                  ? 'The list indicates tour order, not a physical floor route. Progress is kept in the current session.'
                  : 'Danh sách thể hiện thứ tự tham quan, không phải sơ đồ đường đi. Tiến độ được giữ trong phiên hiện tại.',
            ),
            const SizedBox(height: 14),
            Text(
              _stop < widget.stops.length - 1
                  ? (l10n.isEn
                      ? 'Next: ${widget.stops[_stop + 1].name} · ${widget.stops[_stop + 1].location}'
                      : 'Tiếp theo: ${widget.stops[_stop + 1].name} · ${widget.stops[_stop + 1].location}')
                  : (l10n.isEn
                      ? 'This is the final stop of the journey.'
                      : 'Đây là điểm dừng cuối của hành trình.'),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 22),
            SecondaryButton(
              label: l10n.isEn ? 'Learn about artifact' : 'Tìm hiểu hiện vật',
              icon: Icons.menu_book_outlined,
              onPressed: () => openPage(
                context,
                ArtifactDetailScreen(
                  artifact: a,
                  museumName: (museum?.name ?? (l10n.isEn ? 'Museum' : 'Bảo tàng')),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _stop == widget.stops.length - 1
                  ? (l10n.isEn ? 'Complete Journey' : 'Hoàn thành hành trình')
                  : (l10n.isEn ? 'Next Stop' : 'Đến điểm tiếp theo'),
              icon: Icons.arrow_forward,
              onPressed: () => _advance(),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.isEn ? 'Skip this stop' : 'Bỏ qua điểm này',
              icon: Icons.skip_next_outlined,
              onPressed: () => _advance(skip: true),
            ),
            TextButton(
              onPressed: () {
                _record(false);
                Navigator.pop(context);
              },
              child: Text(
                l10n.isEn ? 'End journey early' : 'Kết thúc sớm hành trình',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
