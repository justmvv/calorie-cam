import 'package:flutter/material.dart';

import '../platform/web_files.dart';
import 'format.dart';

/// Shares [file]; if the browser refuses because too much time passed since the tap, asks the
/// user to confirm with a fresh tap and tries again.
Future<ShareOutcome> shareWithRetry(BuildContext context, ShareFile file, {String? title}) async {
  var outcome = await shareOrDownload(file, title: title);
  if (outcome != ShareOutcome.needsGesture || !context.mounted) return outcome;
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.fileReady),
      content: Text(file.name),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.share),
          label: Text(l10n.share),
        ),
      ],
    ),
  );
  if (confirmed != true) return ShareOutcome.cancelled;
  outcome = await shareOrDownload(file, title: title);
  // Still refused (shouldn't happen right after a tap): save the file instead of losing it.
  if (outcome == ShareOutcome.needsGesture) {
    download(file);
    return ShareOutcome.downloaded;
  }
  return outcome;
}
