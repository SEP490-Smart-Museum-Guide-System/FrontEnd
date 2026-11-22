import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/museum.dart';
import '../services/automatic_location_service.dart';

/// Mounted above Navigator: changing tabs/screens never stops GPS tracking.
class AutomaticLocationHost extends StatefulWidget {
  const AutomaticLocationHost({
    super.key,
    required this.child,
    this.service,
    this.messengerKey,
  });
  final Widget child;
  final AutomaticLocationService? service;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;
  @override
  State<AutomaticLocationHost> createState() => _AutomaticLocationHostState();
}

class _AutomaticLocationHostState extends State<AutomaticLocationHost>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? AutomaticLocationService.instance;
  Museum? _announcedMuseum;
  bool _started = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_arrivalChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          !_started &&
          (WidgetsBinding.instance.lifecycleState == null ||
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed)) {
        _start();
      }
    });
  }

  void _start() {
    final firstLaunch = !_started;
    _started = true;
    unawaited(_service.start(requestPermission: firstLaunch));
  }

  void _arrivalChanged() {
    final museum = _service.arrivedMuseum;
    if (museum == null) {
      final previous = _announcedMuseum;
      final fix = _service.latest;
      if (previous != null && fix != null && _service.hasFreshLocation) {
        final distance = Geolocator.distanceBetween(
          fix.latitude,
          fix.longitude,
          previous.latitude!,
          previous.longitude!,
        );
        if (distance - fix.accuracyMeters >
            AutomaticLocationService.radiusMeters) {
          _announcedMuseum = null;
        }
      }
      return;
    }
    if (_announcedMuseum?.id == museum.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _service.arrivedMuseum?.id != museum.id ||
          _announcedMuseum?.id == museum.id) {
        return;
      }
      final messenger = widget.messengerKey?.currentState;
      if (messenger == null) return;
      _announcedMuseum = museum;
      messenger.showSnackBar(
        SnackBar(content: Text('Đã đến khu vực ${museum.name} theo GPS.')),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_service.status != AutomaticLocationStatus.requestingPermission) {
        _start();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _service.pause();
    }
    // `inactive` also occurs while the OS permission dialog is open.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_arrivalChanged);
    _service.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
