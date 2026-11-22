import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/museum.dart';
import 'discovery_api_service.dart';
import 'location_service.dart';

enum AutomaticLocationStatus {
  idle,
  requestingPermission,
  denied,
  deniedForever,
  disabled,
  locating,
  tracking,
  paused,
  error,
}

/// One foreground GPS subscription for the whole app, independent of routes.
/// GPS arrival is an estimate; it never creates a QR presence/room or a visit.
class AutomaticLocationService extends ChangeNotifier {
  AutomaticLocationService({
    Future<List<Museum>> Function(UserLocationResult)? fetchMuseums,
    DateTime Function()? now,
  }) : _fetchMuseums = fetchMuseums ?? _nearbyMuseums,
       _now = now ?? DateTime.now;

  static final instance = AutomaticLocationService();
  static const permissionPromptKey = 'location_permission_prompted_v1';
  static const radiusMeters = 150.0;
  static const arrivalRadiusMeters = 60.0;
  static const arrivalMaxAccuracyMeters = 25.0;
  final Future<List<Museum>> Function(UserLocationResult) _fetchMuseums;
  final DateTime Function() _now;
  AutomaticLocationStatus status = AutomaticLocationStatus.idle;
  UserLocationResult? latest;
  Museum? nearbyMuseum, arrivedMuseum;
  String? error;
  List<Museum> _museums = [];
  DateTime? _catalogAt, _candidateAt;
  String? _candidateId;
  UserLocationResult? _catalogOrigin;
  StreamSubscription<Position>? _positions;
  StreamSubscription<ServiceStatus>? _services;
  Timer? _maintenance, _retry;
  bool _foreground = false, _disposed = false;
  int _generation = 0, _lookup = 0;
  int? _pendingFixGeneration;

  bool get hasFreshLocation => latest != null && _fresh(latest!);
  bool _fresh(UserLocationResult p) {
    final age = p.capturedAt == null ? null : _now().difference(p.capturedAt!);
    return age != null &&
        age >= const Duration(seconds: -5) &&
        age <= const Duration(seconds: 30) &&
        p.latitude.isFinite &&
        p.longitude.isFinite &&
        p.latitude.abs() <= 90 &&
        p.longitude.abs() <= 180 &&
        p.accuracyMeters.isFinite &&
        p.accuracyMeters >= 0 &&
        p.accuracyMeters <= 50 &&
        !p.isMocked &&
        !p.isLastKnown;
  }

  static Future<List<Museum>> _nearbyMuseums(UserLocationResult p) =>
      DiscoveryApiService.fetchMuseums(
        latitude: p.latitude,
        longitude: p.longitude,
        sortBy: 'distance',
      );

