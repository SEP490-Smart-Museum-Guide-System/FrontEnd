import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? controller;
  bool ready = false;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      final web = WebViewController();
      await web.setJavaScriptMode(JavaScriptMode.unrestricted);
      await web.addJavaScriptChannel(
        'VietMapHost',
        onMessageReceived: (message) {
          if (mounted) widget.status(message.message);
        },
      );
      await web.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            ready = true;
            sync();
          },
        ),
      );
      if (!mounted) return;
      setState(() => controller = web);
      await web.loadFlutterAsset('assets/vietmap.html');
    } catch (_) {
      if (mounted)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.status('error');
        });
    }
  }

  List<List<double>>? sentRoute;
  List<List<Object>>? sentPins;
  bool sending = false, dirty = false;
  Future<void> sync() async {
    if (!ready || !mounted) return;
    dirty = true;
    if (sending) return;
    sending = true;
    try {
      while (dirty && mounted) {
        dirty = false;
        final route = widget.route;
        final pins = widget.pins;
        await controller?.runJavaScript(
          'window.setCamera(' +
              jsonEncode([
                ...widget.camera,
                sentRoute != route ? route : null,
                if (sentPins != pins) pins,
              ]) +
              ')',
        );
        sentRoute = route;
        sentPins = pins;
      }
    } catch (_) {
      if (mounted) widget.status('error');
    } finally {
      sending = false;
    }
  }

  @override
  void didUpdateWidget(VietMapSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  Widget build(BuildContext context) => controller == null
      ? const SizedBox.expand()
      : IgnorePointer(child: WebViewWidget(controller: controller!));
}
