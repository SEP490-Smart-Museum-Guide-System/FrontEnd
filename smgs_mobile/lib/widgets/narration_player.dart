import 'dart:async';

import 'package:flutter/material.dart';

import 'museum_ui.dart';
import '../models/artifact.dart';

class NarrationScreen extends StatefulWidget {
  const NarrationScreen({super.key, required this.artifact});
  final Artifact artifact;

  @override
  State<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends State<NarrationScreen> {
  String _length = 'Vừa';
  String _detail = 'Tổng quan';
  String _format = 'Âm thanh';

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Lời kể về hiện vật',
    eyebrow: 'Thuyết minh',
    subtitle: widget.artifact.name,
    children: [
      const SectionHeading('Chọn cách bạn muốn nghe'),
      const Panel(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.language_outlined, color: AppColors.deepBurgundy),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngôn ngữ', style: AppTextStyles.caption),
                  SizedBox(height: 3),
                  Text('Tiếng Việt', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: AppColors.mutedGold),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text('Độ dài', style: AppTextStyles.bodyMedium),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: ['Ngắn', 'Vừa', 'Dài']
            .map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: _length == value,
                onSelected: (_) => setState(() => _length = value),
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _length == value
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 18),
      const Text('Mức độ chi tiết', style: AppTextStyles.bodyMedium),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: ['Tổng quan', 'Chuyên sâu']
            .map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: _detail == value,
                onSelected: (_) => setState(() => _detail = value),
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _detail == value
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 18),
      const Text('Định dạng', style: AppTextStyles.bodyMedium),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: ['Âm thanh', 'Văn bản']
            .map(
              (value) => ChoiceChip(
                avatar: Icon(
                  value == 'Âm thanh'
                      ? Icons.headphones_outlined
                      : Icons.article_outlined,
                  size: 18,
                  color: _format == value
                      ? AppColors.antiqueIvory
                      : AppColors.deepBurgundy,
                ),
                label: Text(value),
                selected: _format == value,
                onSelected: (_) => setState(() => _format = value),
                checkmarkColor: AppColors.antiqueIvory,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _format == value
                      ? AppColors.antiqueIvory
                      : AppColors.darkBrown,
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 22),
      AnimatedSwitcher(
        duration: reduceHeritageMotion(context)
            ? Duration.zero
            : HeritageMotion.standard,
        child: _format == 'Âm thanh'
            ? NarrationPlayer(
                key: ValueKey('$_length:$_detail:$_format'),
                text: widget.artifact.aiGuide,
                variant: '$_length · $_detail',
              )
            : Panel(
                key: ValueKey('$_length:$_detail:$_format'),
                gold: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Bản đọc tiếng Việt'),
                    const SizedBox(height: 8),
                    Text('$_length · $_detail', style: AppTextStyles.caption),
                    const SizedBox(height: 14),
                    Text(
                      widget.artifact.aiGuide,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
      ),
      const SectionHeading('Đọc câu chuyện'),
      Text(widget.artifact.story, style: AppTextStyles.bodyLarge),
    ],
  );
}

class NarrationPlayer extends StatefulWidget {
  const NarrationPlayer({super.key, required this.text, this.variant});
  final String text;
  final String? variant;
  @override
  State<NarrationPlayer> createState() => _NarrationPlayerState();
}

class _NarrationPlayerState extends State<NarrationPlayer> {
  Timer? _timer;
  int _seconds = 0;
  bool get _playing => _timer?.isActive ?? false;
  void _toggle() {
    if (_playing) {
      _timer!.cancel();
      setState(() {});
      return;
    }
    if (_seconds >= 60) _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _seconds++;
        if (_seconds >= 60) timer.cancel();
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Thuyết minh mẫu'),
        if (widget.variant != null) ...[
          const SizedBox(height: 6),
          Text(widget.variant!, style: AppTextStyles.caption),
        ],
        const SizedBox(height: 14),
        Text(widget.text, style: AppTextStyles.bodyLarge),
        const SizedBox(height: 18),
        LinearProgressIndicator(value: _seconds / 60, minHeight: 4),
        const SizedBox(height: 10),
        Text(
          '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')} / 1:00',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _playing
              ? 'Tạm dừng mô phỏng'
              : _seconds >= 60
              ? 'Phát lại mô phỏng'
              : 'Phát thử mô phỏng',
          icon: _playing ? Icons.pause : Icons.play_arrow,
          onPressed: _toggle,
        ),
        const SizedBox(height: 12),
        const Notice(
          'Thanh phát chỉ mô phỏng thao tác, chưa có âm thanh. Bạn có thể đọc toàn bộ nội dung ở trên.',
        ),
      ],
    ),
  );
}
