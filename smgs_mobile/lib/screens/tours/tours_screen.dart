import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../data/mock/mock_museums.dart';
import '../../data/mock/mock_artifacts.dart';
import '../../data/visit_store.dart';
import '../artifact/artifact_detail_screen.dart';

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
  String _interest = 'Lịch sử';
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
        children: ['Lịch sử', 'Nghệ thuật', 'Văn hóa']
            .map(
              (v) => ChoiceChip(
                label: Text(v),
                selected: _interest == v,
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _interest == v
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
                onSelected: (_) => setState(() => _interest = v),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 28),
      PrimaryButton(
        label: 'Gợi ý hành trình',
        icon: Icons.route_outlined,
        onPressed: () {
          var stops = mockArtifacts
              .where((a) => a.museumId == _museumId)
              .toList();
          if (_interest == 'Nghệ thuật') {
            stops = stops.reversed.toList();
          }
          if (_duration == 30) {
            stops = stops.take(1).toList();
          }
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
  int _stop = 0;
  @override
  Widget build(BuildContext context) {
    final a = widget.stops[_stop];
    final museum = mockMuseums.firstWhere((m) => m.id == a.museumId);
    return MuseumPage(
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
                  'Bạn đã đi qua ${widget.stops.length} điểm dừng.',
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
                        Text(e.value.location, style: AppTextStyles.bodySmall),
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
          HeritageArt(kind: a.id, height: 210),
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
            'Tìm phòng theo biển chỉ dẫn tại bảo tàng. Sơ đồ dẫn đường trong nhà chưa được cung cấp.',
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
            onPressed: () {
              if (_stop == widget.stops.length - 1) {
                VisitStore.instance.finishTour();
                setState(() => _done = true);
              } else {
                setState(() => _stop++);
              }
            },
          ),
        ],
      ],
    );
  }
}
