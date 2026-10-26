import '../../../core/commands/command.dart';
import '../../../domain/domain.dart';
import '../models/sort_options.dart';
import '../services/sort_engine.dart';

/// Reversible command that sorts rows within a bounding range as a single atomic operation.
class SortRangeCommand extends Command {
  SortRangeCommand({
    required this.worksheet,
    required this.options,
    required this.engine,
    this.workbook,
  });

  final Worksheet worksheet;
  final SortOptions options;
  final FormulaEngine engine;
  final Workbook? workbook;

  final Map<CellCoordinate, Cell?> _snapshotBefore = {};
  bool _executedOnce = false;

  @override
  String get description =>
      'Sort Range ${options.range.a1} (${options.ascending ? "Ascending" : "Descending"})';

  @override
  void execute() {
    final range = options.range;

    if (!_executedOnce) {
      for (var r = range.topRow; r <= range.bottomRow; r++) {
        for (var c = range.leftCol; c <= range.rightCol; c++) {
          final coord = CellCoordinate(r, c);
          _snapshotBefore[coord] = worksheet.getCell(coord);
        }
      }
      _executedOnce = true;
    }

    // Compute sorted layout
    final sortedCells = const SortEngine().sortRange(worksheet, options);

    // Apply sorted cells to worksheet
    for (final entry in sortedCells.entries) {
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
          // Preserve styling
          final updated = worksheet.getCell(coord);
          if (updated != null) {
            worksheet.setCell(updated.copyWith(style: cell.style));
          }
        } else {
          if (engine.dependencyGraph.hasFormula(coord)) {
            engine.dependencyGraph.removeFormula(coord);
          }
          worksheet.setCell(cell);
        }
      }
    }

    engine.recalculateAll(worksheet, workbook: workbook);
  }

  @override
  void undo() {
    final range = options.range;

    // Clear range
    for (var r = range.topRow; r <= range.bottomRow; r++) {
      for (var c = range.leftCol; c <= range.rightCol; c++) {
        final coord = CellCoordinate(r, c);
        worksheet.removeCell(coord);
        if (engine.dependencyGraph.hasFormula(coord)) {
          engine.dependencyGraph.removeFormula(coord);
        }
      }
    }

    // Restore from snapshot
    for (final entry in _snapshotBefore.entries) {
      final coord = entry.key;
      final cell = entry.value;
      if (cell != null) {
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
