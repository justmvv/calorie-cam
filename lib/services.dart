import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/db.dart';
import 'data/dish_catalog.dart';
import 'ml/food_ai.dart';

/// App-wide services (one instance per process).
class Services {
  Services._(this.db, this.catalog, this.ai, this._prefs)
    : dailyGoal = ValueNotifier(_prefs.getInt(_goalKey) ?? _prefs.getInt('daily_goal_kcal') ?? 2000),
      language = ValueNotifier(_prefs.getString(_languageKey)) {
    dailyGoal.addListener(() => _prefs.setInt(_goalKey, dailyGoal.value));
    language.addListener(() {
      final lang = language.value;
      lang == null ? _prefs.remove(_languageKey) : _prefs.setString(_languageKey, lang);
    });
  }

  // Keys are namespaced: browser storage is shared by every app on the origin
  // (all of a user's <user>.github.io/<repo>/ projects). The goal falls back to the
  // pre-namespacing key once so existing users keep their value.
  static const _goalKey = 'calorie_cam.daily_goal_kcal';
  static const _languageKey = 'calorie_cam.language';

  final AppDatabase db;
  final DishCatalog catalog;
  final FoodAI ai;
  final SharedPreferences _prefs;

  /// Daily goal in kcal; the calendar heatmap intensity is relative to it.
  final ValueNotifier<int> dailyGoal;

  /// UI language code ('en', 'ru'); null means "follow the system".
  final ValueNotifier<String?> language;

  static Future<Services> init() async {
    final ai = FoodAI();
    if (ai.available) ai.warmUp().ignore(); // the model loads in the background
    return Services._(AppDatabase(), await DishCatalog.load(), ai, await SharedPreferences.getInstance());
  }
}

late final Services services;
