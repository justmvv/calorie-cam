import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/context_prior.dart';
import '../data/db.dart';
import '../data/dish_catalog.dart';
import '../ml/food_ai.dart';
import '../services.dart';
import 'dish_search.dart';
import 'format.dart';
import 'nutrition_dialog.dart';
import 'palette.dart';

/// An item on the plate. Nutrition is per 100 g and may be overridden by the user.
class _PlateItem {
  _PlateItem({
    required this.dishId,
    required this.name,
    required this.per100,
    required this.grams,
    required this.portion,
    this.photo,
    bool byKcal = false,
  }) : amountCtl = TextEditingController() {
    // Typing calories needs a known calorie density.
    this.byKcal = byKcal && per100.kcal > 0;
    refreshAmount();
  }

  _PlateItem.dish(Dish d, {_Photo? photo})
    : this(
        dishId: d.id,
        name: d.name('en'),
        per100: Per100(kcal: d.kcal, protein: d.protein, fat: d.fat, carbs: d.carbs),
        grams: d.portion,
        portion: d.portion,
        photo: photo,
      );

  _PlateItem.product(Product p)
    : this(
        dishId: _productId(p.uuid),
        name: p.name,
        per100: Per100(kcal: p.kcal, protein: p.protein, fat: p.fat, carbs: p.carbs),
        grams: p.portion,
        portion: p.portion,
      );

  _PlateItem.setItem(SetItem i, {_Photo? photo})
    : this(dishId: i.dishId, name: i.name, per100: i.per100, grams: i.grams, portion: i.grams, photo: photo);

  /// Catalog dish id, `product:<uuid>` for the user's products, or `custom`.
  String dishId;
  String name;
  Per100 per100;
  final double portion;

  /// The photo the item was recognized on; its thumbnail is stored with the entry.
  final _Photo? photo;

  /// Portion in grams — the source of truth for nutrition.
  double grams;

  /// Whether the amount field takes calories for the whole item instead of grams (the grams
  /// are then derived from the calorie density, so macros scale along).
  late bool byKcal;

  /// The amount field: grams, or calories when [byKcal].
  final TextEditingController amountCtl;

  static String _productId(String uuid) => 'product:$uuid';

  double get kcal => per100.kcal * grams / 100;

  void setGrams(double g) {
    grams = g;
    refreshAmount();
  }

  void setByKcal(bool value) {
    byKcal = value && per100.kcal > 0;
    refreshAmount();
  }

  /// Applies what the user typed in the amount field.
  void amountTyped(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    grams = byKcal ? v * 100 / per100.kcal : v;
  }

  void refreshAmount() => amountCtl.text = (byKcal ? kcal : grams).round().toString();

  /// Catalog dishes are shown in the current language (unless the user renamed them).
  String displayName(AppLocalizations l10n) => switch (services.catalog.byId(dishId)) {
    final dish? => l10n.dishName(dish),
    null => name,
  };
}

/// One photo of the meal and what was recognized on it.
class _Photo {
  _Photo(this.bytes);

  final Uint8List bytes;
  PhotoAnalysis? analysis;
  PlateSuggestion? suggestion;
  bool regionsDone = false;
  Object? error;

  bool get analyzing => analysis == null && error == null;
}

/// Photo recognition result (or manual entry when [image] is null) and confirmation.
/// A meal may consist of several photos (e.g. a set lunch: soup, main, dessert).
class CapturePage extends StatefulWidget {
  const CapturePage({super.key, this.image, this.initialTime});

  final Uint8List? image;
  final DateTime? initialTime;

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  late DateTime _eatenAt = widget.initialTime ?? DateTime.now();
  final _photos = <_Photo>[];
  final _plate = <_PlateItem>[];

  /// Dishes the user removed from the plate: late region results must not put them back.
  final _removed = <String>{};
  var _saving = false;

  /// Context nudges (time of day, familiar dishes over the last 90 days).
  late final Future<Map<String, double>> _prior = services.db
      .dishCounts(DateTime.now().subtract(const Duration(days: 90)))
      .then((counts) => contextPrior(services.catalog, _eatenAt, counts));

