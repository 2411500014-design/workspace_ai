import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'welcome_screen.dart';

class _Destination {
  const _Destination(this.path, this.icon, this.selectedIcon, this.label);

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
}

final _destinations = <_Destination>[
  _Destination('/today', Icons.wb_sunny_outlined, Icons.wb_sunny, (l) => l.navToday),
  _Destination('/project', Icons.insights_outlined, Icons.insights, (l) => l.navProject),
  _Destination('/plan', Icons.view_timeline_outlined, Icons.view_timeline, (l) => l.navPlan),
  _Destination('/documents', Icons.folder_open_outlined, Icons.folder, (l) => l.navDocuments),
  _Destination('/assistant', Icons.forum_outlined, Icons.forum, (l) => l.navAssistant),
];

/// The frame around the five main screens: a navigation rail on wide screens
/// (web, desktop, tablets) and a bottom bar on phones (master plan §12).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    final i = _destinations.indexWhere((d) => location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final l = context.l10n;

    // No server, or no project yet: show a full-screen state instead of empty tabs.
    if (!projects.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(l.appTitle), actions: [_settingsButton(context)]),
        body: projects.hasError ? ErrorView(error: projects.error!, onRetry: () => ref.invalidate(projectsProvider)) : const PageSkeleton(),
      );
    }
    if (projects.requireValue.isEmpty) return const WelcomeScreen();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kRailBreakpoint;
        final body = Scaffold(
          appBar: AppBar(
            title: const _ProjectSwitcher(),
            actions: [
              const _NotificationsButton(),
              _settingsButton(context),
              const SizedBox(width: Space.sm),
            ],
          ),
          body: child,
          bottomNavigationBar: wide
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                  child: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => context.go(_destinations[i].path),
                    destinations: [
                      for (final d in _destinations)
                        NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label(l)),
                    ],
                  ),
                ),
        );
        if (!wide) return body;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 1200,
                minExtendedWidth: 216,
                selectedIndex: _index,
                onDestinationSelected: (i) => context.go(_destinations[i].path),
                labelType: constraints.maxWidth >= 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: Space.lg),
                  child: BrandMark(),
                ),
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label(l))),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  Widget _settingsButton(BuildContext context) => IconButton(
    tooltip: context.l10n.settingsTitle,
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => context.push('/settings'),
  );
}

class _ProjectSwitcher extends ConsumerWidget {
  const _ProjectSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final current = ref.watch(currentProjectProvider);
    final l = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l.switchProject,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == '__new__') {
          context.push('/onboarding');
        } else {
          ref.read(settingsProvider.notifier).selectProject(value);
        }
      },
      itemBuilder: (context) => [
        for (final p in projects)
          CheckedPopupMenuItem<String>(
            value: p.id,
            checked: p.id == current?.id,
            child: Text(p.title, overflow: TextOverflow.ellipsis),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '__new__',
          child: ListTile(leading: const Icon(Icons.add), title: Text(l.newProject)),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(current?.title ?? l.appTitle, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}

class _NotificationsButton extends ConsumerWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider).value ?? const <NotificationItem>[];
    final unread = items.where((n) => !n.read).length;
    return IconButton(
      tooltip: context.l10n.notificationsTitle,
      icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_none)),
      onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _NotificationsSheet()),
    );
  }
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(notificationsProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: AsyncBody(
          value: items,
          onRetry: () => ref.invalidate(notificationsProvider),
          data: (list) => list.isEmpty
              ? EmptyState(icon: Icons.notifications_none, message: l.notificationsEmpty)
              : ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
                      child: Text(l.notificationsTitle, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    for (final n in list)
                      ListTile(
                        leading: Icon(n.type == 'deadline' ? Icons.event_outlined : Icons.monitor_heart_outlined),
                        title: Text(_text(context, n), style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w600)),
                        subtitle: n.createdAt == null ? null : Text(formatDate(context, n.createdAt!.toLocal())),
                        onTap: () async {
                          if (!n.read) {
                            await ref.read(repositoryProvider).markNotificationRead(n.id);
                            ref.invalidate(notificationsProvider);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                            GoRouter.of(context).go('/project');
                          }
                        },
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  String _text(BuildContext context, NotificationItem n) {
    final l = context.l10n;
    if (n.type == 'deadline') return l.notifDeadline((n.payload['days_left'] as num?)?.toInt() ?? 0);
    return l.notifHealthDrop(healthLabel(l, n.payload['to'] as String?));
  }
}
