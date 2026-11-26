import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/localization/app_localizations.dart';
import '../core/network/api_config.dart';
import '../services/token_manager.dart';
import 'model_source_native.dart'
    if (dart.library.js_interop) 'model_source_web.dart';

class ArtifactModelSource extends StatefulWidget {
  const ArtifactModelSource({
    super.key,
    required this.url,
    required this.viewer,
  });

  final String url;
  final Widget Function(String) viewer;

  @override
  State<ArtifactModelSource> createState() => _ArtifactModelSourceState();
}

class _ArtifactModelSourceState extends State<ArtifactModelSource> {
  static final _uploadPath = RegExp(r'^/api/artifacts/\d+/model-3d/file$');
  Future<String>? _source;
  http.Client? _client;
  Future<void> Function()? _release;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ArtifactModelSource oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  void _clear() {
    _client?.close();
    _client = null;
    final release = _release;
    _release = null;
    if (release != null) unawaited(release());
  }

  void _load() {
    _clear();
    final uri = Uri.parse(ApiConfig.mediaUrl(widget.url));
    if (!_uploadPath.hasMatch(uri.path)) {
      _source = null;
      return;
    }
    final client = _client = http.Client();
    _source = _download(client, uri);
  }

  Future<String> _download(http.Client client, Uri uri) async {
    try {
      final response = await client
          .send(
            http.Request('GET', uri)
              ..followRedirects = false
              ..headers.addAll({
                if (uri.origin == Uri.parse(ApiConfig.baseUrl).origin)
                  ...TokenManager.authHeaders,
                'Accept': 'model/gltf-binary',
              }),
          )
          .timeout(const Duration(seconds: 30));
      final type = response.headers['content-type']?.split(';').first.trim();
      if (response.statusCode != 200 ||
          !{'model/gltf-binary', 'application/octet-stream'}.contains(type)) {
        throw http.ClientException('HTTP ${response.statusCode}', uri);
      }
      final model = await storeModel(response);
      if (_client == client) {
        _release = model.release;
      } else {
        await model.release();
      }
      return model.url;
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_source == null) return widget.viewer(widget.url);
    return FutureBuilder<String>(
      future: _source,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: Text(
                context.l10n.isEn
                    ? 'Could not load the 3D model. Retry'
                    : 'Không tải được mô hình 3D. Thử lại',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return widget.viewer(snapshot.requireData);
      },
    );
  }
}
