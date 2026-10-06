import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/backup.dart';
import 'data/db.dart';
import 'data/dish_catalog.dart';
import 'ml/food_ai.dart';
import 'platform/web_files.dart';

/// App-wide services (one instance per process).
class Services {
  Services._(this.db, this.catalog, this.ai, this._prefs)
    : dailyGoal = ValueNotifier(_prefs.getInt(_goalKey) ?? _prefs.getInt('daily_goal_kcal') ?? 2000),
      language = ValueNotifier(_prefs.getString(_languageKey)),
      lastExport = ValueNotifier(switch (_prefs.getInt(_lastExportKey)) {
        final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
        null => null,
      }) {
    dailyGoal.addListener(() => _prefs.setInt(_goalKey, dailyGoal.value));
    language.addListener(() {
      final lang = language.value;
      lang == null ? _prefs.remove(_languageKey) : _prefs.setString(_languageKey, lang);
    });
    lastExport.addListener(() => _prefs.setInt(_lastExportKey, lastExport.value!.millisecondsSinceEpoch));
  }

  // Keys are namespaced: browser storage is shared by every app on the origin
  // (all of a user's <user>.github.io/<repo>/ projects). The goal falls back to the
  // pre-namespacing key once so existing users keep their value.
  static const _goalKey = 'calorie_cam.daily_goal_kcal';
  static const _languageKey = 'calorie_cam.language';
  static const _lastExportKey = 'calorie_cam.last_export_ms';

  final AppDatabase db;
  final DishCatalog catalog;
  final FoodAI ai;
  final SharedPreferences _prefs;

  /// Daily goal in kcal; the calendar heatmap intensity is relative to it.
  final ValueNotifier<int> dailyGoal;

  /// UI language code ('en', 'ru', …); null means "follow the system".
  final ValueNotifier<String?> language;

  /// When the diary was last exported; null if never.
  final ValueNotifier<DateTime?> lastExport;

  /// Whether the browser agreed not to clear the diary when the device runs low on space.
  final storagePersisted = ValueNotifier(false);

  static Future<Services> init() async {
    final ai = FoodAI();
    if (ai.available) ai.warmUp().ignore(); // the model loads in the background
    final services = Services._(AppDatabase(), await DishCatalog.load(), ai, await SharedPreferences.getInstance());
    requestPersistentStorage().then((granted) => services.storagePersisted.value = granted).ignore();
    return services;
  }

  /// Exports the diary as a JSON file via the share sheet (or a download).
  Future<ExportOutcome> exportBackup() async {
    final json = await Backup.export(
      db,
      settings: BackupSettings(dailyGoal: dailyGoal.value, language: language.value),
    );
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final outcome = await shareOrDownload('calorie-cam-backup-$date.json', json);
    if (outcome != ExportOutcome.cancelled) lastExport.value = DateTime.now();
    return outcome;
  }

  /// Lets the user pick a backup file and merges it; null if no file was chosen.
  Future<ImportResult?> importBackup() async {
    final text = await pickTextFile();
    if (text == null) return null;
    final result = await Backup.import(db, text);
    if (result.settings case final s?) {
      dailyGoal.value = s.dailyGoal;
      language.value = s.language;
    }
    return result;
  }
}

late final Services services;
