import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../services/personalized_tour_api.dart';
import '../../services/visitor_experience_api.dart';
import '../../widgets/museum_ui.dart';
import '../museum/visit_progress_screen.dart';
import '../artifact/artifact_detail_screen.dart';
import 'published_tours_screen.dart';

String tourMinutes(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

Future<void> _pushTourPage(BuildContext context, Widget page) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => HeritagePaper(child: page)),
  );
}

class PersonalizedTourBuilder extends StatefulWidget {
  const PersonalizedTourBuilder({
    super.key,
    this.standalone = false,
    this.museumId = '',
  });
  final bool standalone;
  final String museumId;
  @override
  State<PersonalizedTourBuilder> createState() =>
      _PersonalizedTourBuilderState();
}

class _PersonalizedTourBuilderState extends State<PersonalizedTourBuilder> {
  late String _museumId = widget.museumId.isNotEmpty
      ? widget.museumId
      : (AppServices.catalog.museums.firstOrNull?.id ?? '');
  int _minutes = 60;
  bool _busy = false;
  String? _error;
  final _interestInput = TextEditingController();
  final Set<String> _selected = {};
  List<String> _topics = [];
  bool _savedFailed = false;
  late Future<List<Map<String, dynamic>>> _saved = _loadSaved();

  Future<List<Map<String, dynamic>>> _loadSaved() async {
    _savedFailed = false;
    try {
      return await PersonalizedTourApi.saved();
    } catch (_) {
      // This future may finish before its section is scrolled into view.
      _savedFailed = true;
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _interestInput.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    final id = int.tryParse(_museumId);
    if (id == null) return;
    try {
      final rows = await PersonalizedTourApi.interests(id);
      if (mounted && _museumId == id.toString()) {
        setState(() => _topics = rows.map((r) => r['name'] as String).toList());
      }
    } catch (_) {
      // Free-form interests and the existing tour/free-visit options remain usable.
      if (mounted && _museumId == id.toString()) setState(() => _topics = []);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addInterest() {
    final value = _interestInput.text.trim();
    if (value.length < 2 || value.length > 80 || _selected.length >= 8) {
      setState(
        () => _error = 'Nhập sở thích từ 2 đến 80 ký tự, tối đa 8 lựa chọn.',
      );
      return;
    }
    setState(() {
      _selected.add(value);
      _error = null;
      _interestInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(_museumId);
    final chips = {
      ..._topics,
      'Lịch sử',
      'Gốm sứ',
      'Nghệ thuật',
      'Văn hóa',
      'Khoa học',
      ..._selected,
    };
    return MuseumPage(
      back: widget.standalone,
      title: 'Tham quan theo\ncách của bạn.',
      eyebrow: 'Hành trình của bạn',
      subtitle: 'Chọn tour có sẵn, khám phá tự do hoặc thử một gợi ý cá nhân.',
      children: [
        DropdownButtonFormField<String>(
          initialValue: id == null ? null : _museumId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Bảo tàng'),
          items: AppServices.catalog.museums
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _busy
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _museumId = value;
                    _topics = [];
                    _error = null;
                  });
                  _loadTopics();
                },
        ),
        if (id == null)
          const Notice(
            'Chưa có bảo tàng. Hãy tải lại danh mục hoặc liên hệ nhân viên.',
          ),
        const SizedBox(height: 20),
        const Notice(
          'Cá nhân hóa là lựa chọn thêm. Hành trình cá nhân không thay thế vé vào cửa hoặc tour bạn đã mua.',
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Xem tour có sẵn',
          icon: Icons.route_outlined,
          onPressed: id == null || _busy
              ? null
              : () => openPage(context, PublishedToursScreen(museumId: id)),
        ),
        TextButton.icon(
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Tham quan tự do'),
          onPressed: id == null || _busy
              ? null
              : () => _run(() async {
                  final visit = await VisitorExperienceApi.startVisit(id);
                  if (!context.mounted) return;
                  await _pushTourPage(
                    context,
                    VisitProgressScreen(visitId: visit['id'] as int),
                  );
                }),
        ),
        const SectionHeading('Gợi ý hành trình cá nhân'),
        const Text(
          'Bạn có bao nhiêu thời gian?',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [15, 30, 60, 90, 120]
              .map(
                (v) => ChoiceChip(
                  label: Text('$v phút'),
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: _minutes == v
                        ? AppColors.antiqueIvory
                        : AppColors.darkBrown,
                  ),
                  checkmarkColor: AppColors.antiqueIvory,
                  selected: _minutes == v,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _minutes = v),
                ),
              )
              .toList(),
        ),
        const SectionHeading('Bạn muốn khám phá điều gì?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips
              .map(
                (topic) => FilterChip(
                  label: Text(topic),
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: _selected.contains(topic)
                        ? AppColors.antiqueIvory
                        : AppColors.darkBrown,
                  ),
                  checkmarkColor: AppColors.antiqueIvory,
                  selected: _selected.contains(topic),
                  onSelected: _busy
                      ? null
                      : (selected) => setState(() {
                          if (!selected) {
                            _selected.remove(topic);
                          } else if (_selected.length < 8) {
                            _selected.add(topic);
                          } else {
                            _error = 'Bạn có thể chọn tối đa 8 sở thích.';
                          }
                        }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _interestInput,
          maxLength: 80,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: 'Thêm sở thích của bạn',
            hintText: 'Ví dụ: hoa văn, nhạc cụ, đồ đồng…',
            suffixIcon: IconButton(
              onPressed: _busy ? null : _addInterest,
              icon: const Icon(Icons.add),
            ),
          ),
          onSubmitted: (_) {
            if (!_busy) _addInterest();
          },
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Notice(_error!),
          ),
        PrimaryButton(
          label: _busy ? 'Đang chuẩn bị hành trình…' : 'Gợi ý theo sở thích',
          icon: Icons.auto_awesome_outlined,
          onPressed: id == null || _selected.isEmpty || _busy
              ? null
              : () => _run(() async {
                  final result = await PersonalizedTourApi.recommend(
                    id,
                    _minutes,
                    _selected,
                  );
                  if (!context.mounted) return;
                  await _pushTourPage(
                    context,
                    PersonalizedTourDetailScreen(plan: result),
                  );
                  if (mounted) {
                    setState(() {
                      _saved = _loadSaved();
                    });
                  }
                }),
        ),
        const SizedBox(height: 12),
        const Text(
          'Gợi ý dùng nội dung đã xuất bản và quyền truy cập của bạn. Thời lượng là ước tính; bạn có thể chọn ít điểm hơn thời gian đã dành.',
        ),
        const SectionHeading('Hành trình cá nhân đã lưu'),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _saved,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_savedFailed) {
              return Column(
                children: [
                  const Notice('Chưa tải được hành trình đã lưu.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _saved = _loadSaved();
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Notice('Bạn chưa lưu hành trình cá nhân nào.');
            }
            return Column(
              children: rows
                  .map(
                    (p) => ActionTile(
                      title: p['museumName'] as String,
                      subtitle:
                          '${(p['interests'] as List).join(', ')} · ${(p['stops'] as List).length} điểm · ${tourMinutes(p['estimatedMinutes'] as num)} phút',
                      icon: Icons.bookmark_outline,
                      onTap: () => openPage(
                        context,
                        PersonalizedTourDetailScreen(plan: p),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class PersonalizedTourDetailScreen extends StatefulWidget {
  const PersonalizedTourDetailScreen({super.key, required this.plan});
  final Map<String, dynamic> plan;
  @override
  State<PersonalizedTourDetailScreen> createState() =>
      _PersonalizedTourDetailScreenState();
}

class _PersonalizedTourDetailScreenState
    extends State<PersonalizedTourDetailScreen> {
  late Map<String, dynamic> _plan = Map.from(widget.plan);
  bool _busy = false;
  String? _error;

  Future<void> _act({bool start = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_plan['isSaved'] != true) {
        final saved = await PersonalizedTourApi.save(_plan['id'] as String);
        if (!mounted) return;
        setState(() => _plan = saved);
      }
      if (start) {
        final existing = VisitorSession.activeVisit;
        final visit =
            existing?['personalizedTourId'] == _plan['id'] &&
                existing?['status'] == 'InProgress'
            ? existing!
            : await VisitorExperienceApi.startVisit(
                _plan['museumId'] as int,
                personalizedTourId: _plan['id'] as String,
              );
        if (!mounted) return;
        await _pushTourPage(
          context,
          VisitProgressScreen(visitId: visit['id'] as int),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = (_plan['stops'] as List).cast<Map<String, dynamic>>();
    return MuseumPage(
      back: true,
      title: 'Một hành trình\ndành cho bạn.',
      eyebrow: 'Gợi ý cá nhân',
      subtitle: _plan['museumName'] as String,
      children: [
        Text(
          '${stops.length} điểm dừng · ${tourMinutes(_plan['estimatedMinutes'] as num)} / ${_plan['availableMinutes']} phút',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_plan['interests'] as List)
              .map((i) => Chip(label: Text(i as String)))
              .toList(),
        ),
        const SizedBox(height: 16),
        Notice(_plan['notice'] as String),
        const SectionHeading('Các điểm dừng'),
        for (final stop in stops) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stop['orderNo']}. ${stop['name']}',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 8),
                Text(stop['galleryName'] as String),
                Text(
                  '${tourMinutes(stop['visitMinutes'] as num)} phút khám phá · ${tourMinutes(stop['walkMinutes'] as num)} phút chuẩn bị/di chuyển',
                ),
                const SizedBox(height: 8),
                Text(stop['reason'] as String),
                TextButton(
                  onPressed: () {
                    final artifact = AppServices.catalog.artifacts
                        .where((a) => a.id == stop['artifactId'].toString())
                        .firstOrNull;
                    if (artifact != null) {
                      openPage(
                        context,
                        ArtifactDetailScreen(
                          artifact: artifact,
                          museumName: _plan['museumName'] as String,
                        ),
                      );
                    }
                  },
                  child: const Text('Xem hiện vật'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_error != null) Notice(_error!),
        if (stops.isNotEmpty) ...[
          PrimaryButton(
            label: _busy ? 'Đang xử lý…' : 'Bắt đầu hành trình này',
            icon: Icons.play_arrow_outlined,
            onPressed: _busy ? null : () => _act(start: true),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: _plan['isSaved'] == true
                ? 'Đã lưu vào hành trình của bạn'
                : 'Lưu để đi sau',
            icon: Icons.bookmark_outline,
            onPressed: _busy || _plan['isSaved'] == true ? null : () => _act(),
          ),
        ],
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Quay lại lựa chọn tham quan'),
        ),
      ],
    );
  }
}
