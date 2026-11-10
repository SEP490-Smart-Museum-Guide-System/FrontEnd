import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class SketchfabViewer extends StatefulWidget {
  const SketchfabViewer({super.key, required this.url});
  final String url;

  @override
  State<SketchfabViewer> createState() => _SketchfabViewerState();
}

class _SketchfabViewerState extends State<SketchfabViewer> {
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType = 'sketchfab-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) => html.IFrameElement()
      ..src = widget.url
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true
      ..setAttribute('allow', 'autoplay; fullscreen; xr-spatial-tracking'));
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: viewType);
}
