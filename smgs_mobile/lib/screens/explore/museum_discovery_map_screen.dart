import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../models/city.dart';
import '../../models/museum.dart';
import '../../services/discovery_api_service.dart';
import '../../services/location_service.dart';
import '../../services/polyline_decoder.dart';
import '../../widgets/city_filter_sheet.dart';
import '../../widgets/interactive_heritage_map.dart';
import '../../widgets/museum_discovery_card.dart';
import '../../widgets/route_preview_sheet.dart';

class MuseumDiscoveryMapScreen extends StatefulWidget {
  const MuseumDiscoveryMapScreen({super.key});

  @override
  State<MuseumDiscoveryMapScreen> createState() => _MuseumDiscoveryMapScreenState();
}

class _MuseumDiscoveryMapScreenState extends State<MuseumDiscoveryMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _cardScrollController = ScrollController();
  Timer? _debounceTimer;

  List<Museum> _museums = [];
  List<CityItem> _cities = [];
  CityItem? _selectedCity;
  UserLocationResult? _userLocation;
  bool _isNearMeActive = false;
  bool _isLoading = true;
  Museum? _selectedMuseum;
  List<LatLng> _activePolyline = [];

  // Dual mode: true nếu có Google Maps API key hợp lệ
  bool _useNativeGoogleMap = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cardScrollController.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final cities = await DiscoveryApiService.fetchCities();
    final museums = await DiscoveryApiService.fetchMuseums();

    if (mounted) {
      setState(() {
        _cities = cities;
        _museums = museums;
        if (museums.isNotEmpty) {
          _selectedMuseum = museums.first;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilters({String? keyword, CityItem? city, bool sortByDistance = false}) async {
    setState(() => _isLoading = true);
    final museums = await DiscoveryApiService.fetchMuseums(
      keyword: keyword ?? _searchController.text,
      cityCode: city?.code ?? _selectedCity?.code,
      latitude: _userLocation?.latitude,
      longitude: _userLocation?.longitude,
      sortBy: sortByDistance ? 'distance' : null,
    );

    if (mounted) {
      setState(() {
        _museums = museums;
        if (museums.isNotEmpty && !_museums.any((m) => m.id == _selectedMuseum?.id)) {
          _selectedMuseum = museums.first;
        }
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _applyFilters(keyword: text, sortByDistance: _isNearMeActive);
    });
  }

  Future<void> _toggleNearMe() async {
    if (_isNearMeActive) {
      // Tắt chế độ gần tôi
      setState(() => _isNearMeActive = false);
      _applyFilters(sortByDistance: false);
      return;
    }

    // Xin quyền và lấy tọa độ GPS
    final loc = await LocationService.getCurrentUserLocation();
    if (!mounted) return;

    if (loc.isMockOrFallback && loc.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.errorMessage!),
          backgroundColor: AppColors.charcoalBrown,
        ),
      );
    }

    setState(() {
      _userLocation = loc;
      _isNearMeActive = true;
    });

    _applyFilters(sortByDistance: true);
  }

  void _selectMuseum(Museum museum) {
    setState(() {
      _selectedMuseum = museum;
    });

    // Cuộn danh sách card đến vị trí bảo tàng này
    final index = _museums.indexOf(museum);
    if (index >= 0 && _cardScrollController.hasClients) {
      _cardScrollController.animateTo(
        index * 322.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Di chuyển Google Map nếu đang ở chế độ Native
    if (_useNativeGoogleMap && _mapController != null && museum.latitude != 0.0) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(museum.latitude, museum.longitude), 14.5),
      );
    }
  }

  void _openRoutePreview(Museum museum) {
    final userLat = _userLocation?.latitude ?? LocationService.defaultLat;
    final userLng = _userLocation?.longitude ?? LocationService.defaultLng;

    RoutePreviewSheet.show(
      context,
      museum: museum,
      userLat: userLat,
      userLng: userLng,
      onRouteLoaded: (route) {
        if (route.encodedPolyline.isNotEmpty) {
          final points = PolylineDecoder.decode(route.encodedPolyline);
          setState(() => _activePolyline = points);
        } else {
          // Sinh lộ trình mẫu nối điểm
          setState(() {
            _activePolyline = [
              LatLng(userLat, userLng),
              LatLng(
                (userLat + museum.latitude) / 2 + 0.002,
                (userLng + museum.longitude) / 2 - 0.003,
              ),
              LatLng(museum.latitude, museum.longitude),
            ];
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.antiqueIvory,
      body: Stack(
        children: [
          // 1. LAYER BẢN ĐỒ (Google Map hoặc Heritage Canvas Fallback)
          Positioned.fill(
            child: _useNativeGoogleMap ? _buildNativeGoogleMap() : _buildHeritageMap(),
          ),

          // 2. LAYER THANH TÌM KIẾM & BỘ LỌC (TOP FLOATING BAR)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back Button & Search Box
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.charcoalBrown),
                            onPressed: () => Navigator.of(context).maybePop(),
                            tooltip: 'Quay lại',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm bảo tàng, di sản...',
                                hintStyle: TextStyle(color: AppColors.charcoalBrown.withOpacity(0.5), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: AppColors.deepBurgundy),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _applyFilters(keyword: '', sortByDistance: _isNearMeActive);
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                  // Filter Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // City Filter Pill
                        GestureDetector(
                          onTap: () async {
                            final chosen = await CityFilterSheet.show(
                              context,
                              cities: _cities,
                              selectedCityCode: _selectedCity?.code,
                            );
                            setState(() => _selectedCity = chosen);
                            _applyFilters(city: chosen, sortByDistance: _isNearMeActive);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedCity != null ? AppColors.deepBurgundy : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedCity != null
                                    ? AppColors.deepBurgundy
                                    : AppColors.parchmentBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_city,
                                  size: 15,
                                  color: _selectedCity != null ? Colors.white : AppColors.charcoalBrown,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedCity?.name ?? 'Tỉnh / Thành phố',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedCity != null ? Colors.white : AppColors.charcoalBrown,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: _selectedCity != null ? Colors.white : AppColors.charcoalBrown,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // "Gần tôi" Pill
                        GestureDetector(
                          onTap: _toggleNearMe,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isNearMeActive ? AppColors.imperialGold : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isNearMeActive
                                    ? AppColors.imperialGold
                                    : AppColors.parchmentBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 15,
                                  color: _isNearMeActive ? Colors.white : AppColors.charcoalBrown,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Gần tôi nhất',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isNearMeActive ? Colors.white : AppColors.charcoalBrown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Count pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueIvory.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.parchmentBorder),
                          ),
                          child: Text(
                            '${_museums.length} bảo tàng',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoalBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

          // 3. LAYER THẺ BẢO TÀNG TRƯỢT (BOTTOM CAROUSEL)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.deepBurgundy))
                : _museums.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
                            ],
                          ),
                          child: const Text('Không tìm thấy bảo tàng nào theo bộ lọc.'),
                        ),
                      )
                    : SizedBox(
                        height: 195,
                        child: ListView.builder(
                          controller: _cardScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _museums.length,
                          itemBuilder: (context, index) {
                            final museum = _museums[index];
                            final isSelected = museum.id == _selectedMuseum?.id;
                            return MuseumDiscoveryCard(
                              museum: museum,
                              isSelected: isSelected,
                              onTap: () => _selectMuseum(museum),
                              onDirectionsPressed: () => _openRoutePreview(museum),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeritageMap() {
    return InteractiveHeritageMap(
      museums: _museums,
      selectedMuseumId: _selectedMuseum?.id,
      onMuseumSelected: _selectMuseum,
      userLocation: _userLocation != null
          ? LatLng(_userLocation!.latitude, _userLocation!.longitude)
          : null,
      polylinePoints: _activePolyline,
    );
  }

  Widget _buildNativeGoogleMap() {
    final markers = <Marker>{};
    for (final m in _museums) {
      if (m.latitude != 0.0 && m.longitude != 0.0) {
        markers.add(
          Marker(
            markerId: MarkerId(m.id),
            position: LatLng(m.latitude, m.longitude),
            infoWindow: InfoWindow(title: m.name, snippet: m.location),
            onTap: () => _selectMuseum(m),
          ),
        );
      }
    }

    final polylines = <Polyline>{};
    if (_activePolyline.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_preview'),
          points: _activePolyline,
          color: AppColors.deepBurgundy,
          width: 5,
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _selectedMuseum != null
            ? LatLng(_selectedMuseum!.latitude, _selectedMuseum!.longitude)
            : const LatLng(10.7769, 106.7009),
        zoom: 13,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: _isNearMeActive,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
    );
  }
}
