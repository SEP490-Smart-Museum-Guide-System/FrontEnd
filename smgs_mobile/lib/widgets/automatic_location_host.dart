import 'dart:async';
import 'package:flutter/material.dart';
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
  String? _announcedMuseum;
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
      _announcedMuseum = null;
      return;
    }
    if (_announcedMuseum == museum.id) return;
    _announcedMuseum = museum.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _service.arrivedMuseum?.id != museum.id) return;
      widget.messengerKey?.currentState?.showSnackBar(
        SnackBar(content: Text('Đã đến khu vực ${museum.name} theo GPS.')),
      );
    });
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
