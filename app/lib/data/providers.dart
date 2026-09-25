import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import 'api_client.dart';
import 'models.dart';
import 'repository.dart';

// --- settings (per device) ----------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main()'));

@immutable
class AppSettings {
  const AppSettings({this.locale, this.themeMode = ThemeMode.system, this.serverUrl, this.projectId});

  /// null means "follow the device"; the app still falls back to Indonesian.
  final Locale? locale;
  final ThemeMode themeMode;
  final String? serverUrl;
  final String? projectId;

  AppSettings copyWith({Locale? locale, ThemeMode? themeMode, String? serverUrl, String? projectId}) => AppSettings(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    serverUrl: serverUrl ?? this.serverUrl,
    projectId: projectId ?? this.projectId,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _locale = 'locale';
  static const _theme = 'theme_mode';
  static const _server = 'server_url';
  static const _project = 'project_id';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final code = _prefs.getString(_locale);
    return AppSettings(
      locale: code == null ? null : Locale(code),
      themeMode: ThemeMode.values.firstWhere((m) => m.name == _prefs.getString(_theme), orElse: () => ThemeMode.system),
      serverUrl: _prefs.getString(_server),
      projectId: _prefs.getString(_project),
    );
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_locale, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_theme, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setServerUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_server);
      state = AppSettings(locale: state.locale, themeMode: state.themeMode, projectId: state.projectId);
    } else {
      final normalized = AppConfig.normalize(url);
      await _prefs.setString(_server, normalized);
      state = state.copyWith(serverUrl: normalized);
    }
  }

  Future<void> selectProject(String id) async {
    await _prefs.setString(_project, id);
    state = state.copyWith(projectId: id);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

// --- API ---------------------------------------------------------------------------------------

final apiBaseUrlProvider = Provider<String>((ref) => ref.watch(settingsProvider.select((s) => s.serverUrl)) ?? AppConfig.defaultApiBaseUrl);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(apiBaseUrlProvider)));

final repositoryProvider = Provider<PurnaraRepository>((ref) => PurnaraRepository(ref.watch(apiClientProvider)));

// --- data ---------------------------------------------------------------------------------------

final meProvider = FutureProvider<Profile>((ref) => ref.watch(repositoryProvider).me());

final modesProvider = FutureProvider<List<ModeInfo>>((ref) => ref.watch(repositoryProvider).modes());

final projectsProvider = FutureProvider<List<Project>>((ref) => ref.watch(repositoryProvider).projects());

/// The project the user is looking at: the saved choice, else the first project.
final currentProjectProvider = Provider<Project?>((ref) {
  final projects = ref.watch(projectsProvider).value;
  if (projects == null || projects.isEmpty) return null;
  final selected = ref.watch(settingsProvider.select((s) => s.projectId));
  return projects.firstWhere((p) => p.id == selected, orElse: () => projects.first);
});

final todayProvider = FutureProvider<TodayView>((ref) => ref.watch(repositoryProvider).today());

final planProvider = FutureProvider.family<PlanData, String>((ref, id) => ref.watch(repositoryProvider).plan(id));

/// One task, looked up by id; used to find which project it belongs to.
final taskProvider = FutureProvider.family<Task, String>((ref, id) => ref.watch(repositoryProvider).task(id));

final healthProvider = FutureProvider.family<Health, String>((ref, id) => ref.watch(repositoryProvider).health(id));

final suggestionsProvider = FutureProvider.family<List<Suggestion>, String>((ref, id) => ref.watch(repositoryProvider).suggestions(id));

final suggestionProvider = FutureProvider.family<Suggestion, String>((ref, id) => ref.watch(repositoryProvider).suggestion(id));

final requirementsProvider = FutureProvider.family<List<RequirementStatus>, String>(
  (ref, id) => ref.watch(repositoryProvider).requirements(id),
);

final briefProvider = FutureProvider.family<Brief, String>((ref, id) => ref.watch(repositoryProvider).brief(id));

final documentsProvider = FutureProvider.family<List<DocumentItem>, String>((ref, id) => ref.watch(repositoryProvider).documents(id));

final threadsProvider = FutureProvider.family<List<ChatThread>, String>((ref, id) => ref.watch(repositoryProvider).threads(id));

final messagesProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, threadId) => ref.watch(repositoryProvider).messages(threadId),
);

final supervisionNotesProvider = FutureProvider.family<List<NoteItem>, String>(
  (ref, id) => ref.watch(repositoryProvider).notes(id, kind: 'supervision'),
);

final weeklyReviewProvider = FutureProvider.family<WeeklyReview, String>((ref, id) => ref.watch(repositoryProvider).weeklyReview(id));

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) => ref.watch(repositoryProvider).notifications());

/// After any change to a project's plan, everything derived from it is stale.
void refreshProject(WidgetRef ref, String projectId) {
  ref.invalidate(planProvider(projectId));
  ref.invalidate(healthProvider(projectId));
  ref.invalidate(suggestionsProvider(projectId));
  ref.invalidate(requirementsProvider(projectId));
  ref.invalidate(todayProvider);
  ref.invalidate(projectsProvider);
  ref.invalidate(notificationsProvider);
}
