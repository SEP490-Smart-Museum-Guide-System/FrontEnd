import 'package:flutter/material.dart';
import '../../core/network/api_config.dart';
import '../../models/artifact.dart';
import '../../services/backend_api.dart';
import '../../services/discovery_api_service.dart';
import '../../services/token_manager.dart';
import '../artifact/artifact_detail_screen.dart';
import '../scan/scan_screen.dart';

class MyMuseumScreen extends StatefulWidget {
  const MyMuseumScreen({super.key});
  @override
  State<MyMuseumScreen> createState() => _MyMuseumScreenState();
}

class _MyMuseumScreenState extends State<MyMuseumScreen> {
  final _pages = PageController();
  final Map<int, Future<Map<String, dynamic>>> _shelves = {};
  int? _museumId;
  int _page = 0, _generation = 0;
  bool _opening = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load(
    int page,
  ) => _shelves.putIfAbsent(page, () async {
    final data = await BackendApi.request(
      'recognitions/collection?page=${page + 1}&pageSize=4${_museumId == null ? '' : '&museumId=$_museumId'}',
    );
    return Map<String, dynamic>.from(data);
  });

  void _filter(int? museum) {
    setState(() {
      _museumId = museum;
      _page = 0;
      _generation++;
      _shelves.clear();
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  Future<void> _open(Map<String, dynamic> item) async {
    if (_opening || item['available'] != true) return;
    setState(() => _opening = true);
    try {
      final data = await DiscoveryApiService.fetchArtifactDetail(
        item['artifactId'],
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArtifactDetailScreen(
            artifact: Artifact.fromBackendJson(data),
            museumName: item['museumName'] as String,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff211710),
    appBar: AppBar(
      centerTitle: true,
      toolbarHeight: 48,
      title: const Text(
        'Bảo tàng của tôi',
        style: TextStyle(
          color: Color(0xffffe6ba),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xff211710),
      surfaceTintColor: Colors.transparent,
      foregroundColor: const Color(0xffffe6ba),
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Bộ sưu tập những hiện vật bạn đã khám phá',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xffe4cfb0)),
            ),
          ),
          if (!TokenManager.hasToken)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Vui lòng đăng nhập để xem bộ sưu tập.',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                key: ValueKey(_generation),
                future: _load(0),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _error(() => _filter(_museumId));
                  }
                  if (!snapshot.hasData) {
                    return const _Shelf(items: [], loading: true);
                  }
                  final museums = (snapshot.data!['museums'] as List)
                      .cast<Map<String, dynamic>>();
                  final count = snapshot.data!['totalCollected'] as int;
                  final pageCount = snapshot.data!['totalPages'] as int;
                  return Column(
                    children: [
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: [
                          _stat(Icons.inventory_2_outlined, count, 'hiện vật'),
                          _stat(
                            Icons.museum_outlined,
                            museums.length,
                            'bảo tàng',
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: DropdownButtonFormField<int>(
                          key: ValueKey(_museumId),
                          initialValue: _museumId,
                          isExpanded: true,
                          dropdownColor: const Color(0xff38271b),
                          iconEnabledColor: const Color(0xffffe6ba),
                          style: const TextStyle(color: Color(0xffffe6ba)),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xff38271b),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              borderSide: BorderSide(color: Color(0xffab8756)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xffffd087),
                                width: 2,
                              ),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Tất cả bảo tàng'),
                            ),
                            ...museums.map(
                              (m) => DropdownMenuItem(
                                value: m['id'] as int,
                                child: Text(
                                  m['name'] as String,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: _filter,
                        ),
                      ),
                      if (_opening) const LinearProgressIndicator(),
                      Expanded(
                        child: pageCount == 0
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 230,
                                      child: _Shelf(items: []),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Chưa có hiện vật nào trong bộ sưu tập',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xffffe6ba),
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        'Hãy quét mã QR khi tham quan để xây dựng bảo tàng của riêng bạn!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xffe4cfb0),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const Scaffold(
                                              body: SafeArea(
                                                child: ScanScreen(),
                                              ),
                                            ),
                                          ),
                                        );
                                        if (mounted) _filter(_museumId);
                                      },
                                      child: const Text(
                                        'Khám phá hiện vật',
                                        style: TextStyle(
                                          color: Color(0xffffd087),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : PageView.builder(
                                controller: _pages,
                                itemCount: pageCount,
                                onPageChanged: (value) =>
                                    setState(() => _page = value),
                                itemBuilder: (context, page) =>
                                    FutureBuilder<Map<String, dynamic>>(
                                      future: _load(page),
                                      builder: (context, shelf) {
                                        if (shelf.hasError) {
                                          return _error(
                                            () => setState(
                                              () => _shelves.remove(page),
                                            ),
                                          );
                                        }
                                        return _Shelf(
                                          items: shelf.hasData
                                              ? (shelf.data!['items'] as List)
                                                    .cast<
                                                      Map<String, dynamic>
                                                    >()
                                              : [],
                                          loading: !shelf.hasData,
                                          onTap: _open,
                                        );
                                      },
                                    ),
                              ),
                      ),
                      if (pageCount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _pageButton(
                              -1,
                              pageCount,
                              'Kệ trước',
                              Icons.chevron_left,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Kệ ${_page + 1} / $pageCount',
                                  style: const TextStyle(
                                    color: Color(0xffffe6ba),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 64,
                                  child: LinearProgressIndicator(
                                    value: (_page + 1) / pageCount,
                                    minHeight: 3,
                                    color: const Color(0xffd4a564),
                                    backgroundColor: const Color(0xff503a28),
                                  ),
                                ),
                              ],
                            ),
                            _pageButton(
                              1,
                              pageCount,
                              'Kệ sau',
                              Icons.chevron_right,
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );

  Widget _stat(IconData icon, int count, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: const Color(0xffd4a564)),
      const SizedBox(width: 5),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$count',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' $label'),
          ],
        ),
        style: const TextStyle(color: Color(0xffffe6ba), fontSize: 13),
      ),
    ],
  );

  Widget _pageButton(int step, int count, String label, IconData icon) {
    final target = _page + step;
    return IconButton(
      tooltip: label,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      color: const Color(0xffffe6ba),
      disabledColor: const Color(0xff79604b),
      icon: Icon(icon),
      onPressed: target < 0 || target >= count
          ? null
          : () {
              if (!_pages.hasClients) return;
              if (MediaQuery.disableAnimationsOf(context)) {
                _pages.jumpToPage(target);
              } else {
                _pages.animateToPage(
                  target,
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutCubic,
                );
              }
            },
    );
  }

  Widget _error(VoidCallback retry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Chưa tải được bộ sưu tập.',
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: retry,
          child: const Text(
            'Thử lại',
            style: TextStyle(color: Color(0xffffd087)),
          ),
        ),
      ],
    ),
  );
}

