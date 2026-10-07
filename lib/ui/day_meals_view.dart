import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/db.dart';
import '../services.dart';
import 'format.dart';
import 'palette.dart';

/// Day totals and the list of logged items: tap to edit portion/time, swipe to delete.
class DayMealsView extends StatelessWidget {
  const DayMealsView({super.key, required this.day, this.bottomPadding = 0});

  final DateTime day;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Meal>>(
      stream: services.db.watchDay(day),
      builder: (context, snap) {
        final meals = snap.data ?? const <Meal>[];
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPadding),
          children: [
            _DaySummary(meals: meals),
            const SizedBox(height: 16),
            if (snap.hasData && meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text(context.l10n.nothingLogged)),
              ),
            for (final m in meals) _MealTile(meal: m),
          ],
        );
      },
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.meals});
  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    double sum(double Function(Meal) f) => meals.fold(0.0, (a, m) => a + f(m));
    final total = sum((m) => m.kcal);
    final macros = l10n.macrosOf(sum((m) => m.protein), sum((m) => m.fat), sum((m) => m.carbs));
    return ValueListenableBuilder<int>(
      valueListenable: services.dailyGoal,
      builder: (context, goal, _) {
        final over = total > goal;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: Palette.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Palette.blue.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${total.round()}', style: text.displaySmall?.copyWith(color: Colors.white)),
                    Text(' / ${l10n.kcal(goal)}', style: text.titleMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: goal == 0 ? 0 : (total / goal).clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.white24,
                  // Over the goal the bar turns amber so it stands out on the green-blue card.
                  color: over ? Colors.amberAccent : Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  over
                      ? l10n.kcalOver(l10n.kcal(total - goal), macros)
                      : l10n.kcalLeft(l10n.kcal(goal - total), macros),
                  style: text.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = l10n.mealName(meal, services.catalog);
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final photo = await services.db.deleteMeal(meal);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.mealDeleted(name)),
            action: SnackBarAction(label: l10n.undo, onPressed: () => services.db.restoreMeal(meal, photo)),
            // Since Flutter 3.32 a SnackBar with an action stays until dismissed unless told otherwise.
            persist: false,
            duration: const Duration(seconds: 5),
          ),
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Thumb(photoId: meal.photoId),
        title: Text(name),
        subtitle: Text('${l10n.time(meal.eatenAt)} · ${l10n.grams(meal.grams)}'),
        trailing: Text(l10n.kcal(meal.kcal), style: Theme.of(context).textTheme.titleMedium),
        onTap: () => _edit(context),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final l10n = context.l10n;
    final text = meal.grams.round().toString();
    final controller = TextEditingController.fromValue(
      TextEditingValue(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      ),
    );
    var eatenAt = meal.eatenAt;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.mealName(meal, services.catalog)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.portion, suffixText: l10n.gramsUnit),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(l10n.time(eatenAt)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(eatenAt));
                  if (t != null) {
                    setState(() => eatenAt = DateTime(eatenAt.year, eatenAt.month, eatenAt.day, t.hour, t.minute));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    final g = double.tryParse(controller.text.replaceAll(',', '.'));
    if (saved == true && g != null && g > 0) {
      await services.db.updateMeal(meal, grams: g, eatenAt: eatenAt);
    }
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photoId});
  final int? photoId;

  static final _cache = <int, Future<Uint8List?>>{};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 56,
      height: 56,
      color: scheme.surfaceContainerHigh,
      child: Icon(Icons.restaurant, color: scheme.onSurfaceVariant),
    );
    final id = photoId;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: id == null
          ? placeholder
          : FutureBuilder<Uint8List?>(
              future: _cache.putIfAbsent(id, () => services.db.photo(id)),
              builder: (context, snap) => snap.data == null
                  ? placeholder
                  : Image.memory(snap.data!, width: 56, height: 56, fit: BoxFit.cover, gaplessPlayback: true),
            ),
    );
  }
}
