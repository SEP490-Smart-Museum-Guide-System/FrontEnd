import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/automatic_location_service.dart';
import '../services/museum_presence_api.dart';
import '../services/visitor_experience_api.dart';
import '../screens/museum/visitor_indoor_map_screen.dart';

class MuseumArrivalPanel extends StatefulWidget {
  const MuseumArrivalPanel({
    super.key,
    required this.museumId,
    required this.museumName,
    this.locationService,
  });
  final int museumId;
  final String museumName;
  final AutomaticLocationService? locationService;
  @override
  State<MuseumArrivalPanel> createState() => _MuseumArrivalPanelState();
}

class _MuseumArrivalPanelState extends State<MuseumArrivalPanel>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false;
  bool _scanning = false;
  int _generation = 0;
  Map<String, dynamic>? _position, _gps;
  String? _error;
  late final _location =
      widget.locationService ?? AutomaticLocationService.instance;
  DateTime? _assessedAt;
  int? get _visitId {
    final active = VisitorSession.activeVisit;
    if (active == null ||
        active['museumId'] != widget.museumId ||
        active['status'] != 'InProgress') {
      return null;
    }
    return (active['id'] as num?)?.toInt();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_locationChanged);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refresh();
      }
    });
  }

  void _locationChanged() {
    if (!mounted) return;
    if (!_location.hasFreshLocation) {
      setState(() => _gps = null);
      return;
    }
    setState(
      () {},
    ); // Arrival may change when museum metadata finishes loading.
    final time = _location.latest!.capturedAt!;
    if (_assessedAt == null ||
        time.difference(_assessedAt!) >= const Duration(seconds: 10)) {
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _location.removeListener(_locationChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy || _scanning) return;
    final generation = ++_generation;
    var readingPresence = true;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final position = await MuseumPresenceApi.current(
        widget.museumId,
        visitId: _visitId,
      );
      if (!mounted || generation != _generation) return;
      setState(() => _position = position);
      readingPresence = false;
      if (_location.hasFreshLocation) {
        if (!mounted ||
            generation != _generation ||
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed) {
          return;
        }
        final location = _location.latest!;
        _assessedAt = location.capturedAt;
        if (!mounted ||
            generation != _generation ||
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed) {
          return;
        }
        final gps = await MuseumPresenceApi.assess(widget.museumId, location);
        if (mounted &&
            generation == _generation &&
            _location.hasFreshLocation &&
            _location.latest?.capturedAt == location.capturedAt) {
          setState(() => _gps = gps);
        }
      } else {
        setState(() => _gps = null);
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _gps = null;
          _error = readingPresence
              ? 'Chưa kiểm tra được vị trí. Hãy kiểm tra kết nối rồi thử lại.'
              : e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _scan() async {
    if (_scanning) return;
    ++_generation;
    setState(() {
      _scanning = true;
      _busy = false;
    });
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PresenceQrScanner()),
    );
    if (!mounted) return;
    if (code == null) {
      setState(() => _scanning = false);
      return;
    }
    try {
      final result = await MuseumPresenceApi.scan(
        code,
        museumId: widget.museumId,
        visitId: _visitId,
      );
      if (!mounted) return;
      setState(() {
        _position = result;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xác nhận tại ${result['label'] ?? widget.museumName}.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final time = DateTime.tryParse(
      position?['confirmedAt']?.toString() ?? '',
    )?.toLocal();
    final age = time == null ? null : DateTime.now().difference(time);
    final fresh =
        position?['isFresh'] == true &&
        age != null &&
        !age.isNegative &&
        age <= const Duration(minutes: 5);
    final title = fresh
        ? 'Đã xác nhận qua QR'
        : time != null
        ? 'Vị trí xác nhận đã cũ'
        : _location.arrivedMuseum?.id == '${widget.museumId}'
        ? 'Đã đến khu vực bảo tàng (GPS)'
        : _gps?['status'] == 'nearby'
        ? 'Bạn đang ở gần bảo tàng'
        : 'Vị trí đang được cập nhật tự động';
    final details = [
      position?['label'],
      position?['galleryName'],
      position?['floorName'],
    ].whereType<String>().where((s) => s.isNotEmpty).toSet().join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (time != null)
              Text(
                '$details · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              ),
            Text(
              time != null
                  ? 'Vị trí theo lần quét gần nhất; hãy quét lại khi đổi phòng/tầng.'
                  : _location.arrivedMuseum?.id == '${widget.museumId}'
                  ? 'GPS ước tính bạn đã đến. Quét QR khi cần xác định phòng/tầng.'
                  : _gps?['message']?.toString() ??
                        'App tự theo dõi GPS khi đang sử dụng. QR giúp xác định chính xác phòng/tầng.',
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_busy) const LinearProgressIndicator(),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét QR xác nhận'),
                ),
                if (position?['mapId'] != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VisitorIndoorMapScreen(
                          mapId: position!['mapId'],
                          museumName: widget.museumName,
                          visitId: _visitId,
                        ),
                      ),
                    ),
                    child: const Text('Mở sơ đồ'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PresenceQrScanner extends StatefulWidget {
  const PresenceQrScanner({super.key});
  @override
  State<PresenceQrScanner> createState() => _PresenceQrScannerState();
}

class _PresenceQrScannerState extends State<PresenceQrScanner> {
  final _camera = MobileScannerController();
  final _input = TextEditingController();
  bool _done = false;
  @override
  void dispose() {
    _camera.dispose();
    _input.dispose();
    super.dispose();
  }

  void _accept(String code) {
    if (_done || code.trim().isEmpty) return;
    _done = true;
    Navigator.pop(context, code.trim());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quét QR cổng hoặc phòng')),
    body: Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _camera,
            onDetect: (capture) {
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) _accept(code);
            },
            errorBuilder: (_, error) => const Center(
              child: Text('Chưa mở được camera. Bạn có thể nhập mã bên dưới.'),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(
                      labelText: 'Mã QR vị trí',
                    ),
                    onSubmitted: _accept,
                  ),
                ),
                IconButton(
                  onPressed: () => _accept(_input.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
