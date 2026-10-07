import 'dart:convert';

import 'package:drift/drift.dart';

import 'db.dart';

/// Diary backup as a self-describing JSON document:
///
/// ```json
/// {"format": "calorie-cam-backup", "version": 1, "exportedAt": "…",
///  "settings": {"dailyGoal": 2000, "language": "en"},
///  "meals": [{"uuid": "…", "eatenAt": "…", "dishId": "borscht", …, "photo": "<photo uuid>"}],
///  "photos": [{"uuid": "…", "jpeg": "<base64>"}],
///  "products": [{"uuid": "…", "name": "…", "kcal": 360, …}],          // since version 2
///  "sets": [{"uuid": "…", "name": "…", "items": [{"dishId": …}]}],    // since version 2
///  "memories": [{"uuid": "…", "model": "…", "embedding": "<base64 float32>", "items": […]}]}  // since 3
/// ```
///
/// Older files (without products, sets or memories) are still imported.
///
/// Items are identified by their uuid, so importing is a merge: new items are added, an item
/// present on both sides keeps the version with the newer `updatedAt` (millisecond precision), and deletions
/// (tombstones) are carried over so deleted items don't come back.
abstract final class Backup {
  static const format = 'calorie-cam-backup';
  static const version = 3;

  static Future<String> export(AppDatabase db, {required BackupSettings settings}) async {
    final photos = await db.select(db.photos).get();
    final photoUuid = {for (final p in photos) p.id: p.uuid};
    final meals = await (db.select(db.meals)..orderBy([(m) => OrderingTerm.asc(m.eatenAt)])).get();
    final products = await db.select(db.products).get();
    final sets = await db.select(db.mealSets).get();
    final memories = await db.select(db.memories).get();
    return const JsonEncoder.withIndent(' ').convert({
      'format': format,
      'version': version,
      'exportedAt': _iso(DateTime.now()),
      'settings': settings.toJson(),
      'meals': [
        for (final m in meals)
          {
            'uuid': m.uuid,
            'eatenAt': _iso(m.eatenAt),
            'dishId': m.dishId,
            'name': m.name,
            'grams': m.grams,
            'kcal': m.kcal,
            'protein': m.protein,
            'fat': m.fat,
            'carbs': m.carbs,
            'photo': photoUuid[m.photoId],
            'createdAt': _iso(m.createdAt),
            'updatedAt': _iso(DateTime.fromMillisecondsSinceEpoch(m.updatedAtMs)),
            'deleted': m.deleted,
          },
      ],
      'photos': [
        for (final p in photos) {'uuid': p.uuid, 'jpeg': base64Encode(p.jpeg)},
      ],
      'products': [
        for (final p in products)
          {
            'uuid': p.uuid,
            'name': p.name,
            'kcal': p.kcal,
            'protein': p.protein,
            'fat': p.fat,
            'carbs': p.carbs,
            'portion': p.portion,
            'updatedAt': _iso(DateTime.fromMillisecondsSinceEpoch(p.updatedAtMs)),
            'deleted': p.deleted,
          },
      ],
      'sets': [
        for (final s in sets)
          {
            'uuid': s.uuid,
            'name': s.name,
            'items': jsonDecode(s.items),
            'updatedAt': _iso(DateTime.fromMillisecondsSinceEpoch(s.updatedAtMs)),
            'deleted': s.deleted,
          },
      ],
      'memories': [
        for (final m in memories)
          {
            'uuid': m.uuid,
            'model': m.model,
            'embedding': base64Encode(m.embedding),
            'items': jsonDecode(m.items),
            'createdAt': _iso(DateTime.fromMillisecondsSinceEpoch(m.createdAtMs)),
            'updatedAt': _iso(DateTime.fromMillisecondsSinceEpoch(m.updatedAtMs)),
            'deleted': m.deleted,
          },
      ],
    });
  }

