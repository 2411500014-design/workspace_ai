import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'brief_editor.dart';

/// The project brief: the single source of truth for goals and requirements.
/// Every save becomes a new version (master plan §4).
class BriefScreen extends ConsumerStatefulWidget {
  const BriefScreen({super.key});

  @override
  ConsumerState<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends ConsumerState<BriefScreen> {
  BriefContent? _edited;
  BriefDraft? _draft;
  int _revision = 0;
  bool _busy = false;
  bool _dirty = false;

  Future<void> _extract(String projectId) async {
    setState(() => _busy = true);
    try {
      final draft = await ref.read(repositoryProvider).extractBrief(projectId);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _edited = draft.content;
        _revision++;
        _dirty = true;
      });
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(String projectId) async {
    final content = _edited;
    if (content == null) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).saveBrief(projectId, content, source: (_draft?.aiUsed ?? false) ? 'ai' : 'user');
      ref.invalidate(briefProvider(projectId));
      ref.invalidate(requirementsProvider(projectId));
      if (!mounted) return;
      setState(() {
        _draft = null;
        _dirty = false;
        _revision++;
      });
      showMessage(context, l.briefSaved);
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final project = ref.watch(currentProjectProvider);
    if (project == null) return Scaffold(appBar: AppBar(), body: const PageSkeleton());
    final brief = ref.watch(briefProvider(project.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.briefTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: FilledButton(onPressed: _busy || !_dirty ? null : () => _save(project.id), child: Text(l.actionSave)),
          ),
        ],
      ),
      body: AsyncBody(
        value: brief,
        onRetry: () => ref.invalidate(briefProvider(project.id)),
        data: (b) {
          final draft = _draft;
          final reason = draft == null ? null : aiFallbackReason(l, draft.aiError);
          return PageBody(
            maxWidth: kReadingWidth,
            children: [
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (b.version > 0 && draft == null)
                    StatusPill(
                      label: l.briefVersion('${b.version}'),
                      icon: Icons.history,
                      foreground: Theme.of(context).colorScheme.onSurfaceVariant,
                      background: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                  if (draft != null) SourceLabel(aiUsed: draft.aiUsed) else if (b.source == 'ai') const SourceLabel(aiUsed: true),
                  TextButton.icon(
                    onPressed: _busy ? null : () => _extract(project.id),
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_outlined),
                    label: Text(l.briefExtractAgain),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              if (_busy && draft == null) InfoBanner(icon: Icons.hourglass_top, message: l.briefExtracting),
              if (reason != null) InfoBanner(icon: Icons.auto_awesome_outlined, message: reason),
              if (draft != null) InfoBanner(icon: Icons.edit_note, message: l.briefDraftUnsaved),
              if (b.version == 0 && draft == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.lg),
                  child: Text(l.briefEmpty, style: Theme.of(context).textTheme.bodyLarge),
                ),
              BriefEditor(
                key: ValueKey('brief-$_revision-${b.version}'),
                initial: draft?.content ?? b.content,
                onChanged: (content) {
                  _edited = content;
                  if (!_dirty && _differs(content, draft?.content ?? b.content)) setState(() => _dirty = true);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  bool _differs(BriefContent a, BriefContent b) => a.toJson().toString() != b.toJson().toString();
}
