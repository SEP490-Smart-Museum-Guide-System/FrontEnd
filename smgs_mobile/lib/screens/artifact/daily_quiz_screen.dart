import '../../widgets/backend_panel.dart';
import '../../widgets/earned_badges.dart';
import 'package:flutter/material.dart';
import '../../widgets/museum_ui.dart';
import '../../services/backend_api.dart';
import '../../services/app_services.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({
    super.key,
    this.artifactId,
    this.deferredOnly = false,
  });
  final String? artifactId;
  final bool deferredOnly;
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
        body: {
          'dailyEntryId': id,
          'mode': widget.deferredOnly ? 'later' : 'immediate',
        },
      );
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BackendQuizAttemptScreen(
              attempt: Map<String, dynamic>.from(result),
            ),
          ),
        );
      }
      if (mounted) {
        setState(() => _entries = BackendApi.request('daily-quizzes/today'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _defer(int id, bool deferred) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BackendApi.request(
        'daily-quizzes/$id/deferred?deferred=$deferred',
        method: 'PUT',
      );
      if (!mounted) return;
      setState(() => _entries = BackendApi.request('daily-quizzes/today'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deferred ? 'Đã lưu vào Trả lời sau trong ngày.' : 'Đã bỏ lưu.',
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
    title: widget.deferredOnly
        ? 'Trả lời sau trong ngày'
        : 'Câu hỏi trong ngày',
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
          if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          final entries = (snapshot.data as List)
              .cast<Map<String, dynamic>>()
              .where(
                (e) =>
                    (widget.artifactId == null ||
                        e['artifactId'].toString() == widget.artifactId) &&
                    (!widget.deferredOnly || e['status'] == 'deferred'),
              )
              .toList();
          if (entries.isEmpty) {
            return const EmptyState(
              title: 'Chưa có câu hỏi',
              message:
                  'Chưa có câu hỏi được mở cho hiện vật bạn đã quét hôm nay.',
            );
          }
          return Column(
            children: entries
                .map(
                  (e) => Column(
                    children: [
                      ActionTile(
                        title:
                            AppServices.catalog.artifacts
                                .where(
                                  (a) => a.id == e['artifactId'].toString(),
                                )
                                .firstOrNull
                                ?.name ??
                            'Hiện vật #${e['artifactId']}',
                        subtitle:
                            'Bộ câu hỏi #${e['quizId']} · ${e['status'] == 'deferred' ? 'Đã lưu làm sau' : backendStatus(e['status'])}',
                        icon: Icons.quiz_outlined,
                        onTap: () => _start(e['id'] as int),
                      ),
                      if (e['status'] == 'pending' || e['status'] == 'deferred')
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _defer(
                                  e['id'] as int,
                                  e['status'] != 'deferred',
                                ),
                          child: Text(
                            e['status'] == 'deferred'
                                ? 'Bỏ lưu'
                                : 'Trả lời sau',
                          ),
                        ),
                    ],
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
      if (mounted) showEarnedBadges(context, result['newBadges']);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reloadAttempt() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await BackendApi.request('quiz-attempts/${_attempt['id']}');
      if (mounted) setState(() => _attempt = Map<String, dynamic>.from(data));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetAttempt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu lượt mới?'),
        content: const Text(
          'Lượt đang làm sẽ được dừng. Điểm được tính theo quy tắc của hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await BackendApi.request(
        'quiz-attempts/${_attempt['id']}/reset',
        method: 'POST',
        body: {},
      );
      if (mounted) setState(() => _attempt = Map<String, dynamic>.from(data));
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
      Text('Trạng thái: ${backendStatus(_attempt['status'])}'),
      TextButton(
        onPressed: _busy ? null : () => _reloadAttempt(),
        child: const Text('Cập nhật kết quả'),
      ),
      TextButton(
        onPressed: _busy ? null : () => _resetAttempt(),
        child: const Text('Bắt đầu lượt mới'),
      ),
      Text(
        '${_attempt['correctCount']}/${_attempt['totalQuestions']} câu đúng · ${_attempt['score']}/100',
      ),
      Text('${_attempt['pointsEarned'] ?? 0} điểm đã nhận trong lượt này'),
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
