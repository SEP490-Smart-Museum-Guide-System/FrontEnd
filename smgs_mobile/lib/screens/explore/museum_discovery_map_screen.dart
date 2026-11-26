import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/city.dart';
import '../../models/map_place.dart';
import '../../models/museum.dart';
import '../../services/automatic_location_service.dart';
import '../../services/discovery_api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/interactive_heritage_map.dart';
import '../../widgets/place_search_field.dart';
import '../../widgets/route_preview_sheet.dart';
import '../museum/museum_detail_screen.dart';

class MuseumDiscoveryMapScreen extends StatefulWidget {
  const MuseumDiscoveryMapScreen({super.key});
  @override
  State<MuseumDiscoveryMapScreen> createState() =>
      _MuseumDiscoveryMapScreenState();
}

class _MuseumDiscoveryMapScreenState extends State<MuseumDiscoveryMapScreen> {
  List<CityItem> cities = [];
  List<Museum> museums = [];
  String? province, error;
  Museum? selected;
  MapPlace? place;
  bool supportedOnly = false,
      loading = false,
      cityFailed = false,
      locating = false;
  int generation = 0, gpsFocus = 0;
  String search = '';
  UserLocationResult? location;
  List<LatLng> route = [];

  @override
  void initState() {
    super.initState();
    final gps = AutomaticLocationService.instance;
    gps.addListener(_updateGps);
    if (gps.hasFreshLocation) location = gps.latest;
    loadCities();
    load();
  }

  void _updateGps() {
    final gps = AutomaticLocationService.instance;
    if (gps.hasFreshLocation && location != gps.latest) {
      setState(() => location = gps.latest);
    }
  }

  @override
  void dispose() {
    AutomaticLocationService.instance.removeListener(_updateGps);
    super.dispose();
  }

  Future<void> loadCities() async {
    try {
      final data = await DiscoveryApiService.fetchCities();
      if (mounted)
        setState(() {
          cities = data;
          cityFailed = false;
        });
    } catch (_) {
      if (mounted) setState(() => cityFailed = true);
    }
  }

