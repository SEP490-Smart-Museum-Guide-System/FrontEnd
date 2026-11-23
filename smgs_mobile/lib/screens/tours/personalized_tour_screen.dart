import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/app_preferences.dart';
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
    final isEn = AppPreferences.instance.language == 'en';
    final value = _interestInput.text.trim();
    if (value.length < 2 || value.length > 80 || _selected.length >= 8) {
      setState(
        () => _error = isEn
            ? 'Enter interest from 2 to 80 characters, maximum 8 items.'
            : 'Nhập sở thích từ 2 đến 80 ký tự, tối đa 8 lựa chọn.',
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
    final l10n = context.l10n;
    final id = int.tryParse(_museumId);
    final chips = {
      ..._topics,
      l10n.isEn ? 'History' : 'Lịch sử',
      l10n.isEn ? 'Ceramics' : 'Gốm sứ',
      l10n.isEn ? 'Fine Arts' : 'Nghệ thuật',
      l10n.isEn ? 'Culture' : 'Văn hóa',
      l10n.isEn ? 'Science' : 'Khoa học',
      ..._selected,
    };
    return MuseumPage(
      back: widget.standalone,
      title: l10n.isEn ? 'Tour your\nown way.' : 'Tham quan theo\ncách của bạn.',
      eyebrow: l10n.isEn ? 'Your Journey' : 'Hành trình của bạn',
      subtitle: l10n.isEn
          ? 'Choose curated tours, explore freely or try a custom itinerary.'
          : 'Chọn tour có sẵn, khám phá tự do hoặc thử một gợi ý cá nhân.',
      children: [
        BackendPanel(
          resourceKey: 'active-visit-banner',
          load: () async {
            try {
              return await BackendApi.list('visits/me?status=InProgress');
            } catch (_) {
              return <Map<String, dynamic>>[];
            }
          },
          builder: (data, reload) {
            final activeVisits = (data as List).cast<Map<String, dynamic>>();
            if (activeVisits.isEmpty) return const SizedBox.shrink();
            final v = activeVisits.first;
            final mName = AppServices.catalog.museumName(v['museumId'].toString());
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VisitorColors.surface1,
                borderRadius: BorderRadius.circular(VisitorRadius.xl),
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
                          borderRadius: BorderRadius.circular(VisitorRadius.xs),
                        ),
                        child: Text(
                          l10n.isEn ? 'CURRENT VISIT' : 'ĐANG THAM QUAN',
                          style: const TextStyle(
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
                        ? (l10n.isEn
                            ? 'AI personalized journey in progress'
                            : 'Hành trình cá nhân AI đang diễn ra')
                        : (v['tourId'] != null
                            ? (l10n.isEn
                                ? 'Museum tour in progress'
                                : 'Tour tham quan bảo tàng')
                            : (l10n.isEn
                                ? 'Self-guided visit'
                                : 'Lượt tham quan tự do')),
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: l10n.isEn ? 'View Trip Progress' : 'Xem tiến độ chuyến đi',
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
          decoration: InputDecoration(labelText: l10n.isEn ? 'Museum' : 'Bảo tàng'),
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
          Notice(
            l10n.isEn
                ? 'No museum selected. Please reload catalog or contact staff.'
                : 'Chưa có bảo tàng. Hãy tải lại danh mục hoặc liên hệ nhân viên.',
          ),
        const SizedBox(height: 20),
        Notice(
          l10n.isEn
              ? 'Personalization is an optional add-on. Personal journey does not replace admission tickets or purchased tours.'
              : 'Cá nhân hóa là lựa chọn thêm. Hành trình cá nhân không thay thế vé vào cửa hoặc tour bạn đã mua.',
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: l10n.isEn ? 'View Available Tours' : 'Xem tour có sẵn',
          icon: Icons.route_outlined,
          onPressed: id == null || _busy
              ? null
              : () => openPage(context, PublishedToursScreen(museumId: id)),
        ),
        TextButton.icon(
          icon: const Icon(Icons.explore_outlined),
          label: Text(l10n.isEn ? 'Self-Guided Visit' : 'Tham quan tự do'),
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
        SectionHeading(l10n.isEn ? 'Custom Itinerary Suggestions' : 'Gợi ý hành trình cá nhân'),
        Text(
          l10n.isEn ? 'How much time do you have?' : 'Bạn có bao nhiêu thời gian?',
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [15, 30, 60, 90, 120]
              .map(
                (v) => ChoiceChip(
                  label: Text(l10n.isEn ? '$v mins' : '$v phút'),
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
        SectionHeading(l10n.isEn ? 'What do you want to explore?' : 'Bạn muốn khám phá điều gì?'),
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
                            _error = l10n.isEn
                                ? 'You can select up to 8 interests.'
                                : 'Bạn có thể chọn tối đa 8 sở thích.';
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
            labelText: l10n.isEn ? 'Add your interest' : 'Thêm sở thích của bạn',
            hintText: l10n.isEn
                ? 'E.g.: patterns, instruments, bronze…'
                : 'Ví dụ: hoa văn, nhạc cụ, đồ đồng…',
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
          label: _busy
              ? (l10n.isEn ? 'Preparing journey…' : 'Đang chuẩn bị hành trình…')
              : (l10n.isEn ? 'Recommend by Interest' : 'Gợi ý theo sở thích'),
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
        Text(
          l10n.isEn
              ? 'Recommendations use published exhibits and your access permissions. Duration is an estimate; you can visit fewer stops.'
              : 'Gợi ý dùng nội dung đã xuất bản và quyền truy cập của bạn. Thời lượng là ước tính; bạn có thể chọn ít điểm hơn thời gian đã dành.',
        ),
        SectionHeading(l10n.isEn ? 'Saved Personal Journeys' : 'Hành trình cá nhân đã lưu'),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _saved,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_savedFailed) {
              return Column(
                children: [
                  Notice(l10n.isEn ? 'Unable to load saved journeys.' : 'Chưa tải được hành trình đã lưu.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _saved = _loadSaved();
                    }),
                    child: Text(l10n.isEn ? 'Retry' : 'Thử lại'),
                  ),
                ],
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return Notice(l10n.isEn ? 'You have not saved any personal journeys yet.' : 'Bạn chưa lưu hành trình cá nhân nào.');
            }
            return Column(
              children: rows
                  .map(
                    (p) => ActionTile(
                      title: p['museumName'] as String,
                      subtitle:
                          '${(p['interests'] as List).join(', ')} · ${(p['stops'] as List).length} ${l10n.isEn ? 'stops' : 'điểm'} · ${tourMinutes(p['estimatedMinutes'] as num)} ${l10n.isEn ? 'mins' : 'phút'}',
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
    final isEn = AppPreferences.instance.language == 'en';
    final activeId = active['id'] as int;
    final museumName = _plan['museumName'] as String? ?? (isEn ? 'this museum' : 'bảo tàng này');
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VisitorRadius.xl)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.deepBurgundy, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn ? 'Active Visit in Progress' : 'Chuyến đi đang diễn ra',
                style: const TextStyle(
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
              isEn
                  ? 'You have an ongoing visit #$activeId at $museumName.'
                  : 'Bạn đang có chuyến tham quan #$activeId tại $museumName chưa kết thúc.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              isEn
                  ? 'You can view the progress of this visit, or complete it to start your newly generated personalized journey.'
                  : 'Bạn có thể xem tiếp tiến độ chuyến đi này, hoặc kết thúc chuyến cũ để bắt đầu hành trình cá nhân AI vừa tạo.',
              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(isEn ? 'Close' : 'Đóng'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepBurgundy,
              side: const BorderSide(color: AppColors.deepBurgundy),
            ),
            onPressed: () => Navigator.pop(ctx, 'end_and_start'),
            child: Text(isEn ? 'End Old & Start New' : 'Kết thúc cũ & Bắt đầu mới'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
            onPressed: () => Navigator.pop(ctx, 'continue'),
            child: Text(isEn ? 'View Current Visit' : 'Xem tiến độ chuyến đang đi'),
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
            _error = isEn
                ? 'Note: Could not complete previous visit: ${e.toString().replaceFirst("Exception: ", "")}. Please open it to verify.'
                : 'Lưu ý: Không thể tự đóng chuyến cũ: ${e.toString().replaceFirst("Exception: ", "")}. Hãy mở chuyến cũ để kiểm tra.';
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
    final l10n = context.l10n;
    final stops = (_plan['stops'] as List).cast<Map<String, dynamic>>();
    final interests = (_plan['interests'] as List).cast<String>();
    final estMinutes = _plan['estimatedMinutes'] as num? ?? 0;
    final availMinutes = _plan['availableMinutes'] as num? ?? 60;
    final museumName = _plan['museumName'] as String? ?? (l10n.isEn ? 'Museum' : 'Bảo tàng');
    final notice = _plan['notice'] as String? ?? '';

    return MuseumPage(
      back: true,
      title: l10n.isEn ? 'AI Journey\nTailored for You.' : 'Hành trình AI\ndành riêng cho bạn.',
      eyebrow: l10n.isEn ? 'Personalized Itinerary' : 'Lộ trình tham quan cá nhân hóa',
      subtitle: museumName,
      children: [
        // 1. Hero Itinerary Card (May đo bởi AI)
        _buildHeroItineraryCard(
          stops,
          interests,
          estMinutes,
          availMinutes,
          museumName,
          notice,
          l10n,
        ),
        const SizedBox(height: 20),

        // 2. Section Heading
        SectionHeading(l10n.isEn ? 'Itinerary Stations' : 'Lộ trình các trạm dừng'),
        const SizedBox(height: 8),

        // 3. Vertical Connected Timeline Stations
        for (var i = 0; i < stops.length; i++) ...[
          if (i > 0) _buildTravelConnector(stops[i], l10n),
          _buildStationNode(stops[i], i + 1, museumName, l10n),
        ],

        const SizedBox(height: 20),

        // 4. Error Notice if any
        if (_error != null) ...[
          Notice(_error!),
          if (_error!.contains('lượt tham quan') || _error!.contains('visit')) ...[
            const SizedBox(height: 8),
            SecondaryButton(
              label: l10n.isEn ? 'View Current Visit Progress' : 'Mở tiến độ chuyến đi đang diễn ra',
              icon: Icons.map_outlined,
              onPressed: () async {
                final list =
                    await BackendApi.list('visits/me?status=InProgress');
                final active = list.firstWhere(
                  (v) => v['museumId'] == _plan['museumId'],
                  orElse: () =>
                      list.isNotEmpty ? list.first : <String, dynamic>{},
                );
                if (active.isNotEmpty && context.mounted) {
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

        // 5. Action Panel
        if (stops.isNotEmpty) ...[
          Panel(
            gold: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  label: _busy
                      ? (l10n.isEn ? 'Processing…' : 'Đang xử lý…')
                      : (l10n.isEn ? 'Start This Journey' : 'Bắt đầu hành trình này'),
                  icon: Icons.play_arrow_outlined,
                  onPressed: _busy ? null : () => _act(start: true),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: _plan['isSaved'] == true
                      ? (l10n.isEn ? 'Saved to Your Journeys' : 'Đã lưu vào hành trình của bạn')
                      : (l10n.isEn ? 'Save for Later' : 'Lưu để đi sau'),
                  icon: Icons.bookmark_outline,
                  onPressed:
                      _busy || _plan['isSaved'] == true ? null : () => _act(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Center(
          child: TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l10n.isEn ? 'Back to Tour Options' : 'Quay lại lựa chọn tham quan'),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroItineraryCard(
    List<Map<String, dynamic>> stops,
    List<String> interests,
    num estMinutes,
    num availMinutes,
    String museumName,
    String notice,
    AppLocalizations l10n,
  ) {
    final ratio = availMinutes > 0
        ? (estMinutes / availMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softSand,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.mutedGold.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 13, color: AppColors.deepBurgundy),
                    const SizedBox(width: 5),
                    Text(
                      l10n.isEn ? 'AI-OPTIMIZED ROUTE' : 'AI TỐI ƯU LỘ TRÌNH',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AppColors.deepBurgundy,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  museumName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Metric Blocks
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${stops.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBurgundy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.isEn ? 'Stops' : 'Điểm dừng',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.border,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "${tourMinutes(estMinutes)}' / $availMinutes'",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBurgundy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.isEn ? 'Est. / Budget' : 'Dự kiến / Dành ra',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.border,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${interests.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBurgundy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.isEn ? 'Matched Topics' : 'Chủ đề khớp',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Time budget ratio bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 5,
              color: AppColors.softSand,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.deepBurgundy,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Matched Interests Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: interests
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: VisitorColors.surface2,
                      borderRadius: BorderRadius.circular(VisitorRadius.full),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check,
                          size: 11,
                          color: AppColors.deepBurgundy,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),

          if (notice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.deepBurgundy,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notice,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelConnector(Map<String, dynamic> nextStop, AppLocalizations l10n) {
    final walk = nextStop['walkMinutes'] as num? ?? 2;
    final gallery = nextStop['galleryName'] as String? ?? (l10n.isEn ? 'Next Gallery' : 'Phòng tiếp theo');

    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 2.5,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.mutedGold,
                  AppColors.mutedGold.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: VisitorColors.surface2,
              borderRadius: BorderRadius.circular(VisitorRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 14,
                  color: AppColors.deepBurgundy,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.isEn
                      ? '${tourMinutes(walk)} mins walk to $gallery'
                      : '${tourMinutes(walk)} phút di chuyển sang $gallery',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationNode(
    Map<String, dynamic> stop,
    int orderNo,
    String museumName,
    AppLocalizations l10n,
  ) {
    final artifactId = stop['artifactId']?.toString() ?? '';
    final artifact = AppServices.catalog.artifacts
        .where((a) => a.id == artifactId)
        .firstOrNull;

    final visitMin = stop['visitMinutes'] as num? ?? 5;
    final gallery = stop['galleryName'] as String? ?? (l10n.isEn ? 'Gallery' : 'Gian trưng bày');
    final name = stop['name'] as String? ?? (l10n.isEn ? 'Artifact' : 'Hiện vật');
    final reason = stop['reason'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Header Row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.deepBurgundy,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mutedGold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepBurgundy.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$orderNo',
                      style: const TextStyle(
                        color: AppColors.antiqueIvory,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.room,
                            size: 12,
                            color: AppColors.deepBurgundy,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              gallery,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mutedGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.mutedGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: AppColors.deepBurgundy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.isEn ? '${tourMinutes(visitMin)} mins' : '${tourMinutes(visitMin)} phút',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBurgundy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content row with Thumbnail & Reason Callout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(VisitorRadius.sm),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: AppColors.antiqueIvory,
                    child: artifact?.imageUrl.isNotEmpty == true
                        ? Image.network(
                            artifact!.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.museum_outlined,
                              size: 32,
                              color: AppColors.deepBurgundy,
                            ),
                          )
                        : const Icon(
                            Icons.museum_outlined,
                            size: 32,
                            color: AppColors.deepBurgundy,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reason.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.antiqueIvory.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.mutedGold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 13,
                                color: AppColors.mutedGold,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: AppTextStyles.caption.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (artifact != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              openPage(
                                context,
                                ArtifactDetailScreen(
                                  artifact: artifact,
                                  museumName: museumName,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.isEn ? 'View artifact' : 'Xem hiện vật',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepBurgundy,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 11,
                                    color: AppColors.deepBurgundy,
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
          ],
        ),
      ),
    );
  }
}
