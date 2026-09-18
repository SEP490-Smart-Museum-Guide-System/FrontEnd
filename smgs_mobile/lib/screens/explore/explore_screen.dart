import 'package:flutter/material.dart';

import '../../widgets/museum_ui.dart';
import '../../widgets/collection_cards.dart';
import '../../data/mock/mock_museums.dart';
import '../../data/mock/mock_artifacts.dart';

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
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
    _query = '';
    _input.clear();
    _category = 'Tất cả';
    _museum = null;
    _gallery = null;
    _exhibition = null;
  });
  @override
  Widget build(BuildContext context) {
    final museums = mockMuseums
        .where(
          (m) =>
              _searchKey('${m.name} ${m.location}')
                  .contains(_searchKey(_query)) &&
              (_category == 'Tất cả' || m.category == _category),
        )
        .toList();
    if (_sortName) museums.sort((a, b) => a.name.compareTo(b.name));
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
          onChanged: (v) => setState(() => _query = v),
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
                    ...mockMuseums.map(
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
              'Sắp xếp theo tên bảo tàng',
              style: AppTextStyles.bodyMedium,
            ),
            value: _sortName,
            onChanged: (v) => setState(() => _sortName = v ?? false),
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
                          borderRadius: BorderRadius.circular(6),
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
        Text(
          '${_artifacts ? artifacts.length : museums.length} ${_artifacts ? 'hiện vật' : 'bảo tàng'} được tìm thấy',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 14),
        if ((_artifacts && artifacts.isEmpty) ||
            (!_artifacts && museums.isEmpty))
          const EmptyState(
            title: 'Chưa tìm thấy kết quả',
            message: 'Thử một từ khóa khác hoặc chọn “Tất cả” để xem lại bộ sưu tập.',
          ),
        if (_artifacts)
          ...artifacts.map((a) => ArtifactCard(artifact: a))
        else
          ...museums.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: MuseumCard(museum: m),
            ),
          ),
        const SizedBox(height: 10),
        const Notice('Bộ sưu tập minh họa cho trải nghiệm tham quan.'),
      ],
    );
  }
}
