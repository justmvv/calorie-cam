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
      expect(d.kcal, inInclusiveRange(0, 900), reason: d.id);
      expect(d.portion, greaterThan(0), reason: d.id);
      // Calories can't be much lower than the sum from macros (4/9/4 kcal per gram).
      final fromMacros = d.protein * 4 + d.fat * 9 + d.carbs * 4;
      expect(d.kcal, greaterThan(fromMacros * 0.75), reason: d.id);
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

  test('search matches every language, ignoring case, accents and ё/е', () {
    expect(catalog.search('ЩИ').map((d) => d.id), contains('shchi'));
    expect(catalog.search('тушеная').map((d) => d.id), contains('stewed_cabbage'));
    expect(catalog.search('BORSCHT').map((d) => d.id), contains('borscht'));
    expect(catalog.search('jamon').map((d) => d.id), contains('jamon_serrano'));
    expect(catalog.search('stamppot').map((d) => d.id), contains('stamppot'));
    expect(catalog.search('aardappel').map((d) => d.id), contains('boiled_potatoes'));
    expect(catalog.search('  '), hasLength(catalog.dishes.length));
  });

  group('plate suggestion', () {
    test('adds a side found in a part of the photo', () {
      final s = catalog.suggestPlate(catalog.embeddingOf('kotleta'), [
        catalog.embeddingOf('mashed_potatoes'),
        catalog.embeddingOf('kotleta'),
      ]);
      expect(s.preselected.map((d) => d.id), ['kotleta', 'mashed_potatoes']);
      expect(s.options.map((m) => m.dish.id), contains('mashed_potatoes'));
    });

    test('one dish per role: two mains or two sides are not both preselected', () {
      final s = catalog.suggestPlate(catalog.embeddingOf('steak'), [
        catalog.embeddingOf('pelmeni'),
        catalog.embeddingOf('french_fries'),
        catalog.embeddingOf('rice'),
        catalog.embeddingOf('greek_salad'),
      ]);
      final ids = s.preselected.map((d) => d.id).toList();
      expect(ids.first, 'steak');
      expect(ids, hasLength(3));
      expect(ids, isNot(contains('pelmeni'))); // a second main
      expect(ids.where((id) => id == 'french_fries' || id == 'rice'), hasLength(1)); // one side
      expect(ids, contains('greek_salad'));
    });

    test('a single dish stays a single dish', () {
      final borscht = catalog.embeddingOf('borscht');
      final s = catalog.suggestPlate(borscht, [borscht, borscht]);
      expect(s.preselected.map((d) => d.id), ['borscht']);
    });
  });

  group('localization', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    final languages = AppLocalizations.supportedLocales.map((l) => l.languageCode);

    test('every dish has a name in every UI language', () {
      for (final lang in languages) {
        final l10n = lookupAppLocalizations(Locale(lang));
        for (final d in catalog.dishes) {
          expect(d.names[lang]?.trim(), isNotEmpty, reason: '$lang: ${d.id}');
          expect(l10n.dishName(d), d.names[lang]);
        }
      }
    });

    test('every category id is translated in every UI language', () {
      for (final lang in languages) {
        final l10n = lookupAppLocalizations(Locale(lang));
        for (final id in catalog.dishes.map((d) => d.category).toSet()) {
          expect(l10n.category(id), isNot(id), reason: '$lang: $id');
        }
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
