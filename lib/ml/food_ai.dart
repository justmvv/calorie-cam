import 'dart:js_interop';
import 'dart:typed_data';

/// Bridge to `window.foodAI` from web/food_ai.js.
@JS('foodAI')
external _FoodAIJs? get _foodAI;

extension type _FoodAIJs._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> warmUp();
  external JSPromise<_AnalysisJs> analyze(JSUint8Array bytes);
}

extension type _AnalysisJs._(JSObject _) implements JSObject {
  external JSFloat32Array get embedding;
  external JSUint8Array get thumbnail;
}

class PhotoAnalysis {
  const PhotoAnalysis(this.embedding, this.thumbnail);

  /// L2-normalized image embedding.
  final Float32List embedding;

  /// JPEG thumbnail (up to 320 px on the longer side).
  final Uint8List thumbnail;
}

class FoodAI {
  Future<void>? _warmUp;

  bool get available => _foodAI != null;

  /// Loads the model; repeated calls return the same Future.
  Future<void> warmUp() => _warmUp ??= _js.warmUp().toDart.then((_) {}).catchError((Object e) {
    _warmUp = null;
    throw e;
  });

  Future<PhotoAnalysis> analyze(Uint8List imageBytes) async {
    final r = await _js.analyze(imageBytes.toJS).toDart;
    return PhotoAnalysis(r.embedding.toDart, r.thumbnail.toDart);
  }

  _FoodAIJs get _js => _foodAI ?? (throw StateError('food_ai.js is not loaded'));
}
