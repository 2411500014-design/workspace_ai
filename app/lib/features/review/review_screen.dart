import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// Weekly review: what got done, what slipped, and next week's focus
/// (master plan §12). The numbers come from the plan; AI only writes the summary.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final project = ref.watch(currentProjectProvider);
    if (project == null) return Scaffold(appBar: AppBar(), body: const PageSkeleton());
    return Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)),
      body: AsyncBody(
        value: ref.watch(weeklyReviewProvider(project.id)),
        onRetry: () => ref.invalidate(weeklyReviewProvider(project.id)),
        data: (review) => PageBody(
          maxWidth: kReadingWidth,
          onRefresh: () async => ref.invalidate(weeklyReviewProvider(project.id)),
          children: [
            Row(
              children: [
                Expanded(child: Text(l.reviewHealthNow, style: theme.textTheme.titleMedium)),
                HealthPill(status: review.healthNow),
              ],
            ),
            const SizedBox(height: Space.lg),
            if (review.summary != null && review.summary!.isNotEmpty)
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SourceLabel(aiUsed: review.aiUsed),
                    const SizedBox(height: Space.md),
                    Text(review.summary!, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            if (review.recommendReplan)
              InfoBanner(
                tone: BannerTone.warning,
                icon: Icons.tune,
                message: l.reviewRecommendReplan,
                action: TextButton(onPressed: () => context.push('/replan'), child: Text(l.adjustPlan)),
              ),
            SectionCard(
              title: l.reviewDone(review.done.length),
              trailing: review.doneHours > 0 ? Text(l.hoursValue(formatHours(review.doneHours)), style: theme.textTheme.labelLarge) : null,
              child: review.done.isEmpty
                  ? Text(l.reviewNothingDone, style: theme.textTheme.bodyMedium)
                  : _TaskList(tasks: review.done, icon: Icons.check_circle_outline),
            ),
            if (review.slipped.isNotEmpty)
              SectionCard(
                title: l.reviewSlipped,
                child: _TaskList(tasks: review.slipped, icon: Icons.schedule_outlined, showLate: true),
              ),
            if (review.focusNext.isNotEmpty)
              SectionCard(
                title: l.reviewNextFocus,
                child: _TaskList(tasks: review.focusNext, icon: Icons.arrow_forward),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.icon, this.showLate = false});

  final List<TaskBrief> tasks;
  final IconData icon;
  final bool showLate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final t in tasks)
          InkWell(
            onTap: () => context.push('/tasks/${t.id}'),
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(t.title, style: theme.textTheme.bodyMedium)),
                  if (showLate && t.lateDays > 0) LatePill(days: t.lateDays),
                  if (!showLate && t.scheduledEnd != null) Text(formatDate(context, t.scheduledEnd!), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
