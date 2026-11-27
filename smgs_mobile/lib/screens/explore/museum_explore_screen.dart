import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/museum.dart';
import '../../services/automatic_location_service.dart';
import '../../services/discovery_api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/collection_cards.dart';
import '../../widgets/heritage_shimmer.dart';
import '../../widgets/museum_ui.dart';
import 'museum_discovery_map_screen.dart';

class MuseumExploreScreen extends StatefulWidget {
  const MuseumExploreScreen({super.key});

  @override
  State<MuseumExploreScreen> createState() => _MuseumExploreScreenState();
}

class _MuseumExploreScreenState extends State<MuseumExploreScreen>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  Timer? _debounce;
  List<MuseumCategory>? _categories;
  List<Museum> _museums = [];
  MuseumCategory? _selected;
  UserLocationResult? _location;
  String? _sort;
  bool _expanded = false,
      _loading = true,
      _listFailed = false,
      _categoriesFailed = false;
  int _generation = 0, _page = 0, _pages = 0, _total = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCategories());
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DiscoveryApiService.fetchMuseumCategories();
      if (!mounted) return;
      final previous = _selected;
      final selected = categories
          .where((item) => item.id == previous?.id)
          .firstOrNull;
      setState(() {
        _categories = categories;
        _categoriesFailed = false;
        _selected = selected;
      });
      if (previous != null && selected == null) await _load();
    } catch (_) {
      if (mounted) setState(() => _categoriesFailed = true);
    }
  }

  Future<void> _load({bool append = false}) async {
    _debounce?.cancel();
    final generation = ++_generation;
    final page = append ? _page + 1 : 1;
    setState(() {
      if (!append) {
        _museums = [];
        _page = _pages = _total = 0;
      }
      _loading = true;
      _listFailed = false;
    });
    try {
      final results = await DiscoveryApiService.fetchMuseumPage(
        keyword: _search.text,
        categoryId: _selected?.id,
        sortBy: _sort ?? 'default',
        latitude: _location?.latitude,
        longitude: _location?.longitude,
        page: page,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _museums = [..._museums, ...results.items];
        _page = results.page;
        _pages = results.totalPages;
        _total = results.totalCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _listFailed = true;
      });
    }
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _generation++;
    setState(() {
      _museums = [];
      _loading = true;
      _listFailed = false;
    });
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_load()),
    );
  }

  Future<void> _showSort(bool en) async {
    final options = <(String, String)>[
      ('default', en ? 'Default' : 'Mặc định'),
      ('newest', en ? 'Newest' : 'Mới nhất'),
      ('name', en ? 'Name A–Z' : 'Tên A–Z'),
      ('distance', en ? 'Nearest to me' : 'Gần tôi nhất'),
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, label) in options)
              ListTile(
                title: Text(label),
                trailing: key == (_sort ?? 'default')
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, key),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    UserLocationResult? origin;
    if (selected == 'distance') {
      try {
        final gps = AutomaticLocationService.instance;
        origin = gps.hasFreshLocation
            ? gps.latest
            : await LocationService.getCurrentUserLocation();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                en
                    ? 'Location is unavailable.'
                    : 'Chưa lấy được vị trí của bạn.',
              ),
            ),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    _sort = selected == 'default' ? null : selected;
    _location = origin;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final en = context.l10n.isEn;
    final cards = _expanded ? _categories : _categories?.take(4).toList();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return ColoredBox(
      color: VisitorColors.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _loadCategories();
                if (mounted) await _load();
              },
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    sliver: SliverList.list(
                      children: [
                        TextField(
                          controller: _search,
                          onChanged: _searchChanged,
                          decoration: InputDecoration(
                            hintText: en
                                ? 'Search museums…'
                                : 'Tìm kiếm bảo tàng...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: en
                                        ? 'Clear search'
                                        : 'Xóa từ khóa',
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _search.clear();
                                      unawaited(_load());
                                    },
                                  ),
                            isDense: true,
                            filled: true,
                            fillColor: VisitorColors.surface2,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          en
                              ? 'Explore Vietnamese heritage'
                              : 'Khám phá kho tàng di sản Việt Nam',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.sansFamily,
                            fontWeight: FontWeight.w800,
                            color: VisitorColors.text,
                            fontSize: 36,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_categoriesFailed)
                          TextButton(
                            onPressed: _loadCategories,
                            child: Text(
                              en
                                  ? 'Retry loading categories'
                                  : 'Thử tải lại danh mục',
                            ),
                          )
                        else
                          AnimatedSize(
                            duration: reduceHeritageMotion(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            alignment: Alignment.topCenter,
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 82,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: cards?.length ?? 4,
                              itemBuilder: (context, index) {
                                if (cards == null) {
                                  return const HeritageShimmer(
                                    width: double.infinity,
                                    height: 82,
                                    borderRadius: 14,
                                  );
                                }
                                final category = cards[index];
                                return _CategoryCard(
                                  category: category,
                                  selected: _selected?.id == category.id,
                                  onTap: () {
                                    _selected = _selected?.id == category.id
                                        ? null
                                        : category;
                                    unawaited(_load());
                                  },
                                );
                              },
                            ),
                          ),
                        if ((_categories?.length ?? 0) > 4)
                          Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                              iconAlignment: IconAlignment.end,
                              icon: Icon(
                                _expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              label: Text(
                                _expanded
                                    ? (en ? 'Show less' : 'Thu gọn')
                                    : (en
                                          ? 'More categories'
                                          : 'Xem thêm danh mục'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selected?.name ??
                                    (en ? 'All museums' : 'Tất cả bảo tàng'),
                                style: AppTextStyles.sectionTitle,
                              ),
                            ),
                            IconButton(
                              tooltip: en ? 'Sort museums' : 'Sắp xếp bảo tàng',
                              onPressed: () => _showSort(en),
                              icon: const Icon(Icons.tune),
                            ),
                          ],
                        ),
                        if (_selected != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                _selected = null;
                                unawaited(_load());
                              },
                              child: Text(en ? 'Clear filter' : 'Xóa bộ lọc'),
                            ),
                          ),
                        if (!_loading &&
                            !_listFailed &&
                            (_selected != null ||
                                _search.text.trim().isNotEmpty))
                          Text(
                            en
                                ? '$_total museums found'
                                : '$_total bảo tàng được tìm thấy',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, keyboard ? 20 : 88),
                    sliver: SliverList.builder(
                      itemCount: _museums.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _museums.length) {
                          final museum = _museums[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: MuseumCard(
                              key: ValueKey(museum.id),
                              museum: museum,
                              compact: true,
                            ),
                          );
                        }
                        if (_loading) return const HeritageMuseumCardSkeleton();
                        if (_listFailed) {
                          return Column(
                            children: [
                              Text(
                                en
                                    ? 'Could not load museums.'
                                    : 'Chưa tải được danh sách bảo tàng.',
                              ),
                              TextButton(
                                onPressed: () => _load(append: _page > 0),
                                child: Text(en ? 'Retry' : 'Thử lại'),
                              ),
                            ],
                          );
                        }
                        if (_museums.isEmpty) {
                          return Text(
                            _selected != null && _search.text.trim().isEmpty
                                ? (en
                                      ? 'No museums in this category yet.'
                                      : 'Chưa có bảo tàng thuộc danh mục này.')
                                : (en
                                      ? 'No matching museums found.'
                                      : 'Không tìm thấy bảo tàng phù hợp.'),
                          );
                        }
                        if (_page < _pages) {
                          return Center(
                            child: OutlinedButton(
                              onPressed: () => _load(append: true),
                              child: Text(
                                en ? 'Load more museums' : 'Xem thêm bảo tàng',
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!keyboard)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    elevation: 2,
                    backgroundColor: AppColors.mutedGold,
                    foregroundColor: AppColors.darkBrown,
                    onPressed: () => openPage(
                      context,
                      MuseumDiscoveryMapScreen(
                        categoryId: _selected?.id,
                        keyword: _search.text.trim(),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(en ? 'Map' : 'Bản đồ'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  static const assets = {
    'history': 'assets/images/ngoc-lu-web.jpg',
    'culture': 'assets/images/van-hoa.jfif',
    'art': 'assets/images/my-thuat-nghe-thuat.jfif',
    'military': 'assets/images/quan-su.jfif',
    'ethnology': 'assets/images/dan-toc-hoc.jfif',
    'archaeology': 'assets/images/khao-co-hoc.jfif',
    'memorial': 'assets/images/danh-nhan.jfif',
    'science': 'assets/images/khoa-hoc-cong-nghe.jfif',
    'nature': 'assets/images/thien-nhien-dia-chat.jfif',
    'specialized': 'assets/images/chuyen-nganh.jfif',
    'other': 'assets/images/khac.jfif',
  };

  final MuseumCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = assets[category.code];
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: VisitorColors.burgundy,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null) ...[
              Image.asset(
                image,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              const ColoredBox(color: Color(0x73000000)),
            ],
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 5,
                right: 7,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                  semanticLabel: null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
