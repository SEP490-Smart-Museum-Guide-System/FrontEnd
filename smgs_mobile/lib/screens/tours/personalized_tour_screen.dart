import 'package:flutter/material.dart';
import '../../widgets/earned_badges.dart';
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
  String? _validationError;
  final _interestInput = TextEditingController();
  final Set<String> _selected = {};
  final Set<int> _selectedTopicIds = {};
  List<Map<String, dynamic>> _topicsMap = [];
  List<String> _topics = [];
  bool _savedFailed = false;
  late Future<List<Map<String, dynamic>>> _saved = _loadSaved();

  // Curated Recommendation (WF-02) State
  bool _isRecommendingCurated = false;
  Map<String, dynamic>? _curatedRecommendation;
  String? _curatedError;
  bool _savingCurated = false;
  int? _savedTourVersionId;

  Future<List<Map<String, dynamic>>> _loadSaved() async {
    _savedFailed = false;
    final combined = <Map<String, dynamic>>[];
    final parsedMuseumId = int.tryParse(_museumId);

    try {
      final savedRoutes = await VisitorExperienceApi.getSavedRoutes(museumId: parsedMuseumId);
      for (final r in savedRoutes) {
        combined.add({...r, '_itemKind': 'curated_saved'});
      }
    } catch (_) {}

    try {
      final aiSaved = await PersonalizedTourApi.saved();
      for (final p in aiSaved) {
        combined.add({...p, '_itemKind': 'ai_saved'});
      }
    } catch (_) {}

    return combined;
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
      final rows = await VisitorExperienceApi.getMuseumTopics(id);
      if (mounted && _museumId == id.toString() && rows.isNotEmpty) {
        setState(() {
          _topicsMap = rows;
          _topics = rows.map((r) => (r['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
        });
        return;
      }
    } catch (_) {}

    try {
      final rows = await PersonalizedTourApi.interests(id);
      if (mounted && _museumId == id.toString()) {
        setState(() {
          _topicsMap = rows;
          _topics = rows.map((r) => (r['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
        });
      }
    } catch (_) {
      if (mounted && _museumId == id.toString()) {
        setState(() {
          _topicsMap = [];
          _topics = [];
        });
      }
    }
  }

  bool _validateInputs(AppLocalizations l10n) {
    if (_selected.isEmpty && _selectedTopicIds.isEmpty) {
      setState(() {
        _validationError = l10n.isEn
            ? 'Please select at least one topic of interest.'
            : 'Vui lòng chọn ít nhất một chủ đề bạn quan tâm.';
      });
      return false;
    }
    setState(() => _validationError = null);
    return true;
  }

  Future<void> _onRecommendCurated(int museumId, AppLocalizations l10n) async {
    if (!_validateInputs(l10n)) return;
    setState(() {
      _isRecommendingCurated = true;
      _curatedError = null;
      _curatedRecommendation = null;
    });
    try {
      final res = await VisitorExperienceApi.recommendCuratedTour(
        museumId: museumId,
        availableMinutes: _minutes,
        topicIds: _selectedTopicIds.toList(),
      );
      if (mounted) {
        setState(() => _curatedRecommendation = res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _curatedError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isRecommendingCurated = false);
      }
    }
  }

  Future<void> _onGenerateAITour(int museumId, AppLocalizations l10n) async {
    if (!_validateInputs(l10n)) return;
    await _run(() async {
      final result = await PersonalizedTourApi.recommend(
        museumId,
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
    });
  }

  Future<void> _startCuratedVisit(
    int museumId,
    int tourId, {
    int? tourVersionId,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Tự động lưu vào Hành trình cá nhân đã lưu khi khách bấm Bắt đầu hành trình
      try {
        int? resolvedVersionId = tourVersionId;
        if (resolvedVersionId == null) {
          final verRes = await BackendApi.request('tours/$tourId/public-version');
          resolvedVersionId = verRes['id'] as int?;
        }
        if (resolvedVersionId != null) {
          await VisitorExperienceApi.saveRoute(
            tourVersionId: resolvedVersionId,
            availableMinutes: _minutes,
            topicIds: _selectedTopicIds.toList(),
          );
          if (mounted) {
            final nextSaved = _loadSaved();
            setState(() {
              _savedTourVersionId = resolvedVersionId;
              _saved = nextSaved;
            });
          }
        }
      } catch (_) {}

      final visit = await VisitorExperienceApi.startVisit(
        museumId,
        tourId: tourId,
      );
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VisitProgressScreen(
              visitId: visit['id'] as int,
            ),
          ),
        );
        if (mounted) {
          final nextSaved = _loadSaved();
          setState(() {
            _saved = nextSaved;
          });
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('đang có lượt tham quan') || msg.contains('409')) {
        try {
          final list = await BackendApi.list('visits/me?status=InProgress');
          final active = list.firstWhere(
            (v) => v['museumId'] == museumId,
            orElse: () => list.isNotEmpty ? list.first : <String, dynamic>{},
          );
          if (active.isNotEmpty && mounted) {
            await _showCuratedVisitConflictDialog(museumId, tourId, active);
            return;
          }
        } catch (_) {}
      }
      if (mounted) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCuratedVisitConflictDialog(
    int museumId,
    int tourId,
    Map<String, dynamic> active,
  ) async {
    final isEn = AppPreferences.instance.language == 'en';
    final activeId = active['id'] as int;
    final museumName = AppServices.catalog.museumName(museumId.toString());
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
        content: Text(
          isEn
              ? 'You already have an active visit #$activeId at $museumName. Would you like to continue watching your current visit progress?'
              : 'Bạn đang có lượt tham quan #$activeId đang diễn ra tại $museumName. Bạn có muốn mở tiếp tiến độ chuyến đi này không?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(isEn ? 'Close' : 'Đóng'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.deepBurgundy),
            onPressed: () => Navigator.pop(ctx, 'continue'),
            child: Text(isEn ? 'View Current Visit' : 'Xem tiến độ chuyến đang đi'),
          ),
        ],
      ),
    );
    if (!mounted || action != 'continue') return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisitProgressScreen(visitId: activeId),
      ),
    );
  }

  Future<void> _openOrStartSavedCuratedRoute(Map<String, dynamic> savedRoute) async {
    final museumId = (savedRoute['museumId'] as int?) ?? int.tryParse(_museumId);
    final tourId = savedRoute['tourId'] as int?;
    final savedRouteId = savedRoute['id'] as int?;
    if (museumId == null || tourId == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final activeVisits = await BackendApi.list('visits/me?status=InProgress');
      final active = activeVisits.cast<Map<String, dynamic>>().firstWhere(
        (v) => v['museumId'] == museumId,
        orElse: () => <String, dynamic>{},
      );

      if (active.isNotEmpty) {
        final activeId = active['id'] as int;
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => VisitProgressScreen(visitId: activeId),
            ),
          );
          if (mounted) {
            final nextSaved = _loadSaved();
            setState(() {
              _saved = nextSaved;
            });
          }
        }
        return;
      }

      final visit = await BackendApi.request(
        'visits',
        method: 'POST',
        body: {
          'museumId': museumId,
          if (savedRouteId != null) 'savedRouteId': savedRouteId else 'tourId': tourId,
        },
      );
      final visitMap = Map<String, dynamic>.from(visit);
      VisitorSession.activeVisit = visitMap;
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VisitProgressScreen(visitId: visitMap['id'] as int),
          ),
        );
        if (mounted) {
          final nextSaved = _loadSaved();
          setState(() {
            _saved = nextSaved;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
    final chips = <String>{
      ..._topics,
      if (_topics.isEmpty) ...[
        l10n.isEn ? 'History' : 'Lịch sử',
        l10n.isEn ? 'Ceramics' : 'Gốm sứ',
        l10n.isEn ? 'Fine Arts' : 'Nghệ thuật',
        l10n.isEn ? 'Culture' : 'Văn hóa',
        l10n.isEn ? 'Science' : 'Khoa học',
      ],
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
              final list = (await BackendApi.list('visits/me?status=InProgress')).cast<Map<String, dynamic>>();
              if (list.isEmpty) return <Map<String, dynamic>>[];
              final v = Map<String, dynamic>.from(list.first);
              final tourId = v['tourId'] as int?;
              if (tourId != null) {
                try {
                  final tour = await BackendApi.request('tours/$tourId');
                  if (tour is Map && tour['title'] != null) {
                    v['_resolvedTourTitle'] = tour['title'].toString();
                  }
                } catch (_) {}
              }
              return [v];
            } catch (_) {
              return <Map<String, dynamic>>[];
            }
          },
          builder: (data, reload) {
            final activeVisits = (data as List).cast<Map<String, dynamic>>();
            if (activeVisits.isEmpty) return const SizedBox.shrink();
            final v = activeVisits.first;
            final mName = AppServices.catalog.museumName(v['museumId'].toString());
            final tourTitle = (v['_resolvedTourTitle'] ?? v['tourTitle'] ?? '').toString();
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
                        : (tourTitle.isNotEmpty
                            ? tourTitle
                            : (v['tourId'] != null
                                ? (l10n.isEn
                                    ? 'Museum tour in progress'
                                    : 'Tour tham quan bảo tàng')
                                : (l10n.isEn
                                    ? 'Self-guided visit'
                                    : 'Lượt tham quan tự do'))),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.deepBurgundy,
                      fontWeight: FontWeight.w600,
                    ),
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
                  final nextSaved = _loadSaved();
                  setState(() {
                    _museumId = value;
                    _topics = [];
                    _error = null;
                    _saved = nextSaved;
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
        const SizedBox(height: 16),
        Notice(
          l10n.isEn
              ? 'Personalization is an optional add-on. Personal journey does not replace admission tickets or purchased tours.'
              : 'Cá nhân hóa là lựa chọn thêm. Hành trình cá nhân không thay thế vé vào cửa hoặc tour bạn đã mua.',
        ),
        const SizedBox(height: 12),
        // ===== TẦNG 1: TOUR HIỆN CÓ (CAROUSEL VUỐT NGANG + XEM TẤT CẢ) =====
        if (id != null)
          BackendPanel(
            resourceKey: 'published-tours:$_museumId',
            load: () async {
              try {
                return await BackendApi.list('tours?museumId=$id');
              } catch (_) {
                return <Map<String, dynamic>>[];
              }
            },
            builder: (data, reload) {
              final tours = (data as List).cast<Map<String, dynamic>>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SectionHeading(
                          l10n.isEn ? 'Official Museum Tours' : 'Tour hiện có của bảo tàng',
                        ),
                      ),
                      if (tours.isNotEmpty)
                        InkWell(
                          onTap: () => openPage(
                            context,
                            PublishedToursScreen(museumId: id),
                          ),
                          borderRadius: BorderRadius.circular(VisitorRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.isEn
                                      ? 'See all (${tours.length})'
                                      : 'Xem tất cả (${tours.length})',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.deepBurgundy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: AppColors.deepBurgundy,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    l10n.isEn
                        ? 'Swipe to explore curated routes approved by museum experts.'
                        : 'Vuốt ngang để khám phá các tuyến tiêu biểu do giám tuyển phê duyệt.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.darkBrown.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 12),
                  if (tours.isEmpty)
                    Notice(
                      l10n.isEn
                          ? 'No official tours available for this museum yet.'
                          : 'Hiện chưa có tour chính thức nào được công bố.',
                    )
                  else
                    SizedBox(
                      height: 146,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: tours.length > 6 ? 7 : tours.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          if (index == 6 && tours.length > 6) {
                            return InkWell(
                              onTap: () => openPage(
                                context,
                                PublishedToursScreen(museumId: id),
                              ),
                              borderRadius: BorderRadius.circular(VisitorRadius.xl),
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: VisitorColors.surface2,
                                  borderRadius: BorderRadius.circular(VisitorRadius.xl),
                                  border: Border.all(color: AppColors.mutedGold.withOpacity(0.5)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: AppColors.deepBurgundy,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColors.antiqueIvory,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      l10n.isEn
                                          ? 'View all\n${tours.length} tours'
                                          : 'Xem tất cả\n${tours.length} tuyến',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.deepBurgundy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final tour = tours[index];
                          final tourId = tour['id'] as int;
                          final title = (tour['title'] ?? '').toString();
                          final desc = (tour['description'] ?? '').toString();
                          final minutes = tour['estimatedMinutes'] ?? 45;
                          final stopCount = (tour['items'] as List?)?.length ?? 0;

                          return InkWell(
                            onTap: () => openPage(
                              context,
                              PublishedTourDetailScreen(tourId: tourId),
                            ),
                            borderRadius: BorderRadius.circular(VisitorRadius.xl),
                            child: Container(
                              width: 248,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: VisitorColors.surface1,
                                borderRadius: BorderRadius.circular(VisitorRadius.xl),
                                border: Border.all(
                                  color: AppColors.mutedGold.withOpacity(0.35),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.deepBurgundy.withOpacity(0.05),
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
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.deepBurgundy,
                                          borderRadius: BorderRadius.circular(VisitorRadius.sm),
                                        ),
                                        child: const Icon(
                                          Icons.route_outlined,
                                          color: AppColors.antiqueIvory,
                                          size: 17,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: VisitorColors.surface2,
                                          borderRadius: BorderRadius.circular(VisitorRadius.full),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 12,
                                              color: AppColors.deepBurgundy,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.isEn ? '$minutes mins' : '$minutes phút',
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.deepBurgundy,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: AppColors.darkBrown.withOpacity(0.35),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Expanded(
                                    child: Text(
                                      desc.isNotEmpty
                                          ? desc
                                          : (l10n.isEn
                                              ? 'Official curated museum route'
                                              : 'Tuyến tham quan chính thức của bảo tàng'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.darkBrown.withOpacity(0.65),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flag_outlined,
                                        size: 13,
                                        color: AppColors.darkBrown.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.isEn ? '$stopCount stops' : '$stopCount điểm dừng',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.darkBrown.withOpacity(0.75),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        l10n.isEn ? 'Details' : 'Chi tiết',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.deepBurgundy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),

        // ===== TẦNG 2: BỘ CHỌN THỜI GIAN & CHỦ ĐỀ (BẮT BUỘC) =====
        SectionHeading(l10n.isEn ? 'Personalize Your Journey' : 'Tùy biến hành trình theo sở thích'),
        Text(
          l10n.isEn
              ? 'Tell us your time and interests to get a customized tour recommendation.'
              : 'Chọn thời gian và chủ đề bạn yêu thích để nhận gợi ý lộ trình phù hợp.',
          style: AppTextStyles.caption.copyWith(color: AppColors.darkBrown.withOpacity(0.85), height: 1.3),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            text: l10n.isEn ? 'How much time do you have?' : 'Bạn có bao nhiêu thời gian?',
            style: AppTextStyles.cardTitle,
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [15, 30, 45, 60, 90, 120]
              .map(
                (v) => ChoiceChip(
                  label: Text(l10n.isEn ? '$v mins' : '$v phút'),
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: _minutes == v
                        ? AppColors.antiqueIvory
                        : AppColors.darkBrown,
                    fontWeight: _minutes == v ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: AppColors.antiqueIvory,
                  selected: _minutes == v,
                  selectedColor: AppColors.deepBurgundy,
                  backgroundColor: VisitorColors.surface2,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() {
                          _minutes = v;
                          _validationError = null;
                        }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            text: l10n.isEn ? 'Interested topics:' : 'Chủ đề quan tâm:',
            style: AppTextStyles.cardTitle,
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips
              .map(
                (topic) {
                  final isSelected = _selected.contains(topic);
                  final matchedMap = _topicsMap.firstWhere(
                    (m) => (m['name'] ?? '').toString() == topic,
                    orElse: () => <String, dynamic>{},
                  );
                  final topicId = matchedMap['id'] as int?;

                  return FilterChip(
                    label: Text(topic),
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.antiqueIvory
                          : AppColors.darkBrown,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    checkmarkColor: AppColors.antiqueIvory,
                    selected: isSelected,
                    selectedColor: AppColors.deepBurgundy,
                    backgroundColor: VisitorColors.surface2,
                    onSelected: _busy
                        ? null
                        : (selected) => setState(() {
                            _validationError = null;
                            if (!selected) {
                              _selected.remove(topic);
                              if (topicId != null) _selectedTopicIds.remove(topicId);
                            } else if (_selected.length < 8) {
                              _selected.add(topic);
                              if (topicId != null) _selectedTopicIds.add(topicId);
                            } else {
                              _error = l10n.isEn
                                  ? 'You can select up to 8 interests.'
                                  : 'Bạn có thể chọn tối đa 8 sở thích.';
                            }
                          }),
                  );
                },
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _interestInput,
          maxLength: 80,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: l10n.isEn ? 'Add custom interest (optional)' : 'Thêm sở thích khác (tùy chọn)',
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
        if (_validationError != null) ...[
          const SizedBox(height: 8),
          Notice(_validationError!),
        ],
        if (_curatedError != null) ...[
          const SizedBox(height: 8),
          Notice(_curatedError!),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Notice(_error!),
        ],
        const SizedBox(height: 16),

        // ===== TẦNG 3: KẾT QUẢ GỢI Ý HOẶC 2 NÚT HÀNH ĐỘNG =====
        if (_curatedRecommendation != null) ...[
          _buildCuratedResultCard(context, l10n, id),
          const SizedBox(height: 16),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepBurgundy,
                      foregroundColor: AppColors.antiqueIvory,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VisitorRadius.lg),
                      ),
                    ),
                    onPressed: id == null || _isRecommendingCurated || _busy
                        ? null
                        : () => _onRecommendCurated(id, l10n),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRecommendingCurated ? Icons.hourglass_empty : Icons.psychology_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _isRecommendingCurated
                                  ? (l10n.isEn ? 'Finding Tour…' : 'Đang tìm tour…')
                                  : (l10n.isEn ? 'Match Curated Tour' : 'Chọn tour phù hợp'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: VisitorColors.surface2,
                      foregroundColor: AppColors.darkBrown,
                      side: BorderSide.none,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VisitorRadius.lg),
                      ),
                    ),
                    onPressed: id == null || _isRecommendingCurated || _busy
                        ? null
                        : () => _onGenerateAITour(id, l10n),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _busy ? Icons.hourglass_empty : Icons.auto_awesome_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _busy
                                  ? (l10n.isEn ? 'AI Working…' : 'AI đang xử lý…')
                                  : (l10n.isEn ? 'AI Custom Route' : 'Tour AI hóa'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
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
                    onPressed: () {
                      final nextSaved = _loadSaved();
                      setState(() {
                        _saved = nextSaved;
                      });
                    },
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
                    (p) {
                      if (p['_itemKind'] == 'curated_saved') {
                        final title = (p['title'] ?? (l10n.isEn ? 'Saved Route' : 'Lộ trình đã lưu')).toString();
                        final stopCount = (p['artifactIds'] as List?)?.length ?? 0;
                        final estMin = p['estimatedMinutes'] ?? p['availableMinutes'] ?? 45;
                        return ActionTile(
                          title: title,
                          subtitle: l10n.isEn
                              ? '$stopCount stops · $estMin mins'
                              : '$stopCount điểm dừng · $estMin phút',
                          icon: Icons.bookmark_rounded,
                          onTap: () => _openOrStartSavedCuratedRoute(p),
                        );
                      }
                      return ActionTile(
                        title: (p['museumName'] ?? (l10n.isEn ? 'Personal Journey' : 'Hành trình cá nhân')).toString(),
                        subtitle:
                            '${((p['interests'] as List?) ?? []).join(', ')} · ${((p['stops'] as List?) ?? []).length} ${l10n.isEn ? 'stops' : 'điểm'} · ${tourMinutes((p['estimatedMinutes'] as num?) ?? 45)} ${l10n.isEn ? 'mins' : 'phút'}',
                        icon: Icons.bookmark_outline,
                        onTap: () => openPage(
                          context,
                          PersonalizedTourDetailScreen(plan: p),
                        ),
                      );
                    },
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCuratedResultCard(BuildContext context, AppLocalizations l10n, int? museumId) {
    final recs = (_curatedRecommendation!['recommendations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final fallbackExplanation = _curatedRecommendation!['fallbackExplanation'] as String?;
    final fallbackSuggestion = _curatedRecommendation!['fallbackSuggestion'] as Map<String, dynamic>?;

    if (recs.isEmpty) {
      final fbTourId = fallbackSuggestion?['tourId'] as int?;
      final fbVersionId = fallbackSuggestion?['tourVersionId'] as int?;
      final fbStopCount = (fallbackSuggestion?['artifactIds'] as List?)?.length ?? 0;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VisitorColors.surface1,
          borderRadius: BorderRadius.circular(VisitorRadius.xl),
          border: Border.all(color: AppColors.mutedGold),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.deepBurgundy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fallbackExplanation ?? (l10n.isEn ? 'No matching curated tour found.' : 'Không tìm thấy tour có sẵn phù hợp với yêu cầu.'),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
            if (fallbackSuggestion != null && fbTourId != null) ...[
              const SizedBox(height: 14),
              Text(
                l10n.isEn ? 'Suggested alternative route:' : 'Lộ trình thay thế phù hợp nhất:',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBurgundy,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VisitorColors.surface2,
                  borderRadius: BorderRadius.circular(VisitorRadius.lg),
                  border: Border.all(color: AppColors.mutedGold.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fallbackSuggestion['title'] ?? '',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.isEn
                          ? '${fallbackSuggestion['estimatedMinutes']} mins · $fbStopCount stops'
                          : '${fallbackSuggestion['estimatedMinutes']} phút · $fbStopCount điểm dừng',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: l10n.isEn ? 'Start Route' : 'Bắt đầu hành trình',
                            icon: Icons.play_arrow_rounded,
                            height: 38,
                            onPressed: museumId == null || _busy
                                ? null
                                : () => _startCuratedVisit(
                                      museumId,
                                      fbTourId,
                                      tourVersionId: fbVersionId,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.isEn ? 'Details' : 'Xem chi tiết',
                            icon: Icons.visibility_outlined,
                            height: 38,
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PublishedTourDetailScreen(
                                    tourId: fbTourId,
                                    selectedTopicIds: _selectedTopicIds.toList(),
                                    availableMinutes: _minutes,
                                  ),
                                ),
                              );
                              if (mounted) {
                                final nextSaved = _loadSaved();
                                setState(() {
                                  _saved = nextSaved;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.isEn ? 'Back to Selection' : 'Quay lại chọn lại'),
              onPressed: () => setState(() => _curatedRecommendation = null),
            ),
          ],
        ),
      );
    }

    final rec = recs.first;
    final tourId = rec['tourId'] as int;
    final tourVersionId = rec['tourVersionId'] as int;
    final totalScore = rec['totalScore'] is num ? (rec['totalScore'] as num).toDouble() : 1.0;
    final matchPercent = (totalScore * 100).toInt().clamp(0, 100);
    final explanation = (rec['explanation'] ?? '').toString();
    final artifactCount = (rec['artifactIds'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VisitorColors.surface1,
        borderRadius: BorderRadius.circular(VisitorRadius.xl),
        border: Border.all(color: AppColors.mutedGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBurgundy.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepBurgundy,
                  borderRadius: BorderRadius.circular(VisitorRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.antiqueIvory),
                    const SizedBox(width: 4),
                    Text(
                      l10n.isEn ? 'Best Match: $matchPercent%' : 'Khớp $matchPercent%',
                      style: const TextStyle(
                        color: AppColors.antiqueIvory,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                l10n.isEn ? 'Curated Recommendation' : 'Gợi ý từ tour có sẵn',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rec['title'] ?? '',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if ((rec['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rec['description'],
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.darkBrown.withOpacity(0.8)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AppColors.darkBrown.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.isEn ? '${rec['estimatedMinutes']} mins' : '${rec['estimatedMinutes']} phút',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 14, color: AppColors.darkBrown.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.isEn ? '$artifactCount stops' : '$artifactCount điểm dừng',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VisitorColors.surface2,
                borderRadius: BorderRadius.circular(VisitorRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.deepBurgundy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanation,
                      style: AppTextStyles.caption.copyWith(color: AppColors.darkBrown),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.isEn ? 'Start This Journey' : 'Bắt đầu hành trình',
            icon: Icons.play_arrow_rounded,
            onPressed: museumId == null || _busy
                ? null
                : () => _startCuratedVisit(
                      museumId,
                      tourId,
                      tourVersionId: tourVersionId,
                    ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.isEn ? 'Tour Details' : 'Xem chi tiết',
                  icon: Icons.visibility_outlined,
                  height: 38,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PublishedTourDetailScreen(
                          tourId: tourId,
                          selectedTopicIds: _selectedTopicIds.toList(),
                          availableMinutes: _minutes,
                        ),
                      ),
                    );
                    if (mounted) {
                      final nextSaved = _loadSaved();
                      setState(() {
                        _saved = nextSaved;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBrown,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(
                    l10n.isEn ? 'Change' : 'Quay lại',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => setState(() => _curatedRecommendation = null),
                ),
              ),
            ],
          ),
          if (recs.length > 1) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              l10n.isEn
                  ? 'Other matching routes (${recs.length - 1}):'
                  : 'Các lộ trình phù hợp khác (${recs.length - 1}):',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            ...recs.skip(1).map((alt) {
              final altTourId = alt['tourId'] as int;
              final altScore = alt['totalScore'] is num ? (alt['totalScore'] as num).toDouble() : 0.8;
              final altPercent = (altScore * 100).toInt().clamp(0, 100);
              final altStops = (alt['artifactIds'] as List?)?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PublishedTourDetailScreen(
                          tourId: altTourId,
                          selectedTopicIds: _selectedTopicIds.toList(),
                          availableMinutes: _minutes,
                        ),
                      ),
                    );
                    if (mounted) {
                      final nextSaved = _loadSaved();
                      setState(() {
                        _saved = nextSaved;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(VisitorRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: VisitorColors.surface2,
                      borderRadius: BorderRadius.circular(VisitorRadius.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.deepBurgundy.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(VisitorRadius.xs),
                          ),
                          child: Text(
                            '$altPercent%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepBurgundy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (alt['title'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                l10n.isEn
                                    ? '${alt['estimatedMinutes']} mins · $altStops stops'
                                    : '${alt['estimatedMinutes']} phút · $altStops điểm dừng',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.deepBurgundy,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
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
        final rewards = await BackendApi.request('visits/$activeId/complete', method: 'POST', body: {});
        if (mounted) showExplorationRewards(context, rewards);
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
