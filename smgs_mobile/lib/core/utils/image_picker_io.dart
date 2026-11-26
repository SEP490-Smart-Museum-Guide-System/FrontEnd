import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'image_picker_stub.dart';

Future<PickedImageData?> pickImageFromDevice({bool useCamera = false}) async {
  final file = await ImagePicker().pickImage(
    source: useCamera ? ImageSource.camera : ImageSource.gallery,
    preferredCameraDevice: CameraDevice.rear,
    imageQuality: 90,
  );
  if (file == null) return null;
  final bytes = await File(file.path).readAsBytes();
  return PickedImageData(bytes: bytes, filename: file.name);
}
