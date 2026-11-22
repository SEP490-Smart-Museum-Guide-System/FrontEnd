import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_config.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/artifact_gallery.dart';
import '../../models/artifact.dart';
import '../../services/discovery_api_service.dart';
import '../../services/visitor_experience_api.dart';
import '../../data/visit_store.dart';
import '../ai_guide/ai_guide_screen.dart';
import '../../widgets/narration_player.dart';
import '../profile/profile_screen.dart';
import 'artifact_3d_screen.dart';
import 'daily_quiz_screen.dart';

class ArtifactDetailScreen extends StatefulWidget {
  const ArtifactDetailScreen({
    super.key,
    required this.artifact,
    required this.museumName,
  });
  final Artifact artifact;
  final String museumName;
  @override
  State<ArtifactDetailScreen> createState() => _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends State<ArtifactDetailScreen> {
  final _quizKey = GlobalKey();
  bool _skipQuiz = false;
  Map<String, dynamic>? _publishedContent;
  String? _contentError;
  bool _isPremiumLocked = false;
  Artifact? _detail;
  bool _photoError = false;
  bool _loadingPhotos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      VisitStore.instance.view(widget.artifact);
      final id = int.tryParse(widget.artifact.id);
      if (id == null || id <= 0) return;
      try {
        await VisitorExperienceApi.recordDetailView(id, ScanRequest.uuid());
      } on Exception {
        // A failed analytics request must leave the artifact readable.
      }
    });
    _loadPublishedContent();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final id = int.tryParse(widget.artifact.id);
    if (id == null) return;
    setState(() {
      _loadingPhotos = true;
      _photoError = false;
    });
    try {
      final json = await DiscoveryApiService.fetchArtifactDetail(id);
      if (mounted) {
        setState(() => _detail = Artifact.fromBackendJson(json));
      }
    } catch (_) {
      if (mounted) setState(() => _photoError = true);
    } finally {
      if (mounted) setState(() => _loadingPhotos = false);
    }
  }

  Future<void> _loadPublishedContent() async {
    final aId = int.tryParse(widget.artifact.id);
    if (aId != null) {
      try {
        final content = await DiscoveryApiService.fetchPublishedContent(aId);
        if (mounted) {
          setState(() {
            _publishedContent = content;
            _isPremiumLocked = false;
          });
        }
      } catch (e) {
        if (mounted) {
          final errStr = e.toString().toLowerCase();
          final isPremium =
              errStr.contains('403') ||
              errStr.contains('premium') ||
              errStr.contains('pass');
          setState(() {
            _isPremiumLocked = isPremium;
            _contentError = isPremium
                ? 'Hiện vật thuộc danh mục Premium. Cần kích hoạt Vé tham quan (Pass) còn hiệu lực để mở khóa toàn bộ thuyết minh đa ngôn ngữ và âm thanh AI.'
                : 'Chưa tải được nội dung thuyết minh. Vui lòng thử lại.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artifact;
    final summary = _publishedContent?['title'] as String? ?? a.summary;
    final story = _publishedContent?['description'] as String? ?? a.story;
    final detail = _detail;
    final photos = detail != null && detail.photos.isNotEmpty
        ? detail.photos
        : a.photos;
    final modelArtifact = detail?.modelUrl?.trim().isNotEmpty == true
        ? detail!
        : a;
    final modelUrl = modelArtifact.modelUrl?.trim() ?? '';
    final uri = Uri.tryParse(modelUrl);
    final hasModel =
        modelUrl.startsWith('assets/models/') ||
        (uri != null &&
            {'https', 'http'}.contains(uri.scheme) &&
            uri.host.isNotEmpty);
    void model() =>
        openPage(context, Artifact3DScreen(artifact: modelArtifact));
    void ask() => openPage(context, AiGuideScreen(artifact: a));
    final audio = ApiConfig.mediaUrl(_publishedContent?['audioUrl'] as String?);
    final narration = (_publishedContent?['narrationText'] as String?)?.trim();
    final script = narration?.isNotEmpty == true
        ? narration!
        : (_publishedContent?['description'] as String? ?? '');
    final metadata = <String, String>{};
    final paragraphs = <String>[];
    for (final line in (story.trim().isEmpty ? summary : story).split('\n')) {
      final match = RegExp(
        r'^\s*[-*]?\s*(Tên hiện vật|Tên tiếng Anh|Chất liệu|Niên đại|Đặc điểm)\s*:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (match == null) {
        paragraphs.add(line);
      } else {
        final key = match[1]!.toLowerCase();
        final value = match[2]!.trim();
        metadata[key] = value;
        if (key == 'chất liệu' || key == 'niên đại') paragraphs.add(line);
        if (key == 'đặc điểm') paragraphs.add(value);
      }
    }
    if (!metadata.containsKey('niên đại') && a.period.trim().isNotEmpty) {
      paragraphs.add('Niên đại: ${a.period.trim()}');
    }
    final storyText = paragraphs.join('\n').trim();
    final hasNarration = audio.isNotEmpty || script.trim().isNotEmpty;
    final children = <Widget>[
      if (_loadingPhotos) const LinearProgressIndicator(),
      if (_photoError)
        Row(
          children: [
            const Expanded(child: Text('Chưa tải đủ ảnh hiện vật.')),
            TextButton(onPressed: _loadPhotos, child: const Text('Thử lại')),
          ],
        ),
      const Eyebrow('HIỆN VẬT BẢO TÀNG'),
      const SizedBox(height: 8),
      Text(a.name, style: AppTextStyles.pageTitle.copyWith(height: 1.2)),
      if (metadata['tên tiếng anh'] case final String name)
        Text(
          name,
          style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
        ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, size: 17),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              [
                widget.museumName,
                a.location,
              ].where((value) => value.isNotEmpty).join(' · '),
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (_isPremiumLocked) ...[
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.mutedGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.mutedGold),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: AppColors.deepBurgundy,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bảo vật danh mục Premium',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepBurgundy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _contentError ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.darkBrown,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ] else if (_contentError != null) ...[
        Notice(_contentError!),
        TextButton(
          onPressed: () {
            setState(() => _contentError = null);
            _loadPublishedContent();
          },
          child: const Text('Thử lại'),
        ),
      ],
      if (storyText.isNotEmpty) ...[
        const Eyebrow('Câu chuyện'),
        const Text(
          '“',
          style: TextStyle(fontSize: 42, height: 1, color: AppColors.mutedGold),
        ),
        Text(
          storyText,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
      ],
      SizedBox(key: _quizKey),
      if (!_skipQuiz)
        Panel(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bạn đã tìm hiểu xong?',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Thử vài câu hỏi ngắn về hiện vật này.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Làm Quiz ngay',
                onPressed: () =>
                    openPage(context, DailyQuizScreen(artifactId: a.id)),
              ),
              TextButton(
                onPressed: () => setState(() => _skipQuiz = true),
                child: const Text('Để sau'),
              ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      TextButton.icon(
        label: const Text('Góp ý về hiện vật này'),
        icon: const Icon(Icons.chat_bubble_outline, size: 16),
        onPressed: () => openPage(
          context,
          FeedbackScreen(
            targetType: 'artifact',
            targetId: a.id,
            targetName: a.name,
          ),
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            expandedHeight: (MediaQuery.sizeOf(context).height * .46).clamp(
              240.0,
              420.0,
            ),
            title: LayoutBuilder(
              builder: (context, _) {
                final bar = context
                    .dependOnInheritedWidgetOfExactType<
                      FlexibleSpaceBarSettings
                    >();
                return bar == null || bar.currentExtent <= bar.minExtent + 1
                    ? Text(
                        a.name,
                        style: AppTextStyles.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink();
              },
            ),
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: IconButton.filledTonal(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                  icon: const BackButtonIcon(),
                ),
              ),
            ),
            actions: [
              IconButton.filledTonal(
                tooltip: 'Chia sẻ hiện vật',
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await SystemChannels.platform.invokeMethod<void>(
                      'Share.invoke',
                      '${a.name} · ${widget.museumName}',
                    );
                    return;
                  } on MissingPluginException {
                    // Copy the details on platforms without a share sheet.
                  }
                  await Clipboard.setData(
                    ClipboardData(text: '${a.name} · ${widget.museumName}'),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép thông tin hiện vật.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.ios_share_outlined),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ListenableBuilder(
                  listenable: VisitStore.instance,
                  builder: (context, _) {
                    final saved = VisitStore.instance.saved.contains(a.id);
                    return IconButton.filledTonal(
                      tooltip: saved ? 'Bỏ lưu hiện vật' : 'Lưu hiện vật',
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.white,
                      ),
                      isSelected: saved,
                      selectedIcon: const Icon(Icons.bookmark),
                      icon: const Icon(Icons.bookmark_border),
                      onPressed: () => VisitStore.instance.toggleSave(a.id),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: ArtifactGallery(
                photos: photos,
                name: a.name,
                cover: true,
                onModel: hasModel ? model : null,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 9, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 34,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withValues(alpha: .35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              if (hasNarration) ...[
                Expanded(
                  child: NarrationPlayer(
                    compact: true,
                    text: script,
                    audioUrl: audio.isEmpty ? null : audio,
                    onStart: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final target = _quizKey.currentContext;
                        if (target != null) {
                          Scrollable.ensureVisible(
                            target,
                            alignment: .2,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: ask,
                icon: const Icon(Icons.chat_bubble_outline, size: 17),
                label: const Text('Hỏi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