  /// Merges a backup into the database. Throws [FormatException] for anything that isn't
  /// a backup of a supported version.
  static Future<ImportResult> import(AppDatabase db, String text) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const FormatException('not JSON');
    }
    if (decoded is! Map<String, dynamic> || decoded['format'] != format) {
      throw const FormatException('not a Calorie Cam backup');
    }
    final fileVersion = decoded['version'];
    if (fileVersion is! int || fileVersion > version) {
      throw FormatException('unsupported backup version $fileVersion');
    }
    try {
      return await _merge(db, decoded);
    } on TypeError {
      // A field is missing or has the wrong type; the transaction has been rolled back.
      throw const FormatException('damaged backup');
    }
  }

  static Future<ImportResult> _merge(AppDatabase db, Map<String, dynamic> doc) {
    return db.transaction(() async {
      final wasEmpty = (await db.select(db.meals).get()).isEmpty;

      // Photos first, so that items can refer to them.
      final photoIds = {for (final p in await db.select(db.photos).get()) p.uuid: p.id};
      for (final p in (doc['photos'] as List).cast<Map<String, dynamic>>()) {
        final uuid = p['uuid'] as String;
        photoIds[uuid] ??= await db
            .into(db.photos)
            .insert(PhotosCompanion.insert(uuid: Value(uuid), jpeg: base64Decode(p['jpeg'] as String)));
      }

      final counts = _Counts();
      final localMeals = {for (final m in await db.select(db.meals).get()) m.uuid: (m.id, m.updatedAtMs)};
      for (final j in (doc['meals'] as List).cast<Map<String, dynamic>>()) {
        final row = MealsCompanion(
          uuid: Value(j['uuid'] as String),
          eatenAt: Value(DateTime.parse(j['eatenAt'] as String).toLocal()),
          dishId: Value(j['dishId'] as String),
          name: Value(j['name'] as String),
          grams: Value((j['grams'] as num).toDouble()),
          kcal: Value((j['kcal'] as num).toDouble()),
          protein: Value((j['protein'] as num).toDouble()),
          fat: Value((j['fat'] as num).toDouble()),
          carbs: Value((j['carbs'] as num).toDouble()),
          photoId: Value(photoIds[j['photo']]),
          createdAt: Value(DateTime.parse(j['createdAt'] as String).toLocal()),
          updatedAtMs: Value(DateTime.parse(j['updatedAt'] as String).millisecondsSinceEpoch),
          deleted: Value(j['deleted'] as bool? ?? false),
        );
        await counts.merge(
          localMeals[row.uuid.value],
          row.updatedAtMs.value,
          insert: () => db.into(db.meals).insert(row),
          update: (id) => (db.update(db.meals)..where((m) => m.id.equals(id))).write(row),
        );
      }
      await db.deleteOrphanPhotos();

      final localProducts = {for (final p in await db.select(db.products).get()) p.uuid: (p.id, p.updatedAtMs)};
      for (final j in (doc['products'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final row = ProductsCompanion(
          uuid: Value(j['uuid'] as String),
          name: Value(j['name'] as String),
          kcal: Value((j['kcal'] as num).toDouble()),
          protein: Value((j['protein'] as num).toDouble()),
          fat: Value((j['fat'] as num).toDouble()),
          carbs: Value((j['carbs'] as num).toDouble()),
          portion: Value((j['portion'] as num).toDouble()),
          updatedAtMs: Value(DateTime.parse(j['updatedAt'] as String).millisecondsSinceEpoch),
          deleted: Value(j['deleted'] as bool? ?? false),
        );
        await counts.merge(
          localProducts[row.uuid.value],
          row.updatedAtMs.value,
          insert: () => db.into(db.products).insert(row),
          update: (id) => (db.update(db.products)..where((p) => p.id.equals(id))).write(row),
        );
      }

      final localSets = {for (final s in await db.select(db.mealSets).get()) s.uuid: (s.id, s.updatedAtMs)};
      for (final j in (doc['sets'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final items = [for (final i in (j['items'] as List).cast<Map<String, dynamic>>()) SetItem.fromJson(i)];
        final row = MealSetsCompanion(
          uuid: Value(j['uuid'] as String),
          name: Value(j['name'] as String),
          items: Value(jsonEncode([for (final i in items) i.toJson()])),
          updatedAtMs: Value(DateTime.parse(j['updatedAt'] as String).millisecondsSinceEpoch),
          deleted: Value(j['deleted'] as bool? ?? false),
        );
        await counts.merge(
          localSets[row.uuid.value],
          row.updatedAtMs.value,
          insert: () => db.into(db.mealSets).insert(row),
          update: (id) => (db.update(db.mealSets)..where((s) => s.id.equals(id))).write(row),
        );
      }

      final localMemories = {for (final m in await db.select(db.memories).get()) m.uuid: (m.id, m.updatedAtMs)};
      for (final j in (doc['memories'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final items = [for (final i in (j['items'] as List).cast<Map<String, dynamic>>()) SetItem.fromJson(i)];
        final row = MemoriesCompanion(
          uuid: Value(j['uuid'] as String),
          model: Value(j['model'] as String),
          embedding: Value(base64Decode(j['embedding'] as String)),
          items: Value(jsonEncode([for (final i in items) i.toJson()])),
          createdAtMs: Value(DateTime.parse(j['createdAt'] as String).millisecondsSinceEpoch),
          updatedAtMs: Value(DateTime.parse(j['updatedAt'] as String).millisecondsSinceEpoch),
          deleted: Value(j['deleted'] as bool? ?? false),
        );
        await counts.merge(
          localMemories[row.uuid.value],
          row.updatedAtMs.value,
          insert: () => db.into(db.memories).insert(row),
          update: (id) => (db.update(db.memories)..where((m) => m.id.equals(id))).write(row),
        );
      }

      final settings = doc['settings'];
      return ImportResult(
        added: counts.added,
        updated: counts.updated,
        unchanged: counts.unchanged,
        // Settings are only taken over when restoring onto an empty diary (e.g. a new phone),
        // so importing an old backup never overrides choices made since.
        settings: wasEmpty && settings is Map<String, dynamic> ? BackupSettings.fromJson(settings) : null,
      );
    });
  }

  static String _iso(DateTime t) => t.toUtc().toIso8601String();
}

/// Last-writer-wins merge of one row, with counters for the import summary.
class _Counts {
  var added = 0, updated = 0, unchanged = 0;

  /// [local] is (local id, updatedAtMs) of the row with the same uuid, if there is one.
  Future<void> merge(
    (int, int)? local,
    int incomingUpdatedAtMs, {
    required Future<Object?> Function() insert,
    required Future<Object?> Function(int id) update,
  }) async {
    if (local == null) {
      await insert();
      added++;
    } else if (incomingUpdatedAtMs > local.$2) {
      await update(local.$1);
      updated++;
    } else {
      unchanged++;
    }
  }
}

class BackupSettings {
  const BackupSettings({required this.dailyGoal, this.language});

  factory BackupSettings.fromJson(Map<String, dynamic> j) =>
      BackupSettings(dailyGoal: j['dailyGoal'] as int? ?? 2000, language: j['language'] as String?);

  final int dailyGoal;
  final String? language;

  Map<String, Object?> toJson() => {'dailyGoal': dailyGoal, 'language': language};
}

/// Counts cover diary entries, products, sets and remembered photos together.
class ImportResult {
  const ImportResult({required this.added, required this.updated, required this.unchanged, this.settings});

  final int added;
  final int updated;
  final int unchanged;

  /// Settings to apply, present only when the diary was empty before the import.
  final BackupSettings? settings;
}
