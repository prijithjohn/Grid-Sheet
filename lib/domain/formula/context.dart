import '../cell/cell_coordinate.dart';
import '../cell/cell_range.dart';
import '../cell/cell_value.dart';
import '../workbook/workbook_model.dart';
import '../worksheet/worksheet_model.dart';

/// Context provided to [FormulaEvaluator] for looking up cell coordinates and ranges.
abstract class EvaluationContext {
  /// The primary worksheet in which the formula is currently executing.
  Worksheet get activeWorksheet;

  /// Optional workbook containing other sheets for cross-sheet references (e.g. `Sheet2!A1`).
  Workbook? get workbook;

  /// Retrieves the evaluated [CellValue] at [coordinate] on [sheetName] (or active sheet).
  CellValue getCellValue(CellCoordinate coordinate, {String? sheetName});

  /// Retrieves an iterable of evaluated [CellValue]s for all coordinates in [range].
  Iterable<CellValue> getRangeValues(CellRange range, {String? sheetName});
}

/// Standard in-memory evaluation context operating on a [Worksheet] (and optional [Workbook]).
class WorksheetEvaluationContext implements EvaluationContext {
  @override
  final Worksheet activeWorksheet;

  @override
  final Workbook? workbook;

  WorksheetEvaluationContext({required this.activeWorksheet, this.workbook});

  Worksheet _resolveSheet(String? sheetName) {
    if (sheetName == null || sheetName.isEmpty) {
      return activeWorksheet;
    }
    if (workbook != null) {
      final found = workbook!.getSheetByName(sheetName);
      if (found != null) return found;
    }
    if (activeWorksheet.name.toUpperCase() == sheetName.toUpperCase()) {
      return activeWorksheet;
    }
    return activeWorksheet;
  }

  @override
  CellValue getCellValue(CellCoordinate coordinate, {String? sheetName}) {
    final sheet = _resolveSheet(sheetName);
    final cell = sheet.getCell(coordinate);
    if (cell == null || cell.isEmpty) {
      return const EmptyCellValue();
    }
    return cell.computedValue;
  }

  @override
  Iterable<CellValue> getRangeValues(
    CellRange range, {
    String? sheetName,
  }) sync* {
    final sheet = _resolveSheet(sheetName);
    for (var r = range.topRow; r <= range.bottomRow; r++) {
      for (var c = range.leftCol; c <= range.rightCol; c++) {
        final coord = CellCoordinate(r, c);
        final cell = sheet.getCell(coord);
        if (cell == null || cell.isEmpty) {
          yield const EmptyCellValue();
        } else {
          yield cell.computedValue;
        }
      }
    }
  }
}
