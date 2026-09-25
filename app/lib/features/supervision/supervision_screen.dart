import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/providers.dart';

/// Supervision log: notes from a meeting become proposed tasks, never direct
/// changes (master plan §7).
class SupervisionScreen extends ConsumerStatefulWidget {
  const SupervisionScreen({super.key});

  @override
  ConsumerState<SupervisionScreen> createState() => _SupervisionScreenState();
}

class _SupervisionScreenState extends ConsumerState<SupervisionScreen> {
  final _notes = TextEditingController();
  DateTime _date = dateOnly(DateTime.now());
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The unsaved-changes guard follows what is typed.
    _notes.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(String projectId) async {
    final l = context.l10n;
    if (_notes.text.trim().isEmpty) return showMessage(context, '${l.supervisionNotes}: ${l.fieldRequired}');
    final container = containerOf(ref);
    setState(() => _busy = true);
    try {
      final suggestion = await container.read(repositoryProvider).addSupervisionNote(projectId, _notes.text.trim(), _date);
      container.invalidate(supervisionNotesProvider(projectId));
      container.invalidate(suggestionsProvider(projectId));
      container.invalidate(todayProvider);
      container.invalidate(notificationsProvider);
      if (!mounted) return;
      _notes.clear();
      if (suggestion == null) {
        showMessage(context, l.supervisionNoProposal);
      } else {
        context.push('/suggestions/${suggestion.id}');
      }
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final project = ref.watch(currentProjectProvider);
    if (project == null) return Scaffold(appBar: AppBar(), body: const PageSkeleton());
    final history = ref.watch(supervisionNotesProvider(project.id));
    return UnsavedChangesGuard(
      dirty: _notes.text.trim().isNotEmpty && !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.supervisionTitle)),
        body: PageBody(
          maxWidth: kReadingWidth,
          children: [
            Text(l.supervisionIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: Space.lg),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.supervisionDate, style: theme.textTheme.titleSmall),
                  const SizedBox(height: Space.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined),
                      label: Text(formatDateLong(context, _date)),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await pickDate(
                          context,
                          initial: _date,
                          first: DateTime(now.year - 2),
                          last: now.add(const Duration(days: 60)),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  TextField(
                    controller: _notes,
                    minLines: 5,
                    maxLines: 14,
                    decoration: InputDecoration(labelText: l.supervisionNotes, hintText: l.supervisionNotesHint, alignLabelWithHint: true),
                  ),
                  const SizedBox(height: Space.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _save(project.id),
                      icon: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_fix_high_outlined),
                      label: Text(l.supervisionSave),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            Semantics(header: true, child: Text(l.supervisionHistory, style: theme.textTheme.titleMedium)),
            const SizedBox(height: Space.md),
            switch (history) {
              AsyncValue(hasValue: true, :final value?) when value.isEmpty => EmptyState(
                icon: Icons.forum_outlined,
                message: l.supervisionEmpty,
              ),
              AsyncValue(hasValue: true, :final value?) => Column(
                children: [
                  for (final n in value)
                    SectionCard(
                      title: n.meetingDate == null ? null : formatDateLong(context, n.meetingDate!),
                      child: SelectableText(n.content, style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
              AsyncValue(:final error?) => ErrorView(error: error, onRetry: () => ref.invalidate(supervisionNotesProvider(project.id))),
              _ => const PageSkeleton(inline: true, cards: 2),
            },
          ],
        ),
      ),
    );
  }
}
