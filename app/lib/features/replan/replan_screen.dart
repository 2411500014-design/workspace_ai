import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// "Sesuaikan rencana": the scheduler computes the options, the user picks one
/// (master plan §8, re-planning).
class ReplanScreen extends ConsumerStatefulWidget {
  const ReplanScreen({super.key});

  @override
  ConsumerState<ReplanScreen> createState() => _ReplanScreenState();
}

class _ReplanScreenState extends ConsumerState<ReplanScreen> {
  Future<List<Suggestion>>? _options;
  String? _projectId;
  String? _applying;

  @override
  void initState() {
    super.initState();
    // Opened straight from a link, the project list may still be loading: start
    // computing as soon as the project is known.
    _start(ref.read(currentProjectProvider));
    ref.listenManual(currentProjectProvider, (_, project) => setState(() => _start(project)));
  }

  void _start(Project? project) {
    if (_options != null || project == null) return;
    _projectId = project.id;
    _options = ref.read(repositoryProvider).replan(project.id);
  }

  void _recompute() => setState(() => _options = ref.read(repositoryProvider).replan(_projectId!));

  Future<void> _choose(Suggestion option) async {
    final l = context.l10n;
    final container = containerOf(ref);
    setState(() => _applying = option.id);
    try {
      await container.read(repositoryProvider).applySuggestion(option.id);
      refreshProjectIn(container, option.projectId);
      if (!mounted) return;
      showMessage(context, l.suggestionApplied);
      context.canPop() ? context.pop() : context.go('/plan');
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _applying = null);
    }
  }

  /// A decision made on the detail screen makes the other options stale.
  Future<void> _review(Suggestion option) async {
    final decided = await context.push<bool>('/suggestions/${option.id}');
    if (!mounted || decided != true) return;
    context.canPop() ? context.pop() : context.go('/plan');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final project = ref.watch(currentProjectProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.replanTitle),
        actions: [IconButton(tooltip: l.actionRefresh, onPressed: _options == null ? null : _recompute, icon: const Icon(Icons.refresh))],
      ),
      body: _options == null
          ? const LoadingView()
          : FutureBuilder<List<Suggestion>>(
              future: _options,
              builder: (context, snapshot) {
                if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _recompute);
                if (snapshot.connectionState != ConnectionState.done) return LoadingView(message: l.replanComputing);
                final options = snapshot.data!;
                return PageBody(
                  maxWidth: kReadingWidth,
                  children: [
                    Text(l.replanIntro, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: Space.lg),
                    if (project != null) ...[
                      Text(
                        l.deadlineOn(formatDate(context, project.deadline, alwaysYear: true)),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: Space.lg),
                    ],
                    if (options.isNotEmpty &&
                        aiFallbackReason(l, options.first.aiError) != null &&
                        options.first.aiError != 'ai_unavailable')
                      InfoBanner(icon: Icons.auto_awesome_outlined, message: aiFallbackReason(l, options.first.aiError)!),
                    for (final (i, option) in options.indexed)
                      _OptionCard(
                        option: option,
                        recommended: i == 0,
                        busy: _applying != null,
                        applying: _applying == option.id,
                        onChoose: () => _choose(option),
                        onReview: () => _review(option),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.recommended,
    required this.busy,
    required this.applying,
    required this.onChoose,
    required this.onReview,
  });

  final Suggestion option;
  final bool recommended;
  final bool busy;
  final bool applying;
  final VoidCallback onChoose;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = option.params;
    final (icon, title, description) = switch (option.option) {
      'add_capacity' => (
        Icons.more_time,
        l.optionAddCapacity,
        l.optionAddCapacityDesc(formatHours((p['hours_per_week'] as num?)?.toDouble() ?? 0), '${p['weeks'] ?? ''}'),
      ),
      'reduce_scope' => (
        Icons.content_cut,
        l.optionReduceScope,
        l.optionReduceScopeDesc(((p['deferred_titles'] as List?) ?? const []).join(', ')),
      ),
      'extend_deadline' => (
        Icons.event_outlined,
        l.optionExtendDeadline,
        l.optionExtendDeadlineDesc(switch (DateTime.tryParse('${p['new_deadline'] ?? ''}')) {
          final date? => formatDate(context, date, alwaysYear: true),
          null => '',
        }, '${p['days'] ?? ''}'),
      ),
      _ => (Icons.event_repeat, l.optionReschedule, l.optionRescheduleDesc),
    };
    final finish = option.projectedFinish;
    final (fg, bg) = healthColors(context, switch (option.feasibility) {
      'feasible' => 'on_track',
      'tight' => 'at_risk',
      _ => 'off_track',
    });
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: Space.md),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (recommended)
                StatusPill(
                  label: l.recommendedTag,
                  icon: Icons.star_outline,
                  foreground: theme.colorScheme.onPrimaryContainer,
                  background: theme.colorScheme.primaryContainer,
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              StatusPill(
                label: feasibilityLabel(l, option.feasibility, option.shortfallHours),
                icon: option.feasibility == 'feasible' ? Icons.check_circle_outline : Icons.error_outline,
                foreground: fg,
                background: bg,
              ),
              if (finish != null)
                StatusPill(
                  label: l.projectedFinish(formatDate(context, finish, alwaysYear: true)),
                  icon: Icons.flag_outlined,
                  foreground: theme.colorScheme.onSurfaceVariant,
                  background: theme.colorScheme.surfaceContainerHigh,
                ),
              StatusPill(
                label: l.changedTasks(option.changedCount),
                icon: Icons.swap_vert,
                foreground: theme.colorScheme.onSurfaceVariant,
                background: theme.colorScheme.surfaceContainerHigh,
              ),
            ],
          ),
          if (option.rationale.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text(option.rationale, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton(
                onPressed: busy ? null : onChoose,
                child: applying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.chooseOption),
              ),
              OutlinedButton(onPressed: busy ? null : onReview, child: Text(l.previewReviewDetails)),
            ],
          ),
        ],
      ),
    );
  }
}
