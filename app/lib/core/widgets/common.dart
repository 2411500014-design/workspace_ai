import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../l10n.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// True when the OS asks for less motion; every animation here checks it.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Centers content with a readable width and consistent padding.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh, this.maxWidth = kMaxContentWidth});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.xxxl + Space.xxl),
      children: [
        for (final child in children)
          // Full readable width, so headings line up on the left with the cards.
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
      ],
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// A page title with an optional line of context under it (never a label above it).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: theme.textTheme.headlineMedium)),
                if (subtitle != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A raised surface: hairline border, soft ink-tinted shadow, 16 px corners.
/// With [onTap] it responds to touch with a ripple and a slight press.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.selected = false, this.margin});

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.statusColors;
    final radius = BorderRadius.circular(Radii.lg);
    Widget card = AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.enter,
      decoration: BoxDecoration(
        color: selected ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.05), status.card) : status.card,
        borderRadius: radius,
        border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 1.5 : 1),
        boxShadow: status.cardShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: onTap == null ? child : InkWell(onTap: onTap, child: child),
        ),
      ),
    );
    if (onTap != null) card = Pressable(child: card);
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}

/// Scales its child down a touch while a pointer is pressed on it, so the
/// interface visibly "hears" the tap. Releases as soon as the pointer drags away.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.985});

  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Offset? _origin;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return Listener(
      onPointerDown: (e) {
        _origin = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_origin != null && (e.position - _origin!).distance > 8) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(scale: _down ? widget.scale : 1, duration: Motion.press, curve: Motion.enter, child: widget.child),
    );
  }
}

/// Fades and lifts its child into place once, when it first appears.
/// Used for the few moments worth marking: the day's focus and the welcome screen.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 12});

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: Motion.reveal);
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Motion.enter);
  bool _started = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, (1 - _curve.value) * widget.offset), child: child),
      ),
    );
  }
}

/// The Purnara mark: a P whose bowl is a closed ring, for *purna*, "complete".
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.appTitle,
      image: true,
      child: CustomPaint(size: Size.square(size), painter: const BrandMarkPainter()),
    );
  }
}

/// Draws the mark in a 100-unit box, scaled to the canvas. The logo keeps its
/// colours in both themes. tool/make_icons.py draws the same geometry for every
/// platform icon and web/favicon.svg; keep the three in step.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter();

  static const Color top = Color(0xFF128C82);
  static const Color bottom = Color(0xFF0B5C56);

  /// A superellipse (exponent 5): the continuous corners of platform icon shapes.
  static Path tile(Size size) {
    const n = 5.0;
    const steps = 160;
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = 2 * math.pi * i / steps;
      final c = math.cos(t);
      final s = math.sin(t);
      final x = r + r * c.sign * math.pow(c.abs(), 2 / n);
      final y = r + r * s.sign * math.pow(s.abs(), 2 / n);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final rect = Offset.zero & size;
    canvas.drawPath(
      tile(size),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(rect),
    );
    // The ring is a stroke, so the counter stays open where it overlaps the stem.
    final contact = Paint()
      ..color = const Color(0x59032623)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.1 * s);
    final ink = Paint()..color = Colors.white;
    void mark(Paint paint, Offset offset) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.drawRRect(RRect.fromLTRBR(27.25 * s, 22 * s, 38.25 * s, 78 * s, Radius.circular(5.5 * s)), paint);
      canvas.drawCircle(
        Offset(52.25 * s, 42.5 * s),
        15 * s,
        Paint()
          ..color = paint.color
          ..maskFilter = paint.maskFilter
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11 * s,
      );
      canvas.restore();
    }

    if (size.width >= 28) mark(contact, Offset(0, 1.0 * s)); // a soft contact shadow where it is visible
    mark(ink, Offset.zero);
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) => false;
}

/// A short wait with a reason, e.g. "Building your plan…". For page loads use
/// [PageSkeleton] instead, which shows the shape of what is coming.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, strokeCap: StrokeCap.round)),
            const SizedBox(height: Space.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message ?? context.l10n.loading,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder in the shape of a page: a title and a few cards, gently pulsing.
/// It appears only if loading takes longer than a blink, so fast loads never flash.
class PageSkeleton extends StatefulWidget {
  const PageSkeleton({super.key, this.inline = false, this.cards = 3});

  /// Inside a page that already scrolls: only the cards, no title, no scrolling.
  final bool inline;
  final int cards;

  @override
  State<PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<PageSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final block = scheme.surfaceContainerHighest;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: block, borderRadius: BorderRadius.circular(Radii.sm)),
      ),
    );
    Widget card(double height, List<double> lines) => Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: AppCard(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, w) in lines.indexed) ...[if (i > 0) const SizedBox(height: Space.sm + 2), bar(w, i == 0 ? 16 : 12)],
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: context.l10n.loading,
      liveRegion: true,
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 160),
        offset: 0,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.5).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: ExcludeSemantics(
            child: widget.inline
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.cards; i++) card(i == 0 ? 104 : 88, i.isEven ? const [0.6, 0.4] : const [0.5, 0.7]),
                    ],
                  )
                : PageBody(
                    children: [
                      bar(0.42, 28),
                      const SizedBox(height: Space.sm),
                      bar(0.26, 14),
                      const SizedBox(height: Space.xl),
                      for (var i = 0; i < widget.cards; i++) card(i == 0 ? 118 : 104, i == 0 ? const [0.55, 0.8, 0.4] : const [0.7, 0.45]),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A progress bar that glides to a new value, so finishing a task is visible.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 6});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1).toDouble()),
      duration: reduceMotion(context) ? Duration.zero : Motion.reveal,
      curve: Motion.enter,
      builder: (context, v, _) =>
          LinearProgressIndicator(value: v, color: color, minHeight: height, borderRadius: BorderRadius.circular(Radii.pill)),
    );
  }
}

