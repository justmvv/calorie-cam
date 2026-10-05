import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'l10n/app_localizations.dart';

/// Build id: CI passes `--dart-define=BUILD_ID=<sha>` and publishes the same id in
/// build_id.txt. Empty in local builds, which disables the check.
const buildId = String.fromEnvironment('BUILD_ID');

/// Auto-update: compares the running build with the published one (build_id.txt) on start,
/// when the app returns to the foreground, and every 30 minutes.
///
/// If a new version is out and the user is on the home screen, the page reloads silently.
/// If they are in the middle of an entry, an "Update" button is shown instead so nothing is lost.
class UpdateChecker with WidgetsBindingObserver {
  UpdateChecker(this.navigatorKey, this.messengerKey);

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  static const _period = Duration(minutes: 30);

  /// Guards against a reload loop while the CDN still serves the old main.dart.js.
  static const _reloadGuardKey = 'calorie_cam_reload_target';

  var _bannerShown = false;

  void start() {
    if (buildId.isEmpty) return;
    WidgetsBinding.instance.addObserver(this);
    Timer.periodic(_period, (_) => _check());
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final latest = await _fetchLatest();
    if (latest == null || latest == buildId) return;

    final guard = _session(_reloadGuardKey);
    final onHome = !(navigatorKey.currentState?.canPop() ?? true);
    if (onHome && guard != latest) {
      _setSession(_reloadGuardKey, latest);
      web.window.location.reload();
    } else {
      _showBanner();
    }
  }

  Future<String?> _fetchLatest() async {
    try {
      final url = 'build_id.txt?t=${DateTime.now().millisecondsSinceEpoch}';
      final res = await web.window.fetch(url.toJS, web.RequestInit(cache: 'no-store')).toDart;
      if (!res.ok) return null;
      final text = (await res.text().toDart).toDart.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null; // offline: try again next time
    }
  }

  void _showBanner() {
    if (_bannerShown) return;
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    _bannerShown = true;
    final l10n = AppLocalizations.of(messenger.context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.updateAvailable),
        duration: const Duration(days: 1),
        action: SnackBarAction(label: l10n.update, onPressed: () => web.window.location.reload()),
      ),
    );
  }

  static String? _session(String key) {
    try {
      return web.window.sessionStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  static void _setSession(String key, String value) {
    try {
      web.window.sessionStorage.setItem(key, value);
    } catch (_) {}
  }
}
