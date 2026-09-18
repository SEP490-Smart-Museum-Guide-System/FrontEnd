import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../data/visit_store.dart';
import '../../services/app_services.dart';
import '../../models/experience.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.artifact});
  final Artifact artifact;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _question = 0, _score = 0;
  int? _selected;
  bool _answered = false, _finished = false;
  late final List<QuizQuestion> _questions = AppServices.quiz.questions(
    widget.artifact,
  );
  List<String> get _options => _questions[_question].options;
  int get _correct => _questions[_question].correctIndex;
  int _points = 0;
  void _submit() {
    if (_selected == null) {
      return;
    }
    if (!_answered) {
      setState(() {
        _answered = true;
        if (_selected == _correct) {
          _score++;
          _points += _questions[_question].points;
        }
      });
    } else if (_question < _questions.length - 1) {
      setState(() {
        _question++;
        _selected = null;
        _answered = false;
      });
    } else {
      VisitStore.instance.recordQuiz(
        widget.artifact.id,
        _score,
        total: _questions.length,
        points: _points,
      );
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    key: ValueKey('$_question-$_finished'),
    back: true,
    title: _finished ? 'Một dấu ấn mới' : 'Thử tài khám phá',
    eyebrow: 'Hiểu thêm một chút',
    subtitle: widget.artifact.name,
    children: _finished
        ? [
            Panel(
              gold: true,
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 60,
                    color: AppColors.mutedGold,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$_score / ${_questions.length}',
                    style: AppTextStyles.display.copyWith(fontSize: 44),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'câu trả lời đúng',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _score == _questions.length
                        ? 'Bạn đã ghi nhớ rất tốt!'
                        : 'Mỗi lần tìm hiểu là một khám phá mới.',
                    style: AppTextStyles.sectionTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_points điểm trong lượt này',
                    style: AppTextStyles.sectionTitle,
                  ),
                  if (_score == _questions.length) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Huy hiệu: Người bạn của di sản',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Sổ tay ghi nhận kết quả tốt nhất của mỗi hiện vật.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Tiếp tục khám phá',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Thử lại',
              onPressed: () => setState(() {
                _question = 0;
                _score = 0;
                _points = 0;
                _selected = null;
                _answered = false;
                _finished = false;
              }),
            ),
          ]
        : [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Câu ${_question + 1} trên ${_questions.length}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const Icon(
                  Icons.auto_stories_outlined,
                  color: AppColors.mutedGold,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_question + 1) / _questions.length,
              minHeight: 4,
            ),
            const SizedBox(height: 28),
            Text(
              _questions[_question].question,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 24),
            ..._options.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  onPressed: _answered
                      ? null
                      : () => setState(() => _selected = e.key),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: _selected == e.key
                        ? AppColors.deepBurgundy
                        : AppColors.card,
                    foregroundColor: _selected == e.key
                        ? AppColors.antiqueIvory
                        : AppColors.darkBrown,
                    disabledForegroundColor: _selected == e.key
                        ? AppColors.antiqueIvory
                        : AppColors.darkBrown,
                    side: BorderSide(
                      color: _selected == e.key
                          ? AppColors.deepBurgundy
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selected == e.key
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _selected == e.key
                                ? AppColors.antiqueIvory
                                : AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_answered) ...[
              const SizedBox(height: 8),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected == _correct
                          ? 'Chính xác!'
                          : 'Cùng tìm hiểu lại nhé',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đáp án: ${_options[_correct]}.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _questions[_question].explanation,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _answered
                  ? (_question < _questions.length - 1
                        ? 'Câu tiếp theo'
                        : 'Xem kết quả')
                  : 'Trả lời',
              onPressed: _selected == null ? null : _submit,
            ),
          ],
  );
}
