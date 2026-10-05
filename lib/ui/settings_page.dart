import 'package:flutter/material.dart';

import '../services.dart';
import 'format.dart';

/// Daily goal and UI language.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// Language names are shown in their own language so they are recognizable in any UI language.
  static const _languages = {'en': 'English', 'ru': 'Русский'};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: services.dailyGoal,
            builder: (context, goal, _) => ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.dailyGoal),
              subtitle: Text(l10n.dailyGoalHint),
              trailing: Text(l10n.kcal(goal), style: Theme.of(context).textTheme.titleMedium),
              onTap: () => _editDailyGoal(context),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.language, style: Theme.of(context).textTheme.titleSmall),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: services.language,
            builder: (context, language, _) => RadioGroup<String?>(
              groupValue: language,
              onChanged: (value) => services.language.value = value,
              child: Column(
                children: [
                  RadioListTile<String?>(value: null, title: Text(l10n.languageSystem)),
                  for (final MapEntry(key: code, value: name) in _languages.entries)
                    RadioListTile<String?>(value: code, title: Text(name)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDailyGoal(BuildContext context) async {
    final l10n = context.l10n;
    final text = services.dailyGoal.value.toString();
    final controller = TextEditingController.fromValue(
      TextEditingValue(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      ),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dailyGoal),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: l10n.kcalUnit),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: Text(l10n.save)),
        ],
      ),
    );
    if (value != null && value > 0) services.dailyGoal.value = value;
  }
}
