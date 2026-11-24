import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/widgets.dart';

class VietMapSurface extends StatefulWidget {
  const VietMapSurface(
    this.camera,
    this.route,
    this.pins,
    this.status, {
    super.key,
  });
  final List<Object> camera;
  final List<List<double>> route;
  final List<List<Object>> pins;
  final ValueChanged<String> status;
  @override
  State<VietMapSurface> createState() => _SurfaceState();
}

class _SurfaceState extends State<VietMapSurface> {
  html.IFrameElement? frame;
  StreamSubscription<html.MessageEvent>? messages;
  void sync({bool routeChanged = false, bool pinsChanged = false}) =>
      frame?.contentWindow?.postMessage([
        ...widget.camera,
        routeChanged ? widget.route : null,
        if (pinsChanged) widget.pins,
      ], Uri.base.origin);
  @override
  void didUpdateWidget(VietMapSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync(
      routeChanged: oldWidget.route != widget.route,
      pinsChanged: oldWidget.pins != widget.pins,
    );
  }

  @override
  void dispose() {
    messages?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final iframe = element as html.IFrameElement;
      frame = iframe;
      iframe.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..pointerEvents = 'none';
      messages = html.window.onMessage.listen((e) {
        if (mounted &&
            e.source == iframe.contentWindow &&
            e.origin == Uri.base.origin &&
            e.data is String &&
            (e.data as String).startsWith('vietmap:'))
          widget.status((e.data as String).substring(8));
      });
      iframe.onLoad.first.then((_) {
        if (mounted) sync(routeChanged: true, pinsChanged: true);
      });
      iframe.src = 'assets/assets/vietmap.html';
    },
  );
}
