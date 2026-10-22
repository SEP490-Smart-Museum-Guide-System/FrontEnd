import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/map_place.dart';
import '../../widgets/place_search_field.dart';
import '../../core/theme/app_colors.dart';
import '../../models/city.dart';
import '../../models/museum.dart';
import '../../services/discovery_api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/interactive_heritage_map.dart';
import '../../widgets/museum_discovery_card.dart';
import '../../widgets/route_preview_sheet.dart';
import '../museum/museum_detail_screen.dart';

class MuseumDiscoveryMapScreen extends StatefulWidget {
  const MuseumDiscoveryMapScreen({super.key});
  @override
  State<MuseumDiscoveryMapScreen> createState() =>
      _MuseumDiscoveryMapScreenState();
}

class _MuseumDiscoveryMapScreenState extends State<MuseumDiscoveryMapScreen> {
  final _search = TextEditingController();
  final _cards = ScrollController();
  Timer? _debounce;
  List<Museum> _museums = [];
  bool _world = true;
  MapPlace? _place;
  List<CityItem> _cities = [];
  String? _cityCode, _selectedId, _error, _cityError;
  UserLocationResult? _location;
  List<LatLng> _route = [];
  bool _nearMe = false, _loading = false, _locating = false;
  int _request = 0, _page = 0, _totalPages = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _cards.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await DiscoveryApiService.fetchCities();
      if (mounted) {
        setState(() {
          _cities = cities;
          _cityError = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cityError = 'Không tải được tỉnh/thành');
    }
  }

  Future<void> _load({bool more = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _route = [];
        _museums = [];
        _selectedId = null;
        _total = 0;
        _page = 0;
        _totalPages = 0;
      }
    });
    try {
      final result = await DiscoveryApiService.fetchMuseumPage(
        keyword: _search.text,
        cityCode: _cityCode,
        latitude: _nearMe ? _location?.latitude : null,
        longitude: _nearMe ? _location?.longitude : null,
        sortBy: _nearMe ? 'distance' : null,
        page: more ? _page + 1 : 1,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _museums = more ? [..._museums, ...result.items] : result.items;
        _page = result.page;
        _totalPages = result.totalPages;
        _total = result.totalCount;
        _loading = false;
      });
    } catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _error = '$e'.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleNearby() async {
    if (_nearMe) {
      setState(() => _nearMe = false);
      await _load();
      return;
    }
    setState(() => _locating = true);
    try {
      final location = await LocationService.getCurrentUserLocation();
      if (!mounted) return;
      setState(() {
        _location = location;
        _nearMe = true;
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _select(Museum museum) {
    setState(() {
      _selectedId = museum.id;
      _route = [];
    });
    final index = _museums.indexOf(museum);
    if (_cards.hasClients) {
      _cards.animateTo(
        (index * 322.0).clamp(0.0, _cards.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _preview(Museum museum) {
    setState(() {
      _selectedId = museum.id;
      _route = [];
    });
    RoutePreviewSheet.show(
      context,
      museum: museum,
      onRouteLoaded: (route) {
        if (mounted) setState(() => _route = route.routePoints);
      },
    );
  }

  Future<void> _navigateToPlace() async {
    final place = _place;
    if (place == null) return;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${place.latitude},${place.longitude}',
      'travelmode': 'driving',
    });
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Show a retryable error below. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được ứng dụng bản đồ. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.antiqueIvory,
    appBar: AppBar(title: const Text('Khám phá bản đồ')),
    body: SafeArea(
      child: Column(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Mọi địa điểm')),
              ButtonSegment(value: false, label: Text('Bảo tàng SMGS')),
            ],
            selected: {_world},
            onSelectionChanged: (value) {
              _debounce?.cancel();
              FocusScope.of(context).unfocus();
              setState(() {
                _world = value.first;
                _place = null;
                _route = [];
              });
            },
          ),
          if (_world)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PlaceSearchField(
                onSelected: (place) => setState(() => _place = place),
              ),
            ),
          if (!_world) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  hintText: 'Tìm tên bảo tàng',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) {
                  _debounce?.cancel();
                  ++_request; // Invalidate any response for the previous search immediately.
                  _debounce = Timer(
                    const Duration(milliseconds: 400),
                    () => _load(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _cityCode,
                      hint: const Text('Tất cả tỉnh/thành'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tất cả tỉnh/thành'),
                        ),
                        ..._cities.map(
                          (c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (code) {
                        _debounce?.cancel();
                        setState(() => _cityCode = code);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: Text(_locating ? 'Đang lấy GPS…' : 'Gần tôi'),
                    selected: _nearMe,
                    onSelected: _locating
                        ? null
                        : (_) {
                            _debounce?.cancel();
                            _toggleNearby();
                          },
                  ),
                ],
              ),
            ),
            if (_cityError != null)
              TextButton(
                onPressed: _loadCities,
                child: Text('$_cityError · Thử lại'),
              ),
          ],
          Expanded(
            child: InteractiveHeritageMap(
              museums: _world ? const [] : _museums,
              selectedMuseumId: _world ? null : _selectedId,
              placeLocation: _world && _place != null
                  ? LatLng(_place!.latitude, _place!.longitude)
                  : null,
              placeName: _place?.name,
              onMuseumSelected: _select,
              polylinePoints: _world ? const [] : _route,
              userLocation: _location == null
                  ? null
                  : LatLng(_location!.latitude, _location!.longitude),
            ),
          ),
          if (_world && _place != null)
            ListTile(
              title: Text(
                _place!.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _place!.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Chỉ đường bằng Google Maps',
                icon: const Icon(Icons.directions),
                onPressed: _navigateToPlace,
              ),
            ),
          if (!_world) ...[
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(_error!),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _load(more: _page > 0),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            if (!_loading && _error == null && _museums.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Không tìm thấy bảo tàng theo bộ lọc.'),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text('${_museums.length}/$_total bảo tàng'),
                  ),
                ),
                if (_page < _totalPages)
                  TextButton(
                    onPressed: _loading ? null : () => _load(more: true),
                    child: const Text('Tải thêm'),
                  ),
              ],
            ),
            if (_museums.isNotEmpty)
              SizedBox(
                height: 195,
                child: ListView.builder(
                  controller: _cards,
                  scrollDirection: Axis.horizontal,
                  itemCount: _museums.length,
                  itemBuilder: (context, index) {
                    final museum = _museums[index];
                    return MuseumDiscoveryCard(
                      museum: museum,
                      isSelected: museum.id == _selectedId,
                      onTap: () {
                        _select(museum);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MuseumDetailScreen(museum: museum),
                          ),
                        );
                      },
                      onDirectionsPressed: museum.hasCoordinates
                          ? () => _preview(museum)
                          : null,
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
