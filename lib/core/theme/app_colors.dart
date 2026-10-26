import 'package:flutter/material.dart';

/// Design system color tokens for Grid Sheet matching Stitch specifications.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Light Theme: "Grid Professional"
  // ---------------------------------------------------------------------------
  /// Core corporate green for app bar header, brand accents, active toggles.
  static const Color primary = Color(0xFF217346);

  /// Active button backgrounds, sheet active indicators, focus bounding box.
  static const Color primaryContainer = Color(0xFF107C41);

  /// High-contrast pressed state and formula keywords.
  static const Color deepGreen = Color(0xFF185C37);

  /// Alternative high-contrast green.
  static const Color brandAlternate = Color(0xFF006130);

  /// Soft green fill for selected cell ranges and headers.
  static const Color selectionFill = Color(0xFFE2F0D9);

  /// Pure data grid background, formula input field, active sheet backing.
  static const Color canvasWhite = Color(0xFFFFFFFF);

  /// Recessed chrome: toolbars, formula bar backing, status bar, panel docks.
  static const Color recessedChrome = Color(0xFFF5F7F6);

  /// Hover state on grid cells and active worksheet tab background.
  static const Color paleGreenTint = Color(0xFFF0F7F2);

  /// Crisp 1px non-intrusive cell gridline border.
  static const Color gridline = Color(0xFFE3E7E4);

  /// Divider outlines, panel boundaries, formula bar border.
  static const Color neutralBorder = Color(0xFFD9E1DC);

  /// Primary high-contrast body text, formula text, figures.
  static const Color textPrimary = Color(0xFF202124);

  /// Secondary text for headers, inactive controls, status text, units.
  static const Color textSecondary = Color(0xFF5F6B63);

  /// Error color for formula errors (#REF!, #DIV/0!).
  static const Color errorRed = Color(0xFFC62828);

  /// Warning color for circular references and alerts.
  static const Color alertAmber = Color(0xFFB7791F);

  // ---------------------------------------------------------------------------
  // Dark Theme: "Graphite & Mint"
  // ---------------------------------------------------------------------------
  static const Color darkSurface = Color(0xFF101412);
  static const Color darkSurfaceLow = Color(0xFF181C1A);
  static const Color darkSurfaceContainer = Color(0xFF1C201E);
  static const Color darkSurfaceHigh = Color(0xFF272B29);
  static const Color mintPrimary = Color(0xFF4EDEA3);
  static const Color mintContainer = Color(0xFF10B981);
  static const Color darkGridline = Color(0xFF3C4A42);
  static const Color darkTextPrimary = Color(0xFFE0E3DF);
  static const Color darkTextSecondary = Color(0xFFBBCAAF);
}