  Future<void> start({bool requestPermission = true}) async {
    if (_disposed) return;
    _foreground = true;
    final generation = ++_generation;
    await _positions?.cancel();
    _positions = null;
    _maintenance?.cancel();
    _retry?.cancel();
    bool current() => !_disposed && _foreground && generation == _generation;
    try {
      var permission = await Geolocator.checkPermission();
      if (!current()) return;
      if (permission == LocationPermission.denied && requestPermission) {
        final prefs = await SharedPreferences.getInstance();
        if (!current()) return;
        if (prefs.getBool(permissionPromptKey) != true) {
          // Persist before opening the OS dialog, so denial is not nagged on resume.
          await prefs.setBool(permissionPromptKey, true);
          if (!current()) return;
          _setStatus(AutomaticLocationStatus.requestingPermission);
          permission = await Geolocator.requestPermission();
        }
      }
      if (!current()) return;
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _clearLocation();
        _setStatus(
          permission == LocationPermission.deniedForever
              ? AutomaticLocationStatus.deniedForever
              : AutomaticLocationStatus.denied,
        );
        return;
      }
      _watchService();
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (current()) {
          _clearLocation();
          _setStatus(AutomaticLocationStatus.disabled);
        }
        return;
      }
      if (!current()) return;
      _setStatus(AutomaticLocationStatus.locating);
      final settings =
          defaultTargetPlatform == TargetPlatform.android && !kIsWeb
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 3),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            );
      _positions = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
            (position) {
              if (current()) _receive(position);
            },
            onError: (Object _) {
              if (current()) _failed();
            },
            onDone: () {
              if (current()) _failed();
            },
          );
      _maintenance = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!current()) return;
        if (!hasFreshLocation) {
          if (latest != null) {
            _clearLocation();
            _setStatus(AutomaticLocationStatus.locating);
          }
          unawaited(_initialFix(generation));
        }
      });
      unawaited(_initialFix(generation));
    } catch (_) {
      if (current()) _failed();
    }
  }

  void _watchService() {
    if (kIsWeb || _services != null) return;
    try {
      _services = Geolocator.getServiceStatusStream().listen(
        (value) {
          if (!_foreground || _disposed) return;
          if (value == ServiceStatus.disabled) {
            _generation++;
            unawaited(_positions?.cancel());
            _positions = null;
            _clearLocation();
            _setStatus(AutomaticLocationStatus.disabled);
          } else {
            unawaited(start(requestPermission: false));
          }
        },
        onError: (Object _) {
          /* Position stream and resume still recover without this optional feed. */
        },
      );
    } catch (_) {
      // Some platforms support positions but not GPS service status events.
    }
  }

  Future<void> _initialFix(int generation) async {
    if (_pendingFixGeneration == generation) return;
    _pendingFixGeneration = generation;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!_disposed && _foreground && generation == _generation) {
        _receive(position);
      }
    } catch (_) {
      if (!_disposed &&
          _foreground &&
          generation == _generation &&
          !hasFreshLocation) {
        _failed();
      }
    } finally {
      if (_pendingFixGeneration == generation) _pendingFixGeneration = null;
    }
  }

  void _receive(Position position) {
    if (latest?.capturedAt != null &&
        position.timestamp.isBefore(latest!.capturedAt!)) {
      return;
    }
    final sample = UserLocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      capturedAt: position.timestamp,
      isMocked: position.isMocked,
    );
    if (!_fresh(sample)) {
      _clearLocation();
      _setStatus(
        AutomaticLocationStatus.locating,
        'GPS chưa đủ chính xác. Đang tự cập nhật vị trí…',
      );
      return;
    }
    if (latest != null && !hasFreshLocation) _clearLocation();
    latest = sample;
    status = AutomaticLocationStatus.tracking;
    error = null;
    _evaluateArrival();
    notifyListeners();
    final moved = _catalogOrigin == null
        ? double.infinity
        : Geolocator.distanceBetween(
            sample.latitude,
            sample.longitude,
            _catalogOrigin!.latitude,
            _catalogOrigin!.longitude,
          );
    if (_catalogAt == null ||
        _now().difference(_catalogAt!) >= const Duration(minutes: 1) ||
        moved > 100) {
      // Timestamp the attempt too, to avoid flooding a failing API on every fix.
      _catalogAt = _now();
      _catalogOrigin = sample;
      unawaited(_loadMuseums(sample, _generation));
    }
  }

  Future<void> _loadMuseums(UserLocationResult sample, int generation) async {
    final lookup = ++_lookup;
    try {
      final museums = await _fetchMuseums(sample);
      if (_disposed ||
          !_foreground ||
          generation != _generation ||
          lookup != _lookup) {
        return;
      }
      _museums = museums;
      _evaluateArrival();
      notifyListeners();
    } catch (_) {
      if (_disposed ||
          !_foreground ||
          generation != _generation ||
          lookup != _lookup) {
        return;
      }
      _museums = [];
      _evaluateArrival();
      error = 'Chưa tải được bảo tàng gần bạn. Hệ thống sẽ tự thử lại.';
      notifyListeners();
    }
  }

  void _evaluateArrival() {
    final sample = latest;
    nearbyMuseum = null;
    var insideArrivalZone = false;
    if (sample != null && hasFreshLocation) {
      var possibleMuseums = 0;
      for (final museum in _museums) {
        if (!museum.googleMapsVisible || !museum.hasCoordinates) continue;
        final distance = Geolocator.distanceBetween(
          sample.latitude,
          sample.longitude,
          museum.latitude!,
          museum.longitude!,
        );
        if (distance - sample.accuracyMeters > radiusMeters) continue;
        // Even a partial overlap with a second museum makes the fix ambiguous.
        if (++possibleMuseums > 1) {
          nearbyMuseum = null;
          break;
        }
        if (distance + sample.accuracyMeters <= radiusMeters) {
          nearbyMuseum = museum;
          insideArrivalZone =
              sample.accuracyMeters <= arrivalMaxAccuracyMeters &&
              distance + sample.accuracyMeters <= arrivalRadiusMeters;
        }
      }
    }
    if (nearbyMuseum == null || !insideArrivalZone) {
      _candidateId = null;
      _candidateAt = null;
      arrivedMuseum = null;
      return;
    }
    if (_candidateId != nearbyMuseum!.id) {
      _candidateId = nearbyMuseum!.id;
      _candidateAt = sample!.capturedAt;
      arrivedMuseum = null;
    } else if (sample!.capturedAt!.difference(_candidateAt!) >=
        const Duration(seconds: 5)) {
      arrivedMuseum = nearbyMuseum;
    }
  }

  void _clearLocation() {
    latest = null;
    nearbyMuseum = arrivedMuseum = null;
    _candidateId = null;
    _candidateAt = null;
  }

  void _setStatus(AutomaticLocationStatus value, [String? message]) {
    status = value;
    error = message;
    if (!_disposed) notifyListeners();
  }

  void _failed() {
    _generation++;
    unawaited(_positions?.cancel());
    _positions = null;
    _clearLocation();
    _setStatus(
      AutomaticLocationStatus.error,
      'Chưa lấy được GPS. Đang tự thử lại…',
    );
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 15), () {
      if (_foreground && !_disposed) unawaited(start(requestPermission: false));
    });
  }

  void pause() {
    _foreground = false;
    _generation++;
    unawaited(_positions?.cancel());
    _positions = null;
    _maintenance?.cancel();
    _retry?.cancel();
    _clearLocation();
    _setStatus(AutomaticLocationStatus.paused);
  }

  @override
  void dispose() {
    pause();
    _disposed = true;
    unawaited(_services?.cancel());
    super.dispose();
  }
}