  Future<List<Museum>> external(String code) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/places/museums',
    ).replace(queryParameters: {'cityCode': code});
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    final items = DiscoveryApiService.decodeResponse(res)['data'] as List;
    return items.map((item) {
      final p = MapPlace.fromJson(item as Map<String, dynamic>);
      return Museum(
        id: 'osm:${p.latitude},${p.longitude}:${p.name}',
        name: p.name,
        location: p.address,
        description: '',
        imageUrl: '',
        openingHours: '',
        category: '',
        shortIntro: '',
        googleMapsVisible: true,
        latitude: p.latitude,
        longitude: p.longitude,
      );
    }).toList();
  }

  Future<void> load() async {
    final current = ++generation;
    final code = province;
    final includeExternal = !supportedOnly && code != null;
    setState(() {
      loading = true;
      error = null;
      selected = null;
      place = null;
      route = [];
      museums = [];
    });
    final found = <Museum>[];
    String? failure;
    try {
      var page = 1;
      while (true) {
        final data = await DiscoveryApiService.fetchMuseumPage(
          cityCode: code,
          page: page,
        );
        if (!mounted || generation != current) return;
        found.addAll(data.items);
        if (page >= data.totalPages) break;
        page++;
      }
    } catch (e) {
      failure = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted || generation != current) return;
    if (includeExternal) {
      try {
        final others = await external(code);
        if (!mounted || generation != current) return;
        for (final m in others) {
          final duplicate = found.any(
            (x) =>
                x.name.trim().toLowerCase() == m.name.trim().toLowerCase() &&
                (!x.hasCoordinates ||
                    const Distance().as(
                          LengthUnit.Meter,
                          LatLng(x.latitude!, x.longitude!),
                          LatLng(m.latitude!, m.longitude!),
                        ) <
                        500),
          );
          if (!duplicate) found.add(m);
        }
      } catch (e) {
        failure = e.toString().replaceFirst('Exception: ', '');
      }
    }
    if (!mounted || generation != current) return;
    setState(() {
      museums = found;
      loading = false;
      error = failure;
      selected = (supportedOnly || province != null) && place == null
          ? visible.firstOrNull
          : null;
    });
  }

  List<Museum> get visible => search.isEmpty
      ? museums
      : museums
            .where(
              (m) => '${m.name} ${m.location}'.toLowerCase().contains(
                search.trim().toLowerCase(),
              ),
            )
            .toList();

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      final gps = await LocationService.getCurrentUserLocation();
      if (mounted)
        setState(() {
          location = gps;
          gpsFocus++;
          selected = null;
          place = null;
          route = [];
        });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void preview() {
    final m = selected;
    final p =
        place ??
        (m != null && m.id.startsWith('osm:')
            ? MapPlace(m.name, m.location, m.latitude!, m.longitude!)
            : null);
    RoutePreviewSheet.show(
      context,
      museum: p == null ? m : null,
      place: p,
      onRouteLoaded: (r) {
        if (mounted) setState(() => route = r.routePoints);
      },
    );
  }

  Widget pill(Widget child) => Material(
    color: Colors.white,
    elevation: 3,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final list = visible;
    final m = selected;
    final isSystem = m != null && !m.id.startsWith('osm:');
    final keywordMode = supportedOnly || province != null;
    final index = m == null ? -1 : list.indexOf(m);
    void select(Museum value) => setState(() {
      selected = value;
      place = null;
      route = [];
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveHeritageMap(
              key: ValueKey(gpsFocus),
              museums: list,
              fitMuseumList: supportedOnly || province != null,
              selectedMuseumId: m?.id,
              centerOnGps: province == null || gpsFocus > 0,
              onMuseumSelected: select,
              polylinePoints: route,
              placeLocation: place == null
                  ? null
                  : LatLng(place!.latitude, place!.longitude),
              placeName: place?.name,
              userLocation: location == null
                  ? null
                  : LatLng(location!.latitude, location!.longitude),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      pill(
                        BackButton(
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: pill(
                          keywordMode
                              ? TextField(
                                  key: ValueKey((province, supportedOnly)),
                                  onChanged: (v) => setState(() {
                                    search = v;
                                    selected =
                                        (supportedOnly || province != null) &&
                                            place == null
                                        ? visible.firstOrNull
                                        : null;
                                    place = null;
                                    route = [];
                                  }),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: 'Tìm bảo tàng, địa chỉ…',
                                    border: InputBorder.none,
                                  ),
                                )
                              : PlaceSearchField(
                                  onSelected: (p) => setState(() {
                                    place = p;
                                    selected = null;
                                    route = [];
                                  }),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: pill(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_scanner, size: 18),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text('Chỉ bảo tàng được hỗ trợ'),
                            ),
                            Switch(
                              value: supportedOnly,
                              onChanged: (v) {
                                setState(() {
                                  supportedOnly = v;
                                  search = '';
                                });
                                load();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: pill(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: cityFailed
                            ? TextButton(
                                onPressed: loadCities,
                                child: const Text('Tải lại tỉnh/thành'),
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: province,
                                  isExpanded: true,
                                  isDense: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  hint: const Text('Tất cả tỉnh/thành'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Tất cả tỉnh/thành'),
                                    ),
                                    ...cities.map(
                                      (c) => DropdownMenuItem(
                                        value: c.code,
                                        child: Text(c.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      province = v;
                                      search = '';
                                      gpsFocus = 0;
                                    });
                                    load();
                                  },
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: pill(
                      IconButton(
                        tooltip: 'Vị trí của tôi',
                        onPressed: locating ? null : locate,
                        icon: const Icon(Icons.my_location),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          if (loading) const LinearProgressIndicator(),
                          if (error != null)
                            Row(
                              children: [
                                Expanded(child: Text(error!, maxLines: 2)),
                                TextButton(
                                  onPressed: load,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          if (m == null &&
                              place == null &&
                              !loading &&
                              error == null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                list.isEmpty
                                    ? 'Không tìm thấy bảo tàng theo bộ lọc.'
                                    : 'Chọn bảo tàng trên bản đồ.',
                              ),
                            ),
                          if (m != null || place != null) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: SizedBox(
                                width: 58,
                                height: 58,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: m != null && m.imageUrl.isNotEmpty
                                      ? Image.network(
                                          m.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.museum),
                                        )
                                      : const ColoredBox(
                                          color: AppColors.antiqueIvory,
                                          child: Icon(Icons.museum_outlined),
                                        ),
                                ),
                              ),
                              title: Text(
                                m?.name ?? place!.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (isSystem) 'Được hệ thống hỗ trợ',
                                  m?.location ?? place!.address,
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        m?.hasCoordinates == true ||
                                            place != null
                                        ? preview
                                        : null,
                                    icon: const Icon(Icons.directions_outlined),
                                    label: const Text('Xem đường đi'),
                                  ),
                                ),
                                if (isSystem) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MuseumDetailScreen(museum: m),
                                        ),
                                      ),
                                      child: const Text('Xem bảo tàng'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (list.length > 1 && place == null && m != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: 'Bảo tàng trước',
                                  onPressed: index > 0
                                      ? () => select(list[index - 1])
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('${index + 1}/${list.length}'),
                                IconButton(
                                  tooltip: 'Bảo tàng tiếp theo',
                                  onPressed: index + 1 < list.length
                                      ? () => select(list[index + 1])
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

