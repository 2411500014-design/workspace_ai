import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// Reviews one proposal as a list of changes. Nothing changes until the user accepts
/// all of it, some of it, or rejects it (master plan §4 "AI proposes, user decides").
class SuggestionScreen extends ConsumerStatefulWidget {
  const SuggestionScreen({super.key, required this.suggestionId});

  final String suggestionId;

  @override
  ConsumerState<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends ConsumerState<SuggestionScreen> {
  Set<int>? _selected;
  bool _busy = false;

  Future<void> _decide(Suggestion s, {required bool accept}) async {
    final container = containerOf(ref);
    final repo = container.read(repositoryProvider);
    final l = context.l10n;
    final selected = _selected ?? {for (var i = 0; i < s.ops.length; i++) i};
    setState(() => _busy = true);
    try {
      if (accept) {
        final all = selected.length == s.ops.length;
        await repo.applySuggestion(s.id, opIndices: all ? null : (selected.toList()..sort()));
      } else {
        await repo.rejectSuggestion(s.id);
      }
      refreshProjectIn(container, s.projectId);
      container.invalidate(documentsProvider(s.projectId));
      container.invalidate(suggestionProvider(s.id));
      if (!mounted) return;
      showMessage(context, accept ? l.suggestionApplied : l.suggestionRejected);
      context.canPop() ? context.pop(true) : context.go('/project');
    } catch (e) {
      // Decided elsewhere meanwhile (another tab, the phone): show its current state.
      container.invalidate(suggestionProvider(s.id));
      container.invalidate(suggestionsProvider(s.projectId));
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final value = ref.watch(suggestionProvider(widget.suggestionId));
    return Scaffold(
      appBar: AppBar(title: Text(value.hasValue ? suggestionKindLabel(l, value.requireValue.kind) : l.pendingTitle)),
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(suggestionProvider(widget.suggestionId)),
        data: (s) {
          final selected = _selected ?? {for (var i = 0; i < s.ops.length; i++) i};
          return Column(
            children: [
              Expanded(
                child: PageBody(
                  maxWidth: kReadingWidth,
                  children: [
                    _Header(suggestion: s),
                    SectionCard(
                      title: s.isPending ? l.suggestionPick : null,
                      padding: const EdgeInsets.symmetric(vertical: Space.sm),
                      child: Column(
                        children: [
                          for (var i = 0; i < s.ops.length; i++)
                            _OpTile(
                              op: s.ops[i],
                              checked: selected.contains(i),
                              onChanged: !s.isPending || _busy
                                  ? null
                                  : (v) => setState(() {
                                      final next = {...selected};
                                      v == true ? next.add(i) : next.remove(i);
                                      _selected = next;
                                    }),
                            ),
                        ],
                      ),
                    ),
                    if (s.changes.isNotEmpty) _ChangesCard(suggestion: s),
                    if (s.questions.isNotEmpty) _ListCard(title: l.planQuestions, items: s.questions),
                    if (s.assumptions.isNotEmpty) _ListCard(title: l.planAssumptions, items: s.assumptions),
                  ],
                ),
              ),
              if (s.isPending)
                _DecisionBar(
                  busy: _busy,
                  total: s.ops.length,
                  selected: selected.length,
                  onAccept: () => _decide(s, accept: true),
                  onReject: () => _decide(s, accept: false),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final s = suggestion;
    final reason = aiFallbackReason(l, s.aiError);
    final finish = s.projectedFinish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [SourceLabel.forSuggestion(s.kind, aiUsed: s.aiUsed)],
        ),
        const SizedBox(height: Space.md),
        if (!s.isPending) InfoBanner(icon: Icons.task_alt, message: l.errorSuggestionDecided),
        if (reason != null) InfoBanner(icon: Icons.auto_awesome_outlined, message: reason),
        if (s.rationale.isNotEmpty) ...[Text(s.rationale, style: theme.textTheme.bodyLarge), const SizedBox(height: Space.lg)],
        if (s.feasibility != null)
          InfoBanner(
            tone: s.feasibility == 'feasible' ? BannerTone.info : BannerTone.warning,
            icon: s.feasibility == 'feasible' ? Icons.check_circle_outline : Icons.error_outline,
            message: [
              feasibilityLabel(l, s.feasibility, s.shortfallHours),
              if (finish != null) l.projectedFinish(formatDate(context, finish, alwaysYear: true)),
            ].join(' · '),
          ),
        if (s.isPending)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Text(l.suggestionNothingChanges, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}

/// One operation of the diff, in words.
class _OpTile extends StatelessWidget {
  const _OpTile({required this.op, required this.checked, required this.onChanged});

  final SuggestionOp op;
  final bool checked;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = describeOp(context, op);
    return CheckboxListTile(
      value: checked,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
    );
  }
}

/// Icon, title and detail line for a diff operation.
(IconData, String, String?) describeOp(BuildContext context, SuggestionOp op) {
  final l = context.l10n;
  final f = op.fields;
  final label = op.label ?? '${f['title'] ?? op.id ?? ''}';
  String hours(Object? v) => l.hoursValue(formatHours((v as num?)?.toDouble() ?? 0));
  switch ((op.op, op.entity)) {
    case ('add', 'milestone'):
      return (Icons.flag_outlined, l.opAddMilestone('${f['title'] ?? op.key}'), null);
    case ('add', 'task'):
      final title = '${f['title'] ?? ''}';
      final detail = [hours(f['estimate_hours']), if (f['optional'] == true) l.optionalTag].join(' · ');
      return f['parent_task_id'] != null
          ? (Icons.subdirectory_arrow_right, l.opAddSubtask(title), detail)
          : (Icons.add_task, l.opAddTask(title), detail);
    case ('update', 'task') when f['deferred'] == true:
      return (Icons.do_not_disturb_on_outlined, l.opDeferTask(label), null);
    case ('update', 'task'):
      final parts = <String>[
        if (f['estimate_hours'] != null) '${l.taskEstimate}: ${hours(f['estimate_hours'])}',
        if (f['title'] != null && f['title'] != label) '${l.taskTitle}: ${f['title']}',
        if (f['optional'] == true) l.optionalTag,
      ];
      return (Icons.edit_outlined, l.opUpdateTask(label), parts.isEmpty ? null : parts.join(' · '));
    case ('delete', 'task'):
      return (Icons.delete_outline, l.opDeleteTask(label), null);
    case ('add', 'requirement'):
      return (Icons.rule_outlined, l.opAddRequirement('${f['text'] ?? ''}'), null);
    case ('add', 'memory'):
      return (Icons.bookmark_add_outlined, l.opAddMemory('${f['content'] ?? ''}'), null);
    case ('reschedule', 'project'):
      return (Icons.event_repeat, l.opReschedule, null);
    case ('update', 'project') when f['extra_hours'] is Map:
      final extra = Map<String, dynamic>.from(f['extra_hours'] as Map);
      final total = extra.values.fold<double>(0, (sum, v) => sum + ((v as num?)?.toDouble() ?? 0));
      final days = extra.keys.toList()..sort();
      final until = days.isEmpty ? '' : formatDate(context, DateTime.parse(days.last), alwaysYear: true);
      return (Icons.more_time, l.opExtraHours(formatHours(total), until), null);
    case ('update', 'project') when f['deadline'] != null:
      return (Icons.event_outlined, l.opDeadline(formatDate(context, DateTime.parse('${f['deadline']}'), alwaysYear: true)), null);
    case ('update', 'project') when f['hours_by_weekday'] is List:
      final total = (f['hours_by_weekday'] as List).fold<double>(0, (sum, v) => sum + ((v as num?)?.toDouble() ?? 0));
      return (Icons.schedule, l.capacityWeekly(formatHours(total)), null);
    default:
      return (Icons.change_circle_outlined, suggestionKindLabel(l, 'task_change'), null);
  }
}

/// Old and new finish dates for the tasks whose schedule would move.
class _ChangesCard extends StatelessWidget {
  const _ChangesCard({required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    String date(Object? v) => v == null ? '—' : formatDate(context, DateTime.parse('$v'));
    return SectionCard(
      title: l.changedTasks(suggestion.changedCount),
      child: Column(
        children: [
          for (final c in suggestion.changes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: [
                  Expanded(child: Text('${c['key']}  ${c['title']}', style: theme.textTheme.bodyMedium)),
                  const SizedBox(width: Space.md),
                  Text(date(c['old_end']), style: theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: Space.xs),
                    child: Icon(Icons.arrow_forward, size: 16),
                  ),
                  Text(date(c['new_end']), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Text('•  $item'),
            ),
        ],
      ),
    );
  }
}

class _DecisionBar extends StatelessWidget {
  const _DecisionBar({required this.busy, required this.total, required this.selected, required this.onAccept, required this.onReject});

  final bool busy;
  final int total;
  final int selected;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: Row(
                children: [
                  TextButton(onPressed: busy ? null : onReject, child: Text(l.suggestionReject)),
                  const SizedBox(width: Space.sm),
                  // The accept label grows with "3 selected"; on a phone it wraps rather than overflows.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: busy || selected == 0 ? null : onAccept,
                        child: BusyLabel(
                          busy: busy,
                          child: Text(
                            selected == total ? l.suggestionAcceptAll : l.suggestionAcceptSelected(selected),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
