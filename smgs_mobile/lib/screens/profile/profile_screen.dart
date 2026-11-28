import '../../core/localization/app_localizations.dart';
import '../../widgets/visitor_handbook_sheet.dart';
import 'experience_history_screen.dart';
import 'my_museum_screen.dart';
import 'order_detail_screen.dart';
import '../../services/backend_api.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../services/token_manager.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../data/visit_store.dart';
import 'services_screen.dart';
import 'history_screen.dart';
import 'support_refund_screen.dart';
import '../ai_guide/ai_guide_history_screen.dart';
import '../notification/notification_center_screen.dart';
import '../../services/notification_controller.dart';
import '../artifact/daily_quiz_screen.dart';
import '../../services/app_services.dart';
import '../../services/app_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _points = 0;
  int _artifactsCount = 0;
  int _museumsCount = 0;
  int _deferredQuizCount = 0;
  int _walletBalance = 0;
  Map<String, dynamic>? _activeTicketOrder;
  List<String> _thumbnailUrls = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = AppServices.auth.user;
    final store = VisitStore.instance;

    var points = store.points;
    var artifacts = store.viewed.length;
    var museums = 1;
    var deferred = 0;
    var wallet = 0;
    Map<String, dynamic>? activeTicket;
    var thumbs = <String>[];

    if (user != null) {
      try {
        final results = await Future.wait([
          BackendApi.request('gamification/me/points').catchError((_) => {'points': points}),
          BackendApi.request('recognitions/collection?page=1&pageSize=4').catchError((_) => <String, dynamic>{}),
          BackendApi.list('visits/me').catchError((_) => <Map<String, dynamic>>[]),
          BackendApi.list('daily-quizzes/today').catchError((_) => <Map<String, dynamic>>[]),
          BackendApi.request('commerce/wallet/me').catchError((_) => <String, dynamic>{}),
          BackendApi.list('commerce/orders/me').catchError((_) => <Map<String, dynamic>>[]),
        ]);

        final ptsData = results[0] as Map<String, dynamic>?;
        if (ptsData != null && ptsData['points'] != null) {
          points = (ptsData['points'] as num).toInt();
        }

        final collData = results[1] as Map<String, dynamic>?;
        if (collData != null) {
          if (collData['totalCollected'] != null) {
            artifacts = (collData['totalCollected'] as num).toInt();
          } else if (collData['totalCount'] != null) {
            artifacts = (collData['totalCount'] as num).toInt();
          }
          final items = (collData['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          for (final it in items) {
            final url = it['imageUrl']?.toString();
            if (url != null && url.isNotEmpty) {
              thumbs.add(url);
            }
          }
        }

        final visits = results[2] as List<dynamic>?;
        if (visits != null && visits.isNotEmpty) {
          final museumIds = visits.map((v) => v['museumId']).toSet();
          museums = museumIds.length;
        }

        final quizzes = results[3] as List<dynamic>?;
        if (quizzes != null) {
          deferred = quizzes.where((q) => q['status'] == 'deferred' || q['status'] == 'pending').length;
        }

        final walletData = results[4] as Map<String, dynamic>?;
        if (walletData != null && walletData['balance'] != null) {
          wallet = (walletData['balance'] as num).toInt();
        }

        final orders = results[5] as List<dynamic>?;
        if (orders != null && orders.isNotEmpty) {
          final now = DateTime.now();
          final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          for (final ord in orders) {
            if (ord is! Map) continue;
            final map = Map<String, dynamic>.from(ord);
            final status = (map['status'] ?? '').toString().toLowerCase();
            if (status == 'paid' || status == 'completed') {
              final vDate = map['visitDate']?.toString();
              if (vDate != null && vDate.startsWith(todayStr)) {
                activeTicket = map;
                break;
              }
            }
          }

          if (activeTicket == null) {
            for (final ord in orders) {
              if (ord is! Map) continue;
              final map = Map<String, dynamic>.from(ord);
              final status = (map['status'] ?? '').toString().toLowerCase();
              if (status == 'paid' || status == 'completed') {
                final vDate = map['visitDate']?.toString();
                if (vDate != null) {
                  try {
                    final dt = DateTime.parse(vDate);
                    final diff = dt.difference(now).inDays;
                    if (diff >= 0 && diff <= 7) {
                      activeTicket = map;
                      break;
                    }
                  } catch (_) {}
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    if (thumbs.isEmpty) {
      thumbs = AppServices.catalog.artifacts
          .where((a) => a.imageUrl.isNotEmpty)
          .take(3)
          .map((a) => a.imageUrl)
          .toList();
    }

    if (mounted) {
      setState(() {
        _points = points;
        _artifactsCount = artifacts;
        _museumsCount = museums;
        _deferredQuizCount = deferred;
        _walletBalance = wallet;
        _activeTicketOrder = activeTicket;
        _thumbnailUrls = thumbs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([VisitStore.instance, AppServices.auth, AppPreferences.instance]),
      builder: (context, _) {
        final l10n = context.l10n;
        final store = VisitStore.instance;
        final userName = AppServices.auth.user?.name ?? (l10n.isEn ? 'Heritage Explorer' : 'Người dùng SMGS');

        return MuseumPage(
          title: l10n.isEn ? 'Your Corner' : 'Góc của bạn',
          eyebrow: l10n.isEn ? 'Friend of Heritage' : 'Người bạn của di sản',
          action: IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.darkBrown, size: 23),
            tooltip: l10n.isEn ? 'Settings & support' : 'Cài đặt & hỗ trợ',
            onPressed: () => openPage(context, const SettingsAndSupportScreen()),
          ),
          children: [
            // 1. Hero Passport Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.deepBurgundy,
                borderRadius: BorderRadius.circular(VisitorRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBurgundy.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned(
                    right: -25,
                    top: -25,
                    child: Opacity(
                      opacity: 0.12,
                      child: HeritageSeal(size: 160, light: true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.mutedGold.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              child: const Center(
                                child: Icon(Icons.stars_rounded, color: AppColors.mutedGold, size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.isEn ? 'HERITAGE PASSPORT' : 'SỔ TAY DI SẢN',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.sansFamily,
                                      fontSize: 10.5,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.mutedGold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.sansFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.antiqueIvory,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildMetricItem(
                                value: '$_points',
                                label: l10n.isEn ? 'Points' : 'Điểm',
                                icon: Icons.stars_rounded,
                                onTap: () => openPage(context, const ExperienceHistoryScreen(kind: 'points')),
                              ),
                              Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.15)),
                              _buildMetricItem(
                                value: '$_artifactsCount',
                                label: l10n.isEn ? 'Artifacts' : 'Hiện vật',
                                icon: Icons.museum_rounded,
                                onTap: () => openPage(context, const MyMuseumScreen()),
                              ),
                              Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.15)),
                              _buildMetricItem(
                                value: '$_museumsCount',
                                label: l10n.isEn ? 'Museums' : 'Bảo tàng',
                                icon: Icons.explore_rounded,
                                onTap: () => openPage(context, const HistoryScreen()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Active Ticket Card (if today / upcoming pass exists)
            if (_activeTicketOrder != null) _buildActiveTicketCard(context, l10n),

            // 3. Wallet Card
            _buildWalletAndOrdersCard(context, l10n),

            // 4. Section: HOẠT ĐỘNG & TIỆN ÍCH
            const SizedBox(height: 22),
            _buildSectionLabel(l10n.isEn ? 'ACTIVITIES & UTILITIES' : 'HOẠT ĐỘNG & TIỆN ÍCH'),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.confirmation_number_outlined,
              title: l10n.isEn ? 'Tickets & Orders' : 'Vé & Đơn hàng của tôi',
              subtitle: l10n.isEn ? 'Purchased e-tickets & services' : 'Vé điện tử và các gói dịch vụ đã mua',
              onTap: () => openPage(context, const PurchasedServicesScreen()),
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.military_tech_outlined,
              title: l10n.isEn ? 'Heritage Badges' : 'Huy hiệu di sản',
              subtitle: l10n.isEn ? 'Titles & achievements unlocked' : 'Danh hiệu và thành tích khám phá',
              onTap: () => openPage(context, const BadgesScreen()),
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.quiz_outlined,
              title: l10n.isEn ? 'Daily Quiz Challenge' : 'Thử thách Quiz trong ngày',
              subtitle: l10n.isEn ? 'Museum trivia challenges to earn points' : 'Thử thách kiến thức bảo tàng nhận điểm',
              badgeText: _deferredQuizCount > 0
                  ? (l10n.isEn ? '$_deferredQuizCount pending' : '$_deferredQuizCount câu chờ')
                  : null,
              onTap: () => openPage(context, const DailyQuizScreen()),
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.emoji_events_outlined,
              title: l10n.isEn ? 'Challenge Results' : 'Kết quả & Lịch sử thử tài',
              subtitle: l10n.isEn ? 'Scores and quiz answer reviews' : 'Điểm số và câu trả lời các bộ câu hỏi',
              onTap: () => openPage(context, const ExperienceHistoryScreen(kind: 'quiz')),
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.isEn ? 'AI Heritage Conversations' : 'Lịch sử Trợ lý AI',
              subtitle: l10n.isEn ? 'Review questions asked across artifacts' : 'Xem lại các cuộc trò chuyện và câu hỏi di sản',
              onTap: () => openPage(context, const AiGuideHistoryScreen()),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: NotificationController.instance,
              builder: (context, _) {
                final unread = NotificationController.instance.unreadCount;
                return _buildMenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.notificationCenterTitle,
                  subtitle: l10n.isEn ? 'System updates and announcements' : 'Tin nhắn hệ thống và thông báo mới',
                  badgeText: unread > 0 ? (l10n.isEn ? '$unread new' : '$unread mới') : null,
                  onTap: () => openPage(context, const NotificationCenterScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.tune_rounded,
              title: l10n.isEn ? 'Settings & Support' : 'Cài đặt & Hỗ trợ',
              subtitle: l10n.isEn ? 'Language, refund policies & feedback' : 'Ngôn ngữ, chính sách hoàn tiền & góp ý',
              onTap: () => openPage(context, const SettingsAndSupportScreen()),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildMetricItem({
    required String value,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VisitorRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: AppColors.mutedGold.withValues(alpha: 0.9)),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.antiqueIvory,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.antiqueIvory.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTicketCard(BuildContext context, AppLocalizations l10n) {
    if (_activeTicketOrder == null) return const SizedBox.shrink();

    final museumName = _activeTicketOrder!['museumName']?.toString() ?? (l10n.isEn ? 'Museum Pass' : 'Vé Bảo tàng');
    final visitDate = _activeTicketOrder!['visitDate']?.toString() ?? '';
    final orderId = _activeTicketOrder!['id'].toString();
    final quantity = _activeTicketOrder!['quantity'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1810), Color(0xFF1E100B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(
          color: AppColors.mutedGold.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(VisitorRadius.xl),
          onTap: () => openPage(context, OrderDetailScreen(orderId: orderId)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.mutedGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_rounded,
                            color: AppColors.mutedGold,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.isEn ? 'TODAY\'S ADMISSION PASS' : 'VÉ VÀO CỔNG HÔM NAY',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.mutedGold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF81C784),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.isEn ? 'Ready' : 'Sẵn sàng',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.sansFamily,
                              color: Color(0xFFC8E6C9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  museumName,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.antiqueIvory,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.isEn
                      ? 'Visit date: $visitDate · $quantity guest(s)'
                      : 'Ngày tham quan: $visitDate · $quantity người',
                  style: TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 12.5,
                    color: AppColors.antiqueIvory.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mutedGold,
                      foregroundColor: AppColors.darkBrown,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VisitorRadius.md),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => openPage(context, OrderDetailScreen(orderId: orderId)),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: Text(
                      l10n.isEn ? 'Show Check-in QR Code' : 'Mở mã QR soát vé',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAndOrdersCard(BuildContext context, AppLocalizations l10n) {
    final formatted = _walletBalance > 0
        ? '${_walletBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ'
        : '0 đ';
    return InkWell(
      onTap: () => openPage(context, const PurchasedServicesScreen()),
      borderRadius: BorderRadius.circular(VisitorRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: VisitorColors.surface1,
          borderRadius: BorderRadius.circular(VisitorRadius.lg),
          border: Border.all(
            color: AppColors.mutedGold.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.deepBurgundy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.deepBurgundy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.isEn ? 'SMGS Wallet (Refunds)' : 'Ví điện tử hoàn tiền',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      color: AppColors.secondaryText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkBrown,
                      fontSize: 15.5,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                ),
                child: Text(
                  l10n.isEn ? 'Auto-deduct' : 'Cấn trừ khi mua',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    color: Color(0xFF2E7D32),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: AppTextStyles.sansFamily,
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: AppColors.secondaryText,
      ),
    ),
  );
}

Widget _buildMenuTile({
  required IconData icon,
  required String title,
  String? subtitle,
  String? badgeText,
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      color: VisitorColors.surface1,
      borderRadius: BorderRadius.circular(VisitorRadius.lg),
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(VisitorRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.antiqueIvory,
                  borderRadius: BorderRadius.circular(VisitorRadius.sm),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: AppColors.deepBurgundy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SettingsAndSupportScreen extends StatelessWidget {
  const SettingsAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppPreferences.instance,
      builder: (context, _) {
        final l10n = context.l10n;
        final prefs = AppPreferences.instance;
        return MuseumPage(
          back: true,
          title: l10n.isEn ? 'Settings & Support' : 'Cài đặt & hỗ trợ',
          children: [
            _buildSectionLabel(l10n.isEn ? 'PREFERENCES' : 'TÙY CHỈNH'),
            const SizedBox(height: 8),
            // Ngôn ngữ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.antiqueIvory,
                      borderRadius: BorderRadius.circular(VisitorRadius.sm),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.8),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.language_rounded, size: 20, color: AppColors.deepBurgundy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sectionLanguage,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.isEn ? 'Interface & content display' : 'Giao diện & nội dung hiển thị',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildLanguageToggle(prefs),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Cài đặt trải nghiệm
            _buildMenuTile(
              icon: Icons.tune_rounded,
              title: l10n.isEn ? 'Experience Settings' : 'Cài đặt trải nghiệm',
              subtitle: l10n.isEn ? 'Font size, animations & display' : 'Cỡ chữ, chuyển động & hiển thị',
              onTap: () => openPage(context, const SettingsScreen()),
            ),

            const SizedBox(height: 22),
            _buildSectionLabel(l10n.isEn ? 'SUPPORT' : 'HỖ TRỢ'),
            const SizedBox(height: 8),
            // Cẩm nang & quy định
            _buildMenuTile(
              icon: Icons.menu_book_rounded,
              title: l10n.isEn ? 'Handbook & Regulations' : 'Cẩm nang & quy định',
              subtitle: l10n.isEn ? 'Visitor guidelines & museum etiquette' : 'Sổ tay hướng dẫn & nội quy tham quan',
              onTap: () => VisitorHandbookSheet.show(context),
            ),
            const SizedBox(height: 8),
            // Hỗ trợ & hoàn tiền
            _buildMenuTile(
              icon: Icons.support_agent_rounded,
              title: l10n.isEn ? 'Help & Refunds' : 'Hỗ trợ & hoàn tiền',
              subtitle: l10n.isEn ? 'Request assistance & report issues' : 'Gửi yêu cầu trợ giúp & xử lý sự cố',
              onTap: () => openPage(context, const SupportRefundScreen()),
            ),
            const SizedBox(height: 8),
            // Góp ý trải nghiệm
            _buildMenuTile(
              icon: Icons.rate_review_outlined,
              title: l10n.isEn ? 'Visitor Feedback' : 'Góp ý trải nghiệm',
              subtitle: l10n.isEn ? 'Share suggestions to improve services' : 'Đóng góp ý kiến cải thiện dịch vụ',
              onTap: () => openPage(context, const FeedbackScreen()),
            ),

            const SizedBox(height: 24),
            // Nút Đăng xuất
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                VisitStore.instance.reset();
                AppServices.auth.logout();
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 18, color: AppColors.deepBurgundy),
                  const SizedBox(width: 8),
                  Text(
                    l10n.logoutButton,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Mục đã lưu, hiện vật vừa mở và kết quả thử tài mẫu chỉ giữ trong phiên. Lượt tham quan, đơn hàng, điểm và huy hiệu được tải từ hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 12,
                height: 1.45,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'SMGS · Cẩm nang bảo tàng Việt',
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildLanguageToggle(AppPreferences prefs) {
    final isVi = prefs.language == 'vi';
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangButton('Việt', isVi, () => prefs.setLanguage('vi')),
          _buildLangButton('EN', !isVi, () => prefs.setLanguage('en')),
        ],
      ),
    );
  }

  Widget _buildLangButton(String text, bool active, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: active ? AppColors.deepBurgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTextStyles.sansFamily,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? AppColors.antiqueIvory : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
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
          : AppServices.catalog.artifacts
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
    this.existingFeedback,
  });
  final String targetType, targetId, targetName;
  final Map<String, dynamic>? existingFeedback;
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late String? _rating = widget.existingFeedback == null
      ? null
      : [
          'Rất hài lòng',
          'Hài lòng',
          'Bình thường',
          'Chưa hài lòng',
          'Rất không hài lòng',
        ][5 - (widget.existingFeedback!['overallRating'] as int)];
  bool _submitted = false, _sending = false;
  late final _comment = TextEditingController(
    text: widget.existingFeedback?['comment'] as String? ?? '',
  );
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
        ? 'Góp ý đã được máy chủ ghi nhận.'
        : widget.targetName,
    children: _submitted
        ? [
            const Panel(
              child: Notice(
                'Bạn có thể theo dõi kết quả xử lý trong hệ thống.',
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
                  onPressed: widget.existingFeedback?['canEdit'] == false
                      ? null
                      : () => setState(() => _rating = r),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              readOnly: widget.existingFeedback?['canEdit'] == false,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn của bạn (không bắt buộc)',
                hintText: 'Chia sẻ điều bạn muốn cải thiện…',
              ),
            ),
            const SizedBox(height: 20),
            const Notice(
              'Đánh giá bảo tàng cần gắn với lượt tham quan đã hoàn thành. Góp ý chung sẽ được gửi đến bộ phận hỗ trợ.',
            ),
            const SizedBox(height: 20),
            if (widget.existingFeedback?['canEdit'] == false)
              const Notice('Đánh giá này đã hết thời hạn chỉnh sửa.'),
            if (widget.existingFeedback?['staffResponse'] != null)
              Notice(
                'Phản hồi bảo tàng: ${widget.existingFeedback!['staffResponse']['content']}',
              ),
            PrimaryButton(
              label: 'Ghi nhận góp ý',
              onPressed:
                  _rating == null ||
                      _sending ||
                      widget.existingFeedback?['canEdit'] == false
                  ? null
                  : () async {
                      setState(() => _sending = true);
                      try {
                        if (widget.targetType == 'visit' &&
                            int.tryParse(widget.targetId) != null) {
                          await BackendApi.request(
                            widget.existingFeedback == null
                                ? 'feedbacks'
                                : "feedbacks/${widget.existingFeedback!['id']}",
                            method: widget.existingFeedback == null
                                ? 'POST'
                                : 'PUT',
                            body: {
                              'visitId': int.parse(widget.targetId),
                              if (widget.existingFeedback != null) ...{
                                'contentRating':
                                    widget.existingFeedback!['contentRating'],
                                'tourRating':
                                    widget.existingFeedback!['tourRating'],
                                'chatbotRating':
                                    widget.existingFeedback!['chatbotRating'],
                              },
                              'overallRating':
                                  5 -
                                  [
                                    'Rất hài lòng',
                                    'Hài lòng',
                                    'Bình thường',
                                    'Chưa hài lòng',
                                    'Rất không hài lòng',
                                  ].indexOf(_rating!),
                              'comment': _comment.text.trim(),
                            },
                          );
                        } else {
                          await BackendApi.request(
                            'complaints',
                            method: 'POST',
                            body: {
                              'subject': 'Góp ý: ${widget.targetName}',
                              'body': '$_rating. ${_comment.text.trim()}',
                            },
                          );
                        }
                        if (mounted) setState(() => _submitted = true);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      } finally {
                        if (mounted) setState(() => _sending = false);
                      }
                    },
            ),
          ],
  );
}

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late Future<List<dynamic>> _data = _load();
  Future<List<dynamic>> _load() => Future.wait([
    BackendApi.request('gamification/me/points'),
    BackendApi.request('gamification/me/badges'),
    BackendApi.request('gamification/badges'),
  ]);
  @override
  Widget build(BuildContext context) => MuseumPage(
    back: true,
    title: 'Dấu ấn của bạn',
    eyebrow: 'Huy hiệu di sản',
    subtitle: 'Thành tựu và danh hiệu đạt được qua các chuyến khám phá.',
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'BẢNG THÀNH TÍCH',
              style: TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => setState(() => _data = _load()),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tải lại', style: TextStyle(fontSize: 12.5)),
            style: TextButton.styleFrom(foregroundColor: AppColors.deepBurgundy),
          ),
        ],
      ),
      const SizedBox(height: 6),
      FutureBuilder<List<dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) return Notice(snapshot.error.toString());
          final pointsData = snapshot.data![0];
          final points = pointsData is Map ? (pointsData['points'] ?? 0) : 0;
          final badges = snapshot.data![1] as List;
          final definitions = snapshot.data![2] as List;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Points Card
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.deepBurgundy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.mutedGold.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepBurgundy.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.mutedGold.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.mutedGold,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TỔNG ĐIỂM TÍCH LŨY',
                            style: TextStyle(
                              fontFamily: AppTextStyles.sansFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.mutedGold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$points điểm',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.serifFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.antiqueIvory,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${badges.length} huy hiệu đã mở khóa',
                            style: TextStyle(
                              fontFamily: AppTextStyles.sansFamily,
                              fontSize: 12,
                              color: AppColors.antiqueIvory.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'HUY HIỆU ĐƯỢC CẤP',
                style: TextStyle(
                  fontFamily: AppTextStyles.sansFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 10),
              if (badges.isEmpty)
                const EmptyState(
                  title: 'Chưa có huy hiệu nào',
                  message:
                      'Hoàn thành các câu đố quiz và quét hiện vật tại bảo tàng để nhận các danh hiệu di sản danh dự.',
                  icon: Icons.workspace_premium_outlined,
                )
              else
                for (final badge in badges) ...[
                  _buildBadgeCard(badge, definitions),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    ],
  );

  Widget _buildBadgeCard(dynamic badge, List definitions) {
    final def = definitions
        .where((d) => d['id'] == badge['badgeId'])
        .firstOrNull;
    final name = def?['name']?.toString() ??
        badge['name']?.toString() ??
        'Huy hiệu #${badge['badgeId']}';
    final desc = def?['description']?.toString() ??
        badge['description']?.toString() ??
        'Đạt được từ hoạt động tương tác bảo tàng';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.mutedGold.withValues(alpha: 0.25),
                    AppColors.deepBurgundy.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.mutedGold.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.stars_rounded,
                  color: AppColors.deepBurgundy,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.antiqueIvory,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Đã đạt',
                style: TextStyle(
                  fontFamily: AppTextStyles.sansFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBurgundy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppPreferences.instance,
    builder: (context, _) {
      final l10n = context.l10n;
      return MuseumPage(
        back: true,
        title: l10n.isEn ? 'Tailored for You' : 'Vừa vặn với bạn',
        eyebrow: l10n.isEn ? 'Experience Settings' : 'Cài đặt trải nghiệm',
        subtitle: l10n.isEn
            ? 'Customize font size, animations and display options.'
            : 'Tùy chỉnh cỡ chữ, chuyển động và cách hiển thị nội dung theo nhu cầu cá nhân.',
        children: [
          _buildSectionLabel(l10n.isEn ? 'DISPLAY & TEXT' : 'HIỂN THỊ & VĂN BẢN'),
          const SizedBox(height: 8),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VisitorRadius.xl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    activeColor: AppColors.deepBurgundy,
                    activeTrackColor: AppColors.mutedGold.withValues(alpha: 0.4),
                    title: Text(
                      l10n.prefLargeText,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    subtitle: Text(
                      l10n.isEn
                          ? 'Increase font size for easier reading of descriptions.'
                          : 'Tăng kích thước phông chữ để đọc thuyết minh dễ dàng hơn.',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    value: AppPreferences.instance.largeText,
                    onChanged: AppPreferences.instance.setLargeText,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueIvory,
                        borderRadius: BorderRadius.circular(VisitorRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isEn ? 'PREVIEW TEXT' : 'VĂN BẢN XEM TRƯỚC',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.sansFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.mutedGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.isEn
                                ? 'Dong Son bronze drums are iconic artifacts of Dong Son bronze culture, with intricate motifs depicting ancient life.'
                                : 'Trống đồng Đông Sơn là hiện vật tiêu biểu của nền văn hóa Đông Sơn thời kỳ đồ đồng, mang hoa văn tinh xảo miêu tả đời sống cư dân cổ.',
                            style: TextStyle(
                              fontFamily: AppTextStyles.serifFamily,
                              fontSize: AppPreferences.instance.largeText
                                  ? 15.5
                                  : 13.0,
                              height: 1.45,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),
          _buildSectionLabel(l10n.isEn ? 'EFFECTS & ANIMATIONS' : 'HIỆU ỨNG & CHUYỂN ĐỘNG'),
          const SizedBox(height: 8),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(VisitorRadius.xl),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VisitorRadius.xl),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                activeColor: AppColors.deepBurgundy,
                activeTrackColor: AppColors.mutedGold.withValues(alpha: 0.4),
                title: Text(
                  l10n.prefReducedMotion,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
                subtitle: Text(
                  l10n.isEn
                      ? 'Disable page transitions and image movements for smoother navigation.'
                      : 'Tắt hiệu ứng chuyển trang, hiện dần và dịch chuyển ảnh để xem mượt mà hơn.',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                value: AppPreferences.instance.reducedMotion,
                onChanged: AppPreferences.instance.setReducedMotion,
              ),
            ),
          ),

          const SizedBox(height: 20),
          Notice(
            l10n.isEn
                ? 'These experience settings apply immediately and are saved on your device.'
                : 'Cài đặt trải nghiệm này áp dụng tức thì và được lưu lại trên thiết bị.',
          ),
        ],
      );
    },
  );
}

Future<void> openVisitFeedback(
  BuildContext context,
  Map<String, dynamic> visit,
) async {
  try {
    final feedback = visit['hasFeedback'] == true
        ? Map<String, dynamic>.from(
            await BackendApi.request('feedbacks/visit/${visit['id']}'),
          )
        : null;
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FeedbackScreen(
            targetType: 'visit',
            targetId: visit['id'].toString(),
            targetName: AppServices.catalog.museumName(
              visit['museumId'].toString(),
            ),
            existingFeedback: feedback,
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
