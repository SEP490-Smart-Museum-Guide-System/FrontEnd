import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_config.dart';
import '../../models/experience.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import '../../widgets/game_tutorial_overlay.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/visitor_handbook_sheet.dart';

typedef HomeSlide = ({String imageUrl, String caption, String title});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<({String title, List<HomeSlide> slides})?> _home = _load();

  Future<({String title, List<HomeSlide> slides})?> _load() async {
    try {
      final data = await BackendApi.request('visitor-home');
      if (data is! Map<String, dynamic> ||
          data['title'] is! String ||
          data['slides'] is! List) {
        return null;
      }
      return (
        title: data['title'] as String,
        slides: (data['slides'] as List)
            .cast<Map<String, dynamic>>()
            .map(
              (slide) => (
                imageUrl:
                    '${ApiConfig.baseUrl}/visitor-home/images/${Uri.encodeComponent(slide['name'] as String)}',
                caption: slide['caption'] as String,
                title: (slide['title'] as String?) ?? '',
              ),
            )
            .toList(),
      );
    } on Exception {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = AppServices.auth.user;
      if (user != null && user.role != UserRole.visitor) return;
      final show = await GameTutorialOverlay.shouldShow(user?.email ?? 'guest');
      if (show && mounted) HomeScreenTour.start(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final museum = AppServices.catalog.museums.firstOrNull;
    final isEn = context.l10n.isEn;
    return FutureBuilder(
      future: _home,
      builder: (context, snapshot) {
        final home = snapshot.data;
        return VisitorHomeCarousel(
          title: home != null && home.title.isNotEmpty
              ? home.title
              : museum?.name ?? (isEn ? 'Museum Guide' : 'Khám phá bảo tàng'),
          slides: home != null && home.slides.isNotEmpty
              ? home.slides
              : [
                  (
                    imageUrl: ApiConfig.mediaUrl(museum?.imageUrl),
                    caption: '',
                    title: '',
                  ),
                ],
          loading: snapshot.connectionState != ConnectionState.done,
          exploreLabel: isEn ? 'Explore more' : 'Khám phá thêm',
          onExplore: widget.onExplore,
          actions: [
            const NotificationBellButton(color: Colors.white),
            IconButton(
              key: HomeScreenTour.handbookBtnKey,
              tooltip: isEn ? 'Handbook' : 'Cẩm nang tham quan',
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => VisitorHandbookSheet.show(context),
            ),
          ],
        );
      },
    );
  }
}

class VisitorHomeCarousel extends StatefulWidget {
  const VisitorHomeCarousel({
    super.key,
    required this.title,
    required this.slides,
    required this.exploreLabel,
    required this.onExplore,
    this.actions = const [],
    this.loading = false,
  }) : assert(slides.length > 0);

  final String title;
  final List<HomeSlide> slides;
  final String exploreLabel;
  final VoidCallback onExplore;
  final List<Widget> actions;
  final bool loading;

  @override
  State<VisitorHomeCarousel> createState() => _VisitorHomeCarouselState();
}

class _VisitorHomeCarouselState extends State<VisitorHomeCarousel> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    final index = _index.clamp(0, slides.length - 1);
    final slide = slides[index];
    final caption = slide.caption;
    final insets = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xff191615)),
        if (!widget.loading)
          PageView.builder(
            controller: _pages,
            allowImplicitScrolling: true,
            itemCount: slides.length,
            onPageChanged: (page) => setState(() => _index = page),
            itemBuilder: (context, page) {
              final url = slides[page].imageUrl;
              return url.isEmpty
                  ? _fallback()
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => _fallback(),
                    );
            },
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xf5000000),
                  Color(0xb8000000),
                  Colors.transparent,
                ],
                stops: [0, .28, .76],
              ),
            ),
          ),
        ),
        Positioned(
          top: insets.top + 12,
          right: insets.right + 12,
          child: Row(
            children: [
              for (final action in widget.actions)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Material(
                    color: const Color(0x80000000),
                    shape: const CircleBorder(),
                    child: IconButtonTheme(
                      data: IconButtonThemeData(
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      child: action,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: insets.left + 24,
          right: insets.right + 24,
          bottom: insets.bottom + (slides.length > 1 ? 52 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title.isEmpty ? widget.title : slide.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.display.copyWith(
                  fontFamily: AppTextStyles.sansFamily,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.1,
                ),
              ),
              if (caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton.icon(
                key: HomeScreenTour.museumSectionKey,
                onPressed: widget.onExplore,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: const Size(0, 48),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(widget.exploreLabel),
              ),
            ],
          ),
        ),
        if (slides.length > 1)
          Positioned(
            left: insets.left + 14,
            bottom: insets.bottom + 4,
            child: Row(
              children: [
                for (var page = 0; page < slides.length; page++)
                  Semantics(
                    selected: page == index,
                    child: IconButton(
                      tooltip: context.l10n.isEn
                          ? 'Photo ${page + 1}'
                          : 'Ảnh ${page + 1}',
                      onPressed: () => _pages.jumpToPage(page),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 26,
                        height: 44,
                      ),
                      icon: Container(
                        width: page == index ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: page == index ? Colors.white : Colors.white60,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _fallback() => Image.asset(
    'assets/images/national-museum-web.jpg',
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xff302623)),
  );
}
