import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'db.dart' show SetItem;

/// A catalog dish. Nutrition values are per 100 g.
class Dish {
  const Dish({
    required this.id,
    required this.names,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.portion,
    required this.category,
  });

  final String id;

  /// Display names by language code (en, ru, es, nl, …): the name_<code> columns of the catalog.
  final Map<String, String> names;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  /// Typical portion, g.
  final double portion;

  /// Category id (soup, main, …); translated in the UI.
  final String category;

  /// Name in [language], falling back to English.
  String name(String language) => names[language] ?? names['en']!;
}

class DishMatch {
  const DishMatch(this.dish, this.probability);
  final Dish dish;
  final double probability;
}

/// A photo the user logged before and what ended up on the plate (see Memories in db.dart).
class MemoryExample {
  const MemoryExample(this.embedding, this.items);
  final Float32List embedding;
  final List<SetItem> items;
}

/// A past photo that looks like the new one.
class MemoryMatch {
  const MemoryMatch(this.items, this.similarity);
  final List<SetItem> items;

  /// Cosine similarity of the two photos' embeddings.
  final double similarity;

  /// So similar that the same items are put on the plate right away.
  bool get confident => similarity >= DishCatalog.memoryConfident;
}

/// What a photo of a plate most likely contains: options to show, the items to put on the
/// plate right away (a main dish plus, when they're visible, a side, a salad, …), and the most
/// similar photo from the user's history.
class PlateSuggestion {
  const PlateSuggestion(this.options, this.preselected, {this.memory});
  final List<DishMatch> options;
  final List<Dish> preselected;
  final MemoryMatch? memory;
}

/// Role of a dish on a plate; at most one of each is preselected, so a set lunch can get a soup,
/// a main, a side, a salad, bread and a drink at once.
enum PlateRole { soup, main, side, salad, bread, fruit, drink, dessert }

/// Dish catalog (assets/dishes.tsv) plus MobileCLIP text embeddings
/// (assets/dish_embeddings.*, built by tools/build_embeddings.mjs).
class DishCatalog {
  DishCatalog._(this.dishes, this._byId, this._ids, this._embeddings, this._dim, this.model);

  /// The recognition model the embeddings belong to (e.g. "Xenova/mobileclip_s2").
  final String model;

  final List<Dish> dishes;
  final Map<String, Dish> _byId;
  final List<String> _ids;
  final Float32List _embeddings;
  final int _dim;

  /// Softmax "temperature" over cosine similarity. CLIP's native scale (100) almost always
  /// yields 100%/0%; 50 keeps the ranking but shows the real uncertainty.
  static const _logitScale = 50.0;

  static Future<DishCatalog> load() async {
    final tsv = await rootBundle.loadString('assets/dishes.tsv');
    final lines = const LineSplitter().convert(tsv).where((l) => l.trim().isNotEmpty && !l.startsWith('#')).toList();
    final header = lines.first.split('\t');
    int col(String name) => header.indexOf(name);
    final nameColumns = {
      for (final (i, h) in header.indexed)
        if (h.startsWith('name_')) h.substring('name_'.length): i,
    };
    final dishes = [for (final line in lines.skip(1)) _parse(line.split('\t'), col, nameColumns)];

    final meta = jsonDecode(await rootBundle.loadString('assets/dish_embeddings.json'));
    final bin = await rootBundle.load('assets/dish_embeddings.bin');
    final embeddings = bin.buffer.asFloat32List(bin.offsetInBytes, bin.lengthInBytes ~/ 4);

    return DishCatalog._(
      dishes,
      {for (final d in dishes) d.id: d},
      List<String>.from(meta['ids'] as List),
      embeddings,
      meta['dim'] as int,
      meta['model'] as String,
    );
  }

  static Dish _parse(List<String> f, int Function(String) col, Map<String, int> nameColumns) => Dish(
    id: f[col('id')],
    names: {for (final MapEntry(key: lang, value: i) in nameColumns.entries) lang: f[i]},
    kcal: double.parse(f[col('kcal')]),
    protein: double.parse(f[col('protein')]),
    fat: double.parse(f[col('fat')]),
    carbs: double.parse(f[col('carbs')]),
    portion: double.parse(f[col('portion')]),
    category: f[col('category')],
  );

  Dish? byId(String id) => _byId[id];

  /// Top [limit] dishes most similar to the photo.
  ///
  /// [bonus] is added to the logits of the given dishes (memory of similar past photos,
  /// time of day, how often a dish is eaten — see [memoryBonus] and context_prior.dart).
  List<DishMatch> classify(Float32List image, {int limit = 5, Map<String, double> bonus = const {}}) {
    final logits = List<double>.generate(_ids.length, (i) {
      var s = 0.0;
      final off = i * _dim;
      for (var k = 0; k < _dim; k++) {
        s += image[k] * _embeddings[off + k];
      }
      return s * _logitScale + (bonus[_ids[i]] ?? 0);
    });
    // Invalid numbers (a broken model run) must not turn into "the first dishes of the catalog".
    if (logits.any((l) => !l.isFinite)) return const [];
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.fold(0.0, (a, b) => a + b);

    final order = List<int>.generate(_ids.length, (i) => i)..sort((a, b) => logits[b].compareTo(logits[a]));
    return [
      for (final i in order.take(limit))
        if (_byId[_ids[i]] case final dish?) DishMatch(dish, exps[i] / sum),
    ];
  }

