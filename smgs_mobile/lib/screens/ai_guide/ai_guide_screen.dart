import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../services/app_services.dart';
import '../../widgets/narration_player.dart';

class AiGuideScreen extends StatefulWidget {
  const AiGuideScreen({super.key, required this.artifact});
  final Artifact artifact;
  @override
  State<AiGuideScreen> createState() => _AiGuideScreenState();
}

class _AiGuideScreenState extends State<AiGuideScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<({String text, bool visitor})> _messages = [];
  List<String> get _questions => AppServices.guide.suggestions;
  bool _busy = false;
  Future<void> _ask(String value) async {
    final question = value.trim();
    if (question.isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _messages.add((text: question, visitor: true));
      _input.clear();
    });
    String answer;
    try {
      answer = await AppServices.guide.answer(widget.artifact, question);
    } catch (_) {
      answer = 'Chưa thể trả lời lúc này. Bạn hãy thử lại câu hỏi.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _messages.add((text: answer, visitor: false));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        if (reduceHeritageMotion(context)) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
          return;
        }
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hướng dẫn viên')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(24),
              children: [
                const Eyebrow('Cùng bạn tìm hiểu'),
                const SizedBox(height: 10),
                Text(widget.artifact.name, style: AppTextStyles.pageTitle),
                const SizedBox(height: 18),
                const Notice(
                  'Hỏi đáp mẫu từ nội dung bộ sưu tập. Trợ lý thông minh sẽ được kết nối sau.',
                ),
                const SizedBox(height: 22),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_stories_outlined,
                        color: AppColors.deepBurgundy,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.artifact.aiGuide,
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SectionHeading('Bạn có thể hỏi'),
                ..._questions.map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SecondaryButton(
                      label: q,
                      onPressed: _busy ? null : () => _ask(q),
                    ),
                  ),
                ),
                if (_messages.isNotEmpty) const Divider(),
                ..._messages.map(
                  (m) => Align(
                    alignment: m.visitor
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: m.visitor
                            ? AppColors.deepBurgundy
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: m.visitor
                              ? AppColors.deepBurgundy
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.visitor ? 'Bạn' : 'Hướng dẫn viên',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: m.visitor
                                  ? AppColors.antiqueIvory
                                  : AppColors.deepBurgundy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            m.text,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: m.visitor
                                  ? AppColors.antiqueIvory
                                  : AppColors.darkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Đang tìm câu trả lời…',
                          style: AppTextStyles.bodyMedium,
                        ),
                        SizedBox(height: 10),
                        LinearProgressIndicator(),
                      ],
                    ),
                  ),
                if (_messages.isNotEmpty && !_busy)
                  SecondaryButton(
                    label: 'Đọc và nghe câu trả lời',
                    icon: Icons.headphones_outlined,
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      constraints: const BoxConstraints(maxWidth: 500),
                      builder: (context) => SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: NarrationPlayer(text: _messages.last.text),
                        ),
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => showReading(
                    context,
                    title: 'Hỏi bằng giọng nói',
                    text: 'Tính năng giọng nói đang được chuẩn bị. Trong bản trải nghiệm, bạn có thể nhập câu hỏi hoặc chọn gợi ý.',
                  ),
                  icon: const Icon(Icons.mic_none_outlined),
                  label: const Text('Hỏi bằng giọng nói'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: const InputDecoration(
                      hintText: 'Điều bạn muốn tìm hiểu…',
                      labelText: 'Câu hỏi của bạn',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: Tooltip(
                    message: 'Gửi câu hỏi',
                    child: FilledButton(
                      onPressed: _busy ? null : () => _ask(_input.text),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(56, 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward, size: 20),
                          Text('Gửi'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
