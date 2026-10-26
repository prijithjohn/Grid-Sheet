import '../../domain/domain.dart';
import 'command.dart';

/// Reversible command that edits a cell via the [FormulaEngine], supporting
/// formula evaluation, dependency graph updates, and cascaded recalculation.
///
/// On undo, restores the worksheet to its prior state including all cells that
/// were recalculated as dependents, and repairs the dependency graph.
class SetFormulaCommand extends Command {
  SetFormulaCommand({
    required this.engine,
    required this.worksheet,
    required this.coordinate,
    required this.newInput,
    this.workbook,
  });

  final FormulaEngine engine;
  final Worksheet worksheet;
  final CellCoordinate coordinate;
  final String newInput;
  final Workbook? workbook;

  // Snapshot of the entire worksheet's cells before execution (only populated cells)
  final Map<CellCoordinate, Cell> _snapshotBefore = {};

  // The formula ASTs registered in the dependency graph before this command ran
  // (so we can restore them on undo)
  final Map<CellCoordinate, FormulaNode> _graphSnapshotBefore = {};

  bool _executedOnce = false;

  @override
  String get description => 'Edit Cell ${coordinate.a1}';

  @override
  void execute() {
    if (!_executedOnce) {
      // 1. Capture current cell snapshot (populated cells only)
      for (final cell in worksheet.populatedCells) {
        _snapshotBefore[cell.coordinate] = cell;
      }

      // 2. Capture dependency graph snapshot
      for (final coord in engine.dependencyGraph.formulaCells) {
        final ast = engine.dependencyGraph.getFormula(coord);
        if (ast != null) {
          _graphSnapshotBefore[coord] = ast;
        }
      }

      _executedOnce = true;
    }

    // Apply the new input through the formula engine (parse + evaluate + cascade)
    engine.setCellInput(worksheet, coordinate, newInput, workbook: workbook);
  }

  @override
  void undo() {
    // 1. Clear the entire worksheet
    for (final coord in List.of(
      worksheet.populatedCells.map((c) => c.coordinate),
    )) {
      worksheet.removeCell(coord);
    }

    // 2. Clear the dependency graph entries we know about
    for (final coord in engine.dependencyGraph.formulaCells.toList()) {
      engine.dependencyGraph.removeFormula(coord);
    }

    // 3. Restore all cells from snapshot
    for (final cell in _snapshotBefore.values) {
      worksheet.setCell(cell);
    }

    // 4. Restore dependency graph from snapshot
    for (final entry in _graphSnapshotBefore.entries) {
      engine.dependencyGraph.setFormula(entry.key, entry.value);
    }
  }
}

/// Reversible command that clears a range of cells via the [FormulaEngine],
/// removing formula dependencies and triggering cascaded recalculation.
class ClearFormulaRangeCommand extends Command {
  ClearFormulaRangeCommand({
    required this.engine,
    required this.worksheet,
    required this.range,
    this.workbook,
  });

  final FormulaEngine engine;
  final Worksheet worksheet;
  final CellRange range;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell> _snapshotBefore = {};
  final Map<CellCoordinate, FormulaNode> _graphSnapshotBefore = {};
  bool _executedOnce = false;

  @override
  String get description => 'Clear Range ${range.a1}';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final cell in worksheet.populatedCells) {
        _snapshotBefore[cell.coordinate] = cell;
      }
      for (final coord in engine.dependencyGraph.formulaCells) {
        final ast = engine.dependencyGraph.getFormula(coord);
        if (ast != null) {
          _graphSnapshotBefore[coord] = ast;
        }
      }
      _executedOnce = true;
    }

    // Only remove populated cells within the target range
    final populatedCoords = worksheet
        .getPopulatedCellsInRange(range)
        .map((c) => c.coordinate)
        .toList();

    for (final coord in populatedCoords) {
      if (engine.dependencyGraph.hasFormula(coord)) {
        engine.dependencyGraph.removeFormula(coord);
      }
      worksheet.removeCell(coord);
    }

    if (populatedCoords.isNotEmpty) {
      engine.recalculateDependents(
        worksheet,
        populatedCoords,
        workbook: workbook,
      );
    }
  }

  @override
  void undo() {
    // Clear populated cells
    worksheet.clearCells();

    for (final coord in engine.dependencyGraph.formulaCells.toList()) {
      engine.dependencyGraph.removeFormula(coord);
    }

    // Restore snapshot
    for (final cell in _snapshotBefore.values) {
      worksheet.setCell(cell);
    }
    for (final entry in _graphSnapshotBefore.entries) {
      engine.dependencyGraph.setFormula(entry.key, entry.value);
    }
  }
}
