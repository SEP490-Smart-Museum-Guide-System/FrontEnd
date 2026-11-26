import 'dart:io';

import 'package:http/http.dart' as http;

Future<({String url, Future<void> Function() release})> storeModel(
  http.StreamedResponse response,
) async {
  final directory = await Directory.systemTemp.createTemp('smgs_model_');
  final file = File.fromUri(directory.uri.resolve('artifact.glb'));
  Future<void> release() => directory.delete(recursive: true);
  try {
    await response.stream.pipe(file.openWrite());
    return (url: file.uri.toString(), release: release);
  } catch (_) {
    await release();
    rethrow;
  }
}
