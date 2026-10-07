import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform/image_search.dart';
import '../platform/web_files.dart';
import '../services.dart';
import 'format.dart';
import 'share_flow.dart';

/// "Search the web": sends the photo to a reverse image search engine of the user's choice,
/// or to another app via the share sheet (on Android: Google Lens, Yandex and others).
Future<void> showWebImageSearch(BuildContext context, Uint8List photo) {
  // Shrink the photo now: once an engine is tapped the tab has to open without delay.
  final upload = services.ai.resize(photo, 1024).catchError((Object _) => photo);
  Uint8List? ready;
  upload.then((bytes) => ready = bytes);

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(l10n.webSearchTitle, style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l10n.webSearchHint, style: Theme.of(context).textTheme.bodySmall),
            ),
            for (final engine in ImageSearchEngine.values)
              ListTile(
                leading: const Icon(Icons.travel_explore),
                title: Text(engine.label),
                onTap: () {
                  // Normally ready long before the tap; otherwise use the original photo.
                  searchImage(engine, ready ?? photo);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n.otherApp),
              subtitle: Text(l10n.otherAppHint),
              onTap: () async {
                final bytes = ready ?? photo;
                await shareWithRetry(context, ShareFile('photo.jpg', bytes, 'image/jpeg'));
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
