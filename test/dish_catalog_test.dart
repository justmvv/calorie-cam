import 'dart:typed_data';

import 'package:calorie_cam/data/dish_catalog.dart';
import 'package:calorie_cam/ui/format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DishCatalog catalog;

  setUpAll(() async => catalog = await DishCatalog.load());

  test('every catalog dish has an embedding', () {
    // If this fails, tools/build_embeddings.mjs was not run after editing assets/dishes.tsv.
    for (final d in catalog.dishes) {
      expect(catalog.byId(d.id), isNotNull);
    }
    final probe = Float32List(512)..[0] = 1;
    expect(catalog.classify(probe, limit: catalog.dishes.length + 10), hasLength(catalog.dishes.length));
  });

  test('nutrition values are plausible', () {
    for (final d in catalog.dishes) {
      expect(d.kcal, inInclusiveRange(0, 900), reason: d.nameEn);
      expect(d.portion, greaterThan(0), reason: d.nameEn);
      // Calories can't be much lower than the sum from macros (4/9/4 kcal per gram).
      final fromMacros = d.protein * 4 + d.fat * 9 + d.carbs * 4;
      expect(d.kcal, greaterThan(fromMacros * 0.75), reason: d.nameEn);
    }
  });

  test('classify returns descending probabilities that sum to at most 1', () {
    final probe = Float32List(512);
    for (var i = 0; i < probe.length; i++) {
      probe[i] = (i % 7 - 3) / 40;
    }
    final top = catalog.classify(probe);
    expect(top, hasLength(5));
    for (var i = 1; i < top.length; i++) {
      expect(top[i - 1].probability, greaterThanOrEqualTo(top[i].probability));
    }
    expect(top.fold(0.0, (a, m) => a + m.probability), lessThanOrEqualTo(1.0 + 1e-9));
  });

  test('search matches both languages, ignoring case and ё/е', () {
    expect(catalog.search('ЩИ').map((d) => d.id), contains('shchi'));
    expect(catalog.search('тушеная').map((d) => d.id), contains('stewed_cabbage'));
    expect(catalog.search('BORSCHT').map((d) => d.id), contains('borscht'));
    expect(catalog.search('  '), hasLength(catalog.dishes.length));
  });

  group('localization', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ru = lookupAppLocalizations(const Locale('ru'));

    test('every dish has a name in both languages', () {
      for (final d in catalog.dishes) {
        expect(d.nameEn.trim(), isNotEmpty, reason: d.id);
        expect(d.nameRu.trim(), isNotEmpty, reason: d.id);
        expect(en.dishName(d), d.nameEn);
        expect(ru.dishName(d), d.nameRu);
      }
    });

    test('every category id is translated', () {
      for (final id in catalog.dishes.map((d) => d.category).toSet()) {
        expect(en.category(id), isNot(id), reason: 'en: $id');
        expect(ru.category(id), isNot(id), reason: 'ru: $id');
      }
    });

    test('units follow the language', () {
      expect(en.kcal(149.6), '150 kcal');
      expect(ru.kcal(149.6), '150 ккал');
      expect(en.macrosOf(10.4, 5, 20), 'P 10 · F 5 · C 20');
      expect(ru.macrosOf(10.4, 5, 20), 'Б 10 · Ж 5 · У 20');
    });
  });
}
