import '../../../domain/domain.dart';
import '../models/sort_options.dart';

/// Single row record holding its original index and row slice of cells.
class _RowEntry {
  final int originalRow;
  final List<Cell?> cells;

  _RowEntry({required this.originalRow, required this.cells});
}

/// Algorithmic service that calculates sorted row layouts within a bounding range.
class SortEngine {
  const SortEngine();

  /// Sorts row slices within [options.range] on [worksheet].
  ///
  /// Returns a map of `CellCoordinate -> Cell?` representing the new cell state
  /// for the entire range.
  Map<CellCoordinate, Cell?> sortRange(
    Worksheet worksheet,
    SortOptions options,
  ) {
    final range = options.range;
    final startRow = options.hasHeader ? range.topRow + 1 : range.topRow;
    final endRow = range.bottomRow;

    if (startRow >= endRow) {
      // Nothing to sort (0 or 1 data row)
      return {};
    }

    // 1. Extract row slices
    final rowEntries = <_RowEntry>[];
    for (var r = startRow; r <= endRow; r++) {
      final cells = <Cell?>[];
      for (var c = range.leftCol; c <= range.rightCol; c++) {
        cells.add(worksheet.getCell(CellCoordinate(r, c)));
      }
      rowEntries.add(_RowEntry(originalRow: r, cells: cells));
    }

    // 2. Sort row slices stably
    final sortColOffset = options.sortColumn - range.leftCol;

    rowEntries.sort((a, b) {
      final cellA = (sortColOffset >= 0 && sortColOffset < a.cells.length)
          ? a.cells[sortColOffset]
          : null;
      final cellB = (sortColOffset >= 0 && sortColOffset < b.cells.length)
          ? b.cells[sortColOffset]
          : null;

      final aEmpty = cellA == null || cellA.isEmpty;
      final bEmpty = cellB == null || cellB.isEmpty;

      if (aEmpty && bEmpty) {
        return a.originalRow.compareTo(b.originalRow);
      }
      if (aEmpty) return 1; // blanks always at bottom
      if (bEmpty) return -1; // blanks always at bottom

      final cmp = compareCells(cellA, cellB);
      if (cmp != 0) {
        return options.ascending ? cmp : -cmp;
      }
      // Stable sort tie-breaker: original row index
      return a.originalRow.compareTo(b.originalRow);
    });

    // 3. Map sorted row entries to their destination coordinates
    final resultMap = <CellCoordinate, Cell?>{};

    for (var i = 0; i < rowEntries.length; i++) {
      final targetRow = startRow + i;
      final entry = rowEntries[i];
      final deltaRows = targetRow - entry.originalRow;

      for (var j = 0; j < entry.cells.length; j++) {
        final targetCol = range.leftCol + j;
        final targetCoord = CellCoordinate(targetRow, targetCol);
        final sourceCell = entry.cells[j];

        if (sourceCell == null || sourceCell.isEmpty) {
          resultMap[targetCoord] = null;
        } else {
          // If the cell contains a formula, adjust relative references by row delta
          String rawInput = sourceCell.rawInput;
          if (sourceCell.isFormula && deltaRows != 0) {
            rawInput = FormulaReferenceAdjuster.adjustReferences(
              sourceCell.rawInput,
              deltaRows: deltaRows,
            );
          }

          resultMap[targetCoord] = Cell(
            coordinate: targetCoord,
            rawInput: rawInput,
            computedValue: sourceCell.computedValue,
            style: sourceCell.style,
          );
        }
      }
    }

    return resultMap;
  }

  /// Compares two cells for sorting.
  ///
  /// Standard spreadsheet order:
  /// - Non-empty vs Empty: Empty/Blank ALWAYS sorts to the bottom (returns 1 if a is empty, -1 if b is empty).
  /// - Numbers: compared numerically.
  /// - Booleans: FALSE < TRUE.
  /// - Text: compared case-insensitively.
  /// - Numbers vs Text: Numbers come before Text.
  static int compareCells(Cell? a, Cell? b) {
    final aEmpty = a == null || a.isEmpty;
    final bEmpty = b == null || b.isEmpty;

    if (aEmpty && bEmpty) return 0;
    if (aEmpty) return 1; // blanks to bottom
    if (bEmpty) return -1; // blanks to bottom

    final valA = a.computedValue;
    final valB = b.computedValue;

    // Numbers
    if (valA is NumberCellValue && valB is NumberCellValue) {
      return valA.value.compareTo(valB.value);
    }

    // Number vs Text
    if (valA is NumberCellValue && valB is TextCellValue) {
      return -1;
    }
    if (valA is TextCellValue && valB is NumberCellValue) {
      return 1;
    }

    // Booleans
    if (valA is BooleanCellValue && valB is BooleanCellValue) {
      if (valA.value == valB.value) return 0;
      return valA.value ? 1 : -1;
    }

    // Default to string compare on formatted/display text
    final strA = a.displayValue.toLowerCase();
    final strB = b.displayValue.toLowerCase();
    return strA.compareTo(strB);
  }
}
