import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// A catalog dish. Nutrition values are per 100 g.
class Dish {
  const Dish({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.portion,
    required this.category,
  });

  final String id;
  final String nameRu;
  final String nameEn;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  /// Typical portion, g.
  final double portion;

  /// Category id (soup, main, …); translated in the UI.
  final String category;
}

class DishMatch {
  const DishMatch(this.dish, this.probability);
  final Dish dish;
  final double probability;
}

/// Dish catalog (assets/dishes.tsv) plus MobileCLIP text embeddings
/// (assets/dish_embeddings.*, built by tools/build_embeddings.mjs).
class DishCatalog {
  DishCatalog._(this.dishes, this._byId, this._ids, this._embeddings, this._dim);

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
    final dishes = [for (final line in lines.skip(1)) _parse(line.split('\t'), col)];

    final meta = jsonDecode(await rootBundle.loadString('assets/dish_embeddings.json'));
    final bin = await rootBundle.load('assets/dish_embeddings.bin');
    final embeddings = bin.buffer.asFloat32List(bin.offsetInBytes, bin.lengthInBytes ~/ 4);

    return DishCatalog._(
      dishes,
      {for (final d in dishes) d.id: d},
      List<String>.from(meta['ids'] as List),
      embeddings,
      meta['dim'] as int,
    );
  }

  static Dish _parse(List<String> f, int Function(String) col) => Dish(
    id: f[col('id')],
    nameRu: f[col('name_ru')],
    nameEn: f[col('name_en')],
    kcal: double.parse(f[col('kcal')]),
    protein: double.parse(f[col('protein')]),
    fat: double.parse(f[col('fat')]),
    carbs: double.parse(f[col('carbs')]),
    portion: double.parse(f[col('portion')]),
    category: f[col('category')],
  );

  Dish? byId(String id) => _byId[id];

  /// Top [limit] dishes most similar to the photo.
  List<DishMatch> classify(Float32List image, {int limit = 5}) {
    final logits = List<double>.generate(_ids.length, (i) {
      var s = 0.0;
      final off = i * _dim;
      for (var k = 0; k < _dim; k++) {
        s += image[k] * _embeddings[off + k];
      }
      return s * _logitScale;
    });
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.fold(0.0, (a, b) => a + b);

    final order = List<int>.generate(_ids.length, (i) => i)..sort((a, b) => logits[b].compareTo(logits[a]));
    return [
      for (final i in order.take(limit))
        if (_byId[_ids[i]] case final dish?) DishMatch(dish, exps[i] / sum),
    ];
  }

  /// Search by name in either language (case-insensitive substring; ё and е are equivalent).
  List<Dish> search(String query) {
    String norm(String s) => s.toLowerCase().replaceAll('ё', 'е');
    final q = norm(query.trim());
    if (q.isEmpty) return dishes;
    return dishes.where((d) => norm(d.nameRu).contains(q) || norm(d.nameEn).contains(q)).toList();
  }
}