  /// Combines the whole-photo result with results for parts of the photo (web/food_ai.js
  /// regions): the main dish comes from the whole photo; a side, salad, … found confidently in
  /// some part is added too, so "cutlet with mashed potatoes" isn't logged as just a cutlet.
  ///
  /// [memory] are the user's past photos; [prior] a per-dish logit bonus from the context.
  PlateSuggestion suggestPlate(
    Float32List whole,
    List<Float32List> regions, {
    List<MemoryExample> memory = const [],
    Map<String, double> prior = const {},
  }) {
    final (bonus, match) = memoryBonus(whole, memory);
    for (final MapEntry(:key, :value) in prior.entries) {
      bonus.update(key, (v) => v + value, ifAbsent: () => value);
    }
    final options = classify(whole, bonus: bonus);
    if (options.isEmpty) return PlateSuggestion(const [], const [], memory: match);
    final regionTops = [for (final r in regions) ?classify(r, limit: 1, bonus: prior).firstOrNull]
      ..sort((a, b) => b.probability.compareTo(a.probability));

    final preselected = [options.first.dish];
    final roles = {roleOf(options.first.dish)};
    final extra = <DishMatch>[];
    for (final m in regionTops) {
      final role = roleOf(m.dish);
      if (roles.contains(role) || m.probability < _minRegionProbability[role]!) continue;
      if (preselected.length >= maxPreselected) break;
      preselected.add(m.dish);
      roles.add(role);
      if (!options.any((o) => o.dish.id == m.dish.id)) extra.add(m);
    }
    // A dish may score low on the whole photo but high on its own part: show the higher score.
    final best = {for (final m in regionTops.reversed) m.dish.id: m.probability};
    return PlateSuggestion(
      [
        for (final o in [...options, ...extra])
          DishMatch(o.dish, (best[o.dish.id] ?? 0) > o.probability ? best[o.dish.id]! : o.probability),
      ],
      preselected,
      memory: match,
    );
  }

  /// At most this many items are put on the plate automatically (a set lunch: soup, main, side,
  /// salad, drink).
  static const maxPreselected = 5;

  // Memory tuning for MobileCLIP-S2 (tools/eval_set.mjs on 763 Wikipedia photos; different
  // dishes exceed 0.767 photo similarity in only 0.1% of pairs). The user's own repeated meals
  // look much more alike than different photos of a dish, so real matches are stronger.
  /// Below this photo-to-photo similarity a past photo says nothing.
  static const memoryFloor = 0.65;

  /// Logit bonus per unit of similarity above [memoryFloor], in units of the logit scale.
  static const memoryWeight = 1.0; // grid search: 4 hurt, 1 best (+2.7 pp top-1)

  /// From this similarity on, the past plate is suggested as a whole.
  static const memorySuggest = 0.8;

  /// From this similarity on, the past plate is put on the plate right away.
  static const memoryConfident = 0.9;

  /// Logit bonuses for catalog dishes seen on similar past photos, and the most similar past
  /// photo if it is similar enough to suggest its whole plate.
  (Map<String, double>, MemoryMatch?) memoryBonus(Float32List image, List<MemoryExample> memory) {
    final bonus = <String, double>{};
    MemoryExample? best;
    var bestSim = -1.0;
    for (final m in memory) {
      var sim = 0.0;
      for (var k = 0; k < _dim; k++) {
        sim += image[k] * m.embedding[k];
      }
      if (sim > bestSim) (best, bestSim) = (m, sim);
      if (sim <= memoryFloor) continue;
      final b = memoryWeight * (sim - memoryFloor) * _logitScale;
      for (final item in m.items) {
        if (_byId.containsKey(item.dishId) && b > (bonus[item.dishId] ?? 0)) bonus[item.dishId] = b;
      }
    }
    final match = best != null && bestSim >= memorySuggest ? MemoryMatch(best.items, bestSim) : null;
    return (bonus, match);
  }

  /// How sure a part of the photo must be before its dish is added to the plate. Sides and
  /// salads are often small and get low scores; drinks and desserts are easy to hallucinate.
  static const _minRegionProbability = {
    PlateRole.main: 0.3, // next to a soup, e.g. on a set lunch tray
    PlateRole.soup: 0.4, // lower lets sauces pass for soups
    PlateRole.side: 0.15,
    PlateRole.salad: 0.15,
    PlateRole.bread: 0.3,
    PlateRole.fruit: 0.3,
    PlateRole.drink: 0.4,
    PlateRole.dessert: 0.4,
  };

  static const _sideDishIds = {'french_fries'};

  static PlateRole roleOf(Dish d) => switch (d.category) {
    _ when _sideDishIds.contains(d.id) => PlateRole.side,
    'soup' => PlateRole.soup,
    'side' => PlateRole.side,
    'salad' || 'vegetable' => PlateRole.salad,
    'bread' => PlateRole.bread,
    'fruit' => PlateRole.fruit,
    'drink' => PlateRole.drink,
    'dessert' => PlateRole.dessert,
    _ => PlateRole.main,
  };

  @visibleForTesting
  Float32List embeddingOf(String id) {
    final i = _ids.indexOf(id);
    return Float32List.sublistView(_embeddings, i * _dim, (i + 1) * _dim);
  }

  /// Search by name in any language (case-insensitive substring; accents are ignored
  /// and ё matches е, so "jamon" finds "jamón" and "тушеная" finds "тушёная").
  List<Dish> search(String query) {
    if (query.trim().isEmpty) return dishes;
    return dishes.where((d) => d.names.values.any((n) => matchesQuery(n, query))).toList();
  }

  /// The same matching for any name (e.g. the user's own products).
  static bool matchesQuery(String name, String query) {
    final q = _fold(query.trim());
    return q.isEmpty || _fold(name).contains(q);
  }

  static const _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ï': 'i',
    'ó': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'ç': 'c',
    'ё': 'е',
  };

  static String _fold(String s) => s.toLowerCase().split('').map((c) => _accents[c] ?? c).join();
}
