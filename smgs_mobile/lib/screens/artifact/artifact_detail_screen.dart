import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../services/discovery_api_service.dart';
import '../../data/visit_store.dart';
import '../ai_guide/ai_guide_screen.dart';
import 'quiz_screen.dart';
import '../../widgets/narration_player.dart';
import '../profile/profile_screen.dart';
import 'artifact_3d_screen.dart';
import '../museum/indoor_guidance_screen.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        VisitStore.instance.view(widget.artifact);
      }
    });
    _loadPublishedContent();
  }

  Future<void> _loadPublishedContent() async {
    final aId = int.tryParse(widget.artifact.id) ?? (widget.artifact.id == 'artifact_1' ? 1 : null);
    if (aId != null) {
      try {
        final content = await DiscoveryApiService.fetchPublishedContent(aId);
        if (mounted) {
          setState(() => _publishedContent = content);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artifact;
    final summary = _publishedContent?['title'] as String? ?? a.summary;
    final story = _publishedContent?['description'] as String? ?? a.story;
    return StoryScaffold(
      title: a.name,
      photo: a.id == 'artifact_1'
          ? Image.asset(
              'assets/images/ngoc-lu-web.jpg',
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: 'Trống đồng Ngọc Lũ',
            )
          : HeritageArt(kind: a.id, height: 300),
      actions: [
        ListenableBuilder(
          listenable: VisitStore.instance,
          builder: (context, _) => Tooltip(
            message: VisitStore.instance.saved.contains(a.id)
                ? 'Bỏ lưu hiện vật'
                : 'Lưu hiện vật',
            child: TextButton.icon(
              onPressed: () => VisitStore.instance.toggleSave(a.id),
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
        Text(
          a.id == 'artifact_1'
              ? 'Trống đồng Ngọc Lũ · Ảnh: VuThiAnh, Wikimedia Commons'
              : 'Hình minh họa · Không phải ảnh hiện vật gốc',
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
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
        Text(summary, style: AppTextStyles.bodyLarge),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Hỏi hướng dẫn viên',
          icon: Icons.chat_bubble_outline,
          onPressed: () => openPage(context, AiGuideScreen(artifact: a)),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Bản thuyết minh',
          icon: Icons.menu_book_outlined,
          onPressed: () => openPage(context, NarrationScreen(artifact: a)),
        ),
        if (a.id == 'artifact_1' || a.id == '1' || (a.modelUrl != null && a.modelUrl!.isNotEmpty)) ...[
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Xem mô hình 3D',
            icon: Icons.view_in_ar_outlined,
            onPressed: () => openPage(context, Artifact3DScreen(artifact: a)),
          ),
        ],
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
                      const Icon(Icons.school_outlined, color: AppColors.deepBurgundy, size: 22),
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
                        ? 'Câu đố đã được lưu vào "Danh sách Quiz tích lũy trong ngày". Bạn có thể làm ngay hoặc để đến cuối ngày.'
                        : 'Bạn có thể thử sức ngay với 2 câu trắc nghiệm nhanh để tích điểm, hoặc lưu lại để cuối ngày làm.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (isCompleted)
                    SecondaryButton(
                      label: 'Làm lại câu đố khác',
                      icon: Icons.refresh,
                      onPressed: () => openPage(context, QuizScreen(artifact: a)),
                    )
                  else ...[
                    PrimaryButton(
                      label: 'Làm Quiz ngay (+20 điểm)',
                      icon: Icons.play_arrow,
                      onPressed: () => openPage(context, QuizScreen(artifact: a)),
                    ),
                    const SizedBox(height: 8),
                    if (!isDeferred)
                      SecondaryButton(
                        label: 'Để khi rảnh làm sau (Tích lũy cuối ngày)',
                        icon: Icons.alarm_add_outlined,
                        onPressed: () {
                          store.deferQuiz(a.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã lưu câu đố vào mục Quiz tích lũy cuối ngày.'),
                              backgroundColor: AppColors.deepBurgundy,
                            ),
                          );
                        },
                      )
                    else
                      TextButton.icon(
                        onPressed: () => openPage(context, const DailyQuizScreen()),
                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF2E6B3E), size: 18),
                        label: const Text(
                          'Đã lưu · Xem danh sách Quiz trong ngày',
                          style: TextStyle(color: Color(0xFF2E6B3E), fontWeight: FontWeight.w600),
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
