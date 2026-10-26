import '../../domain/domain.dart';
import 'command.dart';

/// Reversible command that fills the contents of the top row downwards
/// throughout the bounding [range], adjusting relative formula references.
class FillDownCommand extends Command {
  FillDownCommand({
    required this.worksheet,
    required this.range,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final CellRange range;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell?> _previousCells = {};
  bool _executedOnce = false;

  @override
  String get description => 'Fill Down ${range.a1}';

  @override
  void execute() {
    if (range.topRow >= range.bottomRow) return;

    if (!_executedOnce) {
      for (var r = range.topRow + 1; r <= range.bottomRow; r++) {
        for (var c = range.leftCol; c <= range.rightCol; c++) {
          final coord = CellCoordinate(r, c);
          _previousCells[coord] = worksheet.getCell(coord);
        }
      }
      _executedOnce = true;
    }

    for (var c = range.leftCol; c <= range.rightCol; c++) {
      final sourceCell = worksheet.getCell(CellCoordinate(range.topRow, c));

      for (var r = range.topRow + 1; r <= range.bottomRow; r++) {
        final targetCoord = CellCoordinate(r, c);

        if (sourceCell == null || sourceCell.isEmpty) {
          worksheet.removeCell(targetCoord);
          if (engine.dependencyGraph.hasFormula(targetCoord)) {
            engine.dependencyGraph.removeFormula(targetCoord);
          }
        } else {
          final deltaRows = r - range.topRow;
          String newInput = sourceCell.rawInput;

          if (sourceCell.isFormula) {
            newInput = FormulaReferenceAdjuster.adjustReferences(
              sourceCell.rawInput,
              deltaRows: deltaRows,
            );
            engine.setCellInput(
              worksheet,
              targetCoord,
              newInput,
              workbook: workbook,
            );
            final updated = worksheet.getCell(targetCoord);
            if (updated != null) {
              worksheet.setCell(updated.copyWith(style: sourceCell.style));
            }
          } else {
            if (engine.dependencyGraph.hasFormula(targetCoord)) {
              engine.dependencyGraph.removeFormula(targetCoord);
            }
            final newCell = Cell.fromInput(
              targetCoord,
              newInput,
              style: sourceCell.style,
            );
            worksheet.setCell(newCell);
          }
        }
      }
    }

    engine.recalculateAll(worksheet, workbook: workbook);
  }

  @override
  void undo() {
    for (final entry in _previousCells.entries) {
      final coord = entry.key;
      final cell = entry.value;

      if (cell == null) {
        worksheet.removeCell(coord);
        if (engine.dependencyGraph.hasFormula(coord)) {
          engine.dependencyGraph.removeFormula(coord);
        }
      } else {
        if (cell.isFormula) {
          engine.setCellInput(
            worksheet,
            coord,
            cell.rawInput,
            workbook: workbook,
          );
          final updated = worksheet.getCell(coord);
          if (updated != null) {
            worksheet.setCell(updated.copyWith(style: cell.style));
          }
        } else {
          worksheet.setCell(cell);
        }
      }
    }

    engine.recalculateAll(worksheet, workbook: workbook);
  }
}

/// Reversible command that fills the contents of the leftmost column rightwards
/// throughout the bounding [range], adjusting relative formula references.
class FillRightCommand extends Command {
  FillRightCommand({
    required this.worksheet,
    required this.range,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final CellRange range;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell?> _previousCells = {};
  bool _executedOnce = false;

  @override
  String get description => 'Fill Right ${range.a1}';

  @override
  void execute() {
    if (range.leftCol >= range.rightCol) return;

    if (!_executedOnce) {
      for (var r = range.topRow; r <= range.bottomRow; r++) {
        for (var c = range.leftCol + 1; c <= range.rightCol; c++) {
          final coord = CellCoordinate(r, c);
          _previousCells[coord] = worksheet.getCell(coord);
        }
      }
      _executedOnce = true;
    }

    for (var r = range.topRow; r <= range.bottomRow; r++) {
      final sourceCell = worksheet.getCell(CellCoordinate(r, range.leftCol));

      for (var c = range.leftCol + 1; c <= range.rightCol; c++) {
        final targetCoord = CellCoordinate(r, c);

        if (sourceCell == null || sourceCell.isEmpty) {
          worksheet.removeCell(targetCoord);
          if (engine.dependencyGraph.hasFormula(targetCoord)) {
            engine.dependencyGraph.removeFormula(targetCoord);
          }
        } else {
          final deltaCols = c - range.leftCol;
          String newInput = sourceCell.rawInput;

          if (sourceCell.isFormula) {
            newInput = FormulaReferenceAdjuster.adjustReferences(
              sourceCell.rawInput,
              deltaCols: deltaCols,
            );
            engine.setCellInput(
              worksheet,
              targetCoord,
              newInput,
              workbook: workbook,
            );
            final updated = worksheet.getCell(targetCoord);
            if (updated != null) {
              worksheet.setCell(updated.copyWith(style: sourceCell.style));
            }
          } else {
            if (engine.dependencyGraph.hasFormula(targetCoord)) {
              engine.dependencyGraph.removeFormula(targetCoord);
            }
            final newCell = Cell.fromInput(
              targetCoord,
              newInput,
              style: sourceCell.style,
            );
            worksheet.setCell(newCell);
          }
        }
      }
    }

    engine.recalculateAll(worksheet, workbook: workbook);
  }

  @override
  void undo() {
    for (final entry in _previousCells.entries) {
      final coord = entry.key;
      final cell = entry.value;

      if (cell == null) {
        worksheet.removeCell(coord);
        if (engine.dependencyGraph.hasFormula(coord)) {
          engine.dependencyGraph.removeFormula(coord);
        }
      } else {
        if (cell.isFormula) {
          engine.setCellInput(
            worksheet,
            coord,
            cell.rawInput,
            workbook: workbook,
          );
          final updated = worksheet.getCell(coord);
          if (updated != null) {
            worksheet.setCell(updated.copyWith(style: cell.style));
          }
        } else {
          worksheet.setCell(cell);
        }
      }
    }

    engine.recalculateAll(worksheet, workbook: workbook);
  }
}

/// Reversible command that duplicates a [sourceRange] to a new location starting at [targetTopLeft].
class DuplicateRangeCommand extends Command {
  DuplicateRangeCommand({
    required this.worksheet,
    required this.sourceRange,
    required this.targetTopLeft,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final CellRange sourceRange;
  final CellCoordinate targetTopLeft;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell?> _previousCells = {};
  bool _executedOnce = false;

  @override
  String get description =>
      'Duplicate ${sourceRange.a1} to ${targetTopLeft.a1}';

  @override
  void execute() {
    final deltaRows = targetTopLeft.row - sourceRange.topRow;
    final deltaCols = targetTopLeft.col - sourceRange.leftCol;

    final targetRange = CellRange(
      targetTopLeft,
      CellCoordinate(
        targetTopLeft.row + sourceRange.rowCount - 1,
        targetTopLeft.col + sourceRange.colCount - 1,
      ),
    );

    if (!_executedOnce) {
      for (var r = targetRange.topRow; r <= targetRange.bottomRow; r++) {
        for (var c = targetRange.leftCol; c <= targetRange.rightCol; c++) {
          final coord = CellCoordinate(r, c);
          _previousCells[coord] = worksheet.getCell(coord);
        }
      }
      _executedOnce = true;
    }

    // Extract source cells first to avoid collision if ranges overlap
    final sourceCells = <CellCoordinate, Cell?>{};
    for (var r = sourceRange.topRow; r <= sourceRange.bottomRow; r++) {
      for (var c = sourceRange.leftCol; c <= sourceRange.rightCol; c++) {
        final coord = CellCoordinate(r, c);
        sourceCells[coord] = worksheet.getCell(coord);
      }
    }

    for (final entry in sourceCells.entries) {
      final srcCoord = entry.key;
      final srcCell = entry.value;
      final targetCoord = CellCoordinate(
        srcCoord.row + deltaRows,
        srcCoord.col + deltaCols,
      );

      if (srcCell == null || srcCell.isEmpty) {
        worksheet.removeCell(targetCoord);
        if (engine.dependencyGraph.hasFormula(targetCoord)) {
          engine.dependencyGraph.removeFormula(targetCoord);
        }
      } else {
        String newInput = srcCell.rawInput;
        if (srcCell.isFormula) {
          newInput = FormulaReferenceAdjuster.adjustReferences(
            srcCell.rawInput,
            deltaRows: deltaRows,
            deltaCols: deltaCols,
          );
          engine.setCellInput(
            worksheet,
            targetCoord,
            newInput,
            workbook: workbook,
          );
          final updated = worksheet.getCell(targetCoord);
          if (updated != null) {
            worksheet.setCell(updated.copyWith(style: srcCell.style));
          }
        } else {
          if (engine.dependencyGraph.hasFormula(targetCoord)) {
            engine.dependencyGraph.removeFormula(targetCoord);
          }
          final newCell = Cell.fromInput(
            targetCoord,
            newInput,
            style: srcCell.style,
          );
          worksheet.setCell(newCell);
        }
      }
    }

    engine.recalculateAll(worksheet, workbook: workbook);
  }

  @override
  void undo() {
    for (final entry in _previousCells.entries) {
      final coord = entry.key;
      final cell = entry.value;

      if (cell == null) {
        worksheet.removeCell(coord);
        if (engine.dependencyGraph.hasFormula(coord)) {
          engine.dependencyGraph.removeFormula(coord);
        }
      } else {
        if (cell.isFormula) {
          engine.setCellInput(
            worksheet,
            coord,
            cell.rawInput,
            workbook: workbook,
          );
          final updated = worksheet.getCell(coord);
          if (updated != null) {
            worksheet.setCell(updated.copyWith(style: cell.style));
          }
        } else {
          worksheet.setCell(cell);
        }
      }
    }

    engine.recalculateAll(worksheet, workbook: workbook);
  }
}

/// Reversible command that inserts [count] rows starting at [startRow].
///
/// Shifts all rows at or below [startRow] down by [count] and adjusts formula references.
class InsertRowsCommand extends Command {
  InsertRowsCommand({
    required this.worksheet,
    required this.startRow,
    this.count = 1,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final int startRow;
  final int count;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell> _allCellsBefore = {};
  final Map<int, double> _rowHeightsBefore = {};
  bool _executedOnce = false;

  @override
  String get description => 'Insert $count Row(s) at ${startRow + 1}';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final cell in worksheet.populatedCells) {
        _allCellsBefore[cell.coordinate] = cell;
      }
      _rowHeightsBefore.addAll(worksheet.customRowHeights);
      _executedOnce = true;
    }

    // 1. Separate cells into unaffected vs shifted
    final cellsToShift = <Cell>[];
    final cellsUnchanged = <Cell>[];

    for (final cell in worksheet.populatedCells) {
      if (cell.coordinate.row >= startRow) {
        cellsToShift.add(cell);
      } else {
        cellsUnchanged.add(cell);
      }
    }

    // Clear worksheet cells
    worksheet.clear();

    // Re-apply unaffected cells with adjusted formula references
    for (final cell in cellsUnchanged) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          insertedRowAt: startRow,
          insertedRowCount: count,
        );
      }
      worksheet.setCell(cell.copyWith(rawInput: raw));
    }

    // Re-apply shifted cells
    for (final cell in cellsToShift) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          insertedRowAt: startRow,
          insertedRowCount: count,
        );
      }
      final newCoord = cell.coordinate.copyWith(
        row: cell.coordinate.row + count,
      );
      worksheet.setCell(
        Cell(
          coordinate: newCoord,
          rawInput: raw,
          computedValue: cell.computedValue,
          style: cell.style,
        ),
      );
    }

