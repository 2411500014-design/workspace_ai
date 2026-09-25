import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled font's licence appears on the licences page with the packages'.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      // Riverpod 3 retries failing providers automatically; API errors such as
      // "not found" should be shown, not retried in a loop.
      retry: (retryCount, error) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PurnaraApp(),
    ),
  );
}
