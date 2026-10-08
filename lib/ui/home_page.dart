import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'calendar_page.dart';
import 'capture_page.dart';
import 'day_meals_view.dart';
import 'day_share.dart';
import 'format.dart';
import 'palette.dart';
import 'settings_page.dart';
import 'take_photo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [const HeartLogo(), const SizedBox(width: 10), Text(l10n.today)]),
        actions: [
          IconButton(
            tooltip: l10n.shareDay,
            icon: const Icon(Icons.ios_share),
            onPressed: () => showDayShare(context, DateTime.now()),
          ),
          IconButton(
            tooltip: l10n.calendar,
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())),
          ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      body: DayMealsView(day: DateTime.now(), bottomPadding: 88),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: () => _fromCamera(context, ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: Text(l10n.takePhoto),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: l10n.fromGallery,
                iconSize: 28,
                onPressed: () => _fromCamera(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
              ),
              IconButton.filledTonal(
                tooltip: l10n.withoutPhoto,
                iconSize: 28,
                onPressed: () => openCapture(context),
                icon: const Icon(Icons.edit_note),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fromCamera(BuildContext context, ImageSource source) async {
    final bytes = await takePhoto(context, source);
    if (bytes != null && context.mounted) await openCapture(context, image: bytes);
  }
}

/// Opens the add screen and shows the total once the user comes back.
Future<void> openCapture(BuildContext context, {Uint8List? image, DateTime? time}) async {
  final added = await Navigator.push<double>(
    context,
    MaterialPageRoute(
      builder: (_) => CapturePage(image: image, initialTime: time),
    ),
  );
  if (added != null && context.mounted) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addedKcal(l10n.kcal(added)))));
  }
}
