import 'dart:async';
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
  final List<({String text, bool visitor, GuideReply? reply})> _messages = [];
  final List<GuideTurn> _history = [];
  String? _error;
  String? _retryQuestion;
  int _generation = 0;
  late final AuthService _auth;
  String? _owner;
  List<String> get _questions => AppServices.guide.suggestions;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _auth = AppServices.auth;
    _owner = _auth.user?.email;
    _auth.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    final owner = _auth.user?.email;
    if (owner != _owner && mounted) {
      setState(() {
        _owner = owner;
        _clear();
      });
    }
  }

  void _clear() {
    _generation++;
    _messages.clear();
    _history.clear();
    _input.clear();
    _busy = false;
    _error = null;
    _retryQuestion = null;
  }

  @override
  void didUpdateWidget(covariant AiGuideScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artifact.id != widget.artifact.id) _clear();
  }

  Future<void> _ask(String value, {bool retry = false}) async {
    final question = value.trim();
    if (question.isEmpty || _busy) {
      return;
    }
    if (question.length > 1000) {
      setState(() => _error = 'Vui lòng nhập câu hỏi tối đa 1.000 ký tự.');
      return;
    }
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
      _retryQuestion = question;
      if (!retry) _messages.add((text: question, visitor: true, reply: null));
      _input.clear();
    });
    try {
      final reply = await AppServices.guide.answer(
        widget.artifact,
        question,
        history: List.of(_history),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _messages.add((text: reply.text, visitor: false, reply: reply));
        if (reply.supported) {
          _history.addAll([
            GuideTurn('user', question),
            GuideTurn('assistant', reply.text),
          ]);
          if (_history.length > 8) _history.removeRange(0, _history.length - 8);
        }
        _retryQuestion = null;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = switch (e) {
          FormatException() => e.message,
          TimeoutException() => 'Trợ lý phản hồi chậm. Vui lòng thử lại.',
          _ =>
            'Chưa thể trả lời lúc này. ${e.toString().replaceFirst(RegExp(r'^Exception: '), '')}',
        },
      );
    }
    if (!mounted || generation != _generation) return;
    setState(() => _busy = false);
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
    _generation++;
    _auth.removeListener(_onSessionChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Trợ lý bảo tàng'),
      actions: [
        IconButton(
          tooltip: 'Cuộc trò chuyện mới',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _busy || _messages.isEmpty ? null : () => setState(_clear),
        ),
      ],
    ),
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
                  'Hỏi về hiện vật đang xem. Trợ lý tham khảo nội dung tiếng Việt đã được bảo tàng xuất bản.',
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
                        'Bạn muốn tìm hiểu ý nghĩa, niên đại hay những chi tiết đáng chú ý của hiện vật?',
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
                            m.visitor ? 'Bạn' : 'Trợ lý bảo tàng',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: m.visitor
                                  ? AppColors.antiqueIvory
                                  : AppColors.deepBurgundy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            container: true,
                            child: Text(
                              m.text,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: m.visitor
                                    ? AppColors.antiqueIvory
                                    : AppColors.darkBrown,
                              ),
                            ),
                          ),
                          if (m.reply?.sources.isNotEmpty == true) ...[
                            const Divider(height: 24),
                            const Text(
                              'Nội dung tham khảo',
                              style: AppTextStyles.caption,
                            ),
                            ...m.reply!.sources.map(
                              (source) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Semantics(
                                  container: true,
                                  child: Text(
                                    '${source.title} · Phiên bản ${source.versionNo}',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                if (_error != null) ...[
                  Notice(_error!),
                  if (_retryQuestion != null)
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _ask(_retryQuestion!, retry: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại câu hỏi'),
                    ),
                ],
                if (_messages.isNotEmpty &&
                    !_busy &&
                    _error == null &&
                    _messages.last.reply?.supported == true)
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
                    maxLength: 1000,
                    enabled: !_busy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: const InputDecoration(
                      hintText: 'Hỏi về hiện vật này…',
                      labelText: 'Câu hỏi của bạn',
                      counterText: '',
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
