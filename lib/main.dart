import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/app_localizations.dart';
import 'services.dart';
import 'ui/home_page.dart';
import 'ui/palette.dart';
import 'update_checker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // date symbols for every supported locale
  services = await Services.init();
  runApp(const CalorieCamApp());
  UpdateChecker(_navigatorKey, _messengerKey).start();
}

final _navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class CalorieCamApp extends StatelessWidget {
  const CalorieCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: services.language,
      builder: (context, language, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        debugShowCheckedModeBanner: false,
        theme: Palette.theme(Brightness.light),
        darkTheme: Palette.theme(Brightness.dark),
        // null = follow the system; unsupported system languages fall back to English
        // (the first entry of supportedLocales).
        locale: language == null ? null : Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // On tablets/desktops keep a phone-like width, otherwise the calendar stretches.
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: child),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
