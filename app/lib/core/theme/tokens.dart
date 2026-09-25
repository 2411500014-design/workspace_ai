import 'package:material_ui/material_ui.dart';

/// Design tokens. The source is design-system/purnara/MASTER.md, refined on
/// 2026-09-25 (see its "Implemented system" section): quiet cool neutrals with a
/// single teal accent, so the accent always means "act here" or "this is yours".
///
/// Filled controls use teal-700 (#0F766E): white text on it is 5.5:1 (WCAG AA).
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// One radius system: controls 12, cards 16, status pills fully round.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Motion follows one rule set: fast ease-out for anything that responds to the
/// user, nothing that makes them wait, and no movement when the OS asks for less.
abstract final class Motion {
  static const Duration press = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration page = Duration(milliseconds: 280);
  static const Duration reveal = Duration(milliseconds: 420);

  /// Strong ease-out: starts immediately, settles softly.
  static const Curve enter = Cubic(0.23, 1, 0.32, 1);

  /// For things that move while staying on screen.
  static const Curve move = Cubic(0.77, 0, 0.175, 1);

  /// Delay between items that enter together.
  static const Duration stagger = Duration(milliseconds: 55);
}

/// Readable line length on wide screens.
const double kMaxContentWidth = 960;

/// Narrower column for focused, mostly single-column screens (Today, forms, details).
const double kReadingWidth = 760;

/// Breakpoint between the bottom navigation bar and the navigation rail.
const double kRailBreakpoint = 840;

class Palette {
  const Palette({
    required this.scheme,
    required this.card,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.cardShadows,
  });

  final ColorScheme scheme;

  /// Raised surfaces (cards, sheets, dialogs): white in light mode, one step
  /// lighter than the page in dark mode.
  final Color card;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Depth for cards: a hairline border does the separating; the shadow only
  /// lifts, tinted with the ink colour so it never reads as grey. None in dark
  /// mode, where lighter surfaces carry the elevation.
  final List<BoxShadow> cardShadows;
}

const Palette lightPalette = Palette(
  scheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0F766E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7F1EC),
    onPrimaryContainer: Color(0xFF0B4A45),
    secondary: Color(0xFF0D9488),
    onSecondary: Color(0xFF042F2E),
    secondaryContainer: Color(0xFFEAF2F0),
    onSecondaryContainer: Color(0xFF1E3D3A),
    tertiary: Color(0xFFC2410C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFDECDF),
    onTertiaryContainer: Color(0xFF7C2D12),
    error: Color(0xFFB91C1C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFDE8E8),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFF6F8F7),
    onSurface: Color(0xFF0F1B1A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFBFCFC),
    surfaceContainer: Color(0xFFF0F3F2),
    surfaceContainerHigh: Color(0xFFE9EEEC),
    surfaceContainerHighest: Color(0xFFE1E7E5),
    onSurfaceVariant: Color(0xFF53625F),
    outline: Color(0xFF7F8C89),
    outlineVariant: Color(0xFFE2E8E6),
    inverseSurface: Color(0xFF1A2624),
    onInverseSurface: Color(0xFFF2F5F4),
    inversePrimary: Color(0xFF6FDCCB),
    shadow: Color(0xFF0B2E2A),
    scrim: Color(0xFF0B1413),
    surfaceTint: Color(0x00000000),
  ),
  card: Color(0xFFFFFFFF),
  success: Color(0xFF15803D),
  successContainer: Color(0xFFE2F6E8),
  onSuccessContainer: Color(0xFF14532D),
  warning: Color(0xFFB45309),
  warningContainer: Color(0xFFFDF1D6),
  onWarningContainer: Color(0xFF713F12),
  cardShadows: [
    BoxShadow(color: Color(0x0A0B2E2A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D0B2E2A), blurRadius: 18, offset: Offset(0, 6)),
  ],
);

const Palette darkPalette = Palette(
  scheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4FC7B5),
    onPrimary: Color(0xFF032A26),
    primaryContainer: Color(0xFF15403B),
    onPrimaryContainer: Color(0xFFC9F1E9),
    secondary: Color(0xFF6ED6C6),
    onSecondary: Color(0xFF032A26),
    secondaryContainer: Color(0xFF1A2A28),
    onSecondaryContainer: Color(0xFFCFE6E1),
    tertiary: Color(0xFFF59E5B),
    onTertiary: Color(0xFF3B1506),
    tertiaryContainer: Color(0xFF45240F),
    onTertiaryContainer: Color(0xFFFFDAC2),
    error: Color(0xFFF28B8B),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF4A1C1C),
    onErrorContainer: Color(0xFFFECACA),
    surface: Color(0xFF0C1110),
    onSurface: Color(0xFFE8EEED),
    surfaceContainerLowest: Color(0xFF080C0B),
    surfaceContainerLow: Color(0xFF131A19),
    surfaceContainer: Color(0xFF172020),
    surfaceContainerHigh: Color(0xFF1C2625),
    surfaceContainerHighest: Color(0xFF232E2D),
    onSurfaceVariant: Color(0xFF9DABA8),
    outline: Color(0xFF6F7D7A),
    outlineVariant: Color(0xFF243030),
    inverseSurface: Color(0xFFE8EEED),
    onInverseSurface: Color(0xFF0C1110),
    inversePrimary: Color(0xFF0F766E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  ),
  card: Color(0xFF131A19),
  success: Color(0xFF5FD18B),
  successContainer: Color(0xFF15361F),
  onSuccessContainer: Color(0xFFC6F0D5),
  warning: Color(0xFFF2C14E),
  warningContainer: Color(0xFF3B2C0E),
  onWarningContainer: Color(0xFFFCE7B0),
  cardShadows: [],
);
