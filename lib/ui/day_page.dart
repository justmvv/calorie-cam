import 'package:flutter/material.dart';

import 'day_meals_view.dart';
import 'day_share.dart';
import 'format.dart';
import 'home_page.dart';

/// Day details opened from the calendar.
class DayPage extends StatelessWidget {
  const DayPage({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dayTitle(day)),
        actions: [
          IconButton(
            tooltip: l10n.shareDay,
            icon: const Icon(Icons.ios_share),
            onPressed: () => showDayShare(context, day),
          ),
        ],
      ),
      body: DayMealsView(day: day, bottomPadding: 72),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            openCapture(context, time: sameDay(day, now) ? now : DateTime(day.year, day.month, day.day, 13)),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
    );
  }
}
