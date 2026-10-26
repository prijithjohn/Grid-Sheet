import '../../../core/commands/command.dart';
import '../../../domain/domain.dart';
import '../models/find_replace_options.dart';
import '../services/find_replace_engine.dart';

/// Reversible command that replaces text in a single cell match.
class ReplaceMatchCommand extends Command {
  ReplaceMatchCommand({
    required this.workbook,
    required this.match,
    required this.options,
    required this.engine,
  });

  final Workbook workbook;
  final FindReplaceMatch match;
  final FindReplaceOptions options;
  final FormulaEngine engine;

  Cell? _previousCell;
  bool _executedOnce = false;
  bool _didReplace = false;

  @override
  String get description =>
      'Replace in ${match.worksheetName}!${match.coordinate.a1}';

  @override
  void execute() {
    if (match.worksheetIndex < 0 ||
        match.worksheetIndex >= workbook.sheetCount) {
      return;
    }

    final sheet = workbook.sheets[match.worksheetIndex];
    if (!_executedOnce) {
      _previousCell = sheet.getCell(match.coordinate);
      _executedOnce = true;
    }

    final currentCell = sheet.getCell(match.coordinate);
    if (currentCell == null) return;

    // Safety: avoid modifying formula source when user searched displayed values
    if (!options.searchFormulas && currentCell.isFormula) {
      return;
    }

    final targetSource = options.searchFormulas
        ? currentCell.rawInput
        : currentCell.displayValue;

    final newText = FindReplaceEngine.computeReplacement(targetSource, options);
    if (newText != targetSource) {
      engine.setCellInput(sheet, match.coordinate, newText, workbook: workbook);
      // Restore style
      final updated = sheet.getCell(match.coordinate);
      if (updated != null && _previousCell != null) {
        sheet.setCell(updated.copyWith(style: _previousCell!.style));
      }
      _didReplace = true;
    }
  }

  @override
  void undo() {
    if (!_didReplace) return;
    if (match.worksheetIndex < 0 ||
        match.worksheetIndex >= workbook.sheetCount) {
      return;
    }

    final sheet = workbook.sheets[match.worksheetIndex];
    if (_previousCell != null) {
      sheet.setCell(_previousCell!);
      if (_previousCell!.isFormula) {
        engine.setCellInput(
          sheet,
          match.coordinate,
          _previousCell!.rawInput,
          workbook: workbook,
        );
      } else {
        engine.recalculateDependents(sheet, [
          match.coordinate,
        ], workbook: workbook);
      }
    } else {
      engine.removeCell(sheet, match.coordinate, workbook: workbook);
    }
  }
}

/// Reversible compound command that performs "Replace All" across all matched cells
/// as a single atomic undoable operation.
class ReplaceAllCommand extends Command {
  ReplaceAllCommand({
    required this.workbook,
    required this.matches,
    required this.options,
    required this.engine,
  });

  final Workbook workbook;
  final List<FindReplaceMatch> matches;
  final FindReplaceOptions options;
  final FormulaEngine engine;

  final Map<int, Map<CellCoordinate, Cell?>> _previousStates = {};
  int _replacedCount = 0;
  bool _executedOnce = false;

  /// The total number of cells modified during execution.
  int get replacedCount => _replacedCount;

  @override
  String get description => 'Replace All ($_replacedCount occurrences)';

  @override
  void execute() {
    if (!_executedOnce) {
      for (final match in matches) {
        if (match.worksheetIndex < 0 ||
            match.worksheetIndex >= workbook.sheetCount) {
          continue;
        }
        final sheet = workbook.sheets[match.worksheetIndex];
        final sheetMap = _previousStates.putIfAbsent(
          match.worksheetIndex,
          () => {},
        );
        sheetMap[match.coordinate] = sheet.getCell(match.coordinate);
      }
      _executedOnce = true;
    }

    _replacedCount = 0;
    for (final match in matches) {
      if (match.worksheetIndex < 0 ||
          match.worksheetIndex >= workbook.sheetCount) {
        continue;
      }
      final sheet = workbook.sheets[match.worksheetIndex];
      final currentCell = sheet.getCell(match.coordinate);
      if (currentCell == null) continue;

      // Avoid modifying formula source when searching displayed values
      if (!options.searchFormulas && currentCell.isFormula) {
        continue;
      }

      final targetSource = options.searchFormulas
          ? currentCell.rawInput
          : currentCell.displayValue;

      final newText = FindReplaceEngine.computeReplacement(
        targetSource,
        options,
      );

      if (newText != targetSource) {
        engine.setCellInput(
          sheet,
          match.coordinate,
          newText,
          workbook: workbook,
        );

        // Preserve styling
        final updated = sheet.getCell(match.coordinate);
        final prev = _previousStates[match.worksheetIndex]?[match.coordinate];
        if (updated != null && prev != null) {
          sheet.setCell(updated.copyWith(style: prev.style));
        }

        _replacedCount++;
      }
    }
  }

  @override
  void undo() {
    for (final sheetEntry in _previousStates.entries) {
      final sheetIndex = sheetEntry.key;
      if (sheetIndex < 0 || sheetIndex >= workbook.sheetCount) continue;
      final sheet = workbook.sheets[sheetIndex];

      for (final cellEntry in sheetEntry.value.entries) {
        final coord = cellEntry.key;
        final cell = cellEntry.value;
        if (cell != null) {
          sheet.setCell(cell);
          if (cell.isFormula) {
            engine.setCellInput(
              sheet,
              coord,
              cell.rawInput,
              workbook: workbook,
            );
          }
        } else {
          engine.removeCell(sheet, coord, workbook: workbook);
        }
      }

      engine.recalculateAll(sheet, workbook: workbook);
    }
  }
}
