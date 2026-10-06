import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

enum ExportOutcome { shared, downloaded, cancelled }

/// Hands a text file to the user: the system share sheet where files can be shared
/// (Android: Google Drive, Files, messengers…), otherwise a regular download.
Future<ExportOutcome> shareOrDownload(String fileName, String text) async {
  final nav = web.window.navigator;
  // Chrome only shares an allow-list of file types; .json isn't on it, plain text is.
  for (final (name, type) in [(fileName, 'application/json'), ('$fileName.txt', 'text/plain')]) {
    final file = web.File([text.toJS].toJS, name, web.FilePropertyBag(type: type));
    final data = web.ShareData(files: [file].toJS);
    if (!_canShare(nav, data)) continue;
    try {
      await nav.share(data).toDart;
      return ExportOutcome.shared;
    } catch (e) {
      if (e.toString().contains('AbortError')) return ExportOutcome.cancelled;
      rethrow;
    }
  }
  final url = web.URL.createObjectURL(web.Blob([text.toJS].toJS, web.BlobPropertyBag(type: 'application/json')));
  (web.HTMLAnchorElement()
        ..href = url
        ..download = fileName)
      .click();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  return ExportOutcome.downloaded;
}

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
