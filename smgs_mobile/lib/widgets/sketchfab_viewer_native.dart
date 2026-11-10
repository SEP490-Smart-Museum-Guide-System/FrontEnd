import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SketchfabViewer extends StatefulWidget {
  const SketchfabViewer({super.key, required this.url});
  final String url;

  @override
  State<SketchfabViewer> createState() => _SketchfabViewerState();
}

class _SketchfabViewerState extends State<SketchfabViewer> {
  late final WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widget.url));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: controller);
}
