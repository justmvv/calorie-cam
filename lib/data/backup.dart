import 'dart:convert';

import 'package:drift/drift.dart';

import 'db.dart';

/// Diary backup as a self-describing JSON document:
///
/// ```json
/// {"format": "calorie-cam-backup", "version": 1, "exportedAt": "…",
///  "settings": {"dailyGoal": 2000, "language": "en"},
///  "meals": [{"uuid": "…", "eatenAt": "…", "dishId": "borscht", …, "photo": "<photo uuid>"}],
///  "photos": [{"uuid": "…", "jpeg": "<base64>"}]}
/// ```
///
/// Items are identified by their uuid, so importing is a merge: new items are added, an item
/// present on both sides keeps the version with the newer `updatedAt` (millisecond precision), and deletions
/// (tombstones) are carried over so deleted items don't come back.
abstract final class Backup {
  static const format = 'calorie-cam-backup';
  static const version = 1;

  static Future<String> export(AppDatabase db, {required BackupSettings settings}) async {
    final photos = await db.select(db.photos).get();
    final photoUuid = {for (final p in photos) p.id: p.uuid};
    final meals = await (db.select(db.meals)..orderBy([(m) => OrderingTerm.asc(m.eatenAt)])).get();
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

      final local = {for (final m in await db.select(db.meals).get()) m.uuid: m};
      var added = 0, updated = 0, unchanged = 0;
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
        final existing = local[row.uuid.value];
        if (existing == null) {
          await db.into(db.meals).insert(row);
          added++;
        } else if (row.updatedAtMs.value > existing.updatedAtMs) {
          await (db.update(db.meals)..where((m) => m.id.equals(existing.id))).write(row);
          updated++;
        } else {
          unchanged++;
        }
      }
      await db.deleteOrphanPhotos();

      final settings = doc['settings'];
      return ImportResult(
        added: added,
        updated: updated,
        unchanged: unchanged,
        // Settings are only taken over when restoring onto an empty diary (e.g. a new phone),
        // so importing an old backup never overrides choices made since.
        settings: wasEmpty && settings is Map<String, dynamic> ? BackupSettings.fromJson(settings) : null,
      );
    });
  }

  static String _iso(DateTime t) => t.toUtc().toIso8601String();
}

class BackupSettings {
  const BackupSettings({required this.dailyGoal, this.language});

  factory BackupSettings.fromJson(Map<String, dynamic> j) =>
      BackupSettings(dailyGoal: j['dailyGoal'] as int? ?? 2000, language: j['language'] as String?);

  final int dailyGoal;
  final String? language;

  Map<String, Object?> toJson() => {'dailyGoal': dailyGoal, 'language': language};
}

class ImportResult {
  const ImportResult({required this.added, required this.updated, required this.unchanged, this.settings});

  final int added;
  final int updated;
  final int unchanged;

  /// Settings to apply, present only when the diary was empty before the import.
  final BackupSettings? settings;
}
