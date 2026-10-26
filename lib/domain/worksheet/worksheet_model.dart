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

  /// Set of 0-indexed rows that are hidden (e.g. filtered or hidden by user).
  final Set<int> _hiddenRows = {};

  /// Number of frozen rows anchored at the top of the worksheet (0 = none).
  int frozenRows = 0;

  /// Number of frozen columns anchored at the left of the worksheet (0 = none).
  int frozenCols = 0;

  /// Optional active tabular filter configuration for this worksheet.
  dynamic filter;

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

  /// Clears all cells within the given [range] without iterating unpopulated rows.
  void clearRange(CellRange range) {
    final rowsToCheck = _sparseMatrix.keys
        .where((r) => r >= range.topRow && r <= range.bottomRow)
        .toList();
    for (final r in rowsToCheck) {
      final rowMap = _sparseMatrix[r];
      if (rowMap == null) continue;

      final colsToRemove = rowMap.keys
          .where((c) => c >= range.leftCol && c <= range.rightCol)
          .toList();
      for (final c in colsToRemove) {
        rowMap.remove(c);
      }

      if (rowMap.isEmpty) {
        _sparseMatrix.remove(r);
      }
    }
  }

  /// Clears all populated cells while preserving custom column widths and row heights.
  void clearCells() {
    _sparseMatrix.clear();
  }

  /// Returns an iterable over all populated cells within the specified [range].
  Iterable<Cell> getPopulatedCellsInRange(CellRange range) sync* {
    for (final entry in _sparseMatrix.entries) {
      final r = entry.key;
      if (r < range.topRow || r > range.bottomRow) continue;
      for (final cellEntry in entry.value.entries) {
        final c = cellEntry.key;
        if (c >= range.leftCol && c <= range.rightCol) {
          yield cellEntry.value;
        }
      }
    }
  }

  /// Clears all cells and custom dimensions in this worksheet.
  void clear() {
    _sparseMatrix.clear();
    _customColumnWidths.clear();
    _customRowHeights.clear();
    _hiddenRows.clear();
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
  ///
  /// Returns 0.0 if the row is currently hidden or filtered out.
  double getRowHeight(int rowIndex) {
    if (isRowHidden(rowIndex)) return 0.0;
    return _customRowHeights[rowIndex] ?? defaultRowHeight;
  }

  /// Whether row [rowIndex] is currently hidden (e.g. filtered out).
  bool isRowHidden(int rowIndex) => _hiddenRows.contains(rowIndex);

  /// Sets whether row [rowIndex] is hidden.
  void setRowHidden(int rowIndex, bool hidden) {
    if (hidden) {
      _hiddenRows.add(rowIndex);
    } else {
      _hiddenRows.remove(rowIndex);
    }
  }

  /// Clears all hidden rows on this worksheet.
  void clearHiddenRows() {
    _hiddenRows.clear();
  }

  /// Set of all currently hidden 0-indexed row indices.
  Set<int> get hiddenRows => Set.unmodifiable(_hiddenRows);

  /// Sets the frozen row and column boundaries.
  void freezePanes({int rows = 0, int cols = 0}) {
    frozenRows = rows.clamp(0, 50);
    frozenCols = cols.clamp(0, 30);
  }

  /// Unfreezes all rows and columns.
  void unfreezePanes() {
    frozenRows = 0;
    frozenCols = 0;
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

  /// Returns the vertical logical pixel offset for the top of row [rowIndex].
  double getRowOffset(int rowIndex) {
    if (rowIndex <= 0) return 0.0;
    if (_customRowHeights.isEmpty && _hiddenRows.isEmpty) {
      return rowIndex * defaultRowHeight;
    }
    double offset = rowIndex * defaultRowHeight;
    for (final hidden in _hiddenRows) {
      if (hidden < rowIndex) {
        offset -= (_customRowHeights[hidden] ?? defaultRowHeight);
      }
    }
    for (final entry in _customRowHeights.entries) {
      if (entry.key < rowIndex && !_hiddenRows.contains(entry.key)) {
        offset += (entry.value - defaultRowHeight);
      }
    }
    return offset;
  }

  /// Returns the horizontal logical pixel offset for the left of column [colIndex].
  double getColumnOffset(int colIndex) {
    if (colIndex <= 0) return 0.0;
    if (_customColumnWidths.isEmpty) {
      return colIndex * defaultColumnWidth;
    }
    double offset = colIndex * defaultColumnWidth;
    for (final entry in _customColumnWidths.entries) {
      if (entry.key < colIndex) {
        offset += (entry.value - defaultColumnWidth);
      }
    }
    return offset;
  }

  /// Returns the 0-indexed row at vertical offset [offsetY], skipping hidden rows.
  int getRowAtOffset(double offsetY) {
    if (offsetY <= 0) return 0;
    if (_customRowHeights.isEmpty && _hiddenRows.isEmpty) {
      return (offsetY / defaultRowHeight).floor().clamp(
        0,
        CellCoordinate.maxRows - 1,
      );
    }
    int row = (offsetY / defaultRowHeight).floor().clamp(
      0,
      CellCoordinate.maxRows - 1,
    );
    double currentY = getRowOffset(row);
    if (currentY > offsetY) {
      while (row > 0 && currentY > offsetY) {
        row--;
        currentY = getRowOffset(row);
      }
    } else {
      while (row < CellCoordinate.maxRows - 1) {
        final h = getRowHeight(row);
        if (currentY + h > offsetY) break;
        currentY += h;
        row++;
      }
    }
    return row.clamp(0, CellCoordinate.maxRows - 1);
  }

  /// Returns the 0-indexed column at horizontal offset [offsetX].
  int getColumnAtOffset(double offsetX) {
    if (offsetX <= 0) return 0;
    if (_customColumnWidths.isEmpty) {
      return (offsetX / defaultColumnWidth).floor().clamp(
        0,
        CellCoordinate.maxCols - 1,
      );
    }
    int col = (offsetX / defaultColumnWidth).floor().clamp(
      0,
      CellCoordinate.maxCols - 1,
    );
    double currentX = getColumnOffset(col);
    if (currentX > offsetX) {
      while (col > 0 && currentX > offsetX) {
        col--;
        currentX = getColumnOffset(col);
      }
    } else {
      while (col < CellCoordinate.maxCols - 1) {
        final w = getColumnWidth(col);
        if (currentX + w > offsetX) break;
        currentX += w;
        col++;
      }
    }
    return col.clamp(0, CellCoordinate.maxCols - 1);
  }

  @override
  String toString() =>
      'Worksheet(id: "$id", name: "$name", populatedCells: $populatedCellCount)';
}
