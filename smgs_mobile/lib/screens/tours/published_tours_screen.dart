import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';
import '../../services/visitor_experience_api.dart';
import '../museum/visit_progress_screen.dart';

class PublishedToursScreen extends StatelessWidget {
  const PublishedToursScreen({
    super.key,
    required this.museumId,
    this.maxMinutes,
  });
  final int museumId;
  final int? maxMinutes;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Các tuyến tham quan',
    subtitle: AppServices.catalog.museumName(museumId.toString()),
    children: [
      if (maxMinutes != null) Text('Thời lượng tối đa $maxMinutes phút'),
      BackendPanel(
        resourceKey: 'published-tours:$museumId:$maxMinutes',
        load: () => BackendApi.list('tours?museumId=$museumId'),
        builder: (data, reload) {
          final rows = (data as List)
              .cast<Map<String, dynamic>>()
              .where(
                (t) =>
                    maxMinutes == null ||
                    (t['estimatedMinutes'] as num) <= maxMinutes!,
              )
              .toList();
          return Column(
            children: [
              TextButton(onPressed: reload, child: const Text('Tải lại')),
              if (rows.isEmpty)
                const Notice('Chưa có tuyến đã xuất bản phù hợp.'),
              for (final tour in rows)
                ActionTile(
                  title: tour['title'],
                  subtitle:
                      '${tour['estimatedMinutes']} phút · ${(tour['items'] as List).length} điểm dừng',
                  icon: Icons.route_outlined,
                  onTap: () => openPage(
                    context,
                    PublishedTourDetailScreen(tourId: tour['id'] as int),
                  ),
                ),
            ],
          );
        },
      ),
      if (maxMinutes != null)
        TextButton(
          onPressed: () =>
              openPage(context, PublishedToursScreen(museumId: museumId)),
          child: const Text('Xem tất cả tuyến tham quan'),
        ),
    ],
  );
}

class PublishedTourDetailScreen extends StatefulWidget {
  const PublishedTourDetailScreen({super.key, required this.tourId});
  final int tourId;
  @override
  State<PublishedTourDetailScreen> createState() =>
      _PublishedTourDetailScreenState();
}

class _PublishedTourDetailScreenState extends State<PublishedTourDetailScreen> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Tuyến tham quan',
    children: [
      if (_error != null) Notice(_error!),
      BackendPanel(
        resourceKey: 'tour:${widget.tourId}',
        load: () => BackendApi.request('tours/${widget.tourId}'),
        builder: (data, reload) {
          final tour = data as Map<String, dynamic>;
          final items =
              (tour['items'] as List).cast<Map<String, dynamic>>().toList()
                ..sort(
                  (a, b) =>
                      (a['orderNo'] as int).compareTo(b['orderNo'] as int),
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tour['title'], style: AppTextStyles.pageTitle),
              Text(tour['description'] ?? ''),
              Text('${tour['estimatedMinutes']} phút'),
              for (final item in items)
                ListTile(
                  leading: Text('${item['orderNo']}'),
                  title: Text(
                    AppServices.catalog.artifacts
                            .where((a) => a.id == item['artifactId'].toString())
                            .firstOrNull
                            ?.name ??
                        'Hiện vật #${item['artifactId']}',
                  ),
                ),
              PrimaryButton(
                label: _busy ? 'Đang bắt đầu…' : 'Bắt đầu chuyến tham quan',
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() {
                          _busy = true;
                          _error = null;
                        });
                        try {
                          final visit = await VisitorExperienceApi.startVisit(
                            tour['museumId'] as int,
                            tourId: widget.tourId,
                          );
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
                          if (mounted) setState(() => _error = e.toString());
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
              ),
            ],
          );
        },
      ),
    ],
  );
}
