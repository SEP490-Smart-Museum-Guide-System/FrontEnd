import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../models/experience.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import 'profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _visits = BackendApi.list(
    'visits/me',
  );
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Lịch sử tham quan',
    children: [
      TextButton(
        onPressed: () => setState(() => _visits = BackendApi.list('visits/me')),
        child: const Text('Tải lại'),
      ),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _visits,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const CircularProgressIndicator();
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          if (snapshot.data!.isEmpty)
            return const EmptyState(
              title: 'Chưa có lượt tham quan',
              message:
                  'Bắt đầu lượt tham quan từ trang bảo tàng để lưu lịch sử.',
            );
          return Column(
            children: snapshot.data!
                .map(
                  (v) => ActionTile(
                    title: AppServices.catalog.museumName(
                      v['museumId'].toString(),
                    ),
                    subtitle: '${v['startedAt']} · ${v['status']}',
                    icon: Icons.history,
                    onTap: () => openPage(
                      context,
                      VisitDetailScreen(
                        visit: VisitRecord(
                          id: v['id'].toString(),
                          museumId: v['museumId'].toString(),
                          date: DateTime.parse(v['startedAt']),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class VisitDetailScreen extends StatefulWidget {
  const VisitDetailScreen({super.key, required this.visit});
  final VisitRecord visit;
  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  late Future<dynamic> _data = BackendApi.request('visits/${widget.visit.id}');
  String? _error;
  bool _busy = false;
  Future<void> _complete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BackendApi.request(
        'visits/${widget.visit.id}/complete',
        method: 'POST',
        body: {},
      );
      if (mounted)
        setState(() => _data = BackendApi.request('visits/${widget.visit.id}'));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Lượt tham quan',
    subtitle: AppServices.catalog.museumName(widget.visit.museumId),
    children: [
      if (_error != null) Notice(_error!),
      FutureBuilder<dynamic>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const CircularProgressIndicator();
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          final v = snapshot.data as Map<String, dynamic>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trạng thái: ${v['status']}'),
              Text('Bắt đầu: ${v['startedAt']}'),
              if (v['completedAt'] != null)
                Text('Kết thúc: ${v['completedAt']}'),
              if (v['status'] == 'InProgress')
                PrimaryButton(
                  label: _busy ? 'Đang gửi…' : 'Kết thúc lượt tham quan',
                  onPressed: _busy ? null : _complete,
                ),
              if (v['status'] == 'Completed' && v['hasFeedback'] != true)
                PrimaryButton(
                  label: 'Đánh giá lượt tham quan',
                  onPressed: () => openPage(
                    context,
                    FeedbackScreen(
                      targetType: 'visit',
                      targetId: widget.visit.id,
                      targetName: AppServices.catalog.museumName(
                        widget.visit.museumId,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
