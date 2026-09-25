import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../plan/task_actions.dart';

/// "Fokus Hari Ini": what to do today in under two minutes (master plan §12).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final me = ref.watch(meProvider).value;
    final l = context.l10n;
    return AsyncBody(
      value: today,
      onRetry: () => ref.invalidate(todayProvider),
      data: (view) => PageBody(
        maxWidth: kReadingWidth,
        onRefresh: () async => ref.invalidate(todayProvider),
        children: [
          PageHeader(title: l.todayTitle, subtitle: formatDateLong(context, view.date)),
          if (me != null && !me.aiEnabled) const _AiNotice(),
          for (final project in view.projects) _ProjectSummaryCard(summary: project),
          if (view.focus.isEmpty)
            SectionCard(
              child: EmptyState(
                icon: Icons.self_improvement_outlined,
                message: l.todayEmpty,
                action: view.upcoming.isEmpty
                    ? null
                    : OutlinedButton(
                        onPressed: () => context.push('/tasks/${view.upcoming.first.id}'),
                        child: Text(view.upcoming.first.title),
                      ),
              ),
            )
          else ...[
            // The day's focus is the one moment on this screen worth marking.
            for (final (i, task) in view.focus.indexed)
              FadeSlideIn(
                key: ValueKey('focus-${task.id}'),
                delay: Motion.stagger * (i + 1),
                child: TaskCard(task: task, prominent: true),
              ),
            if (view.moreToday.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.lg),
                child: TextButton(onPressed: () => context.go('/plan'), child: Text(l.todayMore(view.moreToday.length))),
              ),
          ],
          if (view.upcoming.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Semantics(header: true, child: Text(l.todayUpcoming, style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: Space.md),
            for (final task in view.upcoming) TaskCard(task: task),
          ],
        ],
      ),
    );
  }
}

class _ProjectSummaryCard extends ConsumerWidget {
  const _ProjectSummaryCard({required this.summary});

  final ProjectSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final days = summary.daysLeft;
    return SectionCard(
      title: summary.title,
      trailing: HealthPill(status: summary.hasPlan ? summary.health : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.lg,
            runSpacing: Space.xs,
            children: [
              _Meta(icon: Icons.flag_outlined, text: days < 0 ? l.deadlinePassed : l.daysLeft(days)),
              if (summary.nextMilestoneTitle != null) _Meta(icon: Icons.linear_scale, text: l.nextMilestone(summary.nextMilestoneTitle!)),
              if (summary.hasPlan) _Meta(icon: Icons.schedule, text: l.capacityToday(l.hoursValue(formatHours(summary.hoursToday)))),
            ],
          ),
          if (!summary.hasPlan) ...[
            const SizedBox(height: Space.md),
            Text(l.todayNoPlan, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Space.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).selectProject(summary.id);
                  context.push('/onboarding?project=${summary.id}');
                },
                child: Text(l.todayMakePlan),
              ),
            ),
          ],
          if (summary.needsReschedule || summary.health == 'at_risk' || summary.health == 'off_track') ...[
            const SizedBox(height: Space.md),
            InfoBanner(
              tone: BannerTone.warning,
              icon: Icons.tune,
              message: summary.needsReschedule ? l.needsReschedule : l.reviewRecommendReplan,
              action: TextButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).selectProject(summary.id);
                  context.push('/replan');
                },
                child: Text(l.adjustPlan),
              ),
            ),
          ],
          if (summary.pendingSuggestions > 0)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: InfoBanner(
                icon: Icons.inbox_outlined,
                message: l.pendingSuggestions(summary.pendingSuggestions),
                action: TextButton(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).selectProject(summary.id);
                    context.go('/project');
                  },
                  child: Text(l.reviewAction),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Space.xs),
        Flexible(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
        ),
      ],
    );
  }
}

/// A task in a list: title, context, badges, and the two main actions.
class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task, this.prominent = false});

  final TaskBrief task;
  final bool prominent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final done = task.status == 'done';
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: AppCard(
        onTap: () => context.push('/tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: done,
                    semanticLabel: l.markDone,
                    onChanged: (value) => setTaskDone(context, ref, projectId: task.projectId, taskId: task.id, done: value ?? false),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    // Lines the first line of the title up with the checkbox.
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: Motion.normal,
                            curve: Motion.enter,
                            style: (prominent ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)!.copyWith(
                              decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                              color: done ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                            ),
                            child: Text(task.title),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            [
                              if (task.milestoneTitle.isNotEmpty) task.milestoneTitle,
                              l.hoursValue(formatHours(task.estimateHours)),
                              if (task.scheduledEnd != null)
                                l.taskScheduled(
                                  formatDate(context, task.scheduledStart ?? task.scheduledEnd!),
                                  formatDate(context, task.scheduledEnd!),
                                ),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (task.isCritical || task.lateDays > 0 || prominent)
                Padding(
                  padding: const EdgeInsets.only(top: Space.md, left: 48 + Space.sm),
                  child: Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (task.lateDays > 0) LatePill(days: task.lateDays),
                      if (task.isCritical) const CriticalPill(),
                      if (prominent && !done)
                        TextButton.icon(
                          onPressed: () => showStartHelp(context, ref, task.id),
                          icon: const Icon(Icons.play_circle_outline),
                          label: Text(l.helpMeStart),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "AI is not active" is worth saying once, not every morning.
class _AiNotice extends ConsumerStatefulWidget {
  const _AiNotice();

  @override
  ConsumerState<_AiNotice> createState() => _AiNoticeState();
}

class _AiNoticeState extends ConsumerState<_AiNotice> {
  static const _key = 'ai_notice_dismissed';

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs.getBool(_key) ?? false) return const SizedBox.shrink();
    return InfoBanner(
      message: context.l10n.aiNotActive,
      icon: Icons.auto_awesome_outlined,
      onDismiss: () async {
        await prefs.setBool(_key, true);
        if (mounted) setState(() {});
      },
    );
  }
}
