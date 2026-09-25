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
import '../brief/brief_editor.dart';
import '../documents/documents_screen.dart';
import '../project/capacity_editor.dart';

/// Project setup in six short steps (master plan §12): type, title and deadline,
/// documents, brief, available time, then the plan preview. With [projectId] the
/// wizard resumes an existing project that has no plan yet.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { template, details, documents, brief, capacity, preview }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.template;
  String? _templateId;
  String? _projectId;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();
  DateTime? _deadline;
  bool _deadlineMissing = false;

  BriefDraft? _draft;
  BriefContent? _brief;
  int _briefRevision = 0;

  CapacityValue _capacity = const CapacityValue(hours: [2, 2, 2, 2, 2, 0, 0], blockedDates: [], bufferPct: 0.15);

  Suggestion? _plan;
  bool _busy = false;
  String? _busyMessage;
  Object? _error;

  /// Whether the resumed project's saved details are in the form yet.
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    final resume = widget.projectId;
    if (resume != null) {
      _projectId = resume;
      _step = _Step.documents;
      _hydrate(ref.read(projectsProvider).value);
      // Opened from a link, the project list may still be on its way.
      ref.listenManual(projectsProvider, (_, next) {
        if (!_hydrated) setState(() => _hydrate(next.value));
      });
    }
  }

  void _hydrate(List<Project>? projects) {
    final project = projects?.where((p) => p.id == widget.projectId).firstOrNull;
    if (project == null) return;
    _hydrated = true;
    _templateId = project.template;
    _title.text = project.title;
    _description.text = project.description;
    _target.text = project.target;
    _deadline = project.deadline;
    if (project.hoursByWeekday.length == 7) {
      _capacity = CapacityValue(hours: project.hoursByWeekday, blockedDates: project.blockedDates, bufferPct: project.bufferPct);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<T?> _run<T>(String? message, Future<T> Function() action) async {
    setState(() {
      _busy = true;
      _busyMessage = message;
      _error = null;
    });
    try {
      return await action();
    } catch (e) {
      if (mounted) setState(() => _error = e);
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
        });
      }
    }
  }

  void _go(_Step step) => setState(() {
    _step = step;
    _error = null;
  });

  // --- step transitions ---------------------------------------------------------------

  Future<void> _submitDetails() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _deadlineMissing = _deadline == null);
    if (!valid || _deadline == null) return;
    final container = containerOf(ref);
    final repo = container.read(repositoryProvider);
    final l = context.l10n;
    final project = await _run(l.creatingProject, () async {
      if (_projectId == null) {
        return repo.createProject(
          template: _templateId!,
          title: _title.text.trim(),
          description: _description.text.trim(),
          target: _target.text.trim(),
          deadline: _deadline!,
          hoursByWeekday: _capacity.hours,
        );
      }
      return repo.updateProject(_projectId!, title: _title.text.trim(), description: _description.text.trim(), deadline: _deadline);
    });
    if (project == null || !mounted) return;
    _projectId = project.id;
    _hydrated = true;
    await container.read(settingsProvider.notifier).selectProject(project.id);
    container.invalidate(projectsProvider);
    container.invalidate(todayProvider);
    if (mounted) _go(_Step.documents);
  }

  Future<void> _loadBrief({bool forceExtract = false}) async {
    _go(_Step.brief);
    final repo = ref.read(repositoryProvider);
    final draft = await _run(context.l10n.briefExtracting, () async {
      if (!forceExtract) {
        final saved = await repo.brief(_projectId!);
        if (saved.version > 0 && !saved.content.isEmpty) {
          return BriefDraft(content: saved.content, aiUsed: saved.source == 'ai', aiError: null);
        }
      }
      return repo.extractBrief(_projectId!);
    });
    if (draft == null || !mounted) return;
    setState(() {
      _draft = draft;
      _brief = draft.content;
      _briefRevision++;
    });
  }

  Future<void> _saveBrief() async {
    final content = _brief;
    if (content == null) return;
    final repo = ref.read(repositoryProvider);
    final saved = await _run(null, () => repo.saveBrief(_projectId!, content, source: (_draft?.aiUsed ?? false) ? 'ai' : 'user'));
    if (saved == null || !mounted) return;
    ref.invalidate(briefProvider(_projectId!));
    ref.invalidate(requirementsProvider(_projectId!));
    _go(_Step.capacity);
  }

  Future<void> _saveCapacity() async {
    final repo = ref.read(repositoryProvider);
    final saved = await _run(
      null,
      () => repo.updateProject(
        _projectId!,
        hoursByWeekday: _capacity.hours,
        blockedDates: _capacity.blockedDates,
        bufferPct: _capacity.bufferPct,
      ),
    );
    if (saved == null || !mounted) return;
    ref.invalidate(projectsProvider);
    await _generate();
  }

  Future<void> _generate() async {
    _go(_Step.preview);
    final repo = ref.read(repositoryProvider);
    final plan = await _run(context.l10n.previewGenerating, () => repo.generatePlan(_projectId!));
    if (!mounted) return;
    setState(() => _plan = plan);
  }

  Future<void> _accept() async {
    final plan = _plan;
    if (plan == null) return;
    final repo = ref.read(repositoryProvider);
    final l = context.l10n;
    final applied = await _run(null, () => repo.applySuggestion(plan.id));
    if (applied == null || !mounted) return;
    _finish(l.previewReady);
  }

  Future<void> _reviewDetails() async {
    final plan = _plan;
    if (plan == null) return;
    await context.push('/suggestions/${plan.id}');
    if (!mounted) return;
    ref.invalidate(suggestionProvider(plan.id));
    final latest = await _run(null, () => ref.read(repositoryProvider).suggestion(plan.id));
    if (latest == null || !mounted) return;
    if (latest.status == 'applied' || latest.status == 'partially_applied') {
      _finish(context.l10n.previewReady);
    } else if (latest.status != 'pending') {
      setState(() => _plan = null);
    }
  }

  void _finish(String message) {
    refreshProject(ref, _projectId!);
    ref.invalidate(documentsProvider(_projectId!));
    ref.read(settingsProvider.notifier).selectProject(_projectId!);
    showMessage(context, message);
    context.go('/today');
  }

  // --- layout ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final titles = {
      _Step.template: l.stepTemplate,
      _Step.details: l.stepDetails,
      _Step.documents: l.stepDocuments,
      _Step.brief: l.stepBrief,
      _Step.capacity: l.stepCapacity,
      _Step.preview: l.stepPreview,
    };
    final index = _step.index + 1;
    final total = _Step.values.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectId == null ? l.newProject : (_title.text.isEmpty ? l.newProject : _title.text)),
        leading: IconButton(
          tooltip: l.actionClose,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/today'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.lg),
            child: Center(
              child: Text(
                l.onboardingStep('$index', '$total'),
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          // The bar glides to the next step instead of jumping.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: index / total),
            duration: reduceMotion(context) ? Duration.zero : Motion.page,
            curve: Motion.enter,
            builder: (context, value, _) =>
                LinearProgressIndicator(value: value, minHeight: 3, backgroundColor: theme.colorScheme.outlineVariant),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                // A new list per step, so every step opens at the top.
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.xxl),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(header: true, child: Text(titles[_step]!, style: theme.textTheme.headlineMedium)),
                          const SizedBox(height: Space.xl),
                          if (_error != null) ...[
                            InfoBanner(
                              tone: BannerTone.warning,
                              icon: Icons.error_outline,
                              message: errorMessage(context, _error!, serverUrl: ref.read(apiBaseUrlProvider)),
                            ),
                          ],
                          // Re-animates when the step or the full-page loading view changes, not on
                          // a quick save, which would rebuild the brief editor and lose the edits.
                          FadeSlideIn(
                            key: ValueKey('${_step.name}-${_busy && _busyMessage != null}'),
                            offset: 8,
                            child: _stepBody(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _BottomBar(bar: _actions(context)),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    if (_busy && _busyMessage != null) return LoadingView(message: _busyMessage);
    return switch (_step) {
      _Step.template => _TemplatePicker(selected: _templateId, onSelected: (id) => setState(() => _templateId = id)),
      _Step.details => _detailsForm(context),
      _Step.documents => _documentsStep(context),
      _Step.brief => _briefStep(context),
      _Step.capacity => CapacityEditor(value: _capacity, onChanged: (v) => setState(() => _capacity = v)),
      _Step.preview => _plan == null ? const SizedBox.shrink() : _PlanPreview(plan: _plan!, deadline: _deadline),
    };
  }

  /// The bottom bar: an optional way back on the left, the way forward on the right.
  ({Widget? back, List<Widget> actions}) _actions(BuildContext context) {
    final l = context.l10n;
    Widget back(_Step to) => TextButton(onPressed: _busy ? null : () => _go(to), child: Text(l.actionBack));
    Widget next(VoidCallback? onPressed, [String? label]) => FilledButton(
      onPressed: _busy ? null : onPressed,
      child: BusyLabel(
        busy: _busy && _busyMessage == null,
        child: Text(label ?? l.actionNext, textAlign: TextAlign.center),
      ),
    );
    switch (_step) {
      case _Step.template:
        return (back: null, actions: [next(_templateId == null ? null : () => _go(_Step.details))]);
      case _Step.details:
        return (back: _projectId == null ? back(_Step.template) : null, actions: [next(_submitDetails)]);
      case _Step.documents:
        final docs = ref.watch(documentsProvider(_projectId!)).value ?? const [];
        final processing = docs.any((d) => d.status == 'processing');
        return (
          back: back(_Step.details),
          actions: [
            if (docs.isEmpty) TextButton(onPressed: _busy ? null : _loadBrief, child: Text(l.actionSkip)),
            next(processing ? null : _loadBrief, processing ? l.documentsWaitProcessing : null),
          ],
        );
      case _Step.brief:
        return (back: back(_Step.documents), actions: [next(_brief == null ? null : _saveBrief)]);
      case _Step.capacity:
        final enough = _capacity.weekly > 0;
        return (back: back(_Step.brief), actions: [next(enough ? _saveCapacity : null)]);
      case _Step.preview:
        if (_plan == null && isPlanExists(_error)) {
          return (back: null, actions: [next(() => context.go('/plan'), l.navPlan)]);
        }
        if (_plan == null) {
          // After an error, or after the draft was rejected on the detail screen.
          return (back: back(_Step.capacity), actions: [next(_generate, _error == null ? l.previewRegenerate : l.actionRetry)]);
        }
        return (
          back: back(_Step.capacity),
          actions: [
            TextButton(onPressed: _busy ? null : _reviewDetails, child: Text(l.previewReviewDetails)),
            next(_accept, l.previewAccept),
          ],
        );
    }
  }

  Widget _detailsForm(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _title,
            autofocus: true,
            maxLength: 300,
            textInputAction: TextInputAction.next,
            // The limit still applies; a running 0/300 counter is only noise here.
            decoration: InputDecoration(labelText: l.fieldTitle, hintText: l.fieldTitleHint, counterText: ''),
            validator: (v) => (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: Space.md),
          TextFormField(
            controller: _description,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: l.fieldDescription),
          ),
          const SizedBox(height: Space.lg),
          TextFormField(
            controller: _target,
            decoration: InputDecoration(labelText: l.fieldTarget, hintText: l.fieldTargetHint),
          ),
          const SizedBox(height: Space.xl),
          Text(l.fieldDeadline, style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(_deadline == null ? l.pickDate : formatDateLong(context, _deadline!)),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await pickDate(
                  context,
                  initial: _deadline ?? DateTime(now.year, now.month + 4, now.day),
                  first: now.add(const Duration(days: 1)),
                  last: DateTime(now.year + 5),
                );
                if (picked != null) {
                  setState(() {
                    _deadline = dateOnly(picked);
                    _deadlineMissing = false;
                  });
                }
              },
            ),
          ),
          if (_deadlineMissing)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(l.fieldRequired, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ),
          if (_deadline != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(l.daysLeft(dateOnly(_deadline!).difference(dateOnly(DateTime.now())).inDays), style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }

  Widget _documentsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.documentsStepHint, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: Space.lg),
        DocumentsPanel(projectId: _projectId!),
      ],
    );
  }

  Widget _briefStep(BuildContext context) {
    final l = context.l10n;
    final draft = _draft;
    if (draft == null) {
      return _error == null
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(onPressed: _loadBrief, icon: const Icon(Icons.refresh), label: Text(l.actionRetry)),
            );
    }
    final reason = aiFallbackReason(l, draft.aiError);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SourceLabel(aiUsed: draft.aiUsed),
            TextButton.icon(
              onPressed: _busy ? null : () => _loadBrief(forceExtract: true),
              icon: const Icon(Icons.refresh),
              label: Text(l.briefExtractAgain),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        if (reason != null) InfoBanner(message: reason, icon: Icons.auto_awesome_outlined),
        // Coming back from a later step keeps the edits made here.
        BriefEditor(key: ValueKey(_briefRevision), initial: _brief ?? draft.content, onChanged: (b) => _brief = b),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.bar});

  final ({Widget? back, List<Widget> actions}) bar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                ?bar.back,
                const SizedBox(width: Space.sm),
                // On a narrow phone the actions wrap onto a second line instead of overflowing.
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Space.sm,
                    runSpacing: Space.xs,
                    children: bar.actions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplatePicker extends ConsumerWidget {
  const _TemplatePicker({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = context.localeCode;
    return AsyncBody(
      loading: const PageSkeleton(inline: true, cards: 3),
      value: ref.watch(modesProvider),
      onRetry: () => ref.invalidate(modesProvider),
      data: (modes) {
        final templates = [for (final m in modes) ...m.templates];
        return RadioGroup<String>(
          groupValue: selected,
          onChanged: (id) {
            if (id != null) onSelected(id);
          },
          child: Column(
            children: [
              for (final t in templates)
                Pressable(
                  child: AppCard(
                    margin: const EdgeInsets.only(bottom: Space.md),
                    selected: selected == t.id,
                    child: RadioListTile<String>(
                      value: t.id,
                      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                      title: Text(t.name.of(locale), style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: Text('${t.description.of(locale)}\n${l.templateSummary('${t.taskCount}', formatHours(t.totalHours))}'),
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// What the scheduler would do with the proposed structure (master plan §12, step 6).
class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.plan, required this.deadline});

  final Suggestion plan;
  final DateTime? deadline;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final milestones = plan.ops.where((o) => o.entity == 'milestone').toList();
    final tasks = plan.ops.where((o) => o.entity == 'task').toList();
    final reason = aiFallbackReason(l, plan.aiError);
    final uncovered = (plan.meta['uncovered_requirements'] as List? ?? const []).map((e) => '$e').toList();
    final finish = plan.projectedFinish;
    final tone = plan.feasibility == 'feasible' ? BannerTone.info : BannerTone.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [SourceLabel.forSuggestion(plan.kind, aiUsed: plan.aiUsed)],
        ),
        const SizedBox(height: Space.md),
        if (reason != null) InfoBanner(message: reason, icon: Icons.auto_awesome_outlined),
        InfoBanner(
          tone: tone,
          icon: plan.feasibility == 'feasible' ? Icons.check_circle_outline : Icons.error_outline,
          message: [
            feasibilityLabel(l, plan.feasibility, plan.shortfallHours),
            if (finish != null) l.projectedFinish(formatDate(context, finish, alwaysYear: true)),
            if (deadline != null) l.deadlineOn(formatDate(context, deadline!, alwaysYear: true)),
          ].join(' · '),
        ),
        Text(l.previewSummary('${tasks.length}', formatHours(plan.totalHours)), style: theme.textTheme.titleMedium),
        const SizedBox(height: Space.md),
        for (final m in milestones) _MilestonePreview(milestone: m, tasks: tasks.where((t) => t.fields['milestone_key'] == m.key).toList()),
        if (uncovered.isNotEmpty)
          InfoBanner(tone: BannerTone.warning, icon: Icons.rule_outlined, message: l.previewUncovered(uncovered.join(', '))),
        if (plan.questions.isNotEmpty) _BulletCard(title: l.planQuestions, items: plan.questions),
        if (plan.assumptions.isNotEmpty) _BulletCard(title: l.planAssumptions, items: plan.assumptions),
        Text(l.suggestionNothingChanges, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _MilestonePreview extends StatelessWidget {
  const _MilestonePreview({required this.milestone, required this.tasks});

  final SuggestionOp milestone;
  final List<SuggestionOp> tasks;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final hours = tasks.fold<double>(0, (sum, t) => sum + ((t.fields['estimate_hours'] as num?)?.toDouble() ?? 0));
    return AppCard(
      margin: const EdgeInsets.only(bottom: Space.md),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text('${milestone.fields['title'] ?? milestone.key}', style: theme.textTheme.titleMedium),
        subtitle: Text(l.milestoneSummary('${tasks.length}', formatHours(hours))),
        childrenPadding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.md),
        children: [
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${t.fields['title']}${t.fields['optional'] == true ? ' · ${l.optionalTag}' : ''}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Text(l.hoursValue(formatHours((t.fields['estimate_hours'] as num?)?.toDouble() ?? 0)), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.title, required this.items});

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
              child: Text('•  $item', style: Theme.of(context).textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

/// True when the error is the API's "plan already exists" answer.
bool isPlanExists(Object? error) => error is ApiException && error.code == 'plan_exists';
