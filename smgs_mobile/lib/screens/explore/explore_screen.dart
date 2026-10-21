import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/museum.dart';
import '../../services/discovery_api_service.dart';
import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../widgets/heritage_shimmer.dart';
import '../../data/mock/mock_artifacts.dart';
import 'museum_discovery_map_screen.dart';

String _searchKey(String text) {
  var value = text.toLowerCase();
  const groups = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ',
  ];
  const plain = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
  for (var i = 0; i < groups.length; i++) {
    for (final letter in groups[i].split('')) {
      value = value.replaceAll(letter, plain[i]);
    }
  }
  return value.trim();
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.standalone = false,
    this.museumId,
    this.artifactCategory,
    this.initialQuery = '',
    this.initialArtifacts = false,
  });
  final bool standalone;
  final String? museumId;
  final String? artifactCategory;
  final String initialQuery;
  final bool initialArtifacts;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late String _query = widget.initialQuery;
  late final _input = TextEditingController(text: widget.initialQuery);
  String? _museum, _gallery, _exhibition;
  bool _sortName = false;
  late String _category = widget.artifactCategory ?? 'Tất cả';
  late bool _artifacts =
      widget.museumId != null ||
      widget.artifactCategory != null ||
      widget.initialArtifacts;

  List<Museum> _backendMuseums = [];
  bool _isLoadingMuseums = false;
  String? _museumsError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchBackendMuseums();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _fetchBackendMuseums() async {
    setState(() {
      _isLoadingMuseums = true;
      _museumsError = null;
    });

    try {
      final list = await DiscoveryApiService.fetchMuseums(
        keyword: _query.trim().isNotEmpty ? _query.trim() : null,
        sortBy: _sortName ? 'newest' : null,
      );
      if (mounted) {
        setState(() {
          _backendMuseums = list;
          _isLoadingMuseums = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _museumsError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingMuseums = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    setState(() => _query = val);
    if (!_artifacts) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _fetchBackendMuseums();
      });
    }
  }

  void _clear() {
    setState(() {
      _query = '';
      _input.clear();
      _category = 'Tất cả';
      _museum = null;
      _gallery = null;
      _exhibition = null;
    });
    _fetchBackendMuseums();
  }

  @override
  Widget build(BuildContext context) {
    final filterMuseum = widget.museumId ?? _museum;
    final scoped = mockArtifacts
        .where((a) => filterMuseum == null || a.museumId == filterMuseum)
        .toList();
    final galleries = scoped.map((a) => a.location).toSet().toList();
    final exhibitions = scoped.map((a) => a.exhibition).toSet().toList();
    final artifacts = mockArtifacts
        .where(
          (a) =>
              (filterMuseum == null || a.museumId == filterMuseum) &&
              (_gallery == null || a.location == _gallery) &&
              (_exhibition == null || a.exhibition == _exhibition) &&
              _searchKey('${a.name} ${a.period} ${a.category} ${a.location}')
                  .contains(_searchKey(_query)) &&
              (_category == 'Tất cả' || a.category == _category),
        )
        .toList();
    final categories = _artifacts
        ? ['Tất cả', 'Khảo cổ', 'Cung đình', 'Tư liệu']
        : ['Tất cả', 'Lịch sử', 'Văn hóa'];

    return MuseumPage(
      back: widget.standalone,
      title: 'Khám phá di sản',
      eyebrow: 'Bộ sưu tập',
      subtitle: 'Tìm một điểm đến. Mở một câu chuyện.',
      children: [
        TextField(
          controller: _input,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            labelText: 'Tìm kiếm',
            hintText: 'Tên bảo tàng hoặc hiện vật',
            prefixIcon: Icon(Icons.search_outlined),
          ),
        ),
        const SizedBox(height: 20),
        if (_artifacts)
          ExpansionTile(
            title: const Text(
              'Lọc bảo tàng, chuyên đề, phòng',
              style: AppTextStyles.bodyMedium,
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 18),
            children: [
              if (widget.museumId == null) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('museum-$_museum'),
                  initialValue: _museum ?? '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Bảo tàng'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả bảo tàng'),
                    ),
                    ..._backendMuseums.map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _museum = v == '' ? null : v;
                    _gallery = null;
                    _exhibition = null;
                  }),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                key: ValueKey('exhibition-$_exhibition'),
                initialValue: _exhibition ?? '',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Chuyên đề trưng bày',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Tất cả chuyên đề'),
                  ),
                  ...exhibitions.map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _exhibition = v == '' ? null : v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('gallery-$_gallery'),
                initialValue: _gallery ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Phòng trưng bày'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Tất cả phòng'),
                  ),
                  ...galleries.map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _gallery = v == '' ? null : v),
              ),
            ],
          )
        else
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Sắp xếp mới nhất',
              style: AppTextStyles.bodyMedium,
            ),
            value: _sortName,
            onChanged: (v) {
              setState(() => _sortName = v ?? false);
              _fetchBackendMuseums();
            },
          ),
        if (_query.isNotEmpty ||
            _category != 'Tất cả' ||
            _museum != null ||
            _gallery != null ||
            _exhibition != null)
          TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Xóa bộ lọc và từ khóa'),
          ),
        if (widget.museumId == null) ...[
          Row(
            children: [
              for (final mode in [false, true])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: mode ? 0 : 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _artifacts == mode
                            ? AppColors.deepBurgundy
                            : AppColors.card,
                        foregroundColor: _artifacts == mode
                            ? AppColors.antiqueIvory
                            : AppColors.darkBrown,
                        minimumSize: const Size(48, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () => setState(() {
                        _artifacts = mode;
                        _category = 'Tất cả';
                        _gallery = null;
                        _exhibition = null;
                      }),
                      child: Text(mode ? 'Hiện vật' : 'Bảo tàng'),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // BẢN ĐỒ KHÁM PHÁ & DẪN ĐƯỜNG (MUSEUM DISCOVERY BANNER)
        if (!_artifacts) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepBurgundy,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepBurgundy.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.imperialGold.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined, color: AppColors.imperialGold, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bản đồ Khám phá & Dẫn đường',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Xem vị trí trên bản đồ, lọc bảo tàng gần tôi nhất và chỉ đường ngoài trời.',
                        style: TextStyle(color: Colors.white.withAlpha(215), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.imperialGold,
                    foregroundColor: AppColors.charcoalBrown,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => openPage(context, const MuseumDiscoveryMapScreen()),
                  child: const Text('Mở bản đồ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],

        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: categories
              .map(
                (c) => ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: _category == c
                        ? AppColors.antiqueIvory
                        : AppColors.darkBrown,
                  ),
                  checkmarkColor: AppColors.antiqueIvory,
                  onSelected: (_) => setState(() => _category = c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),

        if (!_artifacts && _isLoadingMuseums) ...[
          const HeritageMuseumCardSkeleton(),
          const HeritageMuseumCardSkeleton(),
        ] else if (!_artifacts && _museumsError != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.deepBurgundy.withAlpha(80)),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppColors.deepBurgundy, size: 36),
                const SizedBox(height: 10),
                Text(
                  _museumsError!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBurgundy,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Thử kết nối lại'),
                  onPressed: _fetchBackendMuseums,
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            '${_artifacts ? artifacts.length : _backendMuseums.length} ${_artifacts ? 'hiện vật' : 'bảo tàng'} được tìm thấy',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          if ((_artifacts && artifacts.isEmpty) ||
              (!_artifacts && _backendMuseums.isEmpty))
            const EmptyState(
              title: 'Chưa tìm thấy kết quả',
              message: 'Thử một từ khóa khác hoặc chọn “Tất cả” để xem lại bộ sưu tập.',
            ),
          if (_artifacts)
            ...artifacts.map((a) => ArtifactCard(artifact: a))
          else
            ..._backendMuseums.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: MuseumCard(museum: m),
              ),
            ),
        ],

        const SizedBox(height: 10),
        const Notice('Dữ liệu kết nối trực tiếp từ máy chủ Smart Museum Guide System.'),
      ],
    );
  }
}