    // Shift custom row heights
    for (final entry in _rowHeightsBefore.entries) {
      if (entry.key >= startRow) {
        worksheet.setRowHeight(entry.key + count, entry.value);
      } else {
        worksheet.setRowHeight(entry.key, entry.value);
      }
    }

    // Rebuild formula dependencies and recalculate
    _rebuildFormulas();
  }

  @override
  void undo() {
    worksheet.clear();
    for (final cell in _allCellsBefore.values) {
      worksheet.setCell(cell);
    }
    for (final entry in _rowHeightsBefore.entries) {
      worksheet.setRowHeight(entry.key, entry.value);
    }
    _rebuildFormulas();
  }

  void _rebuildFormulas() {
    engine.dependencyGraph.clear();
    for (final cell in worksheet.populatedCells) {
      if (cell.isFormula) {
        final ast = engine.parse(cell.rawInput);
        engine.dependencyGraph.setFormula(cell.coordinate, ast);
      }
    }
    engine.recalculateAll(worksheet, workbook: workbook);
  }
}

/// Reversible command that deletes [count] rows starting at [startRow].
class DeleteRowsCommand extends Command {
  DeleteRowsCommand({
    required this.worksheet,
    required this.startRow,
    this.count = 1,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final int startRow;
  final int count;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell> _allCellsBefore = {};
  final Map<int, double> _rowHeightsBefore = {};
  bool _executedOnce = false;

  @override
  String get description => 'Delete $count Row(s) at ${startRow + 1}';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final cell in worksheet.populatedCells) {
        _allCellsBefore[cell.coordinate] = cell;
      }
      _rowHeightsBefore.addAll(worksheet.customRowHeights);
      _executedOnce = true;
    }

