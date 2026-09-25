import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:purnara/app.dart';
import 'package:purnara/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<void> pumpApp(
  WidgetTester tester,
  FakeRepository repo, {
  Map<String, Object> prefs = const {},
  Size size = const Size(400, 860),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // An Indonesian device, the main audience; English is covered by the saved choice.
  tester.platformDispatcher.localesTestValue = const [Locale('id', 'ID')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences), repositoryProvider.overrideWithValue(repo)],
      child: const PurnaraApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('without a project the welcome screen invites the user to start', (tester) async {
    await pumpApp(tester, FakeRepository());
    expect(find.text('Mulai'), findsOneWidget);
    expect(find.text('Selesaikan project besarmu, satu langkah sehari.'), findsOneWidget);
  });

  testWidgets('Today shows the focus task, its badges and the project health', (tester) async {
    await pumpApp(tester, FakeRepository(projectList: [projectJson()], todayView: todayJson()));
    expect(find.text('Fokus hari ini'), findsOneWidget);
    expect(find.text('Baca 10 jurnal utama'), findsOneWidget);
    expect(find.text('Jalur kritis'), findsOneWidget);
    expect(find.text('Sesuai jadwal'), findsOneWidget);
    expect(find.text('Bantu saya mulai'), findsOneWidget);
    // Phones get the bottom navigation bar with five destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('one tap marks a task done and offers undo', (tester) async {
    final repo = FakeRepository(projectList: [projectJson()], todayView: todayJson());
    await pumpApp(tester, repo);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(repo.updates['t1'], {'status': 'done'});
    expect(find.text('Task ditandai selesai.'), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);
  });

  testWidgets('the saved language choice switches the app to English', (tester) async {
    await pumpApp(
      tester,
      FakeRepository(projectList: [projectJson()], todayView: todayJson()),
      prefs: {'locale': 'en'},
    );
    expect(find.text("Today's focus"), findsOneWidget);
    expect(find.text('Critical path'), findsOneWidget);
  });

  testWidgets('wide screens get a navigation rail instead of a bottom bar', (tester) async {
    await pumpApp(
      tester,
      FakeRepository(projectList: [projectJson()], todayView: todayJson()),
      size: const Size(1280, 900),
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('an unreachable server is explained, with a retry button', (tester) async {
    await pumpApp(tester, FakeRepository(failWith: networkError));
    expect(find.textContaining('Tidak bisa terhubung ke server Purnara'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('the setup wizard starts with the project templates', (tester) async {
    await pumpApp(tester, FakeRepository());
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Langkah 1 dari 6'), findsOneWidget);
    expect(find.text('Skripsi'), findsOneWidget);
    // Next stays disabled until a template is chosen.
    final next = find.widgetWithText(FilledButton, 'Lanjut');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.text('Skripsi'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Judul dan deadline'), findsOneWidget);
  });
}
