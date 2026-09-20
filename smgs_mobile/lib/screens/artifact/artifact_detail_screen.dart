import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../models/artifact.dart';
import '../../data/visit_store.dart';
import '../ai_guide/ai_guide_screen.dart';
import 'quiz_screen.dart';
import '../../widgets/narration_player.dart';
import '../profile/profile_screen.dart';
import 'artifact_3d_screen.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        VisitStore.instance.view(widget.artifact);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artifact;
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
        Text(a.summary, style: AppTextStyles.bodyLarge),
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
        if (a.id == 'artifact_1') ...[
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Xem mô hình 3D',
            icon: Icons.view_in_ar_outlined,
            onPressed: () => openPage(context, Artifact3DScreen(artifact: a)),
          ),
        ],
        const SectionHeading('Những điều còn lưu lại'),
        ScrollReveal(child: Text(a.story, style: AppTextStyles.bodyLarge)),
        const SizedBox(height: 24),
        ActionTile(
          title: 'Bạn đã khám phá được gì?',
          subtitle: 'Thử sức với hai câu hỏi ngắn.',
          icon: Icons.quiz_outlined,
          onTap: () => openPage(context, QuizScreen(artifact: a)),
        ),
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