    final cellsToShift = <Cell>[];
    final cellsUnchanged = <Cell>[];

    for (final cell in worksheet.populatedCells) {
      final r = cell.coordinate.row;
      if (r < startRow) {
        cellsUnchanged.add(cell);
      } else if (r >= startRow + count) {
        cellsToShift.add(cell);
      }
      // Cells in [startRow, startRow + count - 1] are deleted
    }

    worksheet.clear();

    for (final cell in cellsUnchanged) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          deletedRowAt: startRow,
          deletedRowCount: count,
        );
      }
      worksheet.setCell(cell.copyWith(rawInput: raw));
    }

    for (final cell in cellsToShift) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          deletedRowAt: startRow,
          deletedRowCount: count,
        );
      }
      final newCoord = cell.coordinate.copyWith(
        row: cell.coordinate.row - count,
      );
      worksheet.setCell(
        Cell(
          coordinate: newCoord,
          rawInput: raw,
          computedValue: cell.computedValue,
          style: cell.style,
        ),
      );
    }

    // Shift row heights
    for (final entry in _rowHeightsBefore.entries) {
      if (entry.key < startRow) {
        worksheet.setRowHeight(entry.key, entry.value);
      } else if (entry.key >= startRow + count) {
        worksheet.setRowHeight(entry.key - count, entry.value);
      }
    }

    _rebuildFormulas();
  }

  @override
  void undo() {
    worksheet.clear();
    for (final cell in _allCellsBefore.values) {
      worksheet.setCell(cell);
    }
    for (final entry in _rowHeightsBefore.entries) {
      worksheet.setRowHeight(entry.key, entry.value);
    }
    _rebuildFormulas();
  }

  void _rebuildFormulas() {
    engine.dependencyGraph.clear();
    for (final cell in worksheet.populatedCells) {
      if (cell.isFormula) {
        final ast = engine.parse(cell.rawInput);
        engine.dependencyGraph.setFormula(cell.coordinate, ast);
      }
    }
    engine.recalculateAll(worksheet, workbook: workbook);
  }
}

