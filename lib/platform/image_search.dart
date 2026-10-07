import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Reverse image search engines that accept a photo uploaded straight from a web form (no API
/// keys, nothing in between). Others (e.g. Yandex) need a scripted upload that browsers don't
/// allow from another site; they are reachable through the share sheet instead.
enum ImageSearchEngine {
  googleLens('Google Lens', 'https://lens.google.com/v3/upload', 'encoded_image', base64Field: false),
  bing('Bing', 'https://www.bing.com/images/search?view=detailv2&iss=sbiupload', 'imageBin', base64Field: true);

  const ImageSearchEngine(this.label, this.url, this.field, {required this.base64Field});

  final String label;
  final String url;
  final String field;

  /// Bing takes the image as a base64 string field, Google Lens as a regular file upload.
  final bool base64Field;
}

/// Opens the engine's results for [jpeg] in a new tab. Call directly from a tap handler:
/// browsers only allow opening a tab in response to one.
void searchImage(ImageSearchEngine engine, Uint8List jpeg) {
  final form = web.HTMLFormElement()
    ..method = 'POST'
    ..action = engine.url
    ..enctype = 'multipart/form-data'
    ..target = '_blank';
  final input = web.HTMLInputElement()..name = engine.field;
  if (engine.base64Field) {
    input
      ..type = 'hidden'
      ..value = base64Encode(jpeg);
  } else {
    final transfer = web.DataTransfer();
    transfer.items.add(web.File([jpeg.toJS].toJS, 'photo.jpg', web.FilePropertyBag(type: 'image/jpeg')));
    input
      ..type = 'file'
      ..files = transfer.files;
  }
  form
    ..style.display = 'none'
    ..append(input);
  web.document.body!.append(form);
  form.submit();
  form.remove();
}