class _Shelf extends StatefulWidget {
  const _Shelf({required this.items, this.loading = false, this.onTap});
  final List<Map<String, dynamic>> items;
  final bool loading;
  final void Function(Map<String, dynamic>)? onTap;

  @override
  State<_Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<_Shelf> {
  int? _pressed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final extra = (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
        0.0,
        double.infinity,
      );
      final height =
          (constraints.maxHeight / 2).clamp(220.0, 350.0) + extra * 4;
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var row = 0; row < 2; row++)
                Container(
                  height: height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xff332217),
                        Color(0xff573b29),
                        Color(0xff4b3223),
                        Color(0xff332218),
                      ],
                      stops: [0, .15, .86, 1],
                    ),
                    border: Border(
                      top: BorderSide(color: Color(0xff97704a), width: 2),
                      bottom: BorderSide(color: Color(0xff765031), width: 10),
                      left: BorderSide(color: Color(0xff775033), width: 7),
                      right: BorderSide(color: Color(0xff775033), width: 7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 9,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (var column = 0; column < 2; column++)
                        Expanded(
                          child: _slot(context, row * 2 + column, column == 1),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _slot(BuildContext context, int index, bool divider) {
    final item = index < widget.items.length ? widget.items[index] : null;
    final available = item?['available'] == true;
    final image = item?['imageUrl'] as String?;
    final textScaler = MediaQuery.textScalerOf(context);
    return Container(
      foregroundDecoration: divider
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xff87603e), width: 5),
              ),
            )
          : null,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1),
          radius: 1.2,
          colors: [
            const Color(0xffffd886).withValues(alpha: .25),
            Colors.transparent,
          ],
        ),
      ),
      child: CustomPaint(
        painter: const _Spotlight(),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            splashColor: const Color(0x30ffd087),
            highlightColor: const Color(0x18ffd087),
            onTap: available ? () => widget.onTap?.call(item!) : null,
            onHighlightChanged: available
                ? (pressed) => setState(() => _pressed = pressed ? index : null)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
              child: Column(
                children: [
                  Container(
                    width: 25,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xffffe0a0),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xffffc766),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: widget.loading
                        ? const SizedBox.expand(
                            child: ColoredBox(color: Colors.white12),
                          )
                        : item == null
                        ? const SizedBox.expand()
                        : AnimatedScale(
                            scale:
                                _pressed == index &&
                                    !MediaQuery.disableAnimationsOf(context)
                                ? .97
                                : 1,
                            duration: const Duration(milliseconds: 110),
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xff201a15),
                                border: Border.all(
                                  color: _pressed == index
                                      ? const Color(0xffffd087)
                                      : const Color(0xffab8756),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: image == null
                                  ? const Center(
                                      child: Icon(
                                        Icons.museum_outlined,
                                        color: Color(0xffc9ad81),
                                        size: 40,
                                      ),
                                    )
                                  : Image.network(
                                      ApiConfig.mediaUrl(image),
                                      headers: TokenManager.authHeaders,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, progress) =>
                                              progress == null
                                              ? child
                                              : const ColoredBox(
                                                  color: Color(0xff3c3026),
                                                ),
                                      errorBuilder: (_, error, stack) =>
                                          const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Color(0xffc9ad81),
                                              size: 36,
                                            ),
                                          ),
                                    ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: double.infinity,
                    height: textScaler.scale(14) * 2.4 + 9,
                    child: item == null
                        ? null
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xff302218),
                              border: Border.all(
                                color: const Color(0xff8d6945),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  item['name'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xffffe6ba),
                                    fontSize: 14,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  SizedBox(
                    height: textScaler.scale(11) * 2.5,
                    child: item != null && !available
                        ? const Text(
                            'Hiện vật hiện không khả dụng',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xffc9ad81),
                              fontSize: 11,
                              height: 1.2,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spotlight extends CustomPainter {
  const _Spotlight();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final reach = size.height * .72;
    final cone = Path()
      ..moveTo(center - 7, 18)
      ..lineTo(center + 7, 18)
      ..lineTo(size.width * .9, reach)
      ..lineTo(size.width * .1, reach)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x65ffd489), Color(0x22ffd489), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 18, size.width, reach - 18))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(_Spotlight oldDelegate) => false;
}
