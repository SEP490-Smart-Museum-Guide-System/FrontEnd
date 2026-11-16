import 'dart:typed_data';

class PickedImageData {
  final Uint8List bytes;
  final String filename;
  const PickedImageData({required this.bytes, required this.filename});
}

Future<PickedImageData?> pickImageFromDevice() async {
  return null;
}
