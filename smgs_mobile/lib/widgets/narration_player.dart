import 'dart:async';
import 'package:flutter/material.dart';

import 'museum_ui.dart';
import '../models/artifact.dart';
import '../services/tts_api_service.dart';

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
  int _totalDurationSeconds = 60;
  bool _isLoading = false;
  String? _errorMessage;
  SpeechResult? _speechResult;
  double _speed = 1.0;

  bool get _playing => _timer?.isActive ?? false;

  @override
  void initState() {
    super.initState();
    _estimateDuration();
  }

  void _estimateDuration() {
    // Vietnamese narration average: ~18-20 characters per second at 1.0x
    final charCount = widget.text.length;
    final estimated = (charCount / (18 * _speed)).ceil();
    _totalDurationSeconds = estimated.clamp(10, 300);
  }

  Future<void> _synthesizeAndPlay() async {
    if (_playing) {
      _timer?.cancel();
      setState(() {});
      return;
    }

    if (_seconds >= _totalDurationSeconds) {
      _seconds = 0;
    }

    if (_speechResult == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await TtsApiService.synthesizeSpeech(
          widget.text,
          speed: _speed,
          language: 'vi-VN',
        );

        if (!mounted) return;
        setState(() {
          _speechResult = result;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        return;
      }
    }

    _startPlaybackTimer();
  }

  void _startPlaybackTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _seconds++;
        if (_seconds >= _totalDurationSeconds) {
          timer.cancel();
        }
      });
    });
    setState(() {});
  }

  void _changeSpeed(double newSpeed) {
    if (_speed == newSpeed) return;
    _timer?.cancel();
    setState(() {
      _speed = newSpeed;
      _seconds = 0;
      _speechResult = null; // Re-synthesize at new speed
      _estimateDuration();
    });
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Eyebrow('Thuyết minh AI (TTS)'),
            if (_speechResult != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mutedGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _speechResult!.cacheHit ? 'Cache HIT' : 'AI Ready',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.deepBurgundy,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        if (widget.variant != null) ...[
          const SizedBox(height: 6),
          Text(widget.variant!, style: AppTextStyles.caption),
        ],
        const SizedBox(height: 14),
        Text(widget.text, style: AppTextStyles.bodyLarge),
        const SizedBox(height: 18),

        // Speed adjustment chips
        Row(
          children: [
            const Text('Tốc độ đọc:', style: AppTextStyles.caption),
            const SizedBox(width: 8),
            for (final sp in [0.75, 1.0, 1.25])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => _changeSpeed(sp),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _speed == sp ? AppColors.deepBurgundy : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _speed == sp ? AppColors.deepBurgundy : AppColors.mutedGold,
                      ),
                    ),
                    child: Text(
                      '${sp}x',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _speed == sp ? AppColors.antiqueIvory : AppColors.darkBrown,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        LinearProgressIndicator(
          value: _totalDurationSeconds > 0 ? (_seconds / _totalDurationSeconds).clamp(0.0, 1.0) : 0,
          minHeight: 4,
          backgroundColor: AppColors.darkBrown.withValues(alpha: 0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.deepBurgundy),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')} / ${_totalDurationSeconds ~/ 60}:${(_totalDurationSeconds % 60).toString().padLeft(2, '0')}',
              style: AppTextStyles.caption,
            ),
            if (_speechResult != null)
              Text(
                '${(_speechResult!.byteLength / 1024).toStringAsFixed(0)} KB · ${_speechResult!.voice}',
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedGold),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepBurgundy),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Đang kết nối AI TTS tổng hợp giọng đọc...',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          )
        else
          PrimaryButton(
            label: _playing
                ? 'Tạm dừng thuyết minh'
                : _seconds >= _totalDurationSeconds
                ? 'Nghe lại thuyết minh'
                : 'Nghe thuyết minh âm thanh',
            icon: _playing ? Icons.pause : Icons.play_arrow,
            onPressed: _synthesizeAndPlay,
          ),
        const SizedBox(height: 12),
        const Notice(
          'Giọng đọc được tổng hợp tự động từ microservice TTS AI trên nội dung thuyết minh đã được Giám tuyển phê duyệt.',
        ),
      ],
    ),
  );
}
