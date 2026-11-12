import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/artifact_gallery.dart';
import '../../models/artifact.dart';
import '../../services/discovery_api_service.dart';
import '../../data/visit_store.dart';
import '../ai_guide/ai_guide_screen.dart';
import 'quiz_screen.dart';
import '../../widgets/narration_player.dart';
import '../profile/profile_screen.dart';
import 'artifact_3d_screen.dart';
import '../museum/indoor_guidance_screen.dart';
import '../museum/visitor_directory_screen.dart';
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
  Map<String, dynamic>? _publishedContent;
  String? _contentError;
  List<String>? _photos;
  bool _photoError = false;
  bool _loadingPhotos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        VisitStore.instance.view(widget.artifact);
      }
    });
    _loadPublishedContent();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final id = int.tryParse(widget.artifact.id);
    if (id == null) return;
    setState(() { _loadingPhotos = true; _photoError = false; });
    try {
      final json = await DiscoveryApiService.fetchArtifactDetail(id);
      if (mounted) setState(() => _photos = Artifact.fromBackendJson(json).photos);
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
          setState(() => _publishedContent = content);
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => _contentError =
                'Chưa tải được nội dung thuyết minh. Vui lòng thử lại.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artifact;
    final summary = _publishedContent?['title'] as String? ?? a.summary;
    final story = _publishedContent?['description'] as String? ?? a.story;
    return StoryScaffold(
      title: a.name,
      photo: ArtifactGallery(photos: _photos ?? a.photos, name: a.name),
      actions: [
        ListenableBuilder(
          listenable: VisitStore.instance,
          builder: (context, _) => Tooltip(
            message: VisitStore.instance.saved.contains(a.id)
                ? 'Bỏ lưu hiện vật'
                : 'Lưu hiện vật',
            child: TextButton.icon(
              onPressed: () {
                VisitStore.instance.toggleSave(a.id);
                ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(VisitStore.instance.saved.contains(a.id) ? 'Đã lưu hiện vật vào bộ sưu tập.' : 'Đã bỏ lưu hiện vật.')));
              },
              icon: Icon(
                VisitStore.instance.saved.contains(a.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: AppColors.deepBurgundy,
              ),
              label: Text(
                VisitStore.instance.saved.contains(a.id) ? 'Đã lưu' : 'Lưu',
              ),
            ),
          ),
        ),
      ],
      children: [
        if (_loadingPhotos) const LinearProgressIndicator(),
        if (_photoError) Row(children: [
          const Expanded(child: Text('Chưa tải đủ ảnh hiện vật.')),
          TextButton(onPressed: _loadPhotos, child: const Text('Thử lại')),
        ]),
        Text(
          a.id == 'artifact_1'
              ? 'Trống đồng Ngọc Lũ · Ảnh: VuThiAnh, Wikimedia Commons'
              : (a.imageUrl.isEmpty
                    ? 'Chưa có ảnh hiện vật'
                    : 'Ảnh hiện vật từ bảo tàng'),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 24),
        Eyebrow(a.category),
        const SizedBox(height: 8),
        Text(
          a.name,
          style: AppTextStyles.display.copyWith(color: AppColors.deepBurgundy),
        ),
        const SizedBox(height: 12),
        Text(
          a.period,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.deepBurgundy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.museumName}\n${a.location}',
          style: AppTextStyles.bodySmall,
        ),
        const Divider(),
        if (_publishedContent != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.mutedGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.mutedGold),
            ),
            child: const Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Icon(Icons.verified, size: 14, color: AppColors.deepBurgundy),
                SizedBox(width: 6),
                Text(
                  'Thuyết minh chính thức đã qua Giám tuyển duyệt',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepBurgundy,
                  ),
                ),
              ],
            ),
          ),
        if (_contentError != null) ...[
          Notice(_contentError!),
          TextButton(
            onPressed: () {
              setState(() => _contentError = null);
              _loadPublishedContent();
            },
            child: const Text('Thử lại'),
          ),
        ],
        Text(summary, style: AppTextStyles.bodyLarge),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Hỏi hướng dẫn viên',
          icon: Icons.chat_bubble_outline,
          onPressed: () => openPage(context, AiGuideScreen(artifact: a)),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.more_horiz), label: const Text('Thuyết minh, chỉ đường & 3D'),
          onPressed: () => showModalBottomSheet<void>(context: context, showDragHandle: true,
            builder: (sheetContext) {
              void go(Widget screen) { Navigator.pop(sheetContext); openPage(context, screen); }
              return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('Đọc & nghe thuyết minh'), trailing: const Icon(Icons.chevron_right), onTap: () => go(NarrationScreen(artifact: a))),
                if (int.tryParse(a.museumId) != null && int.tryParse(a.id) != null)
                  ListTile(leading: const Icon(Icons.directions_walk), title: const Text('Chỉ đường tới hiện vật'), trailing: const Icon(Icons.chevron_right), onTap: () => go(VisitorDirectoryScreen(museumId: int.parse(a.museumId), initialArtifactId: int.parse(a.id), museumName: widget.museumName))),
                if (a.modelUrl?.isNotEmpty == true)
                  ListTile(leading: const Icon(Icons.view_in_ar_outlined), title: const Text('Xem mô hình 3D'), trailing: const Icon(Icons.chevron_right), onTap: () => go(Artifact3DScreen(artifact: a))),
              ])));
            }),
        ),
        const SectionHeading('Những điều còn lưu lại'),
        ScrollReveal(child: Text(story, style: AppTextStyles.bodyLarge)),
        const SizedBox(height: 24),
        // Khối quyết định sau khi đọc xong theo bối cảnh U2
        ListenableBuilder(
          listenable: VisitStore.instance,
          builder: (context, _) {
            final store = VisitStore.instance;
            final isDeferred = store.isQuizDeferred(a.id);
            final isCompleted = store.quizScores.containsKey(a.id);
            final nextArtifact = store.getNextArtifact(a);

            return Panel(
              gold: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        color: AppColors.deepBurgundy,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'BẠN ĐÃ TÌM HIỂU XONG HIỆN VẬT',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.deepBurgundy,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCompleted
                        ? 'Bạn đã hoàn thành bài thử tài cho hiện vật này (Đạt ${store.quizScores[a.id]}/2 câu).'
                        : isDeferred
                        ? 'Bạn đã đánh dấu để xem lại trong phiên này. Danh sách câu đố chính thức được tải từ hệ thống.'
                        : 'Mở danh sách câu đố để xem bài được hệ thống cấp cho hiện vật này.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (isCompleted)
                    SecondaryButton(
                      label: 'Làm lại câu đố khác',
                      icon: Icons.refresh,
                      onPressed: () =>
                          openPage(context, QuizScreen(artifact: a)),
                    )
                  else ...[
                    PrimaryButton(
                      label: 'Khám phá câu đố',
                      icon: Icons.play_arrow,
                      onPressed: () =>
                          openPage(context, QuizScreen(artifact: a)),
                    ),
                    const SizedBox(height: 8),
                    if (!isDeferred)
                      SecondaryButton(
                        label: 'Lưu để làm sau',
                        icon: Icons.alarm_add_outlined,
                        onPressed: () {
                          store.deferQuiz(a.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã lưu câu đố vào mục Quiz tích lũy cuối ngày.',
                              ),
                              backgroundColor: AppColors.deepBurgundy,
                            ),
                          );
                        },
                      )
                    else
                      TextButton.icon(
                        onPressed: () =>
                            openPage(context, const DailyQuizScreen()),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF2E6B3E),
                          size: 18,
                        ),
                        label: const Text(
                          'Đã lưu · Xem danh sách Quiz trong ngày',
                          style: TextStyle(
                            color: Color(0xFF2E6B3E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  if (nextArtifact != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Chỉ đường tới: ${nextArtifact.name}',
                      icon: Icons.directions_walk,
                      onPressed: () => openPage(
                        context,
                        IndoorGuidanceScreen(
                          currentArtifact: a,
                          nextArtifact: nextArtifact,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ActionTile(
          title: 'Góp ý về hiện vật',
          subtitle: 'Chia sẻ cảm nhận về câu chuyện này.',
          icon: Icons.rate_review_outlined,
          onTap: () => openPage(
            context,
            FeedbackScreen(
              targetType: 'artifact',
              targetId: a.id,
              targetName: a.name,
            ),
          ),
        ),
      ],
    );
  }
}
