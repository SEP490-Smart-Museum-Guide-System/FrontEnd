import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/visitor_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/artifact.dart';
import '../../services/app_services.dart';
import '../../services/ai_guide_service.dart';
import 'ai_guide_screen.dart';

class AiGuideHistoryScreen extends StatefulWidget {
  const AiGuideHistoryScreen({super.key});

  @override
  State<AiGuideHistoryScreen> createState() => _AiGuideHistoryScreenState();
}

class _AiGuideHistoryScreenState extends State<AiGuideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<GuideConversationItem>> _conversationsFuture;
  late Future<List<GuideChatMessage>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  void _reload() {
    setState(() {
      _conversationsFuture = AppServices.guide.getMyConversations();
      _messagesFuture = AppServices.guide.getMyMessagesFeed();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openArtifactGuide(int artifactId, String artifactName, int museumId) {
    final artifact = Artifact(
      id: artifactId.toString(),
      name: artifactName,
      category: 'Hiện vật bảo tàng',
      museumId: museumId.toString(),
      imageUrl: '',
      period: '',
      location: '',
      summary: artifactName,
      story: artifactName,
      aiGuide: 'Bạn có thể hỏi Trợ lý AI về chi tiết hiện vật $artifactName.',
      quizPrompt: 'Tìm hiểu về $artifactName',
    );
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AiGuideScreen(artifact: artifact),
          ),
        )
        .then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEn = l10n.isEn;

    return Scaffold(
      backgroundColor: VisitorColors.background,
      appBar: AppBar(
        title: Text(
          isEn ? 'AI Heritage History' : 'Lịch sử Trợ lý AI',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: VisitorColors.burgundy,
          unselectedLabelColor: VisitorColors.secondaryText,
          indicatorColor: VisitorColors.burgundy,
          tabs: [
            Tab(text: isEn ? 'By Artifact' : 'Theo hiện vật'),
            Tab(text: isEn ? 'Timeline' : 'Dòng thời gian'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationsTab(isEn),
          _buildMessagesTimelineTab(isEn),
        ],
      ),
    );
  }

  Widget _buildConversationsTab(bool isEn) {
    return FutureBuilder<List<GuideConversationItem>>(
      future: _conversationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: VisitorColors.secondaryText),
                  const SizedBox(height: 12),
                  Text(
                    isEn ? 'Could not load conversation history.' : 'Không thể tải lịch sử trò chuyện.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _reload,
                    child: Text(isEn ? 'Retry' : 'Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.forum_outlined, size: 56, color: VisitorColors.secondaryText),
                  const SizedBox(height: 16),
                  Text(
                    isEn ? 'No AI conversations yet.' : 'Chưa có cuộc trò chuyện AI nào.',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn
                        ? 'Questions you ask the AI assistant while viewing artifacts will appear here.'
                        : 'Các câu hỏi bạn trao đổi với Trợ lý AI khi xem hiện vật sẽ được lưu tự động tại đây.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(color: VisitorColors.secondaryText),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: VisitorColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openArtifactGuide(item.artifactId, item.artifactName, item.museumId),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.artifactName,
                                style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: VisitorColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isEn ? '${item.exchangeCount} turns' : '${item.exchangeCount} lượt',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: VisitorColors.burgundy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.museumName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.museumName,
                            style: AppTextStyles.caption.copyWith(color: VisitorColors.secondaryText),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: VisitorColors.surface1,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q: ${item.lastQuestion}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A: ${item.lastAnswer}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(color: VisitorColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            item.lastAskedAt.toLocal().toString().substring(0, 16),
                            style: AppTextStyles.caption.copyWith(color: VisitorColors.secondaryText, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessagesTimelineTab(bool isEn) {
    return FutureBuilder<List<GuideChatMessage>>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: Text(isEn ? 'Retry' : 'Thử lại'),
            ),
          );
        }

        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Text(
              isEn ? 'No message timeline recorded.' : 'Chưa có dữ liệu dòng thời gian.',
              style: AppTextStyles.bodyMedium.copyWith(color: VisitorColors.secondaryText),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: VisitorColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              msg.artifactName,
                              style: AppTextStyles.sectionTitle.copyWith(fontSize: 14, color: VisitorColors.burgundy),
                            ),
                          ),
                          Text(
                            msg.createdAt.toLocal().toString().substring(0, 16),
                            style: AppTextStyles.caption.copyWith(color: VisitorColors.secondaryText, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        msg.question,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg.answer,
                        style: AppTextStyles.bodySmall.copyWith(color: VisitorColors.text),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