  @override
  void initState() {
    super.initState();
    if (widget.image case final image?) {
      _addPhoto(image);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchDish());
    }
  }

  @override
  void dispose() {
    for (final p in _plate) {
      p.amountCtl.dispose();
    }
    super.dispose();
  }

  void _addPhoto(Uint8List bytes) {
    final photo = _Photo(bytes);
    setState(() => _photos.add(photo));
    _analyze(photo);
  }

  Future<void> _analyze(_Photo photo) async {
    try {
      // The whole photo first, so the main dish shows up quickly…
      final analysis = await services.ai.analyze(photo.bytes);
      final prior = await _prior;
      final memory = services.memories.value;
      if (!mounted) return;
      setState(() {
        photo.analysis = analysis;
        photo.suggestion = services.catalog.suggestPlate(analysis.embedding, const [], memory: memory, prior: prior);
        _preselect(photo);
      });
      // …then parts of it, to find a side dish or salad next to the main one.
      final regions = await services.ai.analyzeRegions(photo.bytes);
      if (!mounted) return;
      setState(() {
        photo.suggestion = services.catalog.suggestPlate(analysis.embedding, regions, memory: memory, prior: prior);
        photo.regionsDone = true;
        _preselect(photo);
      });
    } catch (e) {
      if (mounted) setState(() => photo.error = e);
    }
  }

  void _preselect(_Photo photo) {
    // A near-identical past photo: put exactly what was logged then (incl. own products).
    if (photo.suggestion!.memory case final m? when m.confident) {
      for (final item in m.items) {
        if (_removed.contains(item.dishId) || _onPlate(item.dishId)) continue;
        _plate.add(_PlateItem.setItem(item, photo: photo));
      }
      return;
    }
    for (final dish in photo.suggestion!.preselected) {
      if (_removed.contains(dish.id) || _onPlate(dish.id)) continue;
      _plate.add(_PlateItem.dish(dish, photo: photo));
    }
  }

  bool _onPlate(String dishId) => _plate.any((p) => p.dishId == dishId);

  /// Tapping an option of a photo. If the dish is on the plate, it is removed. Otherwise it
  /// replaces the item of the same role recognized on that photo — picking "Manti" instead of
  /// the suggested "Pelmeni" swaps them, while the side dish next to them stays. With
  /// [keepOthers] (long press) the dish is added alongside, for photos with two main dishes.
  void _choose(Dish dish, _Photo photo, {bool keepOthers = false}) => setState(() {
    final existing = _plate.indexWhere((p) => p.dishId == dish.id);
    if (existing >= 0) {
      _remove(_plate[existing]);
      return;
    }
    var at = _plate.length;
    if (!keepOthers) {
      final role = DishCatalog.roleOf(dish);
      final replaced = _plate.where((p) => p.photo == photo && _roleOf(p) == role).toList();
      if (replaced.isNotEmpty) at = _plate.indexOf(replaced.first);
      replaced.forEach(_remove);
    }
    _removed.remove(dish.id);
    _plate.insert(at.clamp(0, _plate.length), _PlateItem.dish(dish, photo: photo));
  });

  /// Adds a dish picked in the catalog search (never replaces anything).
  void _addDish(Dish dish) => setState(() {
    _removed.remove(dish.id);
    _plate.add(_PlateItem.dish(dish));
  });

  static PlateRole? _roleOf(_PlateItem item) => switch (services.catalog.byId(item.dishId)) {
    final dish? => DishCatalog.roleOf(dish),
    null => null, // own products and custom items are never replaced by a tap
  };

  void _remove(_PlateItem item) {
    _removed.add(item.dishId);
    _plate.remove(item);
    item.amountCtl.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) _addPhoto(bytes);
  }

  Future<void> _searchDish() async {
    final choice = await showDishSearch(context);
    if (!mounted || choice == null) return;
    switch (choice) {
      case CatalogChoice(:final dish):
        if (!_onPlate(dish.id)) _addDish(dish);
      case ProductChoice(:final product):
        setState(() => _plate.add(_PlateItem.product(product)));
      case SetChoice(:final set):
        setState(() => _plate.addAll(SetItem.listFromJson(set.items).map(_PlateItem.setItem)));
      case ManualChoice():
        await _addManual();
    }
  }

  /// A custom item: the user types the calories in (e.g. from the package).
  Future<void> _addManual() async {
    final l10n = context.l10n;
    // Usually it's "this whole thing had N kcal": start with calories for the whole item.
    final input = await showNutritionDialog(context, name: '', grams: 100, perPortion: true);
    if (input == null || !mounted) return;
    final name = input.name.isEmpty ? l10n.customItem : input.name;
    var dishId = 'custom';
    if (input.saveAsProduct) {
      final product = await services.db.saveProduct(name: name, per100: input.per100, portion: 100);
      dishId = _PlateItem._productId(product.uuid);
    }
    if (!mounted) return;
    setState(
      () => _plate.add(
        _PlateItem(dishId: dishId, name: name, per100: input.per100, grams: 100, portion: 100, byKcal: true),
      ),
    );
  }

  Future<void> _editNutrition(_PlateItem item) async {
    final l10n = context.l10n;
    final input = await showNutritionDialog(
      context,
      name: item.displayName(l10n),
      initial: item.per100,
      grams: item.grams > 0 ? item.grams : item.portion,
    );
    if (input == null || !mounted) return;
    final renamed = input.name.isNotEmpty && input.name != item.displayName(l10n);
    String? productId;
    if (input.saveAsProduct) {
      final name = input.name.isEmpty ? item.displayName(l10n) : input.name;
      final product = await services.db.saveProduct(name: name, per100: input.per100, portion: item.portion);
      productId = _PlateItem._productId(product.uuid);
    }
    if (!mounted) return;
    setState(() {
      item.per100 = input.per100;
      item.setByKcal(item.byKcal); // the field shows calories: refresh it (or leave calorie mode if 0)
      if (renamed) {
        item.name = input.name;
        if (services.catalog.byId(item.dishId) != null) item.dishId = 'custom';
      }
      if (productId != null) item.dishId = productId;
    });
  }

  Future<void> _saveAsSet() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveAsSet),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.setName),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    await services.db.saveSet(name.trim(), [
      for (final p in _plate)
        if (p.grams > 0) SetItem(dishId: p.dishId, name: p.displayName(l10n), grams: p.grams, per100: p.per100),
    ]);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.setSaved(name.trim()))));
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eatenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_eatenAt));
    if (t == null) return;
    setState(() => _eatenAt = DateTime(date.year, date.month, date.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    final items = [
      for (final p in _plate)
        if (p.grams > 0)
          NewMeal(
            dishId: p.dishId,
            name: p.displayName(l10n),
            grams: p.grams,
            kcal: p.kcal,
            protein: p.per100.protein * p.grams / 100,
            fat: p.per100.fat * p.grams / 100,
            carbs: p.per100.carbs * p.grams / 100,
            thumbnail: p.photo?.analysis?.thumbnail ?? _photos.firstOrNull?.analysis?.thumbnail,
          ),
    ];
    try {
      await services.db.addMeals(_eatenAt, items);
      // Remember what each photo turned out to be, for recognizing it next time.
      for (final photo in _photos) {
        final embedding = photo.analysis?.embedding;
        final onPhoto = [
          for (final p in _plate)
            if (p.grams > 0 && (p.photo == photo || _photos.length == 1))
              SetItem(dishId: p.dishId, name: p.displayName(l10n), grams: p.grams, per100: p.per100),
        ];
        if (embedding != null && onPhoto.isNotEmpty) {
          await services.db.addMemory(embedding, onPhoto, model: services.catalog.model);
        }
      }
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
      return;
    }
    if (mounted) Navigator.pop(context, items.fold(0.0, (a, m) => a + m.kcal));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = _plate.fold(0.0, (a, p) => a + p.kcal);
    final canSave = !_saving && _plate.any((p) => p.grams > 0);
    return Scaffold(
      appBar: AppBar(
        title: Text(_photos.isEmpty ? l10n.addManually : l10n.whatsInPhoto),
        actions: [
          IconButton(
            tooltip: l10n.saveAsSet,
            onPressed: _plate.isEmpty ? null : _saveAsSet,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, photo) in _photos.indexed) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(photo.bytes, height: i == 0 ? 240 : 160, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            _recognition(l10n, photo),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(onPressed: _searchDish, icon: const Icon(Icons.search), label: Text(l10n.searchCatalog)),
              TextButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                onLongPress: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l10n.addPhoto),
              ),
            ],
          ),
          for (final item in _plate) _plateCard(l10n, item),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.mealTime),
            subtitle: Text('${l10n.dayTitle(_eatenAt)}, ${l10n.time(_eatenAt)}'),
            onTap: _pickTime,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            onPressed: canSave ? _save : null,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(_plate.isEmpty ? l10n.chooseDish : l10n.addToDiary(l10n.kcal(total))),
          ),
        ),
      ),
    );
  }

  Widget _recognition(AppLocalizations l10n, _Photo photo) {
    if (photo.error != null) {
      return ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(l10n.recognitionFailed),
        subtitle: Text(l10n.chooseManually('${photo.error}')),
      );
    }
    if (photo.analyzing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const LinearProgressIndicator(), const SizedBox(height: 8), Text(l10n.recognizing)],
      );
    }
    final memory = photo.suggestion!.memory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (memory != null) _memoryCard(l10n, photo, memory),
        Text(l10n.looksLike, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in photo.suggestion!.options)
              GestureDetector(
                onLongPress: () => _choose(m.dish, photo, keepOthers: true),
                child: FilterChip(
                  label: Text('${l10n.dishName(m.dish)} · ${l10n.percent(m.probability)}'),
                  selected: _onPlate(m.dish.id),
                  onSelected: (_) => _choose(m.dish, photo),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l10n.chipsHint, style: Theme.of(context).textTheme.bodySmall),
        if (!photo.regionsDone) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.lookingForSides, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ],
      ],
    );
  }

  /// A past photo that looks like this one: what was logged then, and a button to take it over
  /// (when the match is confident, it is on the plate already).
  Widget _memoryCard(AppLocalizations l10n, _Photo photo, MemoryMatch memory) {
    final kcal = memory.items.fold(0.0, (a, i) => a + i.per100.kcal * i.grams / 100);
    final names = memory.items.map((i) => _PlateItem.setItem(i).displayName(l10n)).join(', ');
    final applied = memory.items.every((i) => _onPlate(i.dishId));
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(l10n.memoryMatch(l10n.percent(memory.similarity))),
        subtitle: Text('$names · ${l10n.kcal(kcal)}'),
        trailing: applied
            ? const Icon(Icons.check)
            : FilledButton.tonal(onPressed: () => _applyMemory(photo, memory), child: Text(l10n.memoryUse)),
      ),
    );
  }

  /// Replaces what was recognized on [photo] by what was logged for the similar past photo.
  void _applyMemory(_Photo photo, MemoryMatch memory) => setState(() {
    _plate.where((p) => p.photo == photo).toList().forEach(_remove);
    for (final item in memory.items) {
      _removed.remove(item.dishId);
      if (!_onPlate(item.dishId)) _plate.add(_PlateItem.setItem(item, photo: photo));
    }
  });

  Widget _plateCard(AppLocalizations l10n, _PlateItem item) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.displayName(l10n), style: textTheme.titleMedium)),
                Text(l10n.kcal(item.kcal), style: textTheme.titleMedium),
                IconButton(
                  onPressed: () => setState(() => _remove(item)),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.remove,
                ),
              ],
            ),
            // Tapping the nutrition line lets the user type in the numbers from the package.
            InkWell(
              onTap: () => _editNutrition(item),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${l10n.per100g(l10n.kcal(item.per100.kcal))} · '
                        '${l10n.macrosOf(item.per100.protein, item.per100.fat, item.per100.carbs)}',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 16, semanticLabel: l10n.editNutrition),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 118, // fits four digits plus "kcal"/"ккал"
                  child: TextField(
                    controller: item.amountCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: item.byKcal ? l10n.kcalUnit : l10n.gramsUnit,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (text) => setState(() => item.amountTyped(text)),
                  ),
                ),
                const SizedBox(width: 4),
                // Grams or calories for the whole item, e.g. when the calories are known exactly.
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(l10n.gramsUnit)),
                    ButtonSegment(value: true, label: Text(l10n.kcalUnit), enabled: item.per100.kcal > 0),
                  ],
                  selected: {item.byKcal},
                  onSelectionChanged: (s) => setState(() => item.setByKcal(s.single)),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (label, k) in const [('½', 0.5), ('×1', 1.0), ('×1.5', 1.5), ('×2', 2.0)])
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ActionChip(
                              label: Text(label),
                              tooltip: l10n.grams(item.portion * k),
                              onPressed: () => setState(() => item.setGrams(item.portion * k)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
