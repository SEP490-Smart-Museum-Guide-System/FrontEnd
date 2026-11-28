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
    _loadSavedHistory();
  }

  Future<void> _loadSavedHistory() async {
    final user = AppServices.auth.user;
    if (user == null) return;
    final id = int.tryParse(widget.artifact.id);
    if (id == null || id <= 0) return;
    try {
      final items = await AppServices.guide.getArtifactHistory(id);
      if (mounted && items.isNotEmpty && _messages.isEmpty) {
        setState(() {
          for (final item in items) {
            _messages.add((text: item.question, visitor: true, reply: null));
            _messages.add((
              text: item.answer,
              visitor: false,
              reply: GuideReply(
                text: item.answer,
                supported: item.supported,
                sources: item.sources,
              ),
            ));
          }
          final recent = items.length > 4 ? items.sublist(items.length - 4) : items;
          _history.clear();
          for (final item in recent) {
            _history.add(GuideTurn('user', item.question));
            _history.add(GuideTurn('assistant', item.answer));
          }
        });
      }
    } catch (_) {}
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

  Future<void> _handleClear() async {
    final id = int.tryParse(widget.artifact.id);
    setState(_clear);
    final user = AppServices.auth.user;
    if (user != null && id != null && id > 0) {
      AppServices.guide.clearArtifactHistory(id).catchError((_) => 0);
    }
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
    final user = AppServices.auth.user;
    if (user == null) {
      setState(() => _error = 'Vui lòng đăng nhập để trao đổi với Trợ lý AI.');
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
          onPressed: _busy || _messages.isEmpty ? null : _handleClear,
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (var i = 0; i < _questions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        InkWell(
                          onTap: _busy ? null : () => _ask(_questions[i]),
                          borderRadius: BorderRadius.circular(VisitorRadius.full),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(VisitorRadius.full),
                              border: Border.all(
                                color: AppColors.mutedGold.withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 15,
                                  color: AppColors.deepBurgundy,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _questions[i],
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_messages.isNotEmpty) const Divider(height: 32),
                ..._messages.map(
                  (m) => Align(
                    alignment: m.visitor
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: m.visitor
                            ? AppColors.deepBurgundy
                            : AppColors.card,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(m.visitor ? 16 : 4),
                          bottomRight: Radius.circular(m.visitor ? 4 : 16),
                        ),
                        border: Border.all(
                          color: m.visitor
                              ? AppColors.deepBurgundy
                              : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                m.visitor
                                    ? Icons.person_outline_rounded
                                    : Icons.auto_awesome_rounded,
                                size: 14,
                                color: m.visitor
                                    ? AppColors.mutedGold
                                    : AppColors.deepBurgundy,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                m.visitor ? 'Bạn' : 'Trợ lý bảo tàng',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: m.visitor
                                      ? AppColors.antiqueIvory
                                      : AppColors.deepBurgundy,
                                ),
                              ),
                            ],
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
                                height: 1.45,
                              ),
                            ),
                          ),
                          if (m.reply?.sources.isNotEmpty == true) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.antiqueIvory.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.menu_book_rounded,
                                        size: 13,
                                        color: AppColors.deepBurgundy,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Nội dung tham khảo',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.deepBurgundy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...m.reply!.sources.map(
                                    (source) => Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Semantics(
                                        container: true,
                                        child: Text(
                                          '${source.title} · Phiên bản ${source.versionNo}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.darkBrown,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (_busy)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.deepBurgundy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Đang tìm câu trả lời…',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.darkBrown,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                    decoration: InputDecoration(
                      hintText: 'Hỏi về hiện vật này…',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.darkBrown.withOpacity(0.4),
                      ),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.deepBurgundy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Gửi câu hỏi',
                  child: FilledButton(
                    onPressed: _busy ? null : () => _ask(_input.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepBurgundy,
                      foregroundColor: AppColors.antiqueIvory,
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 20),
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
