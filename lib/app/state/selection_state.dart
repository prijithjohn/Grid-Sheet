import '../../domain/domain.dart';

/// The active mode of a selection in the grid.
enum SelectionMode {
  /// A single active cell.
  cell,

  /// A rectangular contiguous range of cells.
  range,

  /// One or more complete rows selected.
  entireRow,

  /// One or more complete columns selected.
  entireColumn,

  /// The entire worksheet selected (e.g. via top-left corner click).
  entireSheet,
}

/// Represents the selection state within a worksheet grid.
///
/// Immutable data model containing:
/// - The cursor anchor cell ([primaryCell]).
/// - The primary active bounding range ([activeRange]).
/// - Optional disjoint secondary ranges ([secondaryRanges]) for multi-selection.
/// - The current [SelectionMode].
class SelectionState {
  /// Creates a [SelectionState].
  const SelectionState({
    required this.primaryCell,
    required this.activeRange,
    this.secondaryRanges = const [],
    this.mode = SelectionMode.cell,
  });

  /// Initial default selection positioned at cell `A1` (0, 0).
  static const SelectionState initial = SelectionState(
    primaryCell: CellCoordinate(0, 0),
    activeRange: CellRange.normalized(
      start: CellCoordinate(0, 0),
      end: CellCoordinate(0, 0),
      topRow: 0,
      bottomRow: 0,
      leftCol: 0,
      rightCol: 0,
    ),
    secondaryRanges: [],
    mode: SelectionMode.cell,
  );

  /// Creates a single cell selection targeting [coordinate].
  factory SelectionState.fromCell(CellCoordinate coordinate) {
    return SelectionState(
      primaryCell: coordinate,
      activeRange: CellRange(coordinate, coordinate),
      secondaryRanges: const [],
      mode: SelectionMode.cell,
    );
  }

  /// Creates a range selection targeting [range] with an optional [primaryCell].
  factory SelectionState.fromRange(
    CellRange range, {
    CellCoordinate? primaryCell,
  }) {
    return SelectionState(
      primaryCell: primaryCell ?? range.start,
      activeRange: range,
      secondaryRanges: const [],
      mode: range.isSingleCell ? SelectionMode.cell : SelectionMode.range,
    );
  }

  /// The anchor cell coordinate where the cursor currently rests.
  final CellCoordinate primaryCell;

  /// The primary contiguous selection envelope.
  final CellRange activeRange;

  /// Disjoint secondary ranges selected via Ctrl-click/drag.
  final List<CellRange> secondaryRanges;

  /// The active selection mode.
  final SelectionMode mode;

  /// Whether the selection spans only a single cell.
  bool get isSingleCell =>
      mode == SelectionMode.cell &&
      activeRange.isSingleCell &&
      secondaryRanges.isEmpty;

  /// Total count of cells encompassed by this selection.
  int get selectedCellCount {
    var count = activeRange.cellCount;
    for (final sec in secondaryRanges) {
      count += sec.cellCount;
    }
    return count;
  }

  /// Checks if [coordinate] is contained within the primary range or any secondary ranges.
  bool contains(CellCoordinate coordinate) {
    if (activeRange.contains(coordinate)) return true;
    for (final sec in secondaryRanges) {
      if (sec.contains(coordinate)) return true;
    }
    return false;
  }

  /// Returns a new [SelectionState] selecting a single [coordinate].
  SelectionState selectCell(CellCoordinate coordinate) {
    return SelectionState.fromCell(coordinate);
  }

  /// Returns a new [SelectionState] with the primary range extended from [primaryCell] to [toCoordinate].
  SelectionState extendSelection(CellCoordinate toCoordinate) {
    // Build the bounding range; normalize to top-left:bottom-right so that
    // activeRange.a1 always returns the canonical A1 form (e.g. "D4:F6").
    final rawRange = CellRange(primaryCell, toCoordinate);
    final normalizedRange = CellRange(
      CellCoordinate(rawRange.topRow, rawRange.leftCol),
      CellCoordinate(rawRange.bottomRow, rawRange.rightCol),
    );
    return SelectionState(
      primaryCell: primaryCell,
      activeRange: normalizedRange,
      secondaryRanges: secondaryRanges,
      mode: normalizedRange.isSingleCell
          ? SelectionMode.cell
          : SelectionMode.range,
    );
  }

  /// Returns a new [SelectionState] selecting an entire row from column 0 to [CellCoordinate.maxCols] - 1.
  SelectionState selectEntireRow(int row) {
    final start = CellCoordinate(row, 0);
    final end = CellCoordinate(row, CellCoordinate.maxCols - 1);
    return SelectionState(
      primaryCell: start,
      activeRange: CellRange(start, end),
      secondaryRanges: const [],
      mode: SelectionMode.entireRow,
    );
  }

  /// Returns a new [SelectionState] selecting an entire column from row 0 to [CellCoordinate.maxRows] - 1.
  SelectionState selectEntireColumn(int col) {
    final start = CellCoordinate(0, col);
    final end = CellCoordinate(CellCoordinate.maxRows - 1, col);
    return SelectionState(
      primaryCell: start,
      activeRange: CellRange(start, end),
      secondaryRanges: const [],
      mode: SelectionMode.entireColumn,
    );
  }

  /// Returns a new [SelectionState] selecting the entire worksheet canvas.
  SelectionState selectAll() {
    const start = CellCoordinate(0, 0);
    const end = CellCoordinate(
      CellCoordinate.maxRows - 1,
      CellCoordinate.maxCols - 1,
    );
    return const SelectionState(
      primaryCell: start,
      activeRange: CellRange.normalized(
        start: start,
        end: end,
        topRow: 0,
        bottomRow: CellCoordinate.maxRows - 1,
        leftCol: 0,
        rightCol: CellCoordinate.maxCols - 1,
      ),
      secondaryRanges: [],
      mode: SelectionMode.entireSheet,
    );
  }

  /// Returns a new [SelectionState] with an additional disjoint [range] appended.
  SelectionState addSecondaryRange(CellRange range) {
    return SelectionState(
      primaryCell: primaryCell,
      activeRange: activeRange,
      secondaryRanges: [...secondaryRanges, range],
      mode: SelectionMode.range,
    );
  }

  /// Creates a copy with optional parameter overrides.
  SelectionState copyWith({
    CellCoordinate? primaryCell,
    CellRange? activeRange,
    List<CellRange>? secondaryRanges,
    SelectionMode? mode,
  }) {
    return SelectionState(
      primaryCell: primaryCell ?? this.primaryCell,
      activeRange: activeRange ?? this.activeRange,
      secondaryRanges: secondaryRanges ?? this.secondaryRanges,
      mode: mode ?? this.mode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionState &&
          runtimeType == other.runtimeType &&
          primaryCell == other.primaryCell &&
          activeRange == other.activeRange &&
          mode == other.mode &&
          _areListsEqual(secondaryRanges, other.secondaryRanges);

  @override
  int get hashCode => Object.hash(
    primaryCell,
    activeRange,
    mode,
    Object.hashAll(secondaryRanges),
  );

  @override
  String toString() =>
      'SelectionState(primary: ${primaryCell.a1}, range: ${activeRange.a1}, mode: $mode, secondaries: ${secondaryRanges.length})';

  static bool _areListsEqual(List<CellRange> a, List<CellRange> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
