import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_version.dart';
import '../platform/web_files.dart';
import '../update_checker.dart' show buildId;
import '../services.dart';
import 'format.dart';
import 'share_flow.dart';

/// Daily goal, UI language and diary backup.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Language names are shown in their own language so they are recognizable in any UI language.
  static const _languages = {'en': 'English', 'es': 'Español', 'nl': 'Nederlands', 'ru': 'Русский'};

  /// The backup file, built ahead of time: Chrome opens the share sheet only within a few
  /// seconds of a tap, and serializing a diary with photos may take longer than that.
  late Future<ShareFile> _backup;

  @override
  void initState() {
    super.initState();
    _prepareBackup();
    services.dailyGoal.addListener(_prepareBackup);
    services.language.addListener(_prepareBackup);
  }

  @override
  void dispose() {
    services.dailyGoal.removeListener(_prepareBackup);
    services.language.removeListener(_prepareBackup);
    super.dispose();
  }

  void _prepareBackup() => _backup = services.prepareBackup();

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
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.backup, style: Theme.of(context).textTheme.titleSmall),
          ),
          ValueListenableBuilder<DateTime?>(
            valueListenable: services.lastExport,
            builder: (context, last, _) => ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(l10n.exportBackup),
              subtitle: Text(
                last == null
                    ? l10n.neverExported
                    : l10n.lastExport(DateFormat.yMMMd(l10n.localeName).add_Hm().format(last)),
              ),
              onTap: () => _export(context),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.importBackup),
            subtitle: Text(l10n.importHint),
            onTap: () => _import(context),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: services.storagePersisted,
            builder: (context, persisted, _) => ListTile(
              leading: Icon(persisted ? Icons.verified_user_outlined : Icons.info_outline),
              subtitle: Text(persisted ? l10n.storagePersistent : l10n.storageNotPersistent),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              appVersion.isEmpty
                  ? l10n.devBuild
                  : [
                      l10n.versionLabel(appVersion, buildNumber),
                      if (buildId.isNotEmpty) '(${buildId.substring(0, buildId.length.clamp(0, 7))})',
                    ].join(' '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _backup;
      if (!context.mounted) return;
      final outcome = await shareWithRetry(context, file);
      if (outcome == ShareOutcome.shared || outcome == ShareOutcome.downloaded) {
        services.lastExport.value = DateTime.now();
      }
      final message = switch (outcome) {
        ShareOutcome.shared => l10n.exportShared,
        ShareOutcome.downloaded => l10n.exportDownloaded,
        ShareOutcome.cancelled || ShareOutcome.needsGesture => null,
      };
      if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed('$e'))));
      _prepareBackup(); // in case preparing it was what failed
    }
  }

  Future<void> _import(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await services.importBackup();
      if (result == null) return;
      _prepareBackup();
      messenger.showSnackBar(SnackBar(content: Text(l10n.importDone(result.added, result.updated))));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importInvalid)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed('$e'))));
    }
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
