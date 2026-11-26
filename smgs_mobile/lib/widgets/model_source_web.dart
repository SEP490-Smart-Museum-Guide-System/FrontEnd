// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:http/http.dart' as http;

Future<({String url, Future<void> Function() release})> storeModel(
  http.StreamedResponse response,
) async {
  final bytes = await response.stream.toBytes();
  final url = html.Url.createObjectUrlFromBlob(
    html.Blob([bytes], 'model/gltf-binary'),
  );
  return (url: url, release: () async => html.Url.revokeObjectUrl(url));
}
