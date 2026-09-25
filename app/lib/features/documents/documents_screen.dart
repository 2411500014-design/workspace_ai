import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    if (project == null) return const PageSkeleton();
    return PageBody(
      onRefresh: () async => ref.invalidate(documentsProvider(project.id)),
      children: [
        PageHeader(title: context.l10n.documentsTitle),
        DocumentsPanel(projectId: project.id),
      ],
    );
  }
}

/// Upload button plus the document list; also used in onboarding.
class DocumentsPanel extends ConsumerStatefulWidget {
  const DocumentsPanel({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<DocumentsPanel> createState() => _DocumentsPanelState();
}

class _DocumentsPanelState extends ConsumerState<DocumentsPanel> {
  Timer? _poll;
  bool _uploading = false;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// While any document is processing, refresh every two seconds.
  void _schedulePoll(List<DocumentItem> docs) {
    final processing = docs.any((d) => d.status == 'processing');
    if (processing && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => ref.invalidate(documentsProvider(widget.projectId)));
    } else if (!processing && _poll != null) {
      _poll!.cancel();
      _poll = null;
      // Processing may have created a brief-update suggestion.
      ref.invalidate(suggestionsProvider(widget.projectId));
    }
  }

  Future<void> _upload() async {
    final l = context.l10n;
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'docx', 'txt', 'md']);
    if (files.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    final repo = ref.read(repositoryProvider);
    var uploaded = 0;
    final errors = <String>[];
    for (final file in files) {
      try {
        await repo.uploadDocument(widget.projectId, file.name, await file.readAsBytes());
        uploaded++;
      } catch (e) {
        if (mounted) errors.add('${file.name}: ${errorMessage(context, e)}');
      }
    }
    if (!mounted) return;
    setState(() => _uploading = false);
    ref.invalidate(documentsProvider(widget.projectId));
    showMessage(context, [if (uploaded > 0) l.docUploaded(uploaded), ...errors].join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final docs = ref.watch(documentsProvider(widget.projectId));
    ref.listen(documentsProvider(widget.projectId), (_, next) {
      if (next.hasValue) _schedulePoll(next.requireValue);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: _uploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: Text(l.documentsUpload),
            ),
            const SizedBox(width: Space.md),
            Expanded(child: Text(l.documentsHint, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
        const SizedBox(height: Space.lg),
        switch (docs) {
          AsyncValue(hasValue: true, :final value?) when value.isEmpty => EmptyState(
            icon: Icons.description_outlined,
            message: l.documentsEmpty,
          ),
          AsyncValue(hasValue: true, :final value?) => Column(
            children: [for (final d in value) _DocumentCard(document: d, projectId: widget.projectId)],
          ),
          AsyncValue(:final error?) => ErrorView(error: error, onRetry: () => ref.invalidate(documentsProvider(widget.projectId))),
          _ => const PageSkeleton(inline: true, cards: 2),
        },
      ],
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  const _DocumentCard({required this.document, required this.projectId});

  final DocumentItem document;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final repo = ref.read(repositoryProvider);
    final (statusText, statusIcon, fg, bg) = switch (document.status) {
      'ready' => (l.docStatusReady, Icons.check_circle_outline, context.statusSuccess.$1, context.statusSuccess.$2),
      'failed' => (l.docStatusFailed, Icons.error_outline, scheme.onErrorContainer, scheme.errorContainer),
      _ => (l.docStatusProcessing, Icons.hourglass_top, scheme.onSecondaryContainer, scheme.secondaryContainer),
    };
    final meta = <String>[
      documentKindLabel(l, document.kind),
      if (document.pages != null) l.docPages(document.pages!),
      if (document.metadata['year'] != null) '${document.metadata['year']}',
      if (document.metadata['doi'] != null) 'DOI ${document.metadata['doi']}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_outlined, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(document.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: Space.xs),
                        Text(meta.join(' · '), style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.actionDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        message: l.docDeleteConfirm(document.title),
                        confirmLabel: l.actionDelete,
                        destructive: true,
                      );
                      if (!ok) return;
                      await repo.deleteDocument(document.id);
                      ref.invalidate(documentsProvider(projectId));
                    },
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: Space.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(label: statusText, icon: statusIcon, foreground: fg, background: bg),
                  if (document.status == 'failed')
                    TextButton.icon(
                      onPressed: () async {
                        await repo.retryDocument(document.id);
                        ref.invalidate(documentsProvider(projectId));
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l.actionRetry),
                    ),
                ],
              ),
              if (document.status == 'failed') ...[
                const SizedBox(height: Space.sm),
                Text(documentErrorMessage(context, document.errorCode), style: theme.textTheme.bodyMedium),
              ],
              if (document.summary.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                Text(document.summary, maxLines: 6, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                if (!document.summaryAi)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Text(l.docSummaryBasic, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on BuildContext {
  (Color, Color) get statusSuccess => healthColors(this, 'on_track');
}
