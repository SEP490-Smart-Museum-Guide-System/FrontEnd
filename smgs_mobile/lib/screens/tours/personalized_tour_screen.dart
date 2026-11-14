import 'package:flutter/material.dart';
import '../../services/app_services.dart';
import '../../services/backend_api.dart';
import '../../services/personalized_tour_api.dart';
import '../../services/visitor_experience_api.dart';
import '../../widgets/backend_panel.dart';
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
        BackendPanel(
          resourceKey: 'active-visit-banner',
          load: () => BackendApi.list('visits/me?status=InProgress'),
          builder: (data, reload) {
            final activeVisits = (data as List).cast<Map<String, dynamic>>();
            if (activeVisits.isEmpty) return const SizedBox.shrink();
            final v = activeVisits.first;
            final mName = AppServices.catalog.museumName(v['museumId'].toString());
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mutedGold, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkBrown.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.deepBurgundy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ĐANG THAM QUAN',
                          style: TextStyle(
                            color: AppColors.antiqueIvory,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text('#${v['id']}', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mName,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v['personalizedTourId'] != null
                        ? 'Hành trình cá nhân AI đang diễn ra'
                        : (v['tourId'] != null ? 'Tour tham quan bảo tàng' : 'Lượt tham quan tự do'),
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Xem tiến độ chuyến đi',
                          icon: Icons.map_outlined,
                          height: 42,
                          onPressed: () {
                            openPage(
                              context,
                              VisitProgressScreen(visitId: v['id'] as int),
                            );
                            reload();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
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

  Future<void> _showActiveVisitConflictDialog(Map<String, dynamic> active) async {
    final activeId = active['id'] as int;
    final museumName = _plan['museumName'] as String? ?? 'bảo tàng này';
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.deepBurgundy, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Chuyến đi đang diễn ra',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đang có chuyến tham quan #$activeId tại $museumName chưa kết thúc.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Bạn có thể xem tiếp tiến độ chuyến đi này, hoặc kết thúc chuyến cũ để bắt đầu hành trình cá nhân AI vừa tạo.',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Đóng'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepBurgundy,
              side: const BorderSide(color: AppColors.deepBurgundy),
            ),
            onPressed: () => Navigator.pop(ctx, 'end_and_start'),
            child: const Text('Kết thúc cũ & Bắt đầu mới'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
            onPressed: () => Navigator.pop(ctx, 'continue'),
            child: const Text('Xem tiến độ chuyến đang đi'),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == 'cancel') return;

    if (action == 'continue') {
      await _pushTourPage(
        context,
        VisitProgressScreen(visitId: activeId),
      );
    } else if (action == 'end_and_start') {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        await BackendApi.request('visits/$activeId/complete', method: 'POST', body: {});
        VisitorSession.clear();
        final newVisit = await VisitorExperienceApi.startVisit(
          _plan['museumId'] as int,
          personalizedTourId: _plan['id'] as String,
        );
        if (!mounted) return;
        await _pushTourPage(
          context,
          VisitProgressScreen(visitId: newVisit['id'] as int),
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Lưu ý: Không thể tự đóng chuyến cũ: ${e.toString().replaceFirst("Exception: ", "")}. Hãy mở chuyến cũ để kiểm tra.';
          });
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

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
        Map<String, dynamic>? visit;
        final existing = VisitorSession.activeVisit;
        if (existing?['personalizedTourId'] == _plan['id'] &&
            existing?['status'] == 'InProgress') {
          visit = existing!;
        } else {
          try {
            visit = await VisitorExperienceApi.startVisit(
              _plan['museumId'] as int,
              personalizedTourId: _plan['id'] as String,
            );
          } catch (e) {
            final msg = e.toString();
            if (msg.contains('đang có lượt tham quan') || msg.contains('409')) {
              try {
                final list = await BackendApi.list('visits/me?status=InProgress');
                final active = list.firstWhere(
                  (v) => v['museumId'] == _plan['museumId'],
                  orElse: () => list.isNotEmpty ? list.first : <String, dynamic>{},
                );
                if (active.isNotEmpty && mounted) {
                  await _showActiveVisitConflictDialog(active);
                  return;
                }
              } catch (_) {}
            }
            rethrow;
          }
        }
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
        if (_error != null) ...[
          Notice(_error!),
          if (_error!.contains('lượt tham quan')) ...[
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Mở tiến độ chuyến đi đang diễn ra',
              icon: Icons.map_outlined,
              onPressed: () async {
                final list = await BackendApi.list('visits/me?status=InProgress');
                final active = list.firstWhere(
                  (v) => v['museumId'] == _plan['museumId'],
                  orElse: () => list.isNotEmpty ? list.first : <String, dynamic>{},
                );
                if (active.isNotEmpty && mounted) {
                  await _pushTourPage(
                    context,
                    VisitProgressScreen(visitId: active['id'] as int),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
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
