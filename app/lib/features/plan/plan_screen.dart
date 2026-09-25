import 'dart:math' as math;

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
import 'task_actions.dart';

/// The whole plan in three views: list by milestone, board by status, and a
/// timeline of the scheduled dates (master plan §12).
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    if (project == null) return const PageSkeleton();
    final l = context.l10n;
    return AsyncBody(
      value: ref.watch(planProvider(project.id)),
      onRetry: () => ref.invalidate(planProvider(project.id)),
      data: (plan) {
        if (plan.tasks.isEmpty) {
          return PageBody(
            children: [
              EmptyState(
                icon: Icons.view_timeline_outlined,
                message: l.planEmpty,
                action: FilledButton(onPressed: () => context.push('/onboarding?project=${project.id}'), child: Text(l.todayMakePlan)),
              ),
            ],
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            body: Column(
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    tabs: [
                      Tab(icon: const Icon(Icons.list_alt_outlined), text: l.planTabList),
                      Tab(icon: const Icon(Icons.view_kanban_outlined), text: l.planTabBoard),
                      Tab(icon: const Icon(Icons.view_timeline_outlined), text: l.planTabTimeline),
                    ],
                  ),
                ),
                if (plan.project.needsReschedule)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
                    child: InfoBanner(
                      tone: BannerTone.warning,
                      icon: Icons.tune,
                      message: l.needsReschedule,
                      action: TextButton(onPressed: () => context.push('/replan'), child: Text(l.adjustPlan)),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ListView(plan: plan),
                      _BoardView(plan: plan),
                      _TimelineView(plan: plan),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => showAddTaskDialog(context, ref, plan),
              icon: const Icon(Icons.add),
              label: Text(l.taskAdd),
            ),
          ),
        );
      },
    );
  }
}

// --- list ------------------------------------------------------------------------------------

class _ListView extends ConsumerWidget {
  const _ListView({required this.plan});

  final PlanData plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final active = plan.tasks.where((t) => !t.deferred).toList();
    final deferred = plan.tasks.where((t) => t.deferred).toList();
    final milestones = [...plan.milestones]..sort((a, b) => a.position.compareTo(b.position));
    final orphans = active.where((t) => t.parentTaskId == null && (t.milestoneId == null || !milestones.any((m) => m.id == t.milestoneId)));
    return PageBody(
      onRefresh: () async => refreshProject(ref, plan.project.id),
      children: [
        for (final m in milestones)
          _MilestoneSection(
            title: m.title,
            plan: plan,
            tasks: active.where((t) => t.milestoneId == m.id && t.parentTaskId == null).toList(),
          ),
        if (orphans.isNotEmpty) _MilestoneSection(title: l.taskNoMilestone, plan: plan, tasks: orphans.toList()),
        if (deferred.isNotEmpty)
          SectionCard(
            title: l.deferredSection,
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, Space.sm),
            child: Column(
              children: [for (final t in deferred) _TaskRow(task: t, plan: plan, depth: 0)],
            ),
          ),
      ],
    );
  }
}

class _MilestoneSection extends StatelessWidget {
  const _MilestoneSection({required this.title, required this.plan, required this.tasks});

  final String title;
  final PlanData plan;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final leaves = <Task>[];
    void collect(Task t) {
      final children = plan.tasks.where((c) => c.parentTaskId == t.id && !c.deferred).toList();
      if (children.isEmpty) {
        leaves.add(t);
      } else {
        children.forEach(collect);
      }
    }

    tasks.forEach(collect);
    final done = leaves.where((t) => t.isDone).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
                      ),
                      Text(l.milestoneProgress('$done', '${leaves.length}'), style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  ProgressBar(value: leaves.isEmpty ? 0 : done / leaves.length),
                ],
              ),
            ),
            for (final t in tasks) ..._withChildren(t, 0),
            const SizedBox(height: Space.sm),
          ],
        ),
      ),
    );
  }

  List<Widget> _withChildren(Task task, int depth) => [
    _TaskRow(task: task, plan: plan, depth: depth),
    for (final child in plan.tasks.where((c) => c.parentTaskId == task.id && !c.deferred)) ..._withChildren(child, depth + 1),
  ];
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.plan, required this.depth});

  final Task task;
  final PlanData plan;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final isParent = plan.parentIds.contains(task.id);
    final muted = task.deferred || task.isDone;
    final meta = [
      task.key,
      l.hoursValue(formatHours(task.estimateHours)),
      if (task.scheduledEnd != null)
        l.taskScheduled(formatDate(context, task.scheduledStart ?? task.scheduledEnd!), formatDate(context, task.scheduledEnd!))
      else if (!task.deferred && !task.isDone)
        l.taskUnscheduled,
    ].join(' · ');
    return InkWell(
      onTap: () => context.push('/tasks/${task.id}'),
      child: Padding(
        padding: EdgeInsets.fromLTRB(Space.sm + depth * Space.xl, Space.xs, Space.lg, Space.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isDone,
              semanticLabel: l.markDone,
              onChanged: isParent || task.deferred
                  ? null
                  : (v) => setTaskDone(context, ref, projectId: plan.project.id, taskId: task.id, done: v ?? false),
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: (isParent ? theme.textTheme.titleSmall : theme.textTheme.bodyLarge)?.copyWith(
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        color: muted ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (task.lateDays > 0 || task.isCritical || task.optional)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: Wrap(
                          spacing: Space.xs,
                          runSpacing: Space.xs,
                          children: [
                            if (task.lateDays > 0) LatePill(days: task.lateDays),
                            if (task.isCritical && !task.isDone) const CriticalPill(),
                            if (task.optional)
                              StatusPill(
                                label: l.optionalTag,
                                icon: Icons.low_priority,
                                foreground: theme.colorScheme.onSurfaceVariant,
                                background: theme.colorScheme.surfaceContainerHigh,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 12), child: Icon(Icons.chevron_right)),
          ],
        ),
      ),
    );
  }
}

