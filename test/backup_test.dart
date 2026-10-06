import 'dart:convert';

import 'package:calorie_cam/data/backup.dart';
import 'package:calorie_cam/data/db.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory());

const settings = BackupSettings(dailyGoal: 1800, language: 'nl');

NewMeal meal(String dishId, double grams, double kcalPer100) =>
    NewMeal(dishId: dishId, name: dishId, grams: grams, kcal: kcalPer100 * grams / 100, protein: 1, fat: 1, carbs: 1);

Future<List<Meal>> allMeals(AppDatabase db) => db.select(db.meals).get();

void main() {
  // Each test opens several independent in-memory databases on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('new items get unique uuids', () async {
    await db.addMeals(DateTime(2026, 10, 1, 13), [meal('borscht', 300, 49), meal('blini', 150, 230)]);
    final uuids = (await allMeals(db)).map((m) => m.uuid).toSet();
    expect(uuids, hasLength(2));
    expect(
      uuids.every((u) => RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(u)),
      isTrue,
    );
  });

  test('delete is a tombstone hidden from the diary; undo brings the item and photo back', () async {
    final day = DateTime(2026, 10, 2, 9);
    await db.addMeals(day, [meal('oatmeal', 250, 105)], thumbnail: Uint8List.fromList([1, 2, 3]));
    final m = (await allMeals(db)).single;

    final photo = await db.deleteMeal(m);
    expect(photo, isNotNull);
    expect(await db.watchDay(day).first, isEmpty);
    expect((await allMeals(db)).single.deleted, isTrue);
    expect(await db.select(db.photos).get(), isEmpty);

    await db.restoreMeal(m, photo);
    final restored = (await db.watchDay(day).first).single;
    expect(restored.uuid, m.uuid);
    expect(await db.photo(restored.photoId!), [1, 2, 3]);
  });

  test('export → import into an empty diary restores items, photos and settings', () async {
    await db.addMeals(DateTime(2026, 10, 3, 19), [meal('plov', 300, 190)], thumbnail: Uint8List.fromList([9, 9]));
    final json = await Backup.export(db, settings: settings);

    final other = memoryDb();
    addTearDown(other.close);
    final result = await Backup.import(other, json);
    expect(result.added, 1);
    expect(result.settings?.dailyGoal, 1800);
    expect(result.settings?.language, 'nl');

    final a = (await allMeals(db)).single, b = (await allMeals(other)).single;
    expect(b.uuid, a.uuid);
    expect(b.kcal, a.kcal);
    expect(b.eatenAt, a.eatenAt);
    expect(await other.photo(b.photoId!), [9, 9]);
  });

  test('importing the same backup twice adds nothing', () async {
    await db.addMeals(DateTime(2026, 10, 4, 8), [meal('syrniki', 200, 220)]);
    final json = await Backup.export(db, settings: settings);
    final result = await Backup.import(db, json);
    expect((result.added, result.updated, result.unchanged), (0, 0, 1));
    expect(result.settings, isNull); // the diary wasn't empty
    expect(await allMeals(db), hasLength(1));
  });

  test('merge: newer edits win, deletions are kept, other device items are added', () async {
    await db.addMeals(DateTime(2026, 10, 5, 13), [meal('pelmeni', 250, 275), meal('tea', 250, 1)]);
    final backup = await Backup.export(db, settings: settings);

    // Since the backup: one item edited, one deleted.
    final [pelmeni, tea] = await allMeals(db);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await db.updateMeal(pelmeni, grams: 400);
    await db.deleteMeal(tea);

    // The old backup must not undo either change…
    var result = await Backup.import(db, backup);
    expect(result.updated, 0);
    final now = {for (final m in await allMeals(db)) m.dishId: m};
    expect(now['pelmeni']!.grams, 400);
    expect(now['tea']!.deleted, isTrue);

    // …while a backup made on another device brings its items in.
    final phone2 = memoryDb();
    addTearDown(phone2.close);
    await phone2.addMeals(DateTime(2026, 10, 6, 20), [meal('stroopwafel', 30, 460)]);
    result = await Backup.import(db, await Backup.export(phone2, settings: settings));
    expect(result.added, 1);
    expect((await allMeals(db)).map((m) => m.dishId), containsAll(['pelmeni', 'tea', 'stroopwafel']));
  });

  test('a newer backup updates the local copy', () async {
    await db.addMeals(DateTime(2026, 10, 7, 12), [meal('paella', 350, 160)]);
    final other = memoryDb();
    addTearDown(other.close);
    await Backup.import(other, await Backup.export(db, settings: settings));

    await Future<void>.delayed(const Duration(milliseconds: 10));
    await other.updateMeal((await allMeals(other)).single, grams: 500);
    final result = await Backup.import(db, await Backup.export(other, settings: settings));
    expect(result.updated, 1);
    expect((await allMeals(db)).single.grams, 500);
  });

  test('rejects files that are not backups, and damaged backups change nothing', () async {
    await db.addMeals(DateTime(2026, 10, 8, 9), [meal('omelette', 150, 150)]);
    await expectLater(Backup.import(db, 'hello'), throwsFormatException);
    await expectLater(Backup.import(db, '{"format": "other"}'), throwsFormatException);
    await expectLater(Backup.import(db, '{"format": "calorie-cam-backup", "version": 99}'), throwsFormatException);

    final damaged = jsonDecode(await Backup.export(db, settings: settings)) as Map<String, dynamic>;
    final first = Map<String, dynamic>.of((damaged['meals'] as List).first as Map<String, dynamic>)
      ..['uuid'] = 'new-item'
      ..remove('kcal');
    damaged['meals'] = [first];
    await expectLater(Backup.import(db, jsonEncode(damaged)), throwsFormatException);
    expect(await allMeals(db), hasLength(1));
  });

  test('migration from schema v1 keeps the data and assigns uuids', () async {
    final v1 = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('CREATE TABLE photos (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, jpeg BLOB NOT NULL)');
          raw.execute('''CREATE TABLE meals (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, eaten_at INTEGER NOT NULL,
            dish_id TEXT NOT NULL, name TEXT NOT NULL, grams REAL NOT NULL, kcal REAL NOT NULL, protein REAL NOT NULL,
            fat REAL NOT NULL, carbs REAL NOT NULL, photo_id INTEGER NULL REFERENCES photos (id),
            created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''');
          raw.execute('CREATE INDEX meals_eaten_at ON meals (eaten_at)');
          raw.execute("INSERT INTO photos (jpeg) VALUES (x'0102')");
          raw.execute(
            "INSERT INTO meals (eaten_at, dish_id, name, grams, kcal, protein, fat, carbs, photo_id) "
            "VALUES (1791000000, 'borscht', 'Борщ', 300, 147, 3, 6, 20, 1), "
            "(1791003600, 'tea', 'Чай', 250, 2.5, 0, 0, 0.5, NULL)",
          );
          raw.userVersion = 1;
        },
      ),
    );
    addTearDown(v1.close);

    final meals = await allMeals(v1);
    expect(meals.map((m) => m.dishId), ['borscht', 'tea']);
    expect(meals.map((m) => m.uuid).toSet(), hasLength(2));
    expect(meals.every((m) => !m.deleted && m.updatedAtMs == m.createdAt.millisecondsSinceEpoch), isTrue);
    expect((await v1.select(v1.photos).get()).single.uuid, isNotEmpty);
    await v1.addMeals(DateTime(2026, 10, 9), [meal('kefir', 250, 51)]); // still writable
    expect(await allMeals(v1), hasLength(3));
  });
}
