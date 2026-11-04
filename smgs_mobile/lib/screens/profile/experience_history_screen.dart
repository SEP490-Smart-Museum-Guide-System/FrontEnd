import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/backend_panel.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';
import '../artifact/daily_quiz_screen.dart';
import '../artifact/artifact_detail_screen.dart';
import '../../models/artifact.dart';

class ExperienceHistoryScreen extends StatelessWidget {
  const ExperienceHistoryScreen({super.key, required this.kind});
  final String kind;
  String get path => kind == 'quiz'
      ? 'quiz-attempts/me'
      : kind == 'points'
      ? 'gamification/me/transactions'
      : 'recognitions/me';
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: kind == 'quiz'
        ? 'Lịch sử thử tài'
        : kind == 'points'
        ? 'Sổ điểm của bạn'
        : 'Lịch sử quét hiện vật',
    children: [
      BackendPanel(
        resourceKey: path,
        load: () => BackendApi.list(path),
        builder: (data, reload) {
          final rows = (data as List).cast<Map<String, dynamic>>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(onPressed: reload, child: const Text('Tải lại')),
              if (rows.isEmpty) const Notice('Chưa có dữ liệu.'),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: kind == 'points'
                      ? Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(row['points'] as num) > 0 ? '+' : ''}${row['points']} điểm',
                                style: AppTextStyles.sectionTitle,
                              ),
                              Text(row['reason']?.toString() ?? ''),
                              Text(row['createdAt'].toString()),
                            ],
                          ),
                        )
                      : ActionTile(
                          title: kind == 'quiz'
                              ? 'Bộ câu hỏi #${row['quizId']}'
                              : AppServices.catalog.artifacts
                                        .where(
                                          (a) =>
                                              a.id ==
                                              row['artifactId'].toString(),
                                        )
                                        .firstOrNull
                                        ?.name ??
                                    'Hiện vật #${row['artifactId']}',
                          subtitle: kind == 'quiz'
                              ? '${backendStatus(row['status'])} · ${row['correctCount']}/${row['totalQuestions']} câu đúng · ${row['score']}/100'
                              : row['recognizedAt'].toString(),
                          icon: kind == 'quiz'
                              ? Icons.quiz_outlined
                              : Icons.qr_code,
                          onTap: () async {
                            try {
                              if (kind == 'quiz') {
                                final result = Map<String, dynamic>.from(
                                  await BackendApi.request(
                                    'quiz-attempts/${row['id']}',
                                  ),
                                );
                                if (context.mounted) {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BackendQuizAttemptScreen(
                                        attempt: result,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                final result = Map<String, dynamic>.from(
                                  await BackendApi.request(
                                    'artifacts/${row['artifactId']}',
                                  ),
                                );
                                if (context.mounted) {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ArtifactDetailScreen(
                                        artifact: Artifact.fromBackendJson(
                                          result,
                                        ),
                                        museumName: AppServices.catalog
                                            .museumName(
                                              result['museumId'].toString(),
                                            ),
                                      ),
                                    ),
                                  );
                                }
                              }
                              reload();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                        ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
