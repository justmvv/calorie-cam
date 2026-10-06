import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'uuid.dart';

part 'db.g.dart';

/// Photo thumbnails; one photo may be shared by several items on the same plate.
class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Global id, stable across devices and backups (the integer [id] is local).
  TextColumn get uuid => text().clientDefault(newUuid)();
  BlobColumn get jpeg => blob()();
}

/// Logged items. Nutrition is stored as totals (already multiplied by the portion),
/// so edits to the catalog never rewrite history. [name] is a snapshot used when the
/// dish is no longer in the catalog.
///
/// Deleting only marks a row as [deleted] (a tombstone): when backups from different
/// moments are merged, the newest [updatedAtMs] wins and deleted items stay deleted.
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Global id, stable across devices and backups (the integer [id] is local).
  TextColumn get uuid => text().clientDefault(newUuid)();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get dishId => text()();
  TextColumn get name => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get fat => real()();
  RealColumn get carbs => real()();
  IntColumn get photoId => integer().nullable().references(Photos, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last change, epoch milliseconds (drift's DateTime is only second-precise, too coarse
  /// to order edits made in quick succession).
  IntColumn get updatedAtMs => integer().clientDefault(_nowMs)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

class NewMeal {
  const NewMeal({
    required this.dishId,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final String dishId;
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
}

@DriftDatabase(tables: [Photos, Meals])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'calorie_cam',
              web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
            ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX meals_eaten_at ON meals (eaten_at)');
      await _createUuidIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: global ids, change time and tombstones. SQLite can't add a NOT NULL column
        // without a default, so the columns get placeholder defaults and are filled in here.
        await customStatement("ALTER TABLE photos ADD COLUMN uuid TEXT NOT NULL DEFAULT ''");
        await customStatement("ALTER TABLE meals ADD COLUMN uuid TEXT NOT NULL DEFAULT ''");
        await customStatement('ALTER TABLE meals ADD COLUMN updated_at_ms INTEGER NOT NULL DEFAULT 0');
        await m.addColumn(meals, meals.deleted);
        await customStatement('UPDATE meals SET updated_at_ms = created_at * 1000');
        for (final table in ['photos', 'meals']) {
          final rows = await customSelect('SELECT id FROM $table').get();
          for (final row in rows) {
            await customStatement('UPDATE $table SET uuid = ? WHERE id = ?', [newUuid(), row.read<int>('id')]);
          }
        }
        await _createUuidIndexes();
      }
    },
  );

  Future<void> _createUuidIndexes() async {
    await customStatement('CREATE UNIQUE INDEX photos_uuid ON photos (uuid)');
    await customStatement('CREATE UNIQUE INDEX meals_uuid ON meals (uuid)');
  }

  /// Saves a plate: the photo (if any) and all items in a single transaction.
  Future<void> addMeals(DateTime eatenAt, List<NewMeal> items, {Uint8List? thumbnail}) {
    return transaction(() async {
      final photoId = thumbnail == null ? null : await into(photos).insert(PhotosCompanion.insert(jpeg: thumbnail));
      for (final m in items) {
        await into(meals).insert(
          MealsCompanion.insert(
            eatenAt: eatenAt,
            dishId: m.dishId,
            name: m.name,
            grams: m.grams,
            kcal: m.kcal,
            protein: m.protein,
            fat: m.fat,
            carbs: m.carbs,
            photoId: Value(photoId),
          ),
        );
      }
    });
  }

  Stream<List<Meal>> watchRange(DateTime from, DateTime to) =>
      (select(meals)
            ..where(
              (m) => m.eatenAt.isBiggerOrEqualValue(from) & m.eatenAt.isSmallerThanValue(to) & m.deleted.equals(false),
            )
            ..orderBy([(m) => OrderingTerm.asc(m.eatenAt)]))
          .watch();

  Stream<List<Meal>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return watchRange(start, DateTime(day.year, day.month, day.day + 1));
  }

  /// Calories per day of the month (key is the day number).
  Stream<Map<int, double>> watchMonthTotals(DateTime month) =>
      watchRange(DateTime(month.year, month.month), DateTime(month.year, month.month + 1)).map((list) {
        final totals = <int, double>{};
        for (final m in list) {
          totals.update(m.eatenAt.day, (v) => v + m.kcal, ifAbsent: () => m.kcal);
        }
        return totals;
      });

  Future<Uint8List?> photo(int id) async =>
      (await (select(photos)..where((p) => p.id.equals(id))).getSingleOrNull())?.jpeg;

  /// Changes the portion; nutrition is rescaled proportionally.
  Future<void> updateMeal(Meal meal, {double? grams, DateTime? eatenAt}) {
    final k = (grams ?? meal.grams) / meal.grams;
    return update(meals).replace(
      meal.copyWith(
        grams: grams ?? meal.grams,
        kcal: meal.kcal * k,
        protein: meal.protein * k,
        fat: meal.fat * k,
        carbs: meal.carbs * k,
        eatenAt: eatenAt ?? meal.eatenAt,
        updatedAtMs: _nowMs(),
      ),
    );
  }

  /// Marks an item as deleted and removes its photo if nothing else uses it. Returns the
  /// removed photo so that [restoreMeal] can put everything back.
  Future<Photo?> deleteMeal(Meal meal) => transaction(() async {
    await update(meals).replace(meal.copyWith(deleted: true, updatedAtMs: _nowMs(), photoId: const Value(null)));
    final photoId = meal.photoId;
    if (photoId == null) return null;
    final stillUsed = await (select(meals)..where((m) => m.photoId.equals(photoId))).get();
    if (stillUsed.isNotEmpty) return null;
    final photo = await (select(photos)..where((p) => p.id.equals(photoId))).getSingleOrNull();
    await (delete(photos)..where((p) => p.id.equals(photoId))).go();
    return photo;
  });

  Future<void> restoreMeal(Meal meal, Photo? photo) => transaction(() async {
    if (photo != null) await into(photos).insertOnConflictUpdate(photo);
    await update(meals).replace(meal.copyWith(deleted: false, updatedAtMs: _nowMs()));
  });

  /// Removes photos that no item refers to any more.
  Future<void> deleteOrphanPhotos() =>
      customStatement('DELETE FROM photos WHERE id NOT IN (SELECT photo_id FROM meals WHERE photo_id IS NOT NULL)');
}
