import 'dart:js_interop';
import 'dart:typed_data';

/// Bridge to `window.calorieCamera` from web/camera.js: an in-app viewfinder that asks for the
/// back camera explicitly (the system camera app often reopens the last-used, e.g. front, lens).
@JS('calorieCamera')
external _CameraJs? get _camera;

extension type _CameraJs._(JSObject _) implements JSObject {
  external bool get available;
  external JSPromise<JSUint8Array?> takePhoto(_Labels labels);
}

extension type _Labels._(JSObject _) implements JSObject {
  external factory _Labels({String cancel, String switchCamera});
}

/// Result of [takePhoto]: the JPEG, or nothing because the user cancelled.
class CameraShot {
  const CameraShot(this.jpeg);
  final Uint8List? jpeg;
}

/// Takes a photo with the in-app camera. Returns null when the in-app camera can't be used (no
/// permission, no camera, old browser) — then the caller falls back to the system camera.
Future<CameraShot?> takePhoto({required String cancel, required String switchCamera}) async {
  final camera = _camera;
  if (camera == null || !camera.available) return null;
  try {
    final bytes = await camera.takePhoto(_Labels(cancel: cancel, switchCamera: switchCamera)).toDart;
    return CameraShot(bytes?.toDart);
  } catch (_) {
    return null;
  }
}
