import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/api_client.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'task_actions.dart';

/// Everything about one task: status, schedule, estimate, dependencies, the
/// requirements it covers, and the helpers (start, break down, explain).
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lookup = ref.watch(taskProvider(taskId));
    final projectId = lookup.value?.projectId;
    final plan = projectId == null ? null : ref.watch(planProvider(projectId));
    final task = plan?.value?.taskById(taskId);

    final Widget body;
    if (lookup.hasError && !lookup.hasValue) {
      body = ErrorView(error: lookup.error!, onRetry: () => ref.invalidate(taskProvider(taskId)));
    } else if (plan != null && plan.hasError && !plan.hasValue) {
      body = ErrorView(error: plan.error!, onRetry: () => ref.invalidate(planProvider(projectId!)));
    } else if (plan == null || !plan.hasValue) {
      body = const PageSkeleton(cards: 2);
    } else if (task == null) {
      body = const ErrorView(error: ApiException('not_found'));
    } else {
      body = _TaskBody(key: ValueKey(task.id), task: task, plan: plan.requireValue);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(task?.key ?? ''),
        actions: [
          if (task != null)
            IconButton(
              tooltip: l.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirm(context, message: l.taskDeleteConfirm, confirmLabel: l.actionDelete, destructive: true);
                if (!ok) return;
                try {
                  await ref.read(repositoryProvider).deleteTask(task.id);
                  if (context.mounted) context.canPop() ? context.pop() : context.go('/plan');
                  refreshProject(ref, projectId!);
                } catch (e) {
                  if (context.mounted) showMessage(context, errorMessage(context, e));
                }
              },
            ),
        ],
      ),
      body: body,
    );
  }
}

class _TaskBody extends ConsumerStatefulWidget {
  const _TaskBody({super.key, required this.task, required this.plan});

  final Task task;
  final PlanData plan;

  @override
  ConsumerState<_TaskBody> createState() => _TaskBodyState();
}

class _TaskBodyState extends ConsumerState<_TaskBody> {
  late final _title = TextEditingController(text: widget.task.title);
  late final _description = TextEditingController(text: widget.task.description);
  late final _dod = TextEditingController(text: widget.task.definitionOfDone);
  late final _estimate = TextEditingController(text: formatHours(widget.task.estimateHours));
  late final _actual = TextEditingController(text: widget.task.actualHours == null ? '' : formatHours(widget.task.actualHours!));
  late double _importance = widget.task.importance;
  late bool _optional = widget.task.optional;
  late String? _milestoneId = widget.task.milestoneId;
  bool _saving = false;
  bool _dirty = false;

  Task get task => widget.task;
  String get projectId => widget.plan.project.id;

