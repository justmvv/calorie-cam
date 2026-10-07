import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/db.dart';
import 'format.dart';

class NutritionInput {
  const NutritionInput({required this.name, required this.per100, required this.saveAsProduct});

  final String name;
  final Per100 per100;
  final bool saveAsProduct;
}

/// Lets the user type nutrition in, e.g. from a package label: per 100 g or for the whole
/// portion of [grams] (converted to per 100 g). Only calories are required.
Future<NutritionInput?> showNutritionDialog(
  BuildContext context, {
  required String name,
  Per100? initial,
  required double grams,
  bool perPortion = false,
}) => showDialog<NutritionInput>(
  context: context,
  builder: (context) => _NutritionDialog(name: name, initial: initial, grams: grams, perPortion: perPortion),
);

class _NutritionDialog extends StatefulWidget {
  const _NutritionDialog({required this.name, required this.initial, required this.grams, required this.perPortion});

  final String name;
  final Per100? initial;
  final double grams;
  final bool perPortion;

  @override
  State<_NutritionDialog> createState() => _NutritionDialogState();
}

class _NutritionDialogState extends State<_NutritionDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _kcal = TextEditingController(text: _fmt(widget.initial?.kcal));
  late final _protein = TextEditingController(text: _fmt(widget.initial?.protein));
  late final _fat = TextEditingController(text: _fmt(widget.initial?.fat));
  late final _carbs = TextEditingController(text: _fmt(widget.initial?.carbs));
  late var _perPortion = widget.perPortion;
  var _save = false;

  static String _fmt(double? v) => v == null ? '' : (v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1));
  static double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  /// Switching per 100 g ↔ per portion converts the numbers already typed.
  void _setPerPortion(bool perPortion) {
    if (perPortion == _perPortion || widget.grams <= 0) return;
    final k = perPortion ? widget.grams / 100 : 100 / widget.grams;
    for (final c in [_kcal, _protein, _fat, _carbs]) {
      final v = _parse(c.text);
      if (v != null) c.text = _fmt(v * k);
    }
    setState(() => _perPortion = perPortion);
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final k = _perPortion ? 100 / widget.grams : 1.0;
    double value(TextEditingController c) => (_parse(c.text) ?? 0) * k;
    Navigator.pop(
      context,
      NutritionInput(
        name: _name.text.trim(),
        per100: Per100(kcal: value(_kcal), protein: value(_protein), fat: value(_fat), carbs: value(_carbs)),
        saveAsProduct: _save,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    Widget field(TextEditingController c, String label, {bool required = false, String? suffix}) => TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: numbers,
      decoration: InputDecoration(labelText: label, suffixText: suffix, isDense: true),
      validator: required ? (v) => (_parse(v ?? '') ?? 0) > 0 ? null : l10n.kcalRequired : null,
    );
    return AlertDialog(
      title: Text(l10n.nutritionTitle),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.productName, isDense: true),
              validator: (v) => _save && (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.per100Mode)),
                ButtonSegment(value: true, label: Text(l10n.perPortionMode(l10n.grams(widget.grams)))),
              ],
              selected: {_perPortion},
              onSelectionChanged: (s) => _setPerPortion(s.single),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            field(_kcal, l10n.kcalUnit, required: true),
            Row(
              children: [
                Expanded(child: field(_protein, l10n.proteinLabel, suffix: l10n.gramsUnit)),
                const SizedBox(width: 8),
                Expanded(child: field(_fat, l10n.fatLabel, suffix: l10n.gramsUnit)),
                const SizedBox(width: 8),
                Expanded(child: field(_carbs, l10n.carbsLabel, suffix: l10n.gramsUnit)),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _save,
              onChanged: (v) => setState(() => _save = v ?? false),
              title: Text(l10n.saveToMyProducts),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
