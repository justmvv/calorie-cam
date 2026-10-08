import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../platform/camera.dart' as camera;
import 'format.dart';

/// A photo from the back camera (in-app viewfinder, falling back to the system camera) or from
/// the gallery; null if the user cancelled.
Future<Uint8List?> takePhoto(BuildContext context, ImageSource source) async {
  if (source == ImageSource.camera) {
    final l10n = context.l10n;
    final shot = await camera.takePhoto(cancel: l10n.cancel, switchCamera: l10n.switchCamera);
    if (shot != null) return shot.jpeg;
  }
  final file = await ImagePicker().pickImage(source: source, preferredCameraDevice: CameraDevice.rear);
  return file?.readAsBytes();
}
