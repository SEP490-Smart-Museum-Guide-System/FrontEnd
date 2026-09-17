import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../data/visit_store.dart';
import '../../data/mock/mock_artifacts.dart';
import 'services_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: VisitStore.instance,
    builder: (context, _) {
      final store = VisitStore.instance;
      return MuseumPage(
        title: 'Góc của bạn',
        eyebrow: 'Người bạn của di sản',
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.deepBurgundy,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.mutedGold),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const HeritageSeal(size: 48, light: true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SỔ TAY DI SẢN',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.antiqueIvory,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Khách tham quan',
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.antiqueIvory,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stat(value: '${store.viewed.length}', label: 'Đã khám phá'),
              _Stat(value: '${store.saved.length}', label: 'Đã lưu'),
              _Stat(value: '${store.completedTours}', label: 'Hành trình'),
            ],
          ),
          const SectionHeading('Sổ tay tham quan'),
          ActionTile(
            title: 'Lịch sử khám phá',
            subtitle: 'Gặp lại những câu chuyện đã xem.',
            icon: Icons.history_outlined,
            onTap: () => openPage(
              context,
              const PersonalCollectionScreen(kind: 'history'),
            ),
          ),
          ActionTile(
            title: 'Hiện vật đã lưu',
            subtitle: 'Những điều bạn muốn tìm hiểu thêm.',
            icon: Icons.bookmark_border,
            onTap: () => openPage(
              context,
              const PersonalCollectionScreen(kind: 'saved'),
            ),
          ),
          ActionTile(
            title: 'Kết quả thử tài',
            subtitle: 'Nhìn lại những điều đã ghi nhớ.',
            icon: Icons.workspace_premium_outlined,
            onTap: () =>
                openPage(context, const PersonalCollectionScreen(kind: 'quiz')),
          ),
          ActionTile(
            title: 'Dịch vụ số',
            subtitle: 'Tiện ích cho chuyến tham quan.',
            icon: Icons.headphones_outlined,
            onTap: () => openPage(context, const ServicesScreen()),
          ),
          const SectionHeading('Đồng hành cùng bạn'),
          const Panel(
            child: Row(
              children: [
                Icon(Icons.language_outlined, color: AppColors.deepBurgundy),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ngôn ngữ', style: AppTextStyles.bodyMedium),
                      SizedBox(height: 4),
                      Text('Tiếng Việt', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ActionTile(
            title: 'Góp ý trải nghiệm',
            subtitle: 'Giúp cẩm nang ngày một tốt hơn.',
            icon: Icons.rate_review_outlined,
            onTap: () => openPage(context, const FeedbackScreen()),
          ),
          const SizedBox(height: 16),
          const Notice(
            'Bạn đang dùng bản trải nghiệm. Lịch sử, mục đã lưu và kết quả được giữ trong phiên hiện tại; tải lại trang sẽ đặt lại dữ liệu.',
          ),
          const Divider(),
          const Center(
            child: Text(
              'SMGS · Cẩm nang bảo tàng Việt',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      );
    },
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: AppTextStyles.display.copyWith(color: AppColors.deepBurgundy),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    ),
  );
}

class PersonalCollectionScreen extends StatelessWidget {
  const PersonalCollectionScreen({super.key, required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: VisitStore.instance,
    builder: (context, _) {
      final store = VisitStore.instance;
      final artifacts = kind == 'history'
          ? store.viewed
          : mockArtifacts
                .where(
                  (a) => kind == 'saved'
                      ? store.saved.contains(a.id)
                      : store.quizScores.containsKey(a.id),
                )
                .toList();
      return MuseumPage(
        back: true,
        title: kind == 'history'
            ? 'Lịch sử khám phá'
            : kind == 'saved'
            ? 'Hiện vật đã lưu'
            : 'Kết quả thử tài',
        eyebrow: 'Sổ tay của bạn',
        subtitle: 'Những dấu ấn trong phiên tham quan này.',
        children: [
          if (artifacts.isEmpty)
            EmptyState(
              title: 'Câu chuyện đang chờ bạn',
              message: kind == 'saved'
                  ? 'Chạm biểu tượng lưu ở trang hiện vật để thêm vào sổ tay.'
                  : kind == 'quiz'
                  ? 'Hoàn thành câu hỏi ở trang hiện vật để xem kết quả tại đây.'
                  : 'Mở một hiện vật để bắt đầu hành trình khám phá.',
              icon: Icons.auto_stories_outlined,
            ),
          ...artifacts.map(
            (a) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kind == 'quiz')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${store.quizScores[a.id]} / 2 câu trả lời đúng',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ArtifactCard(artifact: a),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String? _rating;
  bool _submitted = false;
  final _comment = TextEditingController();
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: _submitted ? 'Cảm ơn bạn!' : 'Bạn thấy thế nào?',
    eyebrow: 'Góp ý trải nghiệm',
    subtitle: _submitted
        ? 'Góp ý đã được ghi nhận trong phiên trải nghiệm này.'
        : 'Mỗi góp ý giúp chuyến tham quan trở nên dễ dàng hơn.',
    children: _submitted
        ? [
            const Panel(
              child: Notice(
                'Bản trải nghiệm chưa gửi góp ý đến bảo tàng. Nội dung sẽ không được lưu sau khi tải lại trang.',
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Trở về',
              onPressed: () => Navigator.pop(context),
            ),
          ]
        : [
            ...[
              'Rất hài lòng',
              'Hài lòng',
              'Bình thường',
              'Chưa hài lòng',
              'Rất không hài lòng',
            ].map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SecondaryButton(
                  label: '${_rating == r ? '✓  ' : ''}$r',
                  onPressed: () => setState(() => _rating = r),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn của bạn (không bắt buộc)',
                hintText: 'Chia sẻ điều bạn muốn cải thiện…',
              ),
            ),
            const SizedBox(height: 20),
            const Notice('Góp ý hiện chỉ được ghi nhận trong bản trải nghiệm.'),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Ghi nhận góp ý',
              onPressed: _rating == null
                  ? null
                  : () {
                      VisitStore.instance.recordFeedback(
                        _rating!,
                        _comment.text.trim(),
                      );
                      setState(() => _submitted = true);
                    },
            ),
          ],
  );
}
