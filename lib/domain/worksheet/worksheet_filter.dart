import '../cell/cell_coordinate.dart';
import '../cell/cell_model.dart';
import '../cell/cell_range.dart';
import '../cell/cell_value.dart';
import 'worksheet_model.dart';

/// Supported numeric comparison operators for filtering.
enum NumericFilterOp {
  lessThan('<'),
  lessThanOrEqual('<='),
  greaterThan('>'),
  greaterThanOrEqual('>='),
  equal('='),
  notEqual('!=');

  final String symbol;
  const NumericFilterOp(this.symbol);
}

/// Filter condition applied to a single column in a filtered table.
class ColumnFilterCriteria {
  const ColumnFilterCriteria({
    this.textContains,
    this.textEquals,
    this.numericOp,
    this.numericValue,
    this.showBlanks = true,
    this.hideBlanks = false,
  });

  /// Substring pattern to match.
  final String? textContains;

  /// Exact text pattern to match.
  final String? textEquals;

  /// Numeric comparison operator.
  final NumericFilterOp? numericOp;

  /// Numeric reference value to compare against.
  final double? numericValue;

  /// Whether blank cells should be shown.
  final bool showBlanks;

  /// Whether blank cells should be explicitly hidden.
  final bool hideBlanks;

  /// Whether this criteria has any active condition configured.
  bool get isActive =>
      textContains != null ||
      textEquals != null ||
      (numericOp != null && numericValue != null) ||
      hideBlanks;

  /// Evaluates whether [cell] satisfies this filter criteria.
  bool matches(Cell? cell) {
    final isBlank = cell == null || cell.isEmpty;

    if (isBlank) {
      if (hideBlanks) return false;
      // If any specific condition is configured, blanks do not satisfy it
      if (textContains != null ||
          textEquals != null ||
          (numericOp != null && numericValue != null)) {
        return false;
      }
      return showBlanks;
    }

    final displayText = cell.displayValue;

    // Text contains
    if (textContains != null && textContains!.isNotEmpty) {
      if (!displayText.toLowerCase().contains(textContains!.toLowerCase())) {
        return false;
      }
    }

    // Text equals
    if (textEquals != null && textEquals!.isNotEmpty) {
      if (displayText.toLowerCase() != textEquals!.toLowerCase()) {
        return false;
      }
    }

    // Numeric comparison
    if (numericOp != null && numericValue != null) {
      double? cellNum;
      if (cell.computedValue is NumberCellValue) {
        cellNum = (cell.computedValue as NumberCellValue).value.toDouble();
      } else {
        cellNum = double.tryParse(displayText);
      }

      if (cellNum == null) return false;

      switch (numericOp!) {
        case NumericFilterOp.lessThan:
          if (!(cellNum < numericValue!)) return false;
          break;
        case NumericFilterOp.lessThanOrEqual:
          if (!(cellNum <= numericValue!)) return false;
          break;
        case NumericFilterOp.greaterThan:
          if (!(cellNum > numericValue!)) return false;
          break;
        case NumericFilterOp.greaterThanOrEqual:
          if (!(cellNum >= numericValue!)) return false;
          break;
        case NumericFilterOp.equal:
          if (!(cellNum == numericValue!)) return false;
          break;
        case NumericFilterOp.notEqual:
          if (!(cellNum != numericValue!)) return false;
          break;
      }
    }

    return true;
  }
}

/// Represents an active tabular filter applied over a [range] on a worksheet.
class WorksheetFilter {
  WorksheetFilter({
    required this.range,
    Map<int, ColumnFilterCriteria>? columnFilters,
  }) : _columnFilters = Map.of(columnFilters ?? {});

  /// The bounding rectangular range of the filtered table (row 0 is the header row).
  final CellRange range;

  /// Mapping from 0-indexed column index to active filter criteria.
  final Map<int, ColumnFilterCriteria> _columnFilters;

  /// Unmodifiable view of all active column filter criteria.
  Map<int, ColumnFilterCriteria> get columnFilters =>
      Map.unmodifiable(_columnFilters);

  /// Sets or updates filter criteria on column [colIndex].
  void setColumnFilter(int colIndex, ColumnFilterCriteria criteria) {
    if (criteria.isActive) {
      _columnFilters[colIndex] = criteria;
    } else {
      _columnFilters.remove(colIndex);
    }
  }

  /// Clears filter criteria from column [colIndex].
  void clearColumnFilter(int colIndex) {
    _columnFilters.remove(colIndex);
  }

  /// Clears all column criteria.
  void clearAll() {
    _columnFilters.clear();
  }

  /// Evaluates row visibility across [worksheet] and updates its hidden rows set.
  void apply(Worksheet worksheet) {
    worksheet.clearHiddenRows();

    if (_columnFilters.isEmpty) return;

    // Row 0 is the header row and remains visible
    for (var r = range.topRow + 1; r <= range.bottomRow; r++) {
      bool isRowVisible = true;

      for (final entry in _columnFilters.entries) {
        final col = entry.key;
        final criteria = entry.value;
        final cell = worksheet.getCell(CellCoordinate(r, col));

        if (!criteria.matches(cell)) {
          isRowVisible = false;
          break;
        }
      }

      if (!isRowVisible) {
        worksheet.setRowHidden(r, true);
      }
    }
  }
}