// --- board -------------------------------------------------------------------------------------

class _BoardView extends ConsumerWidget {
  const _BoardView({required this.plan});

  final PlanData plan;

  static const _statuses = ['todo', 'in_progress', 'done'];

  Future<void> _move(BuildContext context, WidgetRef ref, Task task, String status) async {
    if (task.status == status) return;
    if (status == 'done') {
      await setTaskDone(context, ref, projectId: plan.project.id, taskId: task.id, done: true);
      return;
    }
    final container = containerOf(ref);
    try {
      await container.read(repositoryProvider).updateTask(task.id, {'status': status});
      refreshProjectIn(container, plan.project.id);
    } catch (e) {
      if (context.mounted) showMessage(context, errorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = plan.leafTasks.where((t) => !t.deferred).toList()
      ..sort((a, b) => (a.scheduledStart ?? DateTime(9999)).compareTo(b.scheduledStart ?? DateTime(9999)));
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kRailBreakpoint;
        Widget column(String status) => _BoardColumn(
          status: status,
          tasks: tasks.where((t) => t.status == status).toList(),
          draggableOnTap: wide,
          onMove: (task, to) => _move(context, ref, task, to),
        );
        if (wide) {
          return Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, s) in _statuses.indexed) ...[if (i > 0) const SizedBox(width: Space.md), Expanded(child: column(s))],
              ],
            ),
          );
        }
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(Space.lg),
          children: [
            for (final (i, s) in _statuses.indexed) ...[
              if (i > 0) const SizedBox(width: Space.md),
              SizedBox(width: math.min(320, constraints.maxWidth - Space.xxl * 2), child: column(s)),
            ],
          ],
        );
      },
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({required this.status, required this.tasks, required this.draggableOnTap, required this.onMove});

  final String status;
  final List<Task> tasks;
  final bool draggableOnTap;
  final void Function(Task task, String status) onMove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) => onMove(details.data, status),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: Motion.fast,
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.xs),
              child: Text('${taskStatusLabel(l, status)} · ${tasks.length}', style: theme.textTheme.titleSmall),
            ),
            const SizedBox(height: Space.sm),
            Expanded(
              child: ListView(
                children: [for (final t in tasks) _draggable(t, _BoardCard(task: t, onMove: (to) => onMove(t, to)))],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _draggable(Task task, Widget child) {
    final feedback = Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(Radii.md),
      child: SizedBox(width: 280, child: child),
    );
    final placeholder = Opacity(opacity: 0.4, child: child);
    return draggableOnTap
        ? Draggable<Task>(data: task, feedback: feedback, childWhenDragging: placeholder, child: child)
        : LongPressDraggable<Task>(data: task, feedback: feedback, childWhenDragging: placeholder, child: child);
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.task, required this.onMove});

  final Task task;
  final ValueChanged<String> onMove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: Space.sm),
      onTap: () => context.push('/tasks/${task.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.xs, Space.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: Space.xs),
                  Text(
                    [
                      task.key,
                      l.hoursValue(formatHours(task.estimateHours)),
                      if (task.scheduledEnd != null) formatDate(context, task.scheduledEnd!),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (task.lateDays > 0 || (task.isCritical && !task.isDone))
                    Padding(
                      padding: const EdgeInsets.only(top: Space.sm),
                      child: Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: [
                          if (task.lateDays > 0) LatePill(days: task.lateDays),
                          if (task.isCritical && !task.isDone) const CriticalPill(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l.boardMoveTo,
              icon: const Icon(Icons.more_vert),
              onSelected: onMove,
              itemBuilder: (context) => [
                for (final s in _BoardView._statuses)
                  if (s != task.status) PopupMenuItem(value: s, child: Text('${l.boardMoveTo}: ${taskStatusLabel(l, s)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- timeline ------------------------------------------------------------------------------------

class _TimelineView extends StatefulWidget {
  const _TimelineView({required this.plan});

  final PlanData plan;

  static const double _row = 40;
  static const double _header = 44;
  static const double _day = 26;
  static const double _names = 200;

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  static const _row = _TimelineView._row;
  static const _header = _TimelineView._header;
  static const _day = _TimelineView._day;
  static const _names = _TimelineView._names;

  ScrollController? _horizontal;

  @override
  void dispose() {
    _horizontal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final l = context.l10n;
    final theme = Theme.of(context);
    final tasks = plan.leafTasks.where((t) => !t.deferred && t.scheduledEnd != null).toList()
      ..sort((a, b) {
        final byStart = (a.scheduledStart ?? a.scheduledEnd!).compareTo(b.scheduledStart ?? b.scheduledEnd!);
        return byStart != 0 ? byStart : a.scheduledEnd!.compareTo(b.scheduledEnd!);
      });
    if (tasks.isEmpty) {
      return PageBody(
        children: [EmptyState(icon: Icons.view_timeline_outlined, message: l.taskUnscheduled)],
      );
    }

    final today = dateOnly(DateTime.now());
    var first = tasks.map((t) => t.scheduledStart ?? t.scheduledEnd!).reduce((a, b) => a.isBefore(b) ? a : b);
    if (today.isBefore(first)) first = today;
    first = first.subtract(Duration(days: first.weekday - 1)); // start on a Monday
    var last = tasks.map((t) => t.scheduledEnd!).reduce((a, b) => a.isAfter(b) ? a : b);
    if (plan.project.deadline.isAfter(last)) last = plan.project.deadline;
    final days = last.difference(first).inDays + 8;
    final width = days * _day;
    final height = _header + tasks.length * _row;
    // Open with today in view.
    final horizontal = _horizontal ??= ScrollController(initialScrollOffset: math.max(0, (today.difference(first).inDays - 1) * _day));

    // On phones the names column gives most of the width to the bars.
    final names = math.min(_names, MediaQuery.sizeOf(context).width * 0.38);
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Space.xxxl + Space.xxl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: names,
              child: Column(
                children: [
                  const SizedBox(height: _header),
                  for (final t in tasks)
                    InkWell(
                      onTap: () => context.push('/tasks/${t.id}'),
                      child: Container(
                        height: _row,
                        padding: const EdgeInsets.symmetric(horizontal: Space.md),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${t.key}  ${t.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: t.isDone ? TextDecoration.lineThrough : null,
                            fontWeight: t.isCritical && !t.isDone ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Scrollbar(
                controller: horizontal,
                child: SingleChildScrollView(
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  child: GestureDetector(
                    onTapUp: (details) {
                      final index = ((details.localPosition.dy - _header) / _row).floor();
                      if (index >= 0 && index < tasks.length) context.push('/tasks/${tasks[index].id}');
                    },
                    child: Semantics(
                      label: l.planTabTimeline,
                      child: CustomPaint(
                        size: Size(width, height),
                        painter: _TimelinePainter(
                          tasks: tasks,
                          first: first,
                          days: days,
                          today: today,
                          deadline: plan.project.deadline,
                          locale: context.localeCode,
                          labels: (today: l.timelineToday, deadline: l.timelineDeadline),
                          colors: _TimelineColors.of(context),
                          textStyle: theme.textTheme.labelSmall!,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineColors {
  const _TimelineColors({
    required this.grid,
    required this.weekend,
    required this.text,
    required this.bar,
    required this.critical,
    required this.done,
    required this.late,
    required this.today,
    required this.deadline,
  });

  factory _TimelineColors.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.statusColors;
    return _TimelineColors(
      grid: scheme.outlineVariant,
      weekend: scheme.surfaceContainerLow,
      text: scheme.onSurfaceVariant,
      bar: scheme.primary,
      critical: scheme.tertiary,
      done: status.success,
      late: scheme.error,
      today: scheme.primary,
      deadline: scheme.error,
    );
  }

  final Color grid;
  final Color weekend;
  final Color text;
  final Color bar;
  final Color critical;
  final Color done;
  final Color late;
  final Color today;
  final Color deadline;
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.tasks,
    required this.first,
    required this.days,
    required this.today,
    required this.deadline,
    required this.locale,
    required this.labels,
    required this.colors,
    required this.textStyle,
  });

  final List<Task> tasks;
  final DateTime first;
  final int days;
  final DateTime today;
  final DateTime deadline;
  final String locale;
  final ({String today, String deadline}) labels;
  final _TimelineColors colors;
  final TextStyle textStyle;

  static const _row = _TimelineView._row;
  static const _header = _TimelineView._header;
  static const _day = _TimelineView._day;

  double _x(DateTime d) => dateOnly(d).difference(first).inDays * _day;

  void _text(Canvas canvas, String text, Offset at, {Color? color, FontWeight? weight}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(color: color ?? colors.text, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    final weekend = Paint()..color = colors.weekend;

    for (var i = 0; i < days; i++) {
      final day = first.add(Duration(days: i));
      final x = i * _day;
      if (day.weekday >= DateTime.saturday) canvas.drawRect(Rect.fromLTWH(x, _header, _day, size.height - _header), weekend);
      if (day.weekday == DateTime.monday) {
        canvas.drawLine(Offset(x, _header - 8), Offset(x, size.height), grid);
        _text(canvas, '${day.day}', Offset(x + 4, 24));
      }
      if (day.day == 1 || i == 0) {
        _text(canvas, _month(day), Offset(x + 4, 4), weight: FontWeight.w600);
      }
    }
    canvas.drawLine(Offset(0, _header), Offset(size.width, _header), grid);

    for (var i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      final top = _header + i * _row;
      final start = t.scheduledStart ?? t.scheduledEnd!;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(_x(start) + 2, top + 10, (t.scheduledEnd!.difference(start).inDays + 1) * _day - 4, _row - 20),
        const Radius.circular(Radii.sm),
      );
      final color = t.isDone
          ? colors.done
          : t.lateDays > 0
          ? colors.late
          : t.isCritical
          ? colors.critical
          : colors.bar;
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: t.isDone ? 0.55 : 0.9));
      canvas.drawLine(Offset(0, top + _row), Offset(size.width, top + _row), grid..color = colors.grid.withValues(alpha: 0.4));
    }

    void marker(DateTime day, Color color, String label) {
      final x = _x(day) + _day / 2;
      if (x < 0 || x > size.width) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2;
      canvas.drawLine(Offset(x, _header - 4), Offset(x, size.height), paint);
      _text(canvas, label, Offset(x + 4, _header - 18), color: color, weight: FontWeight.w600);
    }

    marker(deadline, colors.deadline, labels.deadline);
    marker(today, colors.today, labels.today);
  }

  String _month(DateTime d) {
    const id = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${(locale == 'id' ? id : en)[d.month - 1]} ${d.year}';
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.tasks != tasks || old.first != first || old.colors != colors || old.locale != locale || old.today != today;
}

// --- add task -------------------------------------------------------------------------------------

Future<void> showAddTaskDialog(BuildContext context, WidgetRef ref, PlanData plan) async {
  final created = await showDialog<bool>(
    context: context,
    builder: (_) => _AddTaskDialog(plan: plan),
  );
  if (created == true && context.mounted) showMessage(context, context.l10n.taskSaved);
}

class _AddTaskDialog extends ConsumerStatefulWidget {
  const _AddTaskDialog({required this.plan});

  final PlanData plan;

  @override
  ConsumerState<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _estimate = TextEditingController(text: '2');
  String? _milestoneId;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _estimate.dispose();
    super.dispose();
  }

  double? _parseHours(String? text) => double.tryParse((text ?? '').trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final container = containerOf(ref);
    try {
      await container
          .read(repositoryProvider)
          .createTask(
            widget.plan.project.id,
            title: _title.text.trim(),
            estimateHours: _parseHours(_estimate.text)!,
            milestoneId: _milestoneId,
          );
      refreshProjectIn(container, widget.plan.project.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, errorMessage(context, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final milestones = [...widget.plan.milestones]..sort((a, b) => a.position.compareTo(b.position));
    return AlertDialog(
      title: Text(l.taskAdd),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 480),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                autofocus: true,
                maxLength: 300,
                decoration: InputDecoration(labelText: l.taskTitle, counterText: ''),
                validator: (v) => (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
              ),
              const SizedBox(height: Space.sm),
              TextFormField(
                controller: _estimate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.taskEstimate),
                validator: (v) {
                  final h = _parseHours(v);
                  return h == null || h < 0.5 || h > 40 ? l.estimateRange : null;
                },
              ),
              const SizedBox(height: Space.lg),
              DropdownButtonFormField<String?>(
                initialValue: _milestoneId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.taskMilestone),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l.taskNoMilestone)),
                  for (final m in milestones)
                    DropdownMenuItem<String?>(
                      value: m.id,
                      child: Text(m.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _milestoneId = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l.actionCancel)),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: BusyLabel(busy: _busy, child: Text(l.actionSave)),
        ),
      ],
    );
  }
}
