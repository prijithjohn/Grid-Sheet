import 'dart:math' as math;

import '../cell/cell_coordinate.dart';
import '../cell/cell_model.dart';
import '../cell/cell_range.dart';
import '../cell/cell_style.dart';

/// Pure Dart entity representing a spreadsheet worksheet.
///
/// Uses an ultra-lightweight sparse matrix data structure (`Map<int, Map<int, Cell>>`)
/// to guarantee near-zero memory footprint for unpopulated cells across 1,000,000 rows.
class Worksheet {
  /// Unique stable identifier for this worksheet.
  final String id;

  /// User-visible worksheet tab name (e.g. "Sheet1", "Expenses").
  String _name;

  /// Default column width in desktop logical pixels (matches Stitch design system).
  static const double defaultColumnWidth = 80.0;

  /// Default row height in desktop logical pixels (matches Stitch design system).
  static const double defaultRowHeight = 20.0;

  /// Minimum allowable column width in logical pixels.
  static const double minColumnWidth = 20.0;

  /// Minimum allowable row height in logical pixels.
  static const double minRowHeight = 16.0;

  /// Maximum character length for worksheet names (Excel standard compatibility).
  static const int maxNameLength = 31;

  /// Characters forbidden in worksheet names: `\ / ? * [ ] :`
  static final RegExp _invalidNameChars = RegExp(r'[\\/?*\[\]:]');

  /// Sparse 2D mapping: row index -> (column index -> Cell).
  final Map<int, Map<int, Cell>> _sparseMatrix = {};

  /// Custom column widths in logical pixels: col index -> width.
  final Map<int, double> _customColumnWidths = {};

  /// Custom row heights in logical pixels: row index -> height.
  final Map<int, double> _customRowHeights = {};

  Worksheet({required this.id, required String name})
    : _name = validateName(name);

  /// Worksheet name.
  String get name => _name;

  /// Updates the worksheet name, validating against spreadsheet naming constraints.
  set name(String newName) {
    _name = validateName(newName);
  }

  /// Validates that [name] is non-empty, <= 31 chars, and contains no illegal characters.
  static String validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Worksheet name cannot be empty');
    }
    if (trimmed.length > maxNameLength) {
      throw ArgumentError(
        'Worksheet name cannot exceed $maxNameLength characters: "$name"',
      );
    }
    if (_invalidNameChars.hasMatch(trimmed)) {
      throw ArgumentError(
        'Worksheet name contains forbidden characters (\\ / ? * [ ] :): "$name"',
      );
    }
    return trimmed;
  }

  /// Retrieves a cell if it has been populated or styled, otherwise returns `null`.
  Cell? getCell(CellCoordinate coordinate) {
    return _sparseMatrix[coordinate.row]?[coordinate.col];
  }

  /// Retrieves the cell at [coordinate], or a new empty [Cell] if unpopulated.
  Cell getCellOrEmpty(CellCoordinate coordinate) {
    return getCell(coordinate) ?? Cell.empty(coordinate);
  }

  /// Stores or updates a [cell] in the sparse matrix.
  ///
  /// If the cell is empty and has default styling, removes it from storage
  /// to conserve sparse memory.
  void setCell(Cell cell) {
    final row = cell.coordinate.row;
    final col = cell.coordinate.col;

    if (cell.isEmpty && cell.style == CellStyle.defaultStyle) {
      removeCell(cell.coordinate);
      return;
    }

    final rowMap = _sparseMatrix.putIfAbsent(row, () => {});
    rowMap[col] = cell;
  }

  /// Removes a cell from the sparse matrix.
  void removeCell(CellCoordinate coordinate) {
    final rowMap = _sparseMatrix[coordinate.row];
    if (rowMap != null) {
      rowMap.remove(coordinate.col);
      if (rowMap.isEmpty) {
        _sparseMatrix.remove(coordinate.row);
      }
    }
  }

  /// Sets multiple cells in a single operation.
  void setCells(Iterable<Cell> cells) {
    for (final cell in cells) {
      setCell(cell);
    }
  }

  /// Clears all cells within the given [range].
  void clearRange(CellRange range) {
    for (var r = range.topRow; r <= range.bottomRow; r++) {
      final rowMap = _sparseMatrix[r];
      if (rowMap == null) continue;

      for (var c = range.leftCol; c <= range.rightCol; c++) {
        rowMap.remove(c);
      }

      if (rowMap.isEmpty) {
        _sparseMatrix.remove(r);
      }
    }
  }

  /// Clears all cells and custom dimensions in this worksheet.
  void clear() {
    _sparseMatrix.clear();
    _customColumnWidths.clear();
    _customRowHeights.clear();
  }

  /// Returns an iterable over all populated cells.
  Iterable<Cell> get populatedCells sync* {
    for (final rowMap in _sparseMatrix.values) {
      yield* rowMap.values;
    }
  }

  /// Total count of populated cells in the sparse matrix.
  int get populatedCellCount {
    var count = 0;
    for (final rowMap in _sparseMatrix.values) {
      count += rowMap.length;
    }
    return count;
  }

  /// Maximum 0-indexed row currently populated with data, or -1 if empty.
  int get maxPopulatedRow {
    if (_sparseMatrix.isEmpty) return -1;
    return _sparseMatrix.keys.reduce(math.max);
  }

  /// Maximum 0-indexed column currently populated with data, or -1 if empty.
  int get maxPopulatedCol {
    if (_sparseMatrix.isEmpty) return -1;
    var maxCol = -1;
    for (final rowMap in _sparseMatrix.values) {
      for (final col in rowMap.keys) {
        if (col > maxCol) maxCol = col;
      }
    }
    return maxCol;
  }

  /// Retrieves the width of column [colIndex] in logical pixels.
  double getColumnWidth(int colIndex) {
    return _customColumnWidths[colIndex] ?? defaultColumnWidth;
  }

  /// Sets the custom width of column [colIndex] in logical pixels.
  void setColumnWidth(int colIndex, double width) {
    if (width < minColumnWidth) {
      _customColumnWidths[colIndex] = minColumnWidth;
    } else {
      _customColumnWidths[colIndex] = width;
    }
  }

  /// Resets the width of column [colIndex] to the default width by removing any custom override.
  void resetColumnWidth(int colIndex) {
    _customColumnWidths.remove(colIndex);
  }

  /// Retrieves the height of row [rowIndex] in logical pixels.
  double getRowHeight(int rowIndex) {
    return _customRowHeights[rowIndex] ?? defaultRowHeight;
  }

  /// Sets the custom height of row [rowIndex] in logical pixels.
  void setRowHeight(int rowIndex, double height) {
    if (height < minRowHeight) {
      _customRowHeights[rowIndex] = minRowHeight;
    } else {
      _customRowHeights[rowIndex] = height;
    }
  }

  /// Resets the height of row [rowIndex] to the default height by removing any custom override.
  void resetRowHeight(int rowIndex) {
    _customRowHeights.remove(rowIndex);
  }

  /// Map of all custom column widths.
  Map<int, double> get customColumnWidths =>
      Map.unmodifiable(_customColumnWidths);

  /// Map of all custom row heights.
  Map<int, double> get customRowHeights => Map.unmodifiable(_customRowHeights);

  @override
  String toString() =>
      'Worksheet(id: "$id", name: "$name", populatedCells: $populatedCellCount)';
}