/// Reversible command that inserts [count] columns starting at [startCol].
class InsertColumnsCommand extends Command {
  InsertColumnsCommand({
    required this.worksheet,
    required this.startCol,
    this.count = 1,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final int startCol;
  final int count;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell> _allCellsBefore = {};
  final Map<int, double> _colWidthsBefore = {};
  bool _executedOnce = false;

  @override
  String get description =>
      'Insert $count Column(s) at ${CellCoordinate.columnToLetters(startCol)}';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final cell in worksheet.populatedCells) {
        _allCellsBefore[cell.coordinate] = cell;
      }
      _colWidthsBefore.addAll(worksheet.customColumnWidths);
      _executedOnce = true;
    }

    final cellsToShift = <Cell>[];
    final cellsUnchanged = <Cell>[];

    for (final cell in worksheet.populatedCells) {
      if (cell.coordinate.col >= startCol) {
        cellsToShift.add(cell);
      } else {
        cellsUnchanged.add(cell);
      }
    }

    worksheet.clear();

    for (final cell in cellsUnchanged) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          insertedColAt: startCol,
          insertedColCount: count,
        );
      }
      worksheet.setCell(cell.copyWith(rawInput: raw));
    }

    for (final cell in cellsToShift) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          insertedColAt: startCol,
          insertedColCount: count,
        );
      }
      final newCoord = cell.coordinate.copyWith(
        col: cell.coordinate.col + count,
      );
      worksheet.setCell(
        Cell(
          coordinate: newCoord,
          rawInput: raw,
          computedValue: cell.computedValue,
          style: cell.style,
        ),
      );
    }

    for (final entry in _colWidthsBefore.entries) {
      if (entry.key >= startCol) {
        worksheet.setColumnWidth(entry.key + count, entry.value);
      } else {
        worksheet.setColumnWidth(entry.key, entry.value);
      }
    }

    _rebuildFormulas();
  }

  @override
  void undo() {
    worksheet.clear();
    for (final cell in _allCellsBefore.values) {
      worksheet.setCell(cell);
    }
    for (final entry in _colWidthsBefore.entries) {
      worksheet.setColumnWidth(entry.key, entry.value);
    }
    _rebuildFormulas();
  }

  void _rebuildFormulas() {
    engine.dependencyGraph.clear();
    for (final cell in worksheet.populatedCells) {
      if (cell.isFormula) {
        final ast = engine.parse(cell.rawInput);
        engine.dependencyGraph.setFormula(cell.coordinate, ast);
      }
    }
    engine.recalculateAll(worksheet, workbook: workbook);
  }
}

