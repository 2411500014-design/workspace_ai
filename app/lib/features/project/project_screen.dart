import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'capacity_editor.dart';

/// Project overview: health and why, progress against plan, milestones, the
/// lecturer's requirements, and proposals waiting for a decision.
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    if (project == null) return const PageSkeleton();
    final l = context.l10n;
    final theme = Theme.of(context);
    final pending = (ref.watch(suggestionsProvider(project.id)).value ?? const <Suggestion>[]).where((s) => s.isPending).toList();
    return PageBody(
      onRefresh: () async => refreshProject(ref, project.id),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(project.title, style: theme.textTheme.headlineMedium)),
                  const SizedBox(height: Space.xs),
                  Text(
                    [
                      l.deadlineOn(formatDate(context, project.deadline, alwaysYear: true)),
                      l.capacityWeekly(formatHours(project.weeklyHours)),
                    ].join(' · '),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.projectSettings,
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => ProjectSettingsPage(project: project))),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        if (!project.hasPlan)
          SectionCard(
            child: EmptyState(
              icon: Icons.view_timeline_outlined,
              message: l.todayNoPlan,
              action: FilledButton(onPressed: () => context.push('/onboarding?project=${project.id}'), child: Text(l.todayMakePlan)),
            ),
          )
        else
          _HealthCard(projectId: project.id),
        if (pending.isNotEmpty)
          SectionCard(
            title: l.pendingTitle,
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, Space.sm),
            child: Column(
              children: [
                for (final s in pending)
                  ListTile(
                    leading: Icon(s.aiUsed ? Icons.auto_awesome_outlined : Icons.inbox_outlined),
                    title: Text(suggestionKindLabel(l, s.kind)),
                    subtitle: Text(
                      s.rationale.isNotEmpty ? s.rationale : l.opsCount(s.ops.length),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/suggestions/${s.id}'),
                  ),
              ],
            ),
          ),
        if (project.hasPlan) _MilestonesCard(projectId: project.id),
        _RequirementsCard(projectId: project.id),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          child: Column(
            children: [
              _LinkTile(icon: Icons.description_outlined, label: l.openBrief, onTap: () => context.push('/brief')),
              _LinkTile(icon: Icons.forum_outlined, label: l.openSupervision, onTap: () => context.push('/supervision')),
              if (project.hasPlan) ...[
                _LinkTile(icon: Icons.event_note_outlined, label: l.openReview, onTap: () => context.push('/review')),
                _LinkTile(icon: Icons.tune, label: l.adjustPlan, onTap: () => context.push('/replan')),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}

class _HealthCard extends ConsumerWidget {
  const _HealthCard({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return AsyncBody(
      loading: const PageSkeleton(inline: true, cards: 1),
      value: ref.watch(healthProvider(projectId)),
      onRetry: () => ref.invalidate(healthProvider(projectId)),
      data: (h) {
        final reasons = h.reasons.isEmpty ? [l.healthAllGood] : [for (final r in h.reasons) healthReason(l, r, h.criticalLateDays)];
        return SectionCard(
          title: l.projectOverview,
          trailing: HealthPill(status: h.status),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: Text(r, style: theme.textTheme.bodyLarge),
                ),
              const SizedBox(height: Space.md),
              _ProgressBar(label: l.progressPlanned(formatPct(h.plannedPct)), value: h.plannedPct, color: theme.colorScheme.outline),
              const SizedBox(height: Space.sm),
              _ProgressBar(label: l.progressActual(formatPct(h.actualPct)), value: h.actualPct, color: theme.colorScheme.primary),
              const SizedBox(height: Space.md),
              Text(
                [
                  l.hoursDone(formatHours(h.doneHours), formatHours(h.totalHours)),
                  // Infeasibility is already the first reason above, with its own wording.
                  if (h.feasibility != null && h.feasibility != 'infeasible') feasibilityLabel(l, h.feasibility, 0),
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (h.history.length >= 3 && h.history.any((p) => p.plannedPct > 0 || p.actualPct > 0)) ...[
                const SizedBox(height: Space.lg),
                SizedBox(height: 120, child: _HistoryChart(points: h.history)),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.lg,
                  children: [
                    _Legend(color: theme.colorScheme.outline, label: l.chartPlanned),
                    _Legend(color: theme.colorScheme.primary, label: l.chartActual),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Space.xs),
        ProgressBar(value: value, color: color, height: 8),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: Space.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Planned versus actual progress over time, from the daily snapshots.
class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.points});

  final List<HealthPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final last = points.last;
    return Semantics(
      label: '${l.progressPlanned(formatPct(last.plannedPct))}, ${l.progressActual(formatPct(last.actualPct))}',
      child: CustomPaint(
        painter: _HistoryPainter(
          points: points,
          planned: theme.colorScheme.outline,
          actual: theme.colorScheme.primary,
          grid: theme.colorScheme.outlineVariant,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({required this.points, required this.planned, required this.actual, required this.grid});

  final List<HealthPoint> points;
  final Color planned;
  final Color actual;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - f);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final first = points.first.day;
    final span = points.last.day.difference(first).inDays.clamp(1, 100000);
    Offset at(HealthPoint p, double value) =>
        Offset(size.width * p.day.difference(first).inDays / span, size.height * (1 - value.clamp(0, 1)));

    void line(double Function(HealthPoint) value, Color color) {
      final path = Path()..moveTo(at(points.first, value(points.first)).dx, at(points.first, value(points.first)).dy);
      for (final p in points.skip(1)) {
        final o = at(p, value(p));
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    line((p) => p.plannedPct, planned);
    line((p) => p.actualPct, actual);
  }

  @override
  bool shouldRepaint(_HistoryPainter old) => old.points != points || old.actual != actual;
}

class _MilestonesCard extends ConsumerWidget {
  const _MilestonesCard({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final plan = ref.watch(planProvider(projectId)).value;
    if (plan == null || plan.milestones.isEmpty) return const SizedBox.shrink();
    final leaves = plan.leafTasks.where((t) => !t.deferred).toList();
    final milestones = [...plan.milestones]..sort((a, b) => a.position.compareTo(b.position));
    return SectionCard(
      title: l.milestonesTitle,
      child: Column(
        children: [
          for (final m in milestones)
            Builder(
              builder: (context) {
                final tasks = leaves.where((t) => t.milestoneId == m.id).toList();
                if (tasks.isEmpty) return const SizedBox.shrink();
                final done = tasks.where((t) => t.isDone).length;
                final ends = tasks.map((t) => t.scheduledEnd).whereType<DateTime>();
                final end = ends.isEmpty ? null : ends.reduce((a, b) => a.isAfter(b) ? a : b);
                final complete = done == tasks.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Row(
                    children: [
                      Icon(
                        complete ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: complete ? context.statusColors.success : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: Space.xs),
                            ProgressBar(value: done / tasks.length),
                            const SizedBox(height: Space.xs),
                            Text(
                              [l.milestoneProgress('$done', '${tasks.length}'), if (end != null) formatDate(context, end)].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RequirementsCard extends ConsumerWidget {
  const _RequirementsCard({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final status = context.statusColors;
    final value = ref.watch(requirementsProvider(projectId));
    return SectionCard(
      title: l.requirementsTitle,
      child: switch (value) {
        AsyncValue(hasValue: true, :final value?) when value.isEmpty => Text(l.requirementsEmpty, style: theme.textTheme.bodyMedium),
        AsyncValue(hasValue: true, :final value?) => Column(
          children: [
            for (final r in value)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      r.met ? Icons.check_circle : (r.covered ? Icons.pending_outlined : Icons.warning_amber_outlined),
                      color: r.met ? status.success : (r.covered ? theme.colorScheme.primary : status.warning),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.code}  ${r.text}', style: theme.textTheme.bodyMedium),
                          Text(
                            r.met ? l.requirementMet : (r.covered ? l.requirementCovered : l.requirementUncovered),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        AsyncValue(:final error?) => ErrorView(error: error, onRetry: () => ref.invalidate(requirementsProvider(projectId))),
        _ => const PageSkeleton(inline: true, cards: 1),
      },
    );
  }
}

/// Title, deadline and available time, plus deleting the project.
class ProjectSettingsPage extends ConsumerStatefulWidget {
  const ProjectSettingsPage({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<ProjectSettingsPage> createState() => _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends ConsumerState<ProjectSettingsPage> {
  late final _title = TextEditingController(text: widget.project.title);
  late final _description = TextEditingController(text: widget.project.description);
  late DateTime _deadline = widget.project.deadline;
  late CapacityValue _capacity = CapacityValue(
    hours: widget.project.hoursByWeekday.length == 7 ? widget.project.hoursByWeekday : const [2, 2, 2, 2, 2, 0, 0],
    blockedDates: widget.project.blockedDates,
    bufferPct: widget.project.bufferPct,
  );
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_title.text.trim().isEmpty) return showMessage(context, '${l.fieldTitle}: ${l.fieldRequired}');
    setState(() => _busy = true);
    try {
      final p = widget.project;
      await ref
          .read(repositoryProvider)
          .updateProject(
            p.id,
            title: _title.text.trim(),
            description: _description.text.trim(),
            deadline: _deadline == p.deadline ? null : _deadline,
            hoursByWeekday: _capacity.hours,
            blockedDates: _capacity.blockedDates,
            bufferPct: _capacity.bufferPct,
          );
      refreshProject(ref, p.id);
      if (!mounted) return;
      showMessage(context, l.taskSaved);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await confirm(context, message: l.deleteProjectConfirm, confirmLabel: l.deleteProject, destructive: true);
    if (!ok || !mounted) return;
    try {
      await ref.read(repositoryProvider).deleteProject(widget.project.id);
      ref.invalidate(projectsProvider);
      ref.invalidate(todayProvider);
      if (!mounted) return;
      Navigator.pop(context);
      context.go('/today');
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.projectSettings),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: FilledButton(onPressed: _busy ? null : _save, child: Text(l.actionSave)),
          ),
        ],
      ),
      body: PageBody(
        children: [
          TextField(
            controller: _title,
            maxLength: 300,
            decoration: InputDecoration(labelText: l.fieldTitle),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: l.fieldDescription),
          ),
          const SizedBox(height: Space.xl),
          Text(l.fieldDeadline, style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(formatDateLong(context, _deadline)),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline.isAfter(now) ? _deadline : now.add(const Duration(days: 1)),
                  firstDate: now.add(const Duration(days: 1)),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) setState(() => _deadline = dateOnly(picked));
              },
            ),
          ),
          const SizedBox(height: Space.xl),
          const Divider(),
          const SizedBox(height: Space.lg),
          CapacityEditor(value: _capacity, onChanged: (v) => setState(() => _capacity = v)),
          const SizedBox(height: Space.xxl),
          const Divider(),
          const SizedBox(height: Space.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(l.deleteProject),
            ),
          ),
        ],
      ),
    );
  }
}