  @override
  void dispose() {
    for (final c in [_title, _description, _dod, _estimate, _actual]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _hours(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _update(Json changes, {String? message}) async {
    final l = context.l10n;
    try {
      await ref.read(repositoryProvider).updateTask(task.id, changes);
      refreshProject(ref, projectId);
      ref.invalidate(taskProvider(task.id));
      if (mounted) showMessage(context, message ?? l.taskSaved);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final estimate = _hours(_estimate.text);
    final actual = _actual.text.trim().isEmpty ? null : _hours(_actual.text);
    if (_title.text.trim().isEmpty) return showMessage(context, '${l.taskTitle}: ${l.fieldRequired}');
    if (estimate == null || estimate < 0.5 || estimate > 40) return showMessage(context, l.estimateRange);
    if (_actual.text.trim().isNotEmpty && (actual == null || actual < 0)) return showMessage(context, l.errorValidation);
    setState(() => _saving = true);
    await _update({
      if (_title.text.trim() != task.title) 'title': _title.text.trim(),
      if (_description.text.trim() != task.description) 'description': _description.text.trim(),
      if (_dod.text.trim() != task.definitionOfDone) 'definition_of_done': _dod.text.trim(),
      if (estimate != task.estimateHours) 'estimate_hours': estimate,
      'actual_hours': ?actual,
      if (_importance != task.importance) 'importance': _importance,
      if (_optional != task.optional) 'optional': _optional,
      if (_milestoneId != task.milestoneId) 'milestone_id': _milestoneId,
    });
    if (mounted) {
      setState(() {
        _saving = false;
        _dirty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final plan = widget.plan;
    final isParent = plan.parentIds.contains(task.id);
    final subtasks = plan.tasks.where((t) => t.parentTaskId == task.id).toList();
    final milestones = [...plan.milestones]..sort((a, b) => a.position.compareTo(b.position));
    final requirements = ref.watch(requirementsProvider(projectId)).value ?? const <RequirementStatus>[];
    final linked = requirements.where((r) => task.requirementIds.contains(r.id)).toList();

    return Column(
      children: [
        Expanded(
          child: PageBody(
            maxWidth: kReadingWidth,
            children: [
              TextField(
                controller: _title,
                style: theme.textTheme.headlineSmall,
                maxLines: null,
                // An editable heading, not a form field: no box until it has focus.
                decoration: InputDecoration(
                  hintText: l.taskTitle,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: Space.xs),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                ),
                onChanged: (_) => _touch(),
              ),
              const SizedBox(height: Space.md),
              if (!isParent && !task.deferred)
                SegmentedButton<String>(
                  segments: [
                    for (final s in const ['todo', 'in_progress', 'done']) ButtonSegment(value: s, label: Text(taskStatusLabel(l, s))),
                  ],
                  selected: {task.status},
                  onSelectionChanged: (s) => s.first == 'done'
                      ? setTaskDone(context, ref, projectId: projectId, taskId: task.id, done: true)
                      : _update({'status': s.first}),
                ),
              const SizedBox(height: Space.lg),
              if (task.postponeCount >= 2 && !task.isDone)
                InfoBanner(
                  tone: BannerTone.warning,
                  icon: Icons.low_priority,
                  message: l.taskPostponedTwice(task.postponeCount),
                  action: TextButton(onPressed: () => breakDownTask(context, ref, task.id), child: Text(l.taskBreakDown)),
                ),
              _ScheduleCard(task: task),
              if (!task.isDone)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.lg),
                  child: Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => showStartHelp(context, ref, task.id),
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(l.helpMeStart),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => breakDownTask(context, ref, task.id),
                        icon: const Icon(Icons.account_tree_outlined),
                        label: Text(l.taskBreakDown),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.go(Uri(path: '/assistant', queryParameters: {'q': l.explainPrompt(task.title)}).toString()),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(l.taskExplain),
                      ),
                      if (!isParent)
                        OutlinedButton.icon(
                          onPressed: () => _update({'postpone': true}, message: l.taskPostponed),
                          icon: const Icon(Icons.snooze_outlined),
                          label: Text(l.taskPostpone),
                        ),
                    ],
                  ),
                ),
              if (subtasks.isNotEmpty)
                SectionCard(
                  title: l.subtasksTitle,
                  padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, Space.sm),
                  child: Column(
                    children: [
                      for (final s in subtasks)
                        ListTile(
                          leading: Icon(s.isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                          title: Text(s.title),
                          subtitle: Text('${s.key} · ${l.hoursValue(formatHours(s.estimateHours))}'),
                          onTap: () => context.push('/tasks/${s.id}'),
                        ),
                    ],
                  ),
                ),
              _DependenciesCard(task: task, plan: plan, onChanged: (ids) => _update({'depends_on': ids})),
              if (linked.isNotEmpty)
                SectionCard(
                  title: l.taskRequirements,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in linked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.xs),
                          child: Text('${r.code}  ${r.text}', style: theme.textTheme.bodyMedium),
                        ),
                    ],
                  ),
                ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _estimate,
                            enabled: !isParent,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l.taskEstimate),
                            onChanged: (_) => _touch(),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: TextField(
                            controller: _actual,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l.taskActual),
                            onChanged: (_) => _touch(),
                          ),
                        ),
                      ],
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
                      onChanged: (v) => setState(() {
                        _milestoneId = v;
                        _dirty = true;
                      }),
                    ),
                    const SizedBox(height: Space.lg),
                    Text(l.taskImportance, style: theme.textTheme.titleSmall),
                    const SizedBox(height: Space.sm),
                    SegmentedButton<double>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: 0, label: Text(l.importanceNormal)),
                        ButtonSegment(value: 0.5, label: Text(l.importanceHigh)),
                        ButtonSegment(value: 1, label: Text(l.importanceTop)),
                      ],
                      selected: {_importance},
                      onSelectionChanged: (s) => setState(() {
                        _importance = s.first;
                        _dirty = true;
                      }),
                    ),
                    const SizedBox(height: Space.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.taskOptional),
                      value: _optional,
                      onChanged: (v) => setState(() {
                        _optional = v;
                        _dirty = true;
                      }),
                    ),
                    const SizedBox(height: Space.sm),
                    TextField(
                      controller: _dod,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(labelText: l.taskDefinitionOfDone),
                      onChanged: (_) => _touch(),
                    ),
                    const SizedBox(height: Space.lg),
                    TextField(
                      controller: _description,
                      minLines: 2,
                      maxLines: 8,
                      decoration: InputDecoration(labelText: l.taskNotes),
                      onChanged: (_) => _touch(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_dirty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.check), label: Text(l.actionSave)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final start = task.scheduledStart;
    final end = task.scheduledEnd;
    return SectionCard(
      title: l.taskSchedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            end == null
                ? (task.deferred ? l.taskDeferred : l.taskUnscheduled)
                : l.taskScheduled(formatDate(context, start ?? end, alwaysYear: true), formatDate(context, end, alwaysYear: true)),
            style: theme.textTheme.bodyLarge,
          ),
          if (task.latestFinish != null && !task.isDone) ...[
            const SizedBox(height: Space.xs),
            Text(
              l.taskLatestFinish(formatDate(context, task.latestFinish!, alwaysYear: true)),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (task.lateDays > 0 || (task.isCritical && !task.isDone)) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                if (task.lateDays > 0) LatePill(days: task.lateDays),
                if (task.isCritical && !task.isDone) const CriticalPill(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DependenciesCard extends StatelessWidget {
  const _DependenciesCard({required this.task, required this.plan, required this.onChanged});

  final Task task;
  final PlanData plan;
  final ValueChanged<List<String>> onChanged;

  /// Tasks that may become prerequisites: not this task, its subtasks, or its parents.
  List<Task> _candidates() {
    final excluded = <String>{task.id};
    void down(String id) {
      for (final c in plan.tasks.where((t) => t.parentTaskId == id)) {
        excluded.add(c.id);
        down(c.id);
      }
    }

    down(task.id);
    var parent = task.parentTaskId;
    while (parent != null) {
      excluded.add(parent);
      parent = plan.taskById(parent)?.parentTaskId;
    }
    return plan.tasks.where((t) => !excluded.contains(t.id) && !task.dependsOn.contains(t.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final deps = [for (final id in task.dependsOn) ?plan.taskById(id)];
    return SectionCard(
      title: l.taskDependsOn,
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final d in deps)
            InputChip(
              avatar: Icon(d.isDone ? Icons.check_circle : Icons.hourglass_empty, size: 18),
              label: Text('${d.key} ${d.title}', overflow: TextOverflow.ellipsis),
              onPressed: () => context.push('/tasks/${d.id}'),
              onDeleted: () => onChanged([
                for (final x in task.dependsOn)
                  if (x != d.id) x,
              ]),
              deleteButtonTooltipMessage: l.actionDelete,
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text(l.actionAdd),
            onPressed: () async {
              final picked = await showDialog<Task>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(l.taskDependsOn),
                  children: [
                    for (final t in _candidates())
                      SimpleDialogOption(onPressed: () => Navigator.pop(context, t), child: Text('${t.key}  ${t.title}')),
                  ],
                ),
              );
              if (picked != null) onChanged([...task.dependsOn, picked.id]);
            },
          ),
        ],
      ),
    );
  }
}