/// Reversible command that deletes [count] columns starting at [startCol].
class DeleteColumnsCommand extends Command {
  DeleteColumnsCommand({
    required this.worksheet,
    required this.startCol,
    this.count = 1,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final int startCol;
  final int count;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell> _allCellsBefore = {};
  final Map<int, double> _colWidthsBefore = {};
  bool _executedOnce = false;

  @override
  String get description =>
      'Delete $count Column(s) at ${CellCoordinate.columnToLetters(startCol)}';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final cell in worksheet.populatedCells) {
        _allCellsBefore[cell.coordinate] = cell;
      }
      _colWidthsBefore.addAll(worksheet.customColumnWidths);
      _executedOnce = true;
    }

    final cellsToShift = <Cell>[];
    final cellsUnchanged = <Cell>[];

    for (final cell in worksheet.populatedCells) {
      final c = cell.coordinate.col;
      if (c < startCol) {
        cellsUnchanged.add(cell);
      } else if (c >= startCol + count) {
        cellsToShift.add(cell);
      }
    }

    worksheet.clear();

    for (final cell in cellsUnchanged) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          deletedColAt: startCol,
          deletedColCount: count,
        );
      }
      worksheet.setCell(cell.copyWith(rawInput: raw));
    }

    for (final cell in cellsToShift) {
      var raw = cell.rawInput;
      if (cell.isFormula) {
        raw = FormulaReferenceAdjuster.adjustReferences(
          raw,
          deletedColAt: startCol,
          deletedColCount: count,
        );
      }
      final newCoord = cell.coordinate.copyWith(
        col: cell.coordinate.col - count,
      );
      worksheet.setCell(
        Cell(
          coordinate: newCoord,
          rawInput: raw,
          computedValue: cell.computedValue,
          style: cell.style,
        ),
      );
    }

    for (final entry in _colWidthsBefore.entries) {
      if (entry.key < startCol) {
        worksheet.setColumnWidth(entry.key, entry.value);
      } else if (entry.key >= startCol + count) {
        worksheet.setColumnWidth(entry.key - count, entry.value);
      }
    }

    _rebuildFormulas();
  }

  @override
  void undo() {
    worksheet.clear();
    for (final cell in _allCellsBefore.values) {
      worksheet.setCell(cell);
    }
    for (final entry in _colWidthsBefore.entries) {
      worksheet.setColumnWidth(entry.key, entry.value);
    }
    _rebuildFormulas();
  }

  void _rebuildFormulas() {
    engine.dependencyGraph.clear();
    for (final cell in worksheet.populatedCells) {
      if (cell.isFormula) {
        final ast = engine.parse(cell.rawInput);
        engine.dependencyGraph.setFormula(cell.coordinate, ast);
      }
    }
    engine.recalculateAll(worksheet, workbook: workbook);
  }
}
