import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../data/visit_store.dart';
import '../../data/mock/mock_artifacts.dart';
import 'services_screen.dart';
import 'history_screen.dart';
import '../../services/app_services.dart';
import '../../services/app_preferences.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([VisitStore.instance, AppServices.auth]),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.mutedGold),
                    borderRadius: BorderRadius.circular(9),
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
                        AppServices.auth.user?.name ?? 'Người dùng SMGS',
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
              _Stat(value: '${store.visitedCount}', label: 'Đã tham quan'),
              _Stat(value: '${store.saved.length}', label: 'Đã lưu'),
              _Stat(value: '${store.completedTours}', label: 'Hành trình'),
            ],
          ),
          const SectionHeading('Sổ tay tham quan'),
          ActionTile(
            title: 'Lịch sử khám phá',
            subtitle: 'Gặp lại những câu chuyện đã xem.',
            icon: Icons.history_outlined,
            onTap: () => openPage(context, const HistoryScreen()),
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
            title: 'Vé & Hướng dẫn số',
            subtitle: 'Vé vào cửa, quyền truy cập và gói kết hợp.',
            icon: Icons.confirmation_number_outlined,
            onTap: () => openPage(context, const ServicesScreen()),
          ),
          ActionTile(
            title: 'Huy hiệu của bạn',
            subtitle: '${store.points} điểm · ${store.badges.length} huy hiệu',
            icon: Icons.military_tech_outlined,
            onTap: () => openPage(context, const BadgesScreen()),
          ),
          ActionTile(
            title: 'Đơn mua của bạn',
            subtitle: 'Xem vé, quyền sử dụng và lịch sử thanh toán.',
            icon: Icons.receipt_long_outlined,
            onTap: () => openPage(context, const PurchasedServicesScreen()),
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
          ActionTile(
            title: 'Cài đặt trải nghiệm',
            subtitle: 'Cỡ chữ và chuyển động theo ý bạn.',
            icon: Icons.tune_outlined,
            onTap: () => openPage(context, const SettingsScreen()),
          ),
          SecondaryButton(
            label: 'Đăng xuất',
            icon: Icons.logout,
            onPressed: () {
              VisitStore.instance.reset();
              AppServices.auth.logout();
            },
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
          if (kind == 'quiz') ...[
            Panel(
              gold: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Tiến độ thử tài'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ProgressValue(
                          value: '${store.points}',
                          label: 'Tổng điểm',
                        ),
                      ),
                      Expanded(
                        child: _ProgressValue(
                          value: '${store.quizScores.length}',
                          label: 'Hiện vật',
                        ),
                      ),
                      Expanded(
                        child: _ProgressValue(
                          value: '${store.badges.length}',
                          label: 'Huy hiệu',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${store.quizResults.length} lượt thử tài đã hoàn thành trong phiên này.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
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
                    child: Panel(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Kết quả tốt nhất: ${store.quizScores[a.id]} / 2 câu đúng · '
                        '${store.quizResults.where((r) => r.artifactId == a.id).length} lượt làm',
                        style: AppTextStyles.bodyMedium,
                      ),
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

class _ProgressValue extends StatelessWidget {
  const _ProgressValue({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: AppTextStyles.pageTitle.copyWith(color: AppColors.deepBurgundy),
      ),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
    ],
  );
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    this.targetType = 'app',
    this.targetId = 'smgs',
    this.targetName = 'Cẩm nang SMGS',
  });
  final String targetType, targetId, targetName;
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
        : widget.targetName,
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
                        targetType: widget.targetType,
                        targetId: widget.targetId,
                        targetName: widget.targetName,
                      );
                      setState(() => _submitted = true);
                    },
            ),
          ],
  );
}

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = VisitStore.instance;
    return MuseumPage(
      back: true,
      title: 'Dấu ấn của bạn',
      eyebrow: 'Huy hiệu & điểm khám phá',
      children: [
        Panel(
          gold: true,
          child: Column(
            children: [
              const HeritageSeal(size: 80),
              const SizedBox(height: 16),
              Text('${store.points} điểm', style: AppTextStyles.display),
              const SizedBox(height: 12),
              const Text(
                'Tổng điểm từ kết quả tốt nhất của mỗi hiện vật. Làm lại không cộng trùng điểm.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SectionHeading('Bộ sưu tập huy hiệu'),
        if (store.badges.isEmpty)
          const EmptyState(
            title: 'Huy hiệu đầu tiên đang chờ',
            message: 'Trả lời đúng toàn bộ câu hỏi của một hiện vật để nhận huy hiệu.',
          ),
        for (final badge in store.badges)
          Panel(
            gold: true,
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.mutedGold,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(badge, style: AppTextStyles.sectionTitle)),
              ],
            ),
          ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppPreferences.instance,
    builder: (context, _) => MuseumPage(
      back: true,
      title: 'Vừa vặn với bạn',
      eyebrow: 'Cài đặt trải nghiệm',
      children: [
        const Panel(
          child: Text('Ngôn ngữ: Tiếng Việt', style: AppTextStyles.bodyMedium),
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Chữ lớn hơn', style: AppTextStyles.bodyMedium),
          value: AppPreferences.instance.largeText,
          onChanged: AppPreferences.instance.setLargeText,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Giảm chuyển động',
            style: AppTextStyles.bodyMedium,
          ),
          subtitle: const Text(
            'Tắt hiệu ứng chuyển trang, hiện dần và dịch chuyển ảnh.',
            style: AppTextStyles.caption,
          ),
          value: AppPreferences.instance.reducedMotion,
          onChanged: AppPreferences.instance.setReducedMotion,
        ),
        const SizedBox(height: 20),
        const Notice(
          'Cài đặt và dữ liệu chỉ được giữ trong phiên trải nghiệm hiện tại.',
        ),
      ],
    ),
  );
}
