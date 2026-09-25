import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'features/assistant/assistant_screen.dart';
import 'features/brief/brief_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/plan/plan_screen.dart';
import 'features/plan/task_detail_screen.dart';
import 'features/project/project_screen.dart';
import 'features/replan/replan_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/suggestions/suggestion_screen.dart';
import 'features/supervision/supervision_screen.dart';
import 'features/today/today_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  NoTransitionPage<void> tab(GoRouterState state, Widget child) => NoTransitionPage<void>(key: state.pageKey, child: child);

  return GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/today'),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/today', pageBuilder: (context, state) => tab(state, const TodayScreen())),
          GoRoute(path: '/project', pageBuilder: (context, state) => tab(state, const ProjectScreen())),
          GoRoute(path: '/plan', pageBuilder: (context, state) => tab(state, const PlanScreen())),
          GoRoute(path: '/documents', pageBuilder: (context, state) => tab(state, const DocumentsScreen())),
          GoRoute(
            path: '/assistant',
            pageBuilder: (context, state) => tab(state, AssistantScreen(initialQuestion: state.uri.queryParameters['q'])),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(projectId: state.uri.queryParameters['project']),
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) => TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/suggestions/:id',
        builder: (context, state) => SuggestionScreen(suggestionId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/replan', builder: (context, state) => const ReplanScreen()),
      GoRoute(path: '/brief', builder: (context, state) => const BriefScreen()),
      GoRoute(path: '/supervision', builder: (context, state) => const SupervisionScreen()),
      GoRoute(path: '/review', builder: (context, state) => const ReviewScreen()),
    ],
  );
});
