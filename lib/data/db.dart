import 'dart:convert';

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

/// The user's own products ("My products"), e.g. typed in from a package label.
/// Nutrition is per 100 g. Synced like [Meals]: uuid, [updatedAtMs], tombstones.
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid)();
  TextColumn get name => text()();
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get fat => real()();
  RealColumn get carbs => real()();

  /// Typical portion, g.
  RealColumn get portion => real()();
  IntColumn get updatedAtMs => integer().clientDefault(_nowMs)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

/// Saved sets of items logged together, e.g. a set lunch ("My sets").
/// [items] is a JSON list of [SetItem].
class MealSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid)();
  TextColumn get name => text()();
  TextColumn get items => text()();
  IntColumn get updatedAtMs => integer().clientDefault(_nowMs)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

/// Nutrition per 100 g.
class Per100 {
  const Per100({required this.kcal, this.protein = 0, this.fat = 0, this.carbs = 0});

  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  Map<String, Object> toJson() => {'kcal': kcal, 'protein': protein, 'fat': fat, 'carbs': carbs};

  factory Per100.fromJson(Map<String, dynamic> j) => Per100(
    kcal: (j['kcal'] as num).toDouble(),
    protein: (j['protein'] as num? ?? 0).toDouble(),
    fat: (j['fat'] as num? ?? 0).toDouble(),
    carbs: (j['carbs'] as num? ?? 0).toDouble(),
  );
}

/// One item of a saved set.
class SetItem {
  const SetItem({required this.dishId, required this.name, required this.grams, required this.per100});

  /// Catalog dish id, `product:<uuid>` for the user's products, or `custom`.
  final String dishId;
  final String name;
  final double grams;
  final Per100 per100;

  Map<String, Object> toJson() => {'dishId': dishId, 'name': name, 'grams': grams, ...per100.toJson()};

  factory SetItem.fromJson(Map<String, dynamic> j) => SetItem(
    dishId: j['dishId'] as String,
    name: j['name'] as String,
    grams: (j['grams'] as num).toDouble(),
    per100: Per100.fromJson(j),
  );

  static List<SetItem> listFromJson(String json) => [
    for (final j in (jsonDecode(json) as List).cast<Map<String, dynamic>>()) SetItem.fromJson(j),
  ];
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
    this.thumbnail,
  });

  final String dishId;
  final String name;
  final double grams;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  /// Photo this item was recognized on; items sharing the same bytes share one stored photo.
  final Uint8List? thumbnail;
}

@DriftDatabase(tables: [Photos, Meals, Products, MealSets])
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
  int get schemaVersion => 3;

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
      if (from < 3) {
        // v3: the user's own products and saved sets.
        await m.createTable(products);
        await m.createTable(mealSets);
        await _createV3Indexes();
      }
    },
  );

  Future<void> _createUuidIndexes() async {
    await customStatement('CREATE UNIQUE INDEX photos_uuid ON photos (uuid)');
    await customStatement('CREATE UNIQUE INDEX meals_uuid ON meals (uuid)');
    // On a fresh install all tables exist already.
    if (await _hasTable('products')) await _createV3Indexes();
  }

  Future<void> _createV3Indexes() async {
    await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS products_uuid ON products (uuid)');
    await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS meal_sets_uuid ON meal_sets (uuid)');
  }

  Future<bool> _hasTable(String name) async => (await customSelect(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    variables: [Variable(name)],
  ).get()).isNotEmpty;

  /// Saves a plate: its photos and all items in a single transaction. [thumbnail] is used
  /// for items that don't carry their own.
  Future<void> addMeals(DateTime eatenAt, List<NewMeal> items, {Uint8List? thumbnail}) {
    return transaction(() async {
      final photoIds = <Uint8List, int>{}; // identity map: one row per distinct photo
      Future<int?> photoIdOf(Uint8List? jpeg) async =>
          jpeg == null ? null : photoIds[jpeg] ??= await into(photos).insert(PhotosCompanion.insert(jpeg: jpeg));
      for (final m in items) {
        final photoId = await photoIdOf(m.thumbnail ?? thumbnail);
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

  Stream<List<Product>> watchProducts() =>
      (select(products)
            ..where((p) => p.deleted.equals(false))
            ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  /// Adds a product, or replaces the one with the same [uuid].
  Future<Product> saveProduct({String? uuid, required String name, required Per100 per100, required double portion}) {
    final row = ProductsCompanion(
      uuid: uuid == null ? const Value.absent() : Value(uuid),
      name: Value(name),
      kcal: Value(per100.kcal),
      protein: Value(per100.protein),
      fat: Value(per100.fat),
      carbs: Value(per100.carbs),
      portion: Value(portion),
      updatedAtMs: Value(_nowMs()),
      deleted: const Value(false),
    );
    return into(products).insertReturning(row, onConflict: DoUpdate((_) => row, target: [products.uuid]));
  }

  Future<void> deleteProduct(Product p) => update(products).replace(p.copyWith(deleted: true, updatedAtMs: _nowMs()));

  Stream<List<MealSet>> watchSets() =>
      (select(mealSets)
            ..where((s) => s.deleted.equals(false))
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .watch();

  Future<MealSet> saveSet(String name, List<SetItem> items) => into(
    mealSets,
  ).insertReturning(MealSetsCompanion.insert(name: name, items: jsonEncode([for (final i in items) i.toJson()])));

  Future<void> deleteSet(MealSet s) => update(mealSets).replace(s.copyWith(deleted: true, updatedAtMs: _nowMs()));

  /// Removes photos that no item refers to any more.
  Future<void> deleteOrphanPhotos() =>
      customStatement('DELETE FROM photos WHERE id NOT IN (SELECT photo_id FROM meals WHERE photo_id IS NOT NULL)');
}
