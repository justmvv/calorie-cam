import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// Photo thumbnails; one photo may be shared by several items on the same plate.
class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();
  BlobColumn get jpeg => blob()();
}

/// Logged items. Nutrition is stored as totals (already multiplied by the portion),
/// so edits to the catalog never rewrite history. [name] is a snapshot used when the
/// dish is no longer in the catalog.
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
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
}

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX meals_eaten_at ON meals (eaten_at)');
    },
  );

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
            ..where((m) => m.eatenAt.isBiggerOrEqualValue(from) & m.eatenAt.isSmallerThanValue(to))
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
      ),
    );
  }

  /// Deletes an item and its photo if nothing else uses it. Returns the deleted photo
  /// so that [restoreMeal] can put everything back.
  Future<Photo?> deleteMeal(Meal meal) => transaction(() async {
    await (delete(meals)..where((m) => m.id.equals(meal.id))).go();
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
    await into(meals).insert(meal);
  });
}
