import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key, this.artifactId});
  final String? artifactId;
  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  late Future<dynamic> _entries = BackendApi.request('daily-quizzes/today');
  String? _error;
  bool _busy = false;
  Future<void> _start(int id) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await BackendApi.request(
        'quiz-attempts',
        method: 'POST',
        body: {'dailyEntryId': id, 'mode': 'later'},
      );
      if (mounted)
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BackendQuizAttemptScreen(
              attempt: Map<String, dynamic>.from(result),
            ),
          ),
        );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Câu hỏi trong ngày',
    eyebrow: 'Thử tài khám phá',
    children: [
      const Notice(
        'Câu hỏi được mở sau khi hệ thống ghi nhận bạn quét hiện vật có bộ câu hỏi đã xuất bản.',
      ),
      if (_error != null) Notice(_error!),
      TextButton(
        onPressed: () => setState(
          () => _entries = BackendApi.request('daily-quizzes/today'),
        ),
        child: const Text('Tải lại'),
      ),
      FutureBuilder<dynamic>(
        future: _entries,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const CircularProgressIndicator();
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          final entries = (snapshot.data as List)
              .cast<Map<String, dynamic>>()
              .where(
                (e) =>
                    widget.artifactId == null ||
                    e['artifactId'].toString() == widget.artifactId,
              )
              .toList();
          if (entries.isEmpty)
            return const EmptyState(
              title: 'Chưa có câu hỏi',
              message:
                  'Chưa có câu hỏi được mở cho hiện vật bạn đã quét hôm nay.',
            );
          return Column(
            children: entries
                .map(
                  (e) => ActionTile(
                    title:
                        AppServices.catalog.artifacts
                            .where((a) => a.id == e['artifactId'].toString())
                            .firstOrNull
                            ?.name ??
                        'Hiện vật #${e['artifactId']}',
                    subtitle: 'Bộ câu hỏi #${e['quizId']}',
                    icon: Icons.quiz_outlined,
                    onTap: () => _start(e['id'] as int),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class BackendQuizAttemptScreen extends StatefulWidget {
  const BackendQuizAttemptScreen({super.key, required this.attempt});
  final Map<String, dynamic> attempt;
  @override
  State<BackendQuizAttemptScreen> createState() =>
      _BackendQuizAttemptScreenState();
}

class _BackendQuizAttemptScreenState extends State<BackendQuizAttemptScreen> {
  late Map<String, dynamic> _attempt = widget.attempt;
  bool _busy = false;
  String? _error;
  Future<void> _answer(int questionId, int optionId) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await BackendApi.request(
        'quiz-attempts/${_attempt['id']}/answers',
        method: 'POST',
        body: {'questionId': questionId, 'optionId': optionId},
      );
      if (mounted) setState(() => _attempt = Map<String, dynamic>.from(result));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Thử tài khám phá',
    children: [
      Text('Trạng thái: ${_attempt['status']}'),
      Text(
        '${_attempt['correctCount']}/${_attempt['totalQuestions']} câu đúng · ${_attempt['score']} điểm',
      ),
      if (_error != null) Notice(_error!),
      for (final q
          in (_attempt['questions'] as List).cast<Map<String, dynamic>>())
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['content'], style: AppTextStyles.sectionTitle),
                for (final option in q['options'] as List)
                  TextButton(
                    onPressed: _busy || q['selectedOptionId'] != null
                        ? null
                        : () => _answer(q['id'], option['id']),
                    child: Text(
                      '${q['selectedOptionId'] == option['id'] ? '✓ ' : ''}${option['content']}',
                    ),
                  ),
                if (q['isCorrect'] != null)
                  Text(q['isCorrect'] == true ? 'Chính xác' : 'Chưa chính xác'),
                if (q['explanation'] != null) Text(q['explanation']),
              ],
            ),
          ),
        ),
    ],
  );
}
