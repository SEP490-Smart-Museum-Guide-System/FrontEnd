import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../data/mock/mock_museums.dart';
import '../../data/mock/mock_artifacts.dart';
import '../../data/visit_store.dart';
import '../explore/explore_screen.dart';
import '../artifact/artifact_detail_screen.dart';
import 'home_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onExplore, required this.onScan});
  final VoidCallback onExplore, onScan;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  String get _date {
    final now = DateTime.now();
    final day = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ][now.weekday - 1];
    return '$day, ${now.day} tháng ${now.month}';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      key: const PageStorageKey('home-stories'),
      controller: _scroll,
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          backgroundColor: AppColors.antiqueIvory,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleSpacing: 22,
          title: AnimatedBuilder(
            animation: _scroll,
            builder: (context, _) {
              final offset = _scroll.hasClients ? _scroll.offset : 0.0;
              return Row(
                children: [
                  Text(
                    'SMGS',
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 23,
                      color: AppColors.deepBurgundy,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(width: 1, height: 30, color: AppColors.border),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      offset > 220
                          ? 'Theo dấu\ndi sản Việt'
                          : 'Cẩm nang\nbảo tàng Việt',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  Transform.rotate(
                    angle: reduceHeritageMotion(context) ? 0 : offset / 700,
                    child: const HeritageSeal(size: 38),
                  ),
                ],
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) => LinearProgressIndicator(
                key: const ValueKey('home-reading-progress'),
                value:
                    _scroll.hasClients &&
                        _scroll.position.hasContentDimensions &&
                        _scroll.position.maxScrollExtent > 0
                    ? (_scroll.offset / _scroll.position.maxScrollExtent).clamp(
                        0.0,
                        1.0,
                      )
                    : 0,
                minHeight: 2,
                color: AppColors.deepBurgundy,
                backgroundColor: AppColors.border,
                semanticsLabel: 'Tiến độ khám phá trang chủ',
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _date.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.deepBurgundy,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 19,
                      color: AppColors.mutedGold,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Chạm vào\nmiền ký ức.',
                  style: AppTextStyles.display.copyWith(
                    fontSize: 38,
                    height: 1.2,
                    color: AppColors.deepBurgundy,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mỗi hiện vật, một câu chuyện đang chờ bạn.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => openPage(
                    context,
                    ExploreScreen(
                      standalone: true,
                      initialQuery: value,
                      initialArtifacts: value.trim().isNotEmpty,
                    ),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm di sản',
                    hintText: 'Tìm bảo tàng, hiện vật…',
                    prefixIcon: const Icon(
                      Icons.search_outlined,
                      color: AppColors.deepBurgundy,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Tìm kiếm',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => openPage(
                        context,
                        ExploreScreen(
                          standalone: true,
                          initialQuery: _search.text,
                          initialArtifacts: _search.text.trim().isNotEmpty,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: AppColors.deepBurgundy,
                  borderRadius: BorderRadius.circular(5),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onScan,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.mutedGold),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: AppColors.antiqueIvory,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Giải mã một hiện vật',
                                  style: AppTextStyles.sectionTitle.copyWith(
                                    fontSize: 18,
                                    color: AppColors.antiqueIvory,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quét mã · Mở câu chuyện',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.antiqueIvory,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: AppColors.antiqueIvory,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cuộn tiếp, mở một miền ký ức',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    Icon(Icons.south, size: 19, color: AppColors.deepBurgundy),
                  ],
                ),
                ChapterHeading(
                  number: '01',
                  title: 'Hẹn bạn ở bảo tàng',
                  action: 'Tất cả',
                  onTap: widget.onExplore,
                ),
                ScrollReveal(
                  child: MuseumCard(museum: mockMuseums.first, featured: true),
                ),
                const ChapterHeading(number: '02', title: 'Hiện vật kể chuyện'),
                ScrollReveal(
                  child: _ArtifactEditorial(
                    onTap: () => openPage(
                      context,
                      ArtifactDetailScreen(
                        artifact: mockArtifacts.first,
                        museumName: mockMuseums.first.name,
                      ),
                    ),
                  ),
                ),
                const ChapterHeading(number: '03', title: 'Đi theo sự tò mò'),
                const Text(
                  'Chọn một cánh cửa để bước vào lịch sử.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                const HomeThemes(),
                const ChapterHeading(number: '04', title: 'Một giờ cho di sản'),
                const ScrollReveal(child: HomeRouteCard()),
                const ChapterHeading(number: '05', title: 'Một điểm hẹn khác'),
                const ScrollReveal(child: HomeMuseumStory()),
                const ChapterHeading(
                  number: '06',
                  title: 'Bạn hiểu di sản đến đâu?',
                ),
                const ScrollReveal(child: HomeQuizCard()),
                const ChapterHeading(
                  number: '07',
                  title: 'Trước khi lên đường',
                ),
                const ScrollReveal(child: HomeVisitGuide()),
                ListenableBuilder(
                  listenable: VisitStore.instance,
                  builder: (context, _) => VisitStore.instance.viewed.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ChapterHeading(
                              number: '08',
                              title: 'Trang sách còn mở',
                            ),
                            ScrollReveal(
                              child: ArtifactCard(
                                artifact: VisitStore.instance.viewed.first,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 28),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: HeritageSeal(size: 34),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đi để hiểu. Chạm để nhớ.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gìn giữ ký ức · Kết nối di sản',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    if (reduceHeritageMotion(context)) {
                      _scroll.jumpTo(0);
                    } else {
                      _scroll.animateTo(
                        0,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  icon: const Icon(Icons.north, size: 18),
                  label: const Text('Về đầu trang'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArtifactEditorial extends StatelessWidget {
  const _ArtifactEditorial({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ParallaxPhoto(
                height: 235,
                child: Image.asset(
                  'assets/images/ngoc-lu-web.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: 'Trống đồng Ngọc Lũ, văn hóa Đông Sơn',
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: AppColors.antiqueIvory,
                  child: const Eyebrow('Dấu ấn Đông Sơn'),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiếng vọng\ntừ ngàn xưa.',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Lần theo những vòng hoa văn, gặp lại một nền văn minh.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Khám phá trống đồng',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.deepBurgundy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.deepBurgundy,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
