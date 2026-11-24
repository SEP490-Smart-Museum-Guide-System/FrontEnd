import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import '../../widgets/earned_badges.dart';
import '../../widgets/museum_ui.dart';

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
  late Future<dynamic> _entries;
  late bool _showDeferredOnly;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _showDeferredOnly = widget.deferredOnly;
    _entries = BackendApi.request('daily-quizzes/today');
  }

  void _reload() {
    setState(() {
      _error = null;
      _entries = BackendApi.request('daily-quizzes/today');
    });
  }

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
          'mode': _showDeferredOnly ? 'later' : 'immediate',
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
        _reload();
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
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deferred
                ? 'Đã lưu câu hỏi vào danh sách Trả lời sau.'
                : 'Đã đưa câu hỏi trở lại danh sách hôm nay.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MuseumPage(
      back: true,
      title: _showDeferredOnly ? 'Trả lời sau' : 'Câu hỏi trong ngày',
      eyebrow: 'Thử tài khám phá',
      subtitle: 'Kiểm tra kiến thức lịch sử & mở khóa huy hiệu vinh danh qua các câu đố di sản.',
      children: [
        // Tab filter switch
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  title: 'Tất cả câu hỏi',
                  icon: Icons.auto_awesome_outlined,
                  isSelected: !_showDeferredOnly,
                  onTap: () => setState(() => _showDeferredOnly = false),
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  title: 'Đã lưu làm sau',
                  icon: Icons.bookmark_added_outlined,
                  isSelected: _showDeferredOnly,
                  onTap: () => setState(() => _showDeferredOnly = true),
                ),
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          Notice(_error!),
          const SizedBox(height: 12),
        ],

        FutureBuilder<dynamic>(
          future: _entries,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Notice(snapshot.error.toString()),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Thử lại',
                    icon: Icons.refresh,
                    onPressed: _reload,
                  ),
                ],
              );
            }

            final rawList = (snapshot.data is List) ? (snapshot.data as List) : [];
            final entries = rawList
                .cast<Map<String, dynamic>>()
                .where(
                  (e) =>
                      (widget.artifactId == null ||
                          e['artifactId'].toString() == widget.artifactId) &&
                      (!_showDeferredOnly || e['status'] == 'deferred'),
                )
                .toList();

            if (entries.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.antiqueIvory,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.mutedGold),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        size: 30,
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showDeferredOnly ? 'Không có câu hỏi đã lưu' : 'Chưa có câu hỏi hôm nay',
                      style: AppTextStyles.sectionTitle.copyWith(color: AppColors.darkBrown),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showDeferredOnly
                          ? 'Bạn chưa lưu câu hỏi nào vào mục Trả lời sau trong ngày.'
                          : 'Hãy quét mã QR tại các hiện vật trưng bày để kích hoạt các câu đố di sản hấp dẫn.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (final e in entries) ...[
                  _buildQuizCard(e),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),

        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _busy ? null : _reload,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Làm mới danh sách'),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VisitorRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBurgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(VisitorRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.antiqueIvory : AppColors.darkBrown,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.antiqueIvory : AppColors.darkBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> entry) {
    final artifactId = entry['artifactId']?.toString() ?? '';
    final artifact = AppServices.catalog.artifacts
        .where((a) => a.id == artifactId)
        .firstOrNull;
    final artifactName = artifact?.name ?? 'Hiện vật #$artifactId';
    final status = entry['status']?.toString() ?? 'pending';
    final isDeferred = status == 'deferred';
    final isCompleted = status == 'completed';

    Color statusBgColor = Colors.grey.shade100;
    Color statusTextColor = Colors.grey.shade800;
    String statusLabel = 'Chưa làm';

    if (isCompleted) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade800;
      statusLabel = 'Đã hoàn thành';
    } else if (isDeferred) {
      statusBgColor = AppColors.deepBurgundy.withValues(alpha: 0.1);
      statusTextColor = AppColors.deepBurgundy;
      statusLabel = 'Đã lưu làm sau';
    } else if (status == 'in_progress') {
      statusBgColor = Colors.amber.shade50;
      statusTextColor = Colors.amber.shade900;
      statusLabel = 'Đang thực hiện';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: isDeferred ? Border.all(color: AppColors.mutedGold, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Status chip + Defer bookmark button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(VisitorRadius.xs),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
              const Spacer(),
              if (status == 'pending' || isDeferred)
                IconButton(
                  tooltip: isDeferred ? 'Bỏ lưu' : 'Lưu làm sau',
                  icon: Icon(
                    isDeferred ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                    color: isDeferred ? AppColors.deepBurgundy : AppColors.secondaryText,
                    size: 20,
                  ),
                  onPressed: _busy ? null : () => _defer(entry['id'] as int, !isDeferred),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Artifact title & Quiz details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: VisitorColors.surface2,
                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                ),
                child: const Icon(
                  Icons.history_edu_outlined,
                  size: 24,
                  color: AppColors.deepBurgundy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifactName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bộ câu đố #${entry['quizId']} · Tối đa 100 điểm di sản',
                      style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : () => _start(entry['id'] as int),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? AppColors.darkBrown : AppColors.deepBurgundy,
                foregroundColor: AppColors.antiqueIvory,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VisitorRadius.lg)),
                elevation: 0,
              ),
              icon: Icon(
                isCompleted ? Icons.visibility_outlined : Icons.play_arrow_rounded,
                size: 18,
              ),
              label: Text(
                isCompleted ? 'Xem lại kết quả' : 'Bắt đầu làm bài',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BackendQuizAttemptScreen extends StatefulWidget {
  const BackendQuizAttemptScreen({super.key, required this.attempt});
  final Map<String, dynamic> attempt;

  @override
  State<BackendQuizAttemptScreen> createState() => _BackendQuizAttemptScreenState();
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
      if (mounted && result['newBadges'] != null) {
        showEarnedBadges(context, result['newBadges']);
      }
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
          'Lượt làm hiện tại sẽ được dừng. Điểm số sẽ được tính lại theo quy tắc của hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bắt đầu', style: TextStyle(color: AppColors.deepBurgundy)),
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
  Widget build(BuildContext context) {
    final questions = (_attempt['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final correctCount = _attempt['correctCount'] ?? 0;
    final totalQuestions = _attempt['totalQuestions'] ?? questions.length;
    final score = _attempt['score'] ?? 0;
    final pointsEarned = _attempt['pointsEarned'] ?? 0;
    final status = _attempt['status']?.toString() ?? 'in_progress';
    final isCompleted = status == 'completed';

    return MuseumPage(
      back: true,
      title: 'Thử tài khám phá',
      eyebrow: 'Câu hỏi di sản',
      subtitle: 'Trả lời đúng để nhận điểm cống hiến và mở khóa các huy hiệu quý giá.',
      children: [
        // Scoreboard Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.antiqueIvory,
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
            border: Border.all(color: AppColors.mutedGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkBrown.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.shade700 : AppColors.deepBurgundy,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$correctCount/$totalQuestions',
                        style: const TextStyle(
                          color: AppColors.antiqueIvory,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompleted ? 'Hoàn thành lượt làm bài' : 'Đang thực hiện bài kiểm tra',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.mutedGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Điểm: $score/100',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepBurgundy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+$pointsEarned EXP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.mutedGold),
              const SizedBox(height: 8),

              // Control Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _busy ? null : _reloadAttempt,
                    icon: const Icon(Icons.refresh, size: 15),
                    label: const Text('Cập nhật kết quả', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _resetAttempt,
                    icon: const Icon(Icons.restart_alt, size: 15, color: Colors.brown),
                    label: const Text(
                      'Bắt đầu lượt mới',
                      style: TextStyle(fontSize: 12, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Notice(_error!),
        ],

        const SizedBox(height: 20),

        // Questions List
        for (int i = 0; i < questions.length; i++) ...[
          _buildQuestionCard(questions[i], index: i + 1, total: questions.length),
          const SizedBox(height: 18),
        ],

        const SizedBox(height: 12),
        if (isCompleted)
          PrimaryButton(
            label: 'Hoàn tất & Quay về danh sách',
            icon: Icons.check_circle_outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> q, {
    required int index,
    required int total,
  }) {
    final questionId = q['id'] as int;
    final selectedOptionId = q['selectedOptionId'] as int?;
    final isCorrect = q['isCorrect'] as bool?;
    final explanation = q['explanation']?.toString();
    final options = (q['options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isAnswered = selectedOptionId != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered
              ? (isCorrect == true ? Colors.green.shade400 : Colors.red.shade400)
              : AppColors.border,
          width: isAnswered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Index header
          Row(
            children: [
              Text(
                'CÂU HỎI $index TRÊN $total'.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedGold,
                ),
              ),
              const Spacer(),
              if (isAnswered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCorrect == true ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(VisitorRadius.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 14,
                        color: isCorrect == true ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect == true ? 'Chính xác' : 'Chưa đúng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCorrect == true ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Question Content
          Text(
            q['content']?.toString() ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Options list
          for (int optIdx = 0; optIdx < options.length; optIdx++) ...[
            _buildOptionTile(
              questionId: questionId,
              option: options[optIdx],
              optionLetter: String.fromCharCode(65 + optIdx),
              isSelected: selectedOptionId == options[optIdx]['id'],
              isQuestionAnswered: isAnswered,
              isQuestionCorrect: isCorrect,
            ),
            const SizedBox(height: 8),
          ],

          // Explanation Banner
          if (explanation != null && explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.antiqueIvory,
                borderRadius: BorderRadius.circular(VisitorRadius.md),
                border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: AppColors.deepBurgundy,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kiến thức di sản bổ sung:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBurgundy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          explanation,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.darkBrown,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required int questionId,
    required Map<String, dynamic> option,
    required String optionLetter,
    required bool isSelected,
    required bool isQuestionAnswered,
    required bool? isQuestionCorrect,
  }) {
    final optionId = option['id'] as int;
    final content = option['content']?.toString() ?? '';

    Color tileBgColor = Colors.white;
    Color tileBorderColor = AppColors.border;
    Color letterBgColor = AppColors.antiqueIvory;
    Color letterTextColor = AppColors.darkBrown;

    if (isSelected) {
      if (isQuestionCorrect == true) {
        tileBgColor = Colors.green.shade50;
        tileBorderColor = Colors.green.shade400;
        letterBgColor = Colors.green.shade700;
        letterTextColor = Colors.white;
      } else if (isQuestionCorrect == false) {
        tileBgColor = Colors.red.shade50;
        tileBorderColor = Colors.red.shade400;
        letterBgColor = Colors.red.shade700;
        letterTextColor = Colors.white;
      } else {
        tileBgColor = AppColors.deepBurgundy.withValues(alpha: 0.08);
        tileBorderColor = AppColors.deepBurgundy;
        letterBgColor = AppColors.deepBurgundy;
        letterTextColor = AppColors.antiqueIvory;
      }
    }

    return InkWell(
      onTap: (_busy || isQuestionAnswered) ? null : () => _answer(questionId, optionId),
      borderRadius: BorderRadius.circular(VisitorRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: tileBgColor,
          borderRadius: BorderRadius.circular(VisitorRadius.md),
          border: Border.all(color: tileBorderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: letterBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  optionLetter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: letterTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                isQuestionCorrect == true
                    ? Icons.check_circle_rounded
                    : (isQuestionCorrect == false ? Icons.cancel_rounded : Icons.radio_button_checked),
                size: 18,
                color: isQuestionCorrect == true
                    ? Colors.green.shade700
                    : (isQuestionCorrect == false ? Colors.red.shade700 : AppColors.deepBurgundy),
              ),
          ],
        ),
      ),
    );
  }
}
