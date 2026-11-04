import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/network/api_config.dart';
import '../services/discovery_api_service.dart';
import 'backend_panel.dart';

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
      _publishedNarration(),
      const SectionHeading('Đọc câu chuyện'),
      Text(widget.artifact.story, style: AppTextStyles.bodyLarge),
    ],
  );

  Widget _publishedNarration() {
    final id = int.tryParse(widget.artifact.id);
    if (id == null) return _narrationBody(widget.artifact.aiGuide, null, true);
    return BackendPanel(
      resourceKey: 'narration:$id:vi',
      load: () => DiscoveryApiService.fetchPublishedContent(id),
      builder: (data, _) {
        final content = data as Map<String, dynamic>;
        final text = (content['narrationText'] as String?)?.trim();
        final description = (content['description'] as String?)?.trim() ?? '';
        final audio = ApiConfig.mediaUrl(content['audioUrl'] as String?);
        final script = text?.isNotEmpty == true ? text! : description;
        if (script.isEmpty && audio.isEmpty) {
          return const Notice(
            'Hiện vật chưa có bản thuyết minh được xuất bản.',
          );
        }
        return _narrationBody(script, audio.isEmpty ? null : audio, false);
      },
    );
  }

  Widget _narrationBody(String text, String? audioUrl, bool demo) =>
      AnimatedSwitcher(
        duration: reduceHeritageMotion(context)
            ? Duration.zero
            : HeritageMotion.standard,
        child: _format == 'Âm thanh'
            ? NarrationPlayer(
                key: ValueKey(
                  '${widget.artifact.id}:$_length:$_detail:$_format',
                ),
                text: text,
                audioUrl: audioUrl,
                variant: '$_length · $_detail',
                isDemo: demo,
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
                      text.isEmpty ? 'Bảo tàng mới xuất bản bản thu âm.' : text,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
      );
}

class NarrationPlayer extends StatefulWidget {
  const NarrationPlayer({
    super.key,
    required this.text,
    this.audioUrl,
    this.variant,
    this.isDemo = false,
  });
  final String text;
  final String? audioUrl;
  final String? variant;
  final bool isDemo;

  @override
  State<NarrationPlayer> createState() => _NarrationPlayerState();
}

