import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:purnara/app.dart';
import 'package:purnara/data/models.dart';
import 'package:purnara/data/providers.dart';
import 'package:purnara/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixture_api.dart';

/// Every screen, fed with what the real backend answers for the sample project.
final fixtures = {
  for (final locale in ['id', 'en']) locale: loadSampleFixture(locale),
};

const phone = Size(390, 844);
const desktop = Size(1280, 860);

class Sample {
  Sample(this.tester, this.api, this.fixture);

  final WidgetTester tester;
  final FixtureApiClient api;
  final Json fixture;

  String get projectId => fixture['project_id'] as String;
  Json get answers => Json.from(fixture['answers'] as Map);

  ProviderContainer get container => ProviderScope.containerOf(tester.element(find.byType(PurnaraApp)));

  Future<void> go(String location) async {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  Future<void> push(String location) async {
    container.read(routerProvider).push(location);
    await tester.pumpAndSettle();
  }

  String taskId(String key) =>
      (answers['GET /projects/$projectId/plan']['tasks'] as List).firstWhere((t) => t['key'] == key)['id'] as String;

  String get pendingSuggestionId => (answers['GET /projects/$projectId/suggestions'] as List).first['id'] as String;
}

Future<Sample> pumpSample(
  WidgetTester tester, {
  String locale = 'id',
  Size size = phone,
  ThemeMode theme = ThemeMode.light,
  void Function(FixtureApiClient api, Json fixture)? setUp,
  Map<String, Object> prefs = const {},
}) async {
  final fixture = fixtures[locale]!;
  final api = FixtureApiClient(fixture);
  setUp?.call(api, fixture);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [Locale(locale)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  SharedPreferences.setMockInitialValues({
    'locale': locale,
    'theme_mode': theme.name,
    'project_id': fixture['project_id'] as String,
    ...prefs,
  });
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences), apiClientProvider.overrideWithValue(api)],
      child: const PurnaraApp(),
    ),
  );
  await tester.pumpAndSettle();
  return Sample(tester, api, fixture);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  // --- every screen, both languages, phone and desktop, light and dark -------------------

  for (final locale in ['id', 'en']) {
    for (final (sizeName, size) in [('phone', phone), ('desktop', desktop)]) {
      for (final theme in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('every screen renders cleanly: $locale, $sizeName, ${theme.name}', (tester) async {
          final s = await pumpSample(tester, locale: locale, size: size, theme: theme);
          final locations = [
            '/today',
            '/project',
            '/plan',
            '/documents',
            '/assistant',
            '/brief',
            '/supervision',
            '/review',
            '/replan',
            '/settings',
            '/suggestions/${s.pendingSuggestionId}',
            '/tasks/${s.taskId('T2')}',
          ];
          for (final location in locations) {
            await s.go(location);
            expect(tester.takeException(), isNull, reason: location);
            expect(find.byType(ErrorWidget), findsNothing, reason: location);
          }
          // Project settings open from the project page.
          await s.go('/project');
          await tester.tap(find.byIcon(Icons.tune));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'project settings');
          expect(s.api.misses, isEmpty, reason: 'only endpoints the backend really has');
        });
      }
    }
  }

  // --- flows that used to break --------------------------------------------------------------

  testWidgets('day one of the sample shows the task in progress', (tester) async {
    await pumpSample(tester);
    expect(find.text('Baca dan rangkum jurnal ke matriks literatur'), findsOneWidget);
  });

  testWidgets('undo still works after the done task has left the screen', (tester) async {
    final s = await pumpSample(tester);
    final today = Json.from(s.answers['GET /me/today'] as Map);
    s.api.answers['GET /me/today'] = {...today, 'focus': <Object>[]};
    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('Baca dan rangkum jurnal ke matriks literatur'), findsNothing);
    expect(find.text('Task ditandai selesai.'), findsOneWidget);

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final patches = s.api.writes.where((w) => w.$1 == 'PATCH /tasks/${s.taskId('T2')}').map((w) => w.$2).toList();
    expect(patches, [
      {'status': 'done'},
      {'status': 'todo'},
    ]);
  });

  testWidgets('the welcome screen can open a ready-made sample project', (tester) async {
    late Json projects;
    final s = await pumpSample(
      tester,
      prefs: {'project_id': ''},
      setUp: (api, fixture) {
        final answers = Json.from(fixture['answers'] as Map);
        projects = {'GET /projects': answers['GET /projects'], 'GET /me/today': answers['GET /me/today']};
        api.answers['GET /projects'] = <Object>[];
        api.answers['GET /me/today'] = {
          ...Json.from(answers['GET /me/today'] as Map),
          'focus': <Object>[],
          'upcoming': <Object>[],
          'projects': <Object>[],
        };
        api.onCall = (key) {
          if (key == 'POST /projects/sample') api.answers.addAll(projects);
        };
      },
    );
    expect(find.text('Coba dengan contoh project'), findsOneWidget);
    await tester.tap(find.text('Coba dengan contoh project'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(s.api.writes.map((w) => w.$1), contains('POST /projects/sample'));
    expect(s.api.writes.firstWhere((w) => w.$1 == 'POST /projects/sample').$2, {'locale': 'id'});
    expect(find.text('Contoh project siap. Silakan dicoba.'), findsOneWidget);
    expect(find.text('Baca dan rangkum jurnal ke matriks literatur'), findsOneWidget);
    expect(s.container.read(settingsProvider).projectId, s.projectId);
  });

  testWidgets('a proposal can be accepted in part', (tester) async {
    final s = await pumpSample(tester);
    await s.push('/suggestions/${s.pendingSuggestionId}');
    final boxes = find.byType(Checkbox);
    expect(boxes, findsNWidgets(4));
    await tester.tap(boxes.first);
    await tester.pumpAndSettle();
    final accept = find.widgetWithText(FilledButton, 'Terima 3 yang dipilih');
    expect(accept, findsOneWidget);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final apply = s.api.writes.last;
    expect(apply.$1, 'POST /suggestions/${s.pendingSuggestionId}/apply');
    expect(apply.$2, {
      'op_indices': [1, 2, 3],
    });
    expect(find.text('Usulan diterapkan. Jadwal sudah diperbarui.'), findsOneWidget);
  });

  testWidgets('a failed delete is explained and the document stays', (tester) async {
    final s = await pumpSample(tester);
    await s.go('/documents');
    s.api.failing.add('DELETE /documents/');
    await tester.tap(find.byTooltip('Hapus').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Terjadi kesalahan. Coba lagi sebentar lagi.'), findsOneWidget);
    expect(find.text('PANDUAN PENULISAN SKRIPSI'), findsOneWidget);
  });

  testWidgets('a notification opens the project it is about', (tester) async {
    final s = await pumpSample(
      tester,
      prefs: {'project_id': 'other'},
      setUp: (api, fixture) {
        final answers = Json.from(fixture['answers'] as Map);
        final sample = Json.from((answers['GET /projects'] as List).first as Map);
        api.answers['GET /projects'] = [
          {...sample, 'id': 'other', 'title': 'Project lain'},
          sample,
        ];
        api.answers['GET /notifications'] = [
          {
            'id': 'n1',
            'project_id': fixture['project_id'],
            'type': 'deadline',
            'payload': {'days_left': 30},
            'created_at': '2026-10-05T01:00:00+00:00',
            'read': false,
          },
        ];
      },
    );
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();
    // With several projects, each notice says which one it is about.
    final sheet = find.byType(BottomSheet);
    expect(find.descendant(of: sheet, matching: find.textContaining(s.answers['GET /projects'][0]['title'] as String)), findsOneWidget);
    await tester.tap(find.descendant(of: sheet, matching: find.byType(ListTile)).first);
    await tester.pumpAndSettle();
    expect(s.container.read(settingsProvider).projectId, s.projectId);
    expect(s.container.read(routerProvider).state.uri.path, '/project');
    expect(s.api.writes.map((w) => w.$1), contains('POST /notifications/n1/read'));
  });

  testWidgets('leaving a task with unsaved edits asks first', (tester) async {
    final s = await pumpSample(tester);
    await s.push('/tasks/${s.taskId('T2')}');
    await tester.enterText(find.byType(TextField).first, 'Judul yang baru');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Perubahan belum disimpan. Tinggalkan halaman ini?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Judul yang baru'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tinggalkan'));
    await tester.pumpAndSettle();
    expect(s.container.read(routerProvider).state.uri.path, '/today');
    expect(s.api.writes.where((w) => w.$1.startsWith('PATCH /tasks/')), isEmpty);
  });

  testWidgets('project settings save and close', (tester) async {
    final s = await pumpSample(tester);
    await s.go('/project');
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Skripsi NPC');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final patch = s.api.writes.lastWhere((w) => w.$1 == 'PATCH /projects/${s.projectId}');
    expect((patch.$2! as Map)['title'], 'Skripsi NPC');
    expect(find.widgetWithText(AppBar, 'Pengaturan project'), findsNothing);
    expect(find.text('Tersimpan.'), findsOneWidget);
  });

  testWidgets('re-planning opened straight from a link still computes its options', (tester) async {
    final s = await pumpSample(tester);
    await s.push('/replan');
    expect(s.api.writes.map((w) => w.$1), contains('POST /projects/${s.projectId}/replan'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a question handed to the assistant is asked once the project is known', (tester) async {
    final s = await pumpSample(tester);
    await s.go('/assistant?q=${Uri.encodeQueryComponent('Apa syarat jumlah referensi?')}');
    final asks = s.api.writes.where((w) => w.$1 == 'POST /projects/${s.projectId}/chat').toList();
    expect(asks, hasLength(1));
    expect((asks.single.$2! as Map)['question'], 'Apa syarat jumlah referensi?');
    expect(s.container.read(routerProvider).state.uri.toString(), '/assistant');
  });

  for (final (locale, size) in [('id', phone), ('en', desktop)]) {
    testWidgets('a new project goes through the whole setup wizard: $locale', (tester) async {
      final l = locale == 'id'
          ? (
              next: 'Lanjut',
              skip: 'Lewati',
              pick: 'Pilih tanggal',
              accept: 'Terima rencana',
              ready: 'Rencana siap. Kamu bisa mengubahnya kapan saja.',
            )
          : (
              next: 'Next',
              skip: 'Skip',
              pick: 'Pick a date',
              accept: 'Accept the plan',
              ready: 'Your plan is ready. You can change it any time.',
            );
      final s = await pumpSample(tester, locale: locale, size: size);
      final wizardId = s.fixture['wizard_project_id'] as String;
      await s.push('/onboarding');

      Future<void> next() async {
        final button = find.widgetWithText(FilledButton, l.next);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();
      await next();

      await tester.enterText(find.byType(TextFormField).first, 'Sistem rekomendasi');
      await tester.tap(find.text(l.pick));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(DatePickerDialog), matching: find.byType(TextButton)).last);
      await tester.pumpAndSettle();
      await next();
      expect(s.api.writes.map((w) => w.$1), contains('POST /projects'));

      await tester.tap(find.widgetWithText(TextButton, l.skip));
      await tester.pumpAndSettle();
      expect(s.api.calls, contains('POST /projects/$wizardId/brief/extract'));
      await next();
      expect(s.api.writes.map((w) => w.$1), contains('PUT /projects/$wizardId/brief'));

      await next();
      expect(s.api.writes.map((w) => w.$1), contains('POST /projects/$wizardId/plan/generate'));

      final accept = find.widgetWithText(FilledButton, l.accept);
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(s.api.writes.last.$1, startsWith('POST /suggestions/'));
      expect(find.text(l.ready), findsOneWidget);
      expect(s.container.read(routerProvider).state.uri.path, '/today');
      expect(s.container.read(settingsProvider).projectId, wizardId);
      expect(s.api.misses, isEmpty);
    });
  }

  testWidgets('settings show the address a phone on the same Wi-Fi opens', (tester) async {
    final s = await pumpSample(tester);
    await s.go('/settings');
    await tester.ensureVisible(find.text('Buka di HP'));
    await tester.pumpAndSettle();
    expect(find.text('http://192.168.1.20:8000'), findsOneWidget);
  });
}
