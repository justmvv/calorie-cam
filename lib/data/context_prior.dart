import 'dart:math' as math;

import 'dish_catalog.dart';

/// Gentle nudges from the context, as logit bonuses per dish (see DishCatalog.classify): what
/// fits the time of day, and what the user eats often. They only reorder close candidates — a
/// difference of ~1 logit is what separates "manti" from "pelmeni" — never override the photo.
Map<String, double> contextPrior(DishCatalog catalog, DateTime at, Map<String, int> counts) {
  final hour = at.hour;
  final morning = hour >= 5 && hour < 11;
  final midday = hour >= 11 && hour < 16;
  final evening = hour >= 18 || hour < 3;
  final prior = <String, double>{};
  for (final d in catalog.dishes) {
    var b = switch (d.category) {
      'breakfast' when morning => 0.4,
      'breakfast' when evening => -0.3,
      'soup' when midday => 0.2,
      _ => 0.0,
    };
    // Familiar dishes: +0.25 for one meal in the period, +0.5 for three, at most +0.8 (≈ 8 meals).
    final n = counts[d.id] ?? 0;
    if (n > 0) b += math.min(0.8, 0.25 * math.log(1 + n) / math.ln2);
    if (b != 0) prior[d.id] = b;
  }
  return prior;
}
