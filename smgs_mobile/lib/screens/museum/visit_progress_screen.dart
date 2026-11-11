import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/visitor_experience_api.dart';
import '../../services/app_services.dart';
import '../artifact/artifact_qr_scanner.dart';
import 'visitor_directory_screen.dart';
import '../profile/profile_screen.dart';

class VisitProgressScreen extends StatefulWidget {
  const VisitProgressScreen({super.key, required this.visitId});
  final int visitId;
  @override
  State<VisitProgressScreen> createState() => _VisitProgressScreenState();
}

class _VisitProgressScreenState extends State<VisitProgressScreen> {
  bool _busy = false;
  String? _error;
  void _openMap(Map<String, dynamic> visit) {
    openPage(
      context,
      VisitorDirectoryScreen(
        museumId: visit['museumId'] as int,
        museumName: AppServices.catalog.museumName(
          visit['museumId'].toString(),
        ),
        visitId: widget.visitId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Chuyến tham quan của bạn',
    children: [
      if (_error != null) Notice(_error!),
      BackendPanel(
        resourceKey: 'visit-progress:${widget.visitId}',
        load: () => Future.wait([
          BackendApi.request('visits/${widget.visitId}'),
          VisitorExperienceApi.progress(widget.visitId),
        ]),
        builder: (data, reload) {
          final visit = Map<String, dynamic>.from(data[0]);
          final progress = data[1] as Map<String, dynamic>;
          final stops = (progress['stops'] as List)
              .cast<Map<String, dynamic>>();
          final active = visit['status'] == 'InProgress';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppServices.catalog.museumName(visit['museumId'].toString()),
                style: AppTextStyles.cardTitle,
              ),
              Text(backendStatus(visit['status'])),
              if (visit['personalizedTourId'] != null)
                const Text('Hành trình cá nhân · Thứ tự điểm dừng đã được lưu'),
              Text('Bắt đầu: ${visit['startedAt']}'),
              TextButton(
                onPressed: reload,
                child: const Text('Cập nhật tiến độ'),
              ),
              if (stops.isEmpty)
                const Notice(
                  'Lượt tham quan tự do. Quét QR tại hiện vật để ghi nhận khám phá.',
                ),
              for (final stop in stops)
                ListTile(
                  leading: Icon(
                    stop['lastVisitedAt'] == null
                        ? Icons.radio_button_unchecked
                        : Icons.check_circle_outline,
                  ),
                  title: Text(
                    AppServices.catalog.artifacts
                            .where((a) => a.id == stop['artifactId'].toString())
                            .firstOrNull
                            ?.name ??
                        'Hiện vật #${stop['artifactId']}',
                  ),
                  subtitle: Text(
                    stop['lastVisitedAt'] == null
                        ? 'Chưa ghi nhận quét'
                        : 'Đã quét: ${stop['lastVisitedAt']}',
                  ),
                ),
              if (active) ...[
                PrimaryButton(
                  label: 'Quét QR để ghi nhận',
                  icon: Icons.qr_code_scanner,
                  onPressed: _busy
                      ? null
                      : () async {
                          VisitorSession.activeVisit = visit;
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ArtifactQrScanner(visitId: widget.visitId),
                            ),
                          );
                          reload();
                        },
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Chỉ đường trên sơ đồ bảo tàng',
                  icon: Icons.map_outlined,
                  onPressed: () => _openMap(visit),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: _busy ? 'Đang hoàn tất…' : 'Kết thúc chuyến tham quan',
                  onPressed: _busy
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Kết thúc chuyến tham quan?'),
                              content: const Text(
                                'Hệ thống sẽ kiểm tra điều kiện hoàn thành của tuyến tham quan.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Tiếp tục tham quan'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Kết thúc'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true || !mounted) return;
                          setState(() {
                            _busy = true;
                            _error = null;
                          });
                          try {
                            await BackendApi.request(
                              'visits/${widget.visitId}/complete',
                              method: 'POST',
                              body: {},
                            );
                            if (VisitorSession.activeVisit?['id'] ==
                                widget.visitId) {
                              VisitorSession.clear();
                            }
                            reload();
                          } catch (e) {
                            if (mounted) setState(() => _error = e.toString());
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
              ],
              if (visit['status'] == 'Completed')
                TextButton(
                  onPressed: () async {
                    await openVisitFeedback(context, visit);
                    reload();
                  },
                  child: Text(
                    visit['hasFeedback'] == true
                        ? 'Xem / chỉnh sửa đánh giá'
                        : 'Đánh giá chuyến tham quan',
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
