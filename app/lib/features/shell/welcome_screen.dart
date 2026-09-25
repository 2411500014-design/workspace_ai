import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';

/// First run: what Purnara does, and one way in. The preview on the side is
/// built from the app's own components, so it shows the product rather than
/// describing it.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(tooltip: l.settingsTitle, icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
          const SizedBox(width: Space.sm),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final copy = _Copy(large: wide);
          const preview = _Preview();
          if (!wide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, Space.xxxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      const SizedBox(height: Space.xxl + Space.sm),
                      preview,
                    ],
                  ),
                ),
              ),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Space.xxxl, vertical: Space.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: copy),
                    const SizedBox(width: Space.xxxl + Space.lg),
                    const Expanded(flex: 6, child: preview),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({required this.large});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final headline = (large ? theme.textTheme.displayLarge : theme.textTheme.headlineLarge)!.copyWith(
      fontSize: large ? 40 : 30,
      height: 1.12,
      letterSpacing: large ? -1.2 : -0.8,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeSlideIn(
          child: Row(
            children: [
              const BrandMark(size: 36),
              const SizedBox(width: Space.md),
              Text(l.appTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        SizedBox(height: large ? Space.xxl + Space.sm : Space.xl),
        FadeSlideIn(
          delay: Motion.stagger,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Semantics(header: true, child: Text(l.onboardingWelcomeTitle, style: headline)),
          ),
        ),
        const SizedBox(height: Space.lg),
        FadeSlideIn(
          delay: Motion.stagger * 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              l.onboardingWelcomeBody,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: large ? 17 : 16),
            ),
          ),
        ),
        SizedBox(height: large ? Space.xxl : Space.xl),
        FadeSlideIn(
          delay: Motion.stagger * 3,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: Space.xl + 4),
            ),
            onPressed: () => context.push('/onboarding'),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text(l.onboardingStart),
          ),
        ),
      ],
    );
  }
}

/// A still life of the Today screen: a project on track and two focus tasks, the
/// first of which ticks itself done shortly after the page opens.
class _Preview extends StatefulWidget {
  const _Preview();

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  bool _done = false;
  bool _scheduled = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (reduceMotion(context)) {
      _done = true;
    } else {
      _timer = Timer(const Duration(milliseconds: 1300), () => setState(() => _done = true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(Space.xl),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                offset: 16,
                child: Text(l.todayTitle, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: Space.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                offset: 16,
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(l.welcomePreviewProject, style: theme.textTheme.titleMedium)),
                            const HealthPill(status: 'on_track'),
                          ],
                        ),
                        const SizedBox(height: Space.sm),
                        Text('${l.daysLeft(96)} · ${l.nextMilestone(l.welcomePreviewMilestone)}', style: theme.textTheme.bodySmall),
                        const SizedBox(height: Space.md),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _done ? 0.38 : 0.31),
                          duration: reduceMotion(context) ? Duration.zero : Motion.reveal,
                          curve: Motion.enter,
                          builder: (context, value, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(value: value, minHeight: 6, borderRadius: BorderRadius.circular(Radii.pill)),
                              const SizedBox(height: Space.xs + 2),
                              Text(
                                l.progressActual('${(value * 100).round()}'),
                                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                offset: 16,
                child: _PreviewTask(title: l.welcomePreviewTask1, meta: l.hoursValue('4'), done: _done),
              ),
              const SizedBox(height: Space.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                offset: 16,
                child: _PreviewTask(title: l.welcomePreviewTask2, meta: l.hoursValue('6'), critical: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewTask extends StatelessWidget {
  const _PreviewTask({required this.title, required this.meta, this.done = false, this.critical = false});

  final String title;
  final String meta;
  final bool done;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.statusColors;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.lg, Space.md),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Motion.normal,
              curve: Motion.enter,
              width: 22,
              height: 22,
              margin: const EdgeInsets.all(Space.xs),
              decoration: BoxDecoration(
                color: done ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: done ? scheme.primary : scheme.outline, width: 1.5),
              ),
              child: AnimatedScale(
                scale: done ? 1 : 0.6,
                duration: Motion.normal,
                curve: Motion.enter,
                child: AnimatedOpacity(
                  opacity: done ? 1 : 0,
                  duration: Motion.fast,
                  child: Icon(Icons.check, size: 16, color: scheme.onPrimary),
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: Motion.normal,
                    style: theme.textTheme.titleSmall!.copyWith(
                      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: scheme.onSurfaceVariant,
                    ),
                    child: Text(title),
                  ),
                  const SizedBox(height: 2),
                  Text(meta, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (critical) ...[
              const SizedBox(width: Space.sm),
              const CriticalPill(),
            ] else
              AnimatedOpacity(
                opacity: done ? 1 : 0,
                duration: Motion.normal,
                child: Icon(Icons.check_circle, size: 20, color: status.success),
              ),
          ],
        ),
      ),
    );
  }
}
