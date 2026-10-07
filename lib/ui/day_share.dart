import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../data/db.dart';
import '../platform/web_files.dart';
import '../services.dart';
import 'format.dart';
import 'palette.dart';
import 'share_flow.dart';

/// "Share the day": a preview of a picture of the day (total, macros, dishes) and a button that
/// hands it as a PNG to the share sheet.
Future<void> showDayShare(BuildContext context, DateTime day) async {
  final meals = await services.db.watchDay(day).first;
  final photos = <int, Uint8List>{};
  for (final id in meals.map((m) => m.photoId).nonNulls.toSet()) {
    if (await services.db.photo(id) case final jpeg?) photos[id] = jpeg;
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _DaySharePreview(day: day, meals: meals, photos: photos),
  );
}

class _DaySharePreview extends StatefulWidget {
  const _DaySharePreview({required this.day, required this.meals, required this.photos});

  final DateTime day;
  final List<Meal> meals;
  final Map<int, Uint8List> photos;

  @override
  State<_DaySharePreview> createState() => _DaySharePreviewState();
}

class _DaySharePreviewState extends State<_DaySharePreview> {
  final _card = GlobalKey();
  var _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      image.dispose();
      if (!mounted) return;
      final name = 'calorie-cam-${DateFormat('yyyy-MM-dd').format(widget.day)}.png';
      final outcome = await shareWithRetry(context, ShareFile(name, png, 'image/png'));
      if (mounted && outcome != ShareOutcome.cancelled) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: RepaintBoundary(
                key: _card,
                child: _DayCard(day: widget.day, meals: widget.meals, photos: widget.photos, l10n: l10n),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GradientButton(
              onPressed: _busy ? null : _share,
              icon: const Icon(Icons.share),
              label: Text(l10n.share),
            ),
          ),
        ),
      ],
    );
  }
}

/// The picture itself. Always light, whatever the app theme, so it looks the same wherever
/// it ends up.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.meals, required this.photos, required this.l10n});

  final DateTime day;
  final List<Meal> meals;
  final Map<int, Uint8List> photos;
  final AppLocalizations l10n;

  static const _ink = Color(0xFF1B2A1E);
  static const _muted = Color(0xFF5B6B5E);

  @override
  Widget build(BuildContext context) {
    double sum(double Function(Meal) f) => meals.fold(0.0, (a, m) => a + f(m));
    final total = sum((m) => m.kcal);
    final goal = services.dailyGoal.value;
    final date = DateFormat.yMMMMEEEEd(l10n.localeName).format(day);
    return SizedBox(
      width: 360,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(gradient: Palette.brandGradient),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(toBeginningOfSentenceCase(date), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${total.round()}',
                          style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w600),
                        ),
                        Text(' / ${l10n.kcal(goal)}', style: const TextStyle(color: Colors.white70, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: goal == 0 ? 0 : (total / goal).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        color: total > goal ? Colors.amberAccent : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.macrosOf(sum((m) => m.protein), sum((m) => m.fat), sum((m) => m.carbs)),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.nothingLogged, style: const TextStyle(color: _muted)),
              ),
            for (final m in meals)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 20, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: switch (photos[m.photoId]) {
                        final jpeg? => Image.memory(jpeg, width: 40, height: 40, fit: BoxFit.cover),
                        null => Container(
                          width: 40,
                          height: 40,
                          color: Palette.herbPale,
                          child: const Icon(Icons.restaurant, size: 20, color: Palette.herbDeep),
                        ),
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.mealName(m, services.catalog),
                            style: const TextStyle(color: _ink, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${l10n.time(m.eatenAt)} · ${l10n.grams(m.grams)}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(l10n.kcal(m.kcal), style: const TextStyle(color: _ink, fontSize: 15)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HeartLogo(size: 18),
                  const SizedBox(width: 6),
                  Text(l10n.appTitle, style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
