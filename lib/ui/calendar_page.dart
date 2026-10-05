import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services.dart';
import 'day_page.dart';
import 'format.dart';

/// Monthly heatmap: the more eaten relative to the daily goal, the deeper the red.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  var _month = DateTime(DateTime.now().year, DateTime.now().month);

  /// Intensity saturates at 150% of the goal.
  static const _maxRatio = 1.5;

  static Color heat(double ratio) {
    final t = (ratio / _maxRatio).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFFFEBEE), const Color(0xFFB71C1C), t)!;
  }

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendar)),
      body: ValueListenableBuilder<int>(
        valueListenable: services.dailyGoal,
        builder: (context, goal, _) => StreamBuilder<Map<int, double>>(
          stream: services.db.watchMonthTotals(_month),
          builder: (context, snap) {
            final totals = snap.data ?? const <int, double>{};
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Text(
                        toBeginningOfSentenceCase(DateFormat('LLLL y', l10n.localeName).format(_month)),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(onPressed: isCurrent ? null : () => _shift(1), icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                const SizedBox(height: 8),
                _MonthGrid(month: _month, totals: totals, goal: goal),
                const SizedBox(height: 16),
                _Legend(goal: goal),
                const SizedBox(height: 16),
                _MonthStats(totals: totals, goal: goal),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.totals, required this.goal});

  final DateTime month;
  final Map<int, double> totals;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = month.weekday - 1; // weeks start on Monday
    // Localized short weekday names, Monday first (2024-01-01 is a Monday).
    final weekdayFormat = DateFormat.E(context.l10n.localeName);
    final weekdays = [
      for (var i = 0; i < 7; i++) toBeginningOfSentenceCase(weekdayFormat.format(DateTime(2024, 1, 1 + i))),
    ];

    return Column(
      children: [
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(child: Text(w, style: Theme.of(context).textTheme.labelMedium)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < leading; i++) const SizedBox(),
            for (var day = 1; day <= daysInMonth; day++)
              _DayCell(
                date: DateTime(month.year, month.month, day),
                kcal: totals[day],
                goal: goal,
                isToday: sameDay(today, DateTime(month.year, month.month, day)),
                isFuture: DateTime(month.year, month.month, day).isAfter(today),
                emptyColor: scheme.surfaceContainerHighest,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.kcal,
    required this.goal,
    required this.isToday,
    required this.isFuture,
    required this.emptyColor,
  });

  final DateTime date;
  final double? kcal;
  final int goal;
  final bool isToday;
  final bool isFuture;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final ratio = kcal == null ? 0.0 : kcal! / goal;
    final color = kcal == null ? emptyColor : _CalendarPageState.heat(ratio);
    final onColor = kcal != null && ratio > 0.6 ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Opacity(
      opacity: isFuture ? 0.35 : 1,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isToday ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isFuture ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DayPage(day: date))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(color: onColor, fontWeight: FontWeight.w600),
              ),
              if (kcal != null)
                FittedBox(
                  child: Text(
                    '${kcal!.round()}',
                    style: TextStyle(color: onColor.withValues(alpha: 0.85), fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.goal});
  final int goal;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [for (var r = 0.0; r <= _CalendarPageState._maxRatio; r += 0.25) _CalendarPageState.heat(r)],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('0', style: style),
            ),
            // The goal sits at 1/1.5 of the bar width; Alignment.x is in [-1, 1].
            Align(
              alignment: const Alignment(2 / _CalendarPageState._maxRatio - 1, 0),
              child: Text(context.l10n.goalLabel(goal), style: style),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(goal * _CalendarPageState._maxRatio).round()}+', style: style),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthStats extends StatelessWidget {
  const _MonthStats({required this.totals, required this.goal});
  final Map<int, double> totals;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (totals.isEmpty) return Center(child: Text(l10n.noEntriesThisMonth));
    final sum = totals.values.fold(0.0, (a, b) => a + b);
    final over = totals.values.where((v) => v > goal).length;
    final textTheme = Theme.of(context).textTheme;
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(value, style: textTheme.titleLarge),
          Text(label, style: textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
    return Row(
      children: [
        stat('${(sum / totals.length).round()}', l10n.statAvgKcal),
        stat('${totals.length}', l10n.statDaysLogged),
        stat('$over', l10n.statDaysOver),
      ],
    );
  }
}
