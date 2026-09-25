import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/l10n.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'router.dart';

class PurnaraApp extends ConsumerWidget {
  const PurnaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      // Indonesian unless the device (or the user) asks for English.
      localeResolutionCallback: (device, supported) =>
          supported.firstWhere((l) => l.languageCode == device?.languageCode, orElse: () => const Locale('id')),
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
