import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../data/db.dart';
import '../data/dish_catalog.dart';
import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Locale-aware formatting of values shown in the UI.
extension Formatting on AppLocalizations {
  String kcal(num v) => kcalValue(v.round());
  String grams(num v) => gramsValue(v.round());
  String macrosOf(num protein, num fat, num carbs) => macros(protein.round(), fat.round(), carbs.round());
  String time(DateTime t) => DateFormat.Hm(localeName).format(t);
  String percent(double v) => NumberFormat.percentPattern(localeName).format(v);

  String dayTitle(DateTime d) {
    final now = DateTime.now();
    if (sameDay(d, now)) return today;
    if (sameDay(d, now.subtract(const Duration(days: 1)))) return yesterday;
    return DateFormat.MMMMEEEEd(localeName).format(d);
  }

  String dishName(Dish d) => localeName == 'ru' ? d.nameRu : d.nameEn;

  /// Name from the catalog in the current language; falls back to the name saved with the entry.
  String mealName(Meal m, DishCatalog catalog) => switch (catalog.byId(m.dishId)) {
    final dish? => dishName(dish),
    null => m.name,
  };

  String category(String id) => switch (id) {
    'soup' => categorySoup,
    'main' => categoryMain,
    'bakery' => categoryBakery,
    'fast_food' => categoryFastFood,
    'asian' => categoryAsian,
    'salad' => categorySalad,
    'breakfast' => categoryBreakfast,
    'side' => categorySide,
    'bread' => categoryBread,
    'dessert' => categoryDessert,
    'fruit' => categoryFruit,
    'snack' => categorySnack,
    'vegetable' => categoryVegetable,
    'drink' => categoryDrink,
    _ => id,
  };
}

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
