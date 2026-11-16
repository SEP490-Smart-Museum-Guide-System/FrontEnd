// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'image_picker_stub.dart';

Future<PickedImageData?> pickImageFromDevice({bool useCamera = false}) async {
  final completer = Completer<PickedImageData?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';
  if (useCamera) {
    input.setAttribute('capture', 'environment');
  }
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((e) {
      final result = reader.result;
      if (result is Uint8List) {
        if (!completer.isCompleted) {
          completer.complete(PickedImageData(bytes: result, filename: file.name));
        }
      } else if (result is ByteBuffer) {
        if (!completer.isCompleted) {
          completer.complete(PickedImageData(
            bytes: Uint8List.view(result),
            filename: file.name,
          ));
        }
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });
    reader.onError.listen((e) {
      if (!completer.isCompleted) completer.complete(null);
    });
  });

  return completer.future;
}
