import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

const String kFontFamily = 'PlusJakartaSans';

/// Colours and depth that Material's ColorScheme has no slot for.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.card,
    required this.cardShadows,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  factory StatusColors.from(Palette p) => StatusColors(
    card: p.card,
    cardShadows: p.cardShadows,
    success: p.success,
    successContainer: p.successContainer,
    onSuccessContainer: p.onSuccessContainer,
    warning: p.warning,
    warningContainer: p.warningContainer,
    onWarningContainer: p.onWarningContainer,
  );

  final Color card;
  final List<BoxShadow> cardShadows;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      card: Color.lerp(card, other.card, t)!,
      cardShadows: t < 0.5 ? cardShadows : other.cardShadows,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
    );
  }
}

extension StatusColorsX on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>()!;
}

/// Type scale from the master plan (§12): 12, 14, 16, 20, 24, 32. Nothing below 12.
/// Headings tighten slightly as they grow; small data text uses tabular figures so
/// dates and hours line up.
TextTheme _textTheme(Color color, Color muted) {
  const tabular = [FontFeature.tabularFigures()];
  TextStyle style(double size, FontWeight weight, {double height = 1.45, double tracking = 0, bool data = false, Color? tint}) => TextStyle(
    fontFamily: kFontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: tint ?? color,
    letterSpacing: tracking,
    fontFeatures: data ? tabular : null,
  );
  return TextTheme(
    displayLarge: style(32, FontWeight.w700, height: 1.15, tracking: -0.8),
    displayMedium: style(32, FontWeight.w700, height: 1.15, tracking: -0.8),
    displaySmall: style(32, FontWeight.w700, height: 1.15, tracking: -0.8),
    headlineLarge: style(32, FontWeight.w700, height: 1.2, tracking: -0.8),
    headlineMedium: style(24, FontWeight.w700, height: 1.25, tracking: -0.5),
    headlineSmall: style(24, FontWeight.w600, height: 1.3, tracking: -0.4),
    titleLarge: style(20, FontWeight.w600, height: 1.35, tracking: -0.25),
    titleMedium: style(16, FontWeight.w600, height: 1.4, tracking: -0.1),
    titleSmall: style(14, FontWeight.w600, height: 1.4),
    bodyLarge: style(16, FontWeight.w400, height: 1.55),
    bodyMedium: style(14, FontWeight.w400, height: 1.5),
    bodySmall: style(12, FontWeight.w500, height: 1.45, data: true, tint: muted),
    labelLarge: style(14, FontWeight.w600, height: 1.3),
    labelMedium: style(12, FontWeight.w600, height: 1.3, data: true),
    labelSmall: style(12, FontWeight.w500, height: 1.3, data: true),
  );
}

/// Pages arrive with a short fade and rise; they leave the way they came.
class _PurnaraPageTransitions extends PageTransitionsBuilder {
  const _PurnaraPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final enter = CurvedAnimation(parent: animation, curve: Motion.enter, reverseCurve: Motion.enter.flipped);
    // The page underneath recedes a little, so the new one reads as "on top".
    final behind = CurvedAnimation(parent: secondaryAnimation, curve: Motion.enter, reverseCurve: Motion.enter.flipped);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(behind),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(enter),
          child: child,
        ),
      ),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final palette = brightness == Brightness.light ? lightPalette : darkPalette;
  final scheme = palette.scheme;
  final text = _textTheme(scheme.onSurface, scheme.onSurfaceVariant);
  final control = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));
  const minButton = Size(64, 48);
  const buttonPadding = EdgeInsets.symmetric(horizontal: Space.xl - 2);
  OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    borderSide: BorderSide(color: color, width: width),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: kFontFamily,
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    hoverColor: scheme.onSurface.withValues(alpha: 0.04),
    focusColor: scheme.primary.withValues(alpha: 0.12),
    highlightColor: scheme.onSurface.withValues(alpha: 0.04),
    extensions: [StatusColors.from(palette)],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _PurnaraPageTransitions(),
        TargetPlatform.iOS: _PurnaraPageTransitions(),
        TargetPlatform.macOS: _PurnaraPageTransitions(),
        TargetPlatform.windows: _PurnaraPageTransitions(),
        TargetPlatform.linux: _PurnaraPageTransitions(),
        TargetPlatform.fuchsia: _PurnaraPageTransitions(),
      },
    ),
    // The browser's defaults for these belong to no design system.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.22),
      selectionHandleColor: scheme.primary,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) ? 8 : 5),
      radius: const Radius.circular(Radii.pill),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => scheme.onSurfaceVariant.withValues(alpha: s.contains(WidgetState.hovered) || s.contains(WidgetState.dragged) ? 0.5 : 0.28),
      ),
      crossAxisMargin: 2,
      mainAxisMargin: 4,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: Space.lg,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: palette.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        padding: buttonPadding,
        shape: control,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        padding: buttonPadding,
        shape: control,
        textStyle: text.labelLarge,
        foregroundColor: scheme.onSurface,
        backgroundColor: palette.card,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minButton,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        shape: control,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: scheme.onSurfaceVariant),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 1,
      extendedTextStyle: text.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
        shape: WidgetStatePropertyAll(control),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline.withValues(alpha: 0.45))),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primaryContainer : palette.card),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: scheme.outline, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.outline),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : scheme.outline),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 14),
      border: inputBorder(scheme.outline),
      enabledBorder: inputBorder(scheme.outline.withValues(alpha: 0.7)),
      focusedBorder: inputBorder(scheme.primary, 2),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 2),
      labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      floatingLabelStyle: text.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
      hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      helperStyle: text.bodySmall,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
      height: 68,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium?.copyWith(
          color: s.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: text.labelLarge?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      indicatorColor: scheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: scheme.outlineVariant,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
      labelStyle: text.labelMedium,
      side: BorderSide(color: scheme.outlineVariant),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
      minVerticalPadding: Space.sm,
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: text.bodySmall,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      collapsedIconColor: scheme.onSurfaceVariant,
      tilePadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      elevation: 3,
      width: 440,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: scheme.shadow.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg + 4)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyLarge,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg + 4)),
      headerHeadlineStyle: text.headlineMedium,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.card,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: scheme.shadow.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      textStyle: text.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: scheme.outline.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg + 4))),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: Colors.transparent,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(Radii.sm)),
      textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      padding: const EdgeInsets.symmetric(horizontal: Space.sm + 2, vertical: 6),
    ),
    badgeTheme: BadgeThemeData(backgroundColor: scheme.tertiary, textColor: scheme.onTertiary),
  );
}
