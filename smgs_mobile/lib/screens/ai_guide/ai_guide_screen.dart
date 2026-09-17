import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';

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
  static const _questions = [
    'Hiện vật này có ý nghĩa gì?',
    'Hiện vật thuộc thời kỳ nào?',
    'Tôi nên chú ý chi tiết nào?',
  ];
  void _ask(String value) {
    final question = value.trim();
    if (question.isEmpty) {
      return;
    }
    final a = widget.artifact;
    final answer = question == _questions[0]
        ? a.summary
        : question == _questions[1]
        ? 'Hiện vật được giới thiệu trong bối cảnh: ${a.period}.'
        : question == _questions[2]
        ? a.aiGuide
        : 'Mình chưa có câu trả lời được kiểm chứng cho câu hỏi này trong bản trải nghiệm. Bạn có thể chọn câu hỏi gợi ý hoặc hỏi nhân viên bảo tàng để tìm hiểu thêm.';
    setState(() {
      _messages.add((text: question, visitor: true));
      _messages.add((text: answer, visitor: false));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
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
                    child: SecondaryButton(label: q, onPressed: () => _ask(q)),
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
                  child: IconButton.filled(
                    tooltip: 'Gửi câu hỏi',
                    onPressed: () => _ask(_input.text),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_upward),
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