/// A round, softly tinted badge that holds the icon of an empty or error state.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.foreground, required this.background});

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, size: 26, color: foreground),
  );
}

class ErrorView extends ConsumerWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(
                icon: Icons.cloud_off_outlined,
                foreground: theme.colorScheme.onSurfaceVariant,
                background: theme.colorScheme.surfaceContainerHigh,
              ),
              const SizedBox(height: Space.lg),
              Text(
                errorMessage(context, error, serverUrl: ref.watch(apiBaseUrlProvider)),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: Space.xl),
                FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 20), label: Text(context.l10n.actionRetry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxl, horizontal: Space.lg),
      child: Column(
        children: [
          _IconBadge(
            icon: icon,
            foreground: theme.colorScheme.primary,
            background: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ),
          const SizedBox(height: Space.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          if (action != null) ...[const SizedBox(height: Space.xl), action!],
        ],
      ),
    );
  }
}

/// Renders an [AsyncValue] with the shared loading and error states.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, this.onRetry, this.loading});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// What to show while loading; a page skeleton by default.
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) when !value.hasValue => ErrorView(error: error, onRetry: onRetry),
      _ when value.hasValue => data(value.requireValue),
      _ => loading ?? const PageSkeleton(),
    };
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.trailing, required this.child, this.padding});

  final String? title;
  final Widget? trailing;
  final Widget child;

  /// Padding around [child]. Lists pass zero sides so their tiles reach the edges;
  /// the title keeps its own inset either way.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final content = padding ?? const EdgeInsets.all(Space.lg);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(header: true, child: Text(title!, style: Theme.of(context).textTheme.titleMedium)),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            Padding(
              padding: title == null ? content : content.copyWith(top: Space.md),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small label with icon and text; colour is never the only signal.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.icon, required this.foreground, required this.background});

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.fromLTRB(Space.sm, 3, Space.sm + 2, 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class HealthPill extends StatelessWidget {
  const HealthPill({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = healthColors(context, status);
    return StatusPill(label: healthLabel(context.l10n, status), icon: healthIcon(status), foreground: fg, background: bg);
  }
}

class CriticalPill extends StatelessWidget {
  const CriticalPill({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StatusPill(
      label: context.l10n.criticalBadge,
      icon: Icons.bolt_outlined,
      foreground: scheme.onTertiaryContainer,
      background: scheme.tertiaryContainer,
    );
  }
}

class LatePill extends StatelessWidget {
  const LatePill({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StatusPill(
      label: context.l10n.lateBadge(days),
      icon: Icons.schedule_outlined,
      foreground: scheme.onErrorContainer,
      background: scheme.errorContainer,
    );
  }
}

/// Says where a proposal came from (master plan §12: AI proposals are clearly labelled).
class SourceLabel extends StatelessWidget {
  const SourceLabel({super.key, required this.aiUsed, this.scheduler = false, this.template = false});

  /// Label for a suggestion, from its kind: plans come from a template, re-plans from
  /// the scheduler, everything else from rules over the user's own text.
  factory SourceLabel.forSuggestion(String kind, {required bool aiUsed}) =>
      SourceLabel(aiUsed: aiUsed, scheduler: kind == 'replan', template: kind == 'plan');

  final bool aiUsed;
  final bool scheduler;
  final bool template;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = aiUsed
        ? l.aiLabel
        : scheduler
        ? l.schedulerLabel
        : template
        ? l.templateLabel
        : l.basicLabel;
    return StatusPill(
      label: label,
      icon: aiUsed ? Icons.auto_awesome_outlined : Icons.rule_outlined,
      foreground: scheme.onSecondaryContainer,
      background: scheme.secondaryContainer,
    );
  }
}

/// A gentle note, e.g. why the non-AI version was used.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.action,
    this.tone = BannerTone.info,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Widget? action;
  final BannerTone tone;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.statusColors;
    final (fg, bg) = switch (tone) {
      BannerTone.warning => (status.onWarningContainer, status.warningContainer),
      BannerTone.info => (scheme.onSecondaryContainer, scheme.secondaryContainer),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          Space.md + 2,
          Space.sm + 2,
          onDismiss == null && action == null ? Space.md + 2 : Space.xs,
          Space.sm + 2,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.md)),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg)),
            ),
            if (action != null) ...[const SizedBox(width: Space.sm), action!],
            if (onDismiss != null)
              IconButton(
                tooltip: context.l10n.actionClose,
                onPressed: onDismiss,
                icon: Icon(Icons.close, size: 18, color: fg),
              ),
          ],
        ),
      ),
    );
  }
}

enum BannerTone { info, warning }

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(BuildContext context, {required String message, required String confirmLabel, bool destructive = false}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Text(message)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.actionCancel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
