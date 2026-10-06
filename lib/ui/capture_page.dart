import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/db.dart';
import '../data/dish_catalog.dart';
import '../ml/food_ai.dart';
import '../services.dart';
import 'dish_search.dart';
import 'format.dart';
import 'palette.dart';

/// An item on the plate: a dish and its portion.
class _PlateItem {
  _PlateItem(this.dish) : gramsCtl = TextEditingController(text: dish.portion.round().toString());

  final Dish dish;
  final TextEditingController gramsCtl;

  double get grams => double.tryParse(gramsCtl.text.replaceAll(',', '.')) ?? 0;
  double get kcal => dish.kcal * grams / 100;
}

/// Photo recognition result (or manual entry when [image] is null) and confirmation.
class CapturePage extends StatefulWidget {
  const CapturePage({super.key, this.image, this.initialTime});

  final Uint8List? image;
  final DateTime? initialTime;

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  late DateTime _eatenAt = widget.initialTime ?? DateTime.now();
  PhotoAnalysis? _analysis;
  List<DishMatch> _matches = const [];
  final _plate = <_PlateItem>[];
  Object? _error;
  var _saving = false;

  bool get _analyzing => widget.image != null && _analysis == null && _error == null;

  @override
  void initState() {
    super.initState();
    if (widget.image != null) {
      _analyze();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchDish());
    }
  }

  Future<void> _searchDish() async {
    final dish = await showDishSearch(context);
    if (dish != null && !_plate.any((p) => p.dish.id == dish.id)) _toggle(dish);
  }

  @override
  void dispose() {
    for (final p in _plate) {
      p.gramsCtl.dispose();
    }
    super.dispose();
  }

  Future<void> _analyze() async {
    try {
      final analysis = await services.ai.analyze(widget.image!);
      final matches = services.catalog.classify(analysis.embedding);
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _matches = matches;
        if (matches.isNotEmpty) _plate.add(_PlateItem(matches.first.dish));
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _toggle(Dish dish) => setState(() {
    final i = _plate.indexWhere((p) => p.dish.id == dish.id);
    if (i >= 0) {
      _plate.removeAt(i).gramsCtl.dispose();
    } else {
      _plate.add(_PlateItem(dish));
    }
  });

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
            dishId: p.dish.id,
            name: l10n.dishName(p.dish),
            grams: p.grams,
            kcal: p.kcal,
            protein: p.dish.protein * p.grams / 100,
            fat: p.dish.fat * p.grams / 100,
            carbs: p.dish.carbs * p.grams / 100,
          ),
    ];
    try {
      await services.db.addMeals(_eatenAt, items, thumbnail: _analysis?.thumbnail);
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
      appBar: AppBar(title: Text(widget.image == null ? l10n.addManually : l10n.whatsInPhoto)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(widget.image!, height: 240, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            _recognition(l10n),
          ],
          TextButton.icon(onPressed: _searchDish, icon: const Icon(Icons.search), label: Text(l10n.searchCatalog)),
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

  Widget _recognition(AppLocalizations l10n) {
    if (_error != null) {
      return ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(l10n.recognitionFailed),
        subtitle: Text(l10n.chooseManually('$_error')),
      );
    }
    if (_analyzing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(l10n.recognizing),
          const SizedBox(height: 8),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.looksLike, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in _matches)
              FilterChip(
                label: Text('${l10n.dishName(m.dish)} · ${l10n.percent(m.probability)}'),
                selected: _plate.any((p) => p.dish.id == m.dish.id),
                onSelected: (_) => _toggle(m.dish),
              ),
          ],
        ),
      ],
    );
  }

  Widget _plateCard(AppLocalizations l10n, _PlateItem item) {
    final d = item.dish;
    void setGrams(double g) => setState(() => item.gramsCtl.text = g.round().toString());
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.dishName(d), style: Theme.of(context).textTheme.titleMedium)),
                Text(l10n.kcal(item.kcal), style: Theme.of(context).textTheme.titleMedium),
                IconButton(onPressed: () => _toggle(d), icon: const Icon(Icons.close), tooltip: l10n.remove),
              ],
            ),
            Text(
              '${l10n.per100g(l10n.kcal(d.kcal))} · ${l10n.macrosOf(d.protein, d.fat, d.carbs)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: item.gramsCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: l10n.gramsUnit,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
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
                              tooltip: l10n.grams(d.portion * k),
                              onPressed: () => setGrams(d.portion * k),
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