class _NarrationPlayerState extends State<NarrationPlayer> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  SpeechResult? _audio;
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero, _duration = Duration.zero;
  double? _dragPosition;
  double _speed = 1;
  bool _busy = false, _sourceReady = false;
  String? _error;
  int _request = 0;

  bool get _playing => _state == PlayerState.playing;
  bool get _recorded => widget.audioUrl?.trim().isNotEmpty == true;
  bool get _hasContent => _recorded || widget.text.trim().isNotEmpty;

  bool _current(int request) => mounted && request == _request;

  AudioPlayer _ensurePlayer() {
    if (_player != null) return _player!;
    final player = AudioPlayer();
    _player = player;
    bool active() => mounted && identical(_player, player);
    void onError(Object error) {
      if (!active()) return;
      setState(() {
        _state = PlayerState.paused;
        _error = 'Không thể phát âm thanh. Hãy nhấn nghe để thử lại.';
      });
      unawaited(player.pause().catchError((Object _) {}));
    }

    _subscriptions.addAll([
      player.onPlayerStateChanged.listen((state) {
        if (active()) setState(() => _state = state);
      }, onError: onError),
      player.onDurationChanged.listen((duration) {
        if (active()) setState(() => _duration = duration);
      }, onError: onError),
      player.onPositionChanged.listen((position) {
        if (active()) setState(() => _position = position);
      }, onError: onError),
      player.onPlayerComplete.listen((_) {
        if (active()) {
          setState(() {
            _state = PlayerState.completed;
            _position = _duration;
          });
        }
      }, onError: onError),
    ]);
    return player;
  }

  Future<void> _toggle() async {
    if (_busy || !_hasContent) return;
    final request = _request;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_playing) {
        await _player!.pause();
        return;
      }
      if (_audio == null) {
        final audio = _recorded
            ? await TtsApiService.fetchPublishedAudio(widget.audioUrl!)
            : await TtsApiService.synthesizeSpeech(widget.text);
        if (!_current(request)) return;
        _audio = audio;
      }
      final player = _ensurePlayer();
      if (!_sourceReady) {
        await player.setReleaseMode(ReleaseMode.stop);
        if (!_current(request)) return;
        await player.setSource(
          BytesSource(_audio!.audioBytes, mimeType: _audio!.mimeType),
        );
        if (!_current(request)) return;
        _sourceReady = true;
      }
      await player.setPlaybackRate(_speed);
      if (!_current(request)) return;
      if (_state == PlayerState.completed) {
        await player.seek(Duration.zero);
        if (!_current(request)) return;
        _position = Duration.zero;
      }
      await player.resume();
    } catch (_) {
      if (_current(request)) {
        setState(() {
          _state = PlayerState.paused;
          _error = _audio == null
              ? 'Chưa tải được âm thanh. Kiểm tra kết nối và thử lại.'
              : 'Không thể phát âm thanh. Hãy nhấn nghe để thử lại.';
        });
      }
    } finally {
      if (_current(request)) setState(() => _busy = false);
    }
  }

  Future<void> _changeSpeed(double value) async {
    if (_busy || value == _speed) return;
    final request = _request;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_sourceReady) await _player!.setPlaybackRate(value);
      if (_current(request)) setState(() => _speed = value);
    } catch (_) {
      if (_current(request)) {
        setState(() => _error = 'Chưa đổi được tốc độ. Vui lòng thử lại.');
      }
    } finally {
      if (_current(request)) setState(() => _busy = false);
    }
  }

  Future<void> _seek(double milliseconds) async {
    if (_busy || !_sourceReady) return;
    final request = _request;
    setState(() {
      _busy = true;
      _dragPosition = null;
      _error = null;
    });
    try {
      final position = Duration(milliseconds: milliseconds.round());
      await _player!.seek(position);
      if (_current(request)) {
        setState(() {
          _position = position;
          if (_state == PlayerState.completed) _state = PlayerState.paused;
        });
      }
    } catch (_) {
      if (_current(request)) {
        setState(
          () => _error = 'Chưa chuyển được vị trí nghe. Vui lòng thử lại.',
        );
      }
    } finally {
      if (_current(request)) setState(() => _busy = false);
    }
  }

  void _releasePlayer() {
    ++_request;
    final player = _player;
    _player = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    if (player != null) unawaited(player.dispose().catchError((Object _) {}));
  }

  @override
  void didUpdateWidget(covariant NarrationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.audioUrl != widget.audioUrl) {
      _releasePlayer();
      _audio = null;
      _sourceReady = false;
      _state = PlayerState.stopped;
      _position = _duration = Duration.zero;
      _dragPosition = null;
      _error = null;
      _busy = false;
    }
  }

  @override
  void dispose() {
    _releasePlayer();
    super.dispose();
  }

  String _time(Duration value) {
    final seconds = value.inSeconds.clamp(0, 86400);
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _duration.inMilliseconds.toDouble();
    final progress = (_dragPosition ?? _position.inMilliseconds.toDouble())
        .clamp(0.0, total > 0 ? total : 1.0);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(
            _recorded ? 'Bản thu của bảo tàng' : 'Thuyết minh tiếng Việt',
          ),
          if (widget.variant != null) ...[
            const SizedBox(height: 6),
            Text(widget.variant!, style: AppTextStyles.caption),
          ],
          if (widget.text.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(widget.text, style: AppTextStyles.bodyLarge),
          ],
          const SizedBox(height: 18),
          const Text('Tốc độ đọc', style: AppTextStyles.caption),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final speed in [0.75, 1.0, 1.25])
                ChoiceChip(
                  label: Text('${speed}x'),
                  selected: _speed == speed,
                  onSelected: _busy ? null : (_) => _changeSpeed(speed),
                ),
            ],
          ),
          Slider(
            semanticFormatterCallback: (value) =>
                _time(Duration(milliseconds: value.round())),
            value: progress,
            max: total > 0 ? total : 1,
            onChanged: total > 0 && !_busy
                ? (value) => setState(() => _dragPosition = value)
                : null,
            onChangeEnd: total > 0 && !_busy ? _seek : null,
          ),
          Text(
            '${_time(Duration(milliseconds: progress.round()))} / ${total > 0 ? _time(_duration) : '--:--'}',
            style: AppTextStyles.caption,
          ),
          if (_audio != null) ...[
            const SizedBox(height: 6),
            Text(
              '${(_audio!.byteLength / 1024).toStringAsFixed(0)} KB · ${_audio!.voice}',
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: 14),
          if (_error != null) ...[Notice(_error!), const SizedBox(height: 12)],
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đang chuẩn bị âm thanh…',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            )
          else
            PrimaryButton(
              label: _playing
                  ? 'Tạm dừng thuyết minh'
                  : _state == PlayerState.completed
                  ? 'Nghe lại thuyết minh'
                  : 'Nghe thuyết minh âm thanh',
              icon: _playing ? Icons.pause : Icons.play_arrow,
              onPressed: _hasContent ? _toggle : null,
            ),
          const SizedBox(height: 12),
          Notice(
            widget.isDemo
                ? 'Đây là nội dung mẫu để trải nghiệm giọng đọc.'
                : _recorded
                ? 'Đang sử dụng bản thu âm đã được bảo tàng xuất bản.'
                : 'Giọng đọc được tổng hợp từ nội dung hiển thị. Bạn có thể tạm dừng, tua và đổi tốc độ nghe.',
          ),
        ],
      ),
    );
  }
}
