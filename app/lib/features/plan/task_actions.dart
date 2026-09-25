import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/providers.dart';

/// One-tap progress update (master plan §12), with undo.
Future<void> setTaskDone(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String taskId,
  required bool done,
}) async {
  final repo = ref.read(repositoryProvider);
  final l = context.l10n;
  try {
    await repo.updateTask(taskId, {'status': done ? 'done' : 'todo'});
    refreshProject(ref, projectId);
    if (!context.mounted || !done) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.markedDone),
          action: SnackBarAction(
            label: l.actionUndo,
            onPressed: () async {
              await repo.updateTask(taskId, {'status': 'todo'});
              refreshProject(ref, projectId);
            },
          ),
        ),
      );
  } catch (e) {
    if (context.mounted) showMessage(context, errorMessage(context, e));
  }
}

/// "Help me start": a first step of about 25 minutes (master plan §12).
Future<void> showStartHelp(BuildContext context, WidgetRef ref, String taskId) async {
  final l = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.timer_outlined),
      title: Text(l.firstStepTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: FutureBuilder(
          future: ref.read(repositoryProvider).startHelp(taskId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text(errorMessage(context, snapshot.error!));
            if (!snapshot.hasData) return const SizedBox(height: 120, child: LoadingView());
            final help = snapshot.data!;
            final reason = aiFallbackReason(l, help.aiError);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(help.firstStep, style: Theme.of(context).textTheme.bodyLarge),
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
  try {
    final suggestion = await ref.read(repositoryProvider).breakdownTask(taskId);
    if (context.mounted) context.push('/suggestions/${suggestion.id}');
  } catch (e) {
    if (context.mounted) showMessage(context, errorMessage(context, e));
  }
}
