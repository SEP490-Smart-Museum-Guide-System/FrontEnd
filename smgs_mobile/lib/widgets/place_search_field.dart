import 'dart:async';
import 'package:flutter/material.dart';
import '../models/map_place.dart';
import '../services/place_search_service.dart';

class PlaceSearchField extends StatefulWidget {
  const PlaceSearchField({
    super.key,
    required this.onSelected,
    this.search = PlaceSearchService.search,
  });
  final ValueChanged<MapPlace?> onSelected;
  final Future<List<MapPlace>> Function(String) search;
  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final _text = TextEditingController();
  Timer? _timer;
  int _generation = 0;
  List<MapPlace> _items = [];
  bool _loading = false;
  String? _message;

  void _changed(String value) {
    _timer?.cancel();
    final generation = ++_generation;
    widget.onSelected(null);
    setState(() {
      _items = [];
      _message = null;
      _loading = value.trim().length >= 3;
    });
    if (_loading) {
      _timer = Timer(
        const Duration(milliseconds: 700),
        () => _find(generation),
      );
    }
  }

  Future<void> _find(int generation) async {
    try {
      final items = await widget.search(_text.text.trim());
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = items;
        _loading = false;
        _message = items.isEmpty
            ? 'Không tìm thấy địa điểm. Thử thêm tên thành phố.'
            : null;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _message = 'Không tải được gợi ý. Nhấn tìm kiếm để thử lại.';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        controller: _text,
        maxLength: 200,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm địa điểm, đường, địa chỉ…',
          helperText: 'Nhập ít nhất 3 ký tự · OpenStreetMap / Photon',
          counterText: '',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Xóa tìm kiếm',
            icon: const Icon(Icons.clear),
            onPressed: () {
              _text.clear();
              _changed('');
            },
          ),
        ),
        onChanged: _changed,
        onSubmitted: (value) {
          _timer?.cancel();
          if (value.trim().length >= 3) {
            setState(() => _loading = true);
            _find(++_generation);
          }
        },
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_message != null) Text(_message!),
      if (_items.isNotEmpty)
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final place = _items[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.place_outlined),
                title: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  place.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _timer?.cancel();
                  ++_generation;
                  _text.text = place.name;
                  setState(() {
                    _items = [];
                    _message = null;
                    _loading = false;
                  });
                  FocusScope.of(context).unfocus();
                  widget.onSelected(place);
                },
              );
            },
          ),
        ),
    ],
  );
}
