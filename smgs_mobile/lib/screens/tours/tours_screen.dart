import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../data/mock/mock_museums.dart';
import '../../data/visit_store.dart';
import '../artifact/artifact_detail_screen.dart';
import '../../services/app_services.dart';
import '../../widgets/museum_route_map.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({
    super.key,
    this.standalone = false,
    this.museumId = 'museum_national',
  });
  final bool standalone;
  final String museumId;
  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  int _duration = 60;
  final Set<String> _interests = {'Lịch sử'};
  String get _interest => _interests.join(', ');
  late String _museumId = widget.museumId;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: widget.standalone,
    title: 'Đi theo điều\nbạn yêu thích.',
    eyebrow: 'Hành trình của bạn',
    subtitle: 'Một lộ trình vừa vặn với thời gian và sự tò mò của bạn.',
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MuseumPhoto(museumId: _museumId, height: 180),
      ),
      const SectionHeading('Bạn muốn ghé thăm đâu?'),
      DropdownButtonFormField<String>(
        initialValue: _museumId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Bảo tàng'),
        items: mockMuseums
            .map(
              (m) => DropdownMenuItem(
                value: m.id,
                child: Text(m.name, style: AppTextStyles.bodySmall),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _museumId = value!),
      ),
      const SectionHeading('Bạn có bao nhiêu thời gian?'),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [30, 60, 90, 120]
            .map(
              (v) => ChoiceChip(
                label: Text('$v phút'),
                selected: _duration == v,
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _duration == v
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
                onSelected: (_) => setState(() => _duration = v),
              ),
            )
            .toList(),
      ),
      const SectionHeading('Điều gì khiến bạn tò mò?'),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: ['Lịch sử', 'Nghệ thuật', 'Văn hóa', 'Khoa học']
            .map(
              (v) => ChoiceChip(
                label: Text(v),
                selected: _interests.contains(v),
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _interests.contains(v)
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
                onSelected: (selected) => setState(() {
                  selected ? _interests.add(v) : _interests.remove(v);
                }),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 28),
      if (_interests.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Notice('Chọn ít nhất một sở thích để tạo hành trình.'),
        ),
      PrimaryButton(
        label: 'Gợi ý hành trình',
        icon: Icons.route_outlined,
        onPressed: _interests.isEmpty
            ? null
            : () {
                final stops = AppServices.tours.plan(
                  _museumId,
                  _duration,
                  _interests,
                );
                openPage(
                  context,
                  TourRouteScreen(
                    stops: stops,
                    duration: _duration,
                    interest: _interest,
                  ),
                );
              },
      ),
      const SizedBox(height: 18),
      const Notice(
        'Lộ trình được gợi ý từ bộ sưu tập mẫu. Bạn có thể điều chỉnh nhịp tham quan tùy ý.',
      ),
    ],
  );
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
    if (widget.stops.isEmpty) {
      return const MuseumPage(
        back: true,
        title: 'Chưa có lộ trình',
        children: [
          EmptyState(
            title: 'Hãy chọn lại bảo tàng',
            message: 'Bộ sưu tập hiện chưa có điểm dừng phù hợp.',
          ),
        ],
      );
    }
    final a = widget.stops[_stop];
    final museum = mockMuseums.firstWhere((m) => m.id == a.museumId);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_done) _record(false);
      },
      child: MuseumPage(
        key: ValueKey('$_started-$_done-$_stop'),
        back: true,
        title: _done
            ? 'Hành trình đáng nhớ'
            : _started
            ? 'Dừng chân khám phá'
            : 'Dấu ấn Việt Nam',
        eyebrow: _done
            ? 'Đã hoàn thành'
            : _started
            ? 'Điểm dừng ${_stop + 1} / ${widget.stops.length}'
            : 'Hành trình gợi ý',
        subtitle: museum.name,
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
                  const Text(
                    'Cảm ơn bạn đã dành thời gian cho di sản.',
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đã ghé ${_visited.length} điểm · Bỏ qua ${_skipped.length} điểm',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Trở về',
              onPressed: () => Navigator.pop(context),
            ),
          ] else if (!_started) ...[
            MuseumPhoto(museumId: museum.id, height: 185),
            const SizedBox(height: 20),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.duration} phút dành cho khám phá',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.stops.length} điểm dừng · Chủ đề ${widget.interest.toLowerCase()}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SectionHeading('Những điểm dừng của bạn'),
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
              label: 'Bắt đầu hành trình',
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
            const Notice(
              'Sơ đồ minh họa, không định vị trực tiếp. Tìm phòng theo biển chỉ dẫn tại bảo tàng.',
            ),
            const SizedBox(height: 14),
            Text(
              _stop < widget.stops.length - 1
                  ? 'Tiếp theo: ${widget.stops[_stop + 1].name} · ${widget.stops[_stop + 1].location}'
                  : 'Đây là điểm dừng cuối của hành trình.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 22),
            SecondaryButton(
              label: 'Tìm hiểu hiện vật',
              icon: Icons.menu_book_outlined,
              onPressed: () => openPage(
                context,
                ArtifactDetailScreen(artifact: a, museumName: museum.name),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _stop == widget.stops.length - 1
                  ? 'Hoàn thành hành trình'
                  : 'Đến điểm tiếp theo',
              icon: Icons.arrow_forward,
              onPressed: () => _advance(),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Bỏ qua điểm này',
              icon: Icons.skip_next_outlined,
              onPressed: () => _advance(skip: true),
            ),
            TextButton(
              onPressed: () {
                _record(false);
                Navigator.pop(context);
              },
              child: const Text('Kết thúc sớm hành trình'),
            ),
          ],
        ],
      ),
    );
  }
}
