import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/providers.dart';

/// One-tap progress update (master plan §12), with undo.
///
/// The card that was tapped usually disappears once the task is done, so everything
/// needed afterwards (repository, container, messenger) is captured before the first
/// `await`; nothing touches the card's `ref` or `context` later.
Future<void> setTaskDone(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String taskId,
  required bool done,
}) async {
  final container = containerOf(ref);
  final repo = container.read(repositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  void report(Object error) {
    if (messenger.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(messenger.context, error))));
    }
  }

  try {
    await repo.updateTask(taskId, {'status': done ? 'done' : 'todo'});
  } catch (e) {
    report(e);
    return;
  }
  refreshProjectIn(container, projectId);
  if (!done || !messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l.markedDone),
        action: SnackBarAction(
          label: l.actionUndo,
          onPressed: () async {
            try {
              await repo.updateTask(taskId, {'status': 'todo'});
              refreshProjectIn(container, projectId);
            } catch (e) {
              report(e);
            }
          },
        ),
      ),
    );
}

/// "Help me start": a first step of about 25 minutes (master plan §12).
Future<void> showStartHelp(BuildContext context, WidgetRef ref, String taskId) async {
  final l = context.l10n;
  // Asked once, not on every rebuild of the dialog.
  final help = ref.read(repositoryProvider).startHelp(taskId);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.timer_outlined),
      title: Text(l.firstStepTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: FutureBuilder(
          future: help,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(errorMessage(context, snapshot.error!));
            if (!snapshot.hasData) return const SizedBox(height: 120, child: LoadingView());
            final data = snapshot.data!;
            final reason = aiFallbackReason(l, data.aiError);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(data.firstStep, style: Theme.of(context).textTheme.bodyLarge),
                if (reason != null) ...[const SizedBox(height: Space.md), Text(reason, style: Theme.of(context).textTheme.bodySmall)],
              ],
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionClose))],
    ),
  );
}

/// "Break this task down": creates a suggestion and opens it for review.
Future<void> breakDownTask(BuildContext context, WidgetRef ref, String taskId) async {
  final repo = ref.read(repositoryProvider);
  final suggestion = await runWithProgress(context, context.l10n.breakingDown, () => repo.breakdownTask(taskId));
  if (suggestion != null && context.mounted) context.push('/suggestions/${suggestion.id}');
}
