/// Layout dimensions and spacing constants strictly adhering to Stitch specifications.
class AppDimensions {
  AppDimensions._();

  /// Height of the custom desktop title command bar.
  static const double titleBarHeight = 36.0;

  /// Height of the ribbon tab navigation bar.
  static const double ribbonTabHeight = 32.0;

  /// Height of the expanded ribbon action panel.
  static const double ribbonActionHeight = 56.0;

  /// Total expanded ribbon height (32 + 56 = 88px).
  static const double ribbonExpandedHeight = 88.0;

  /// Total collapsed ribbon height (tabs only = 32px).
  static const double ribbonCollapsedHeight = 32.0;

  /// Height of the formula input bar.
  static const double formulaBarHeight = 28.0;

  /// Width of the cell coordinate Name Box.
  static const double nameBoxWidth = 64.0;

  /// Width of the `fx` helper button.
  static const double fxButtonWidth = 28.0;

  /// Height of the bottom sheet tab strip.
  static const double sheetTabStripHeight = 28.0;

  /// Height of the status bar docked at bottom edge.
  static const double statusBarHeight = 22.0;

  /// Height of the column header strip (A, B, C...).
  static const double columnHeaderHeight = 24.0;

  /// Width of the row header strip (1, 2, 3...).
  static const double rowHeaderWidth = 42.0;

  /// Width of the left vertical tool dock rail.
  static const double leftToolDockWidth = 48.0;

  /// Default cell width.
  static const double defaultCellWidth = 80.0;

  /// Default cell height.
  static const double defaultCellHeight = 20.0;

  /// Minimum column width allowed during resize.
  static const double minColumnWidth = 24.0;

  /// Minimum row height allowed during resize.
  static const double minRowHeight = 16.0;

  /// Size of the autofill handle at bottom-right of selection ring.
  static const double autofillHandleSize = 5.0;
}
