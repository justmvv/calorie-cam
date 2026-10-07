import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

enum ShareOutcome {
  shared,
  downloaded,
  cancelled,

  /// The browser refused because the call no longer counts as a response to a tap (it only
  /// allows sharing for a few seconds after one). Ask the user to tap again and retry.
  needsGesture,
}

/// A file to hand to the user.
class ShareFile {
  const ShareFile(this.name, this.bytes, this.type, {this.alternatives = const []});

  ShareFile.text(String name, String text, String type, {List<(String, String)> alternatives = const []})
    : this(name, Uint8List.fromList(utf8.encode(text)), type, alternatives: alternatives);

  final String name;
  final Uint8List bytes;
  final String type;

  /// Other (name, MIME type) pairs to try if the browser won't share [type]. Chrome only shares
  /// an allow-list of file types: images and plain text are on it, JSON isn't.
  final List<(String, String)> alternatives;
}

/// Hands a file to the user: the system share sheet where the browser can share files
/// (Android: Google Drive, Files, messengers…), otherwise a regular download.
///
/// Must be called right after a user tap, with as little async work in between as possible.
Future<ShareOutcome> shareOrDownload(ShareFile file, {String? title}) async {
  final nav = web.window.navigator;
  for (final (name, type) in [(file.name, file.type), ...file.alternatives]) {
    final data = web.ShareData(files: [_file(file.bytes, name, type)].toJS);
    if (title != null) data.title = title;
    if (!_canShare(nav, data)) continue;
    try {
      await nav.share(data).toDart;
      return ShareOutcome.shared;
    } catch (e) {
      final error = e.toString();
      if (error.contains('AbortError')) return ShareOutcome.cancelled;
      if (error.contains('NotAllowedError')) return ShareOutcome.needsGesture;
      break; // anything else: fall back to a download
    }
  }
  download(file);
  return ShareOutcome.downloaded;
}

/// Saves a file through the browser's download mechanism.
void download(ShareFile file) {
  final url = web.URL.createObjectURL(web.Blob([file.bytes.toJS].toJS, web.BlobPropertyBag(type: file.type)));
  (web.HTMLAnchorElement()
        ..href = url
        ..download = file.name)
      .click();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}

web.File _file(Uint8List bytes, String name, String type) =>
    web.File([bytes.toJS].toJS, name, web.FilePropertyBag(type: type));

bool _canShare(web.Navigator nav, web.ShareData data) {
  try {
    return nav.canShare(data);
  } catch (_) {
    return false; // no Web Share API
  }
}

/// Lets the user pick a text file; returns its contents, or null if the picker was dismissed.
Future<String?> pickTextFile({String accept = '.json,.txt,application/json,text/plain'}) {
  final done = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  input.addEventListener(
    'change',
    ((web.Event _) {
      final file = input.files?.item(0);
      if (done.isCompleted) return;
      done.complete(file == null ? null : _readText(file));
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!done.isCompleted) done.complete(null);
    }).toJS,
  );
  input.click();
  return done.future;
}

Future<String> _readText(web.File file) async => (await file.text().toDart).toDart;

/// Asks the browser to keep this site's storage when the device runs low on space.
/// Chrome decides on its own (installed PWAs usually qualify) and never shows a prompt.
Future<bool> requestPersistentStorage() async {
  try {
    final storage = web.window.navigator.storage;
    if ((await storage.persisted().toDart).toDart) return true;
    return (await storage.persist().toDart).toDart;
  } catch (_) {
    return false;
  }
}
