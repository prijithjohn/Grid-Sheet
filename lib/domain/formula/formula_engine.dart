import '../cell/cell_coordinate.dart';
import '../cell/cell_model.dart';
import '../cell/cell_value.dart';
import '../workbook/workbook_model.dart';
import '../worksheet/worksheet_model.dart';
import 'ast.dart';
import 'context.dart';
import 'dependency_graph.dart';
import 'evaluator.dart';
import 'parser.dart';

/// Central engine coordinating parsing, evaluation, dependency management, and recalculation.
class FormulaEngine {
  final DependencyGraph dependencyGraph;
  final FormulaEvaluator evaluator;

  FormulaEngine({DependencyGraph? dependencyGraph, FormulaEvaluator? evaluator})
    : dependencyGraph = dependencyGraph ?? DependencyGraph(),
      evaluator = evaluator ?? FormulaEvaluator();

  /// Parses a formula expression string into a [FormulaNode] AST.
  FormulaNode parse(String formulaSource) {
    return FormulaParser.fromString(formulaSource).parse();
  }

  /// Evaluates an AST [node] directly within [context].
  CellValue evaluateNode(FormulaNode node, EvaluationContext context) {
    return evaluator.evaluate(node, context);
  }

  /// Parses and evaluates [formulaSource] in a single step.
  CellValue evaluateFormula(String formulaSource, EvaluationContext context) {
    final ast = parse(formulaSource);
    return evaluateNode(ast, context);
  }

  /// Updates or creates a cell with [rawInput] on [worksheet], updating the dependency graph
  /// and automatically recalculating the cell and all affected dependent formulas.
  void setCellInput(
    Worksheet worksheet,
    CellCoordinate coordinate,
    String rawInput, {
    Workbook? workbook,
  }) {
    final trimmed = rawInput.trim();
    final isFormula = trimmed.startsWith('=');

    final existingCell = worksheet.getCell(coordinate);
    final style = existingCell?.style;

    if (trimmed.isEmpty) {
      removeCell(worksheet, coordinate, workbook: workbook);
      return;
    }

    if (isFormula) {
      // 1. Parse formula
      final ast = parse(trimmed);

      // 2. Register in dependency graph
      dependencyGraph.setFormula(coordinate, ast);

      // 3. Create evaluation context
      final context = WorksheetEvaluationContext(
        activeWorksheet: worksheet,
        workbook: workbook,
      );

      // 4. Check for direct/indirect circular reference
      if (dependencyGraph.hasCycle(coordinate)) {
        final cell = Cell(
          coordinate: coordinate,
          rawInput: rawInput,
          computedValue: const ErrorCellValue(CellError.circular),
          style:
              style ?? existingCell?.style ?? CellModel.empty(coordinate).style,
        );
        worksheet.setCell(cell);
      } else {
        // Initial evaluation of this cell
        final computed = evaluator.evaluate(ast, context);
        final cell = Cell(
          coordinate: coordinate,
          rawInput: rawInput,
          computedValue: computed,
          style:
              style ?? existingCell?.style ?? CellModel.empty(coordinate).style,
        );
        worksheet.setCell(cell);
      }

      // 5. Recalculate all affected dependents
      recalculateDependents(worksheet, [coordinate], workbook: workbook);
    } else {
      // Not a formula - remove from dependency graph if it previously was a formula
      if (dependencyGraph.hasFormula(coordinate)) {
        dependencyGraph.removeFormula(coordinate);
      }

      final cell = Cell.fromInput(
        coordinate,
        rawInput,
        style:
            style ?? existingCell?.style ?? CellModel.empty(coordinate).style,
      );
      worksheet.setCell(cell);

      // Recalculate dependents that read from this precedent cell
      recalculateDependents(worksheet, [coordinate], workbook: workbook);
    }
  }

  /// Removes a cell at [coordinate] and recalculates any dependent formulas.
  void removeCell(
    Worksheet worksheet,
    CellCoordinate coordinate, {
    Workbook? workbook,
  }) {
    if (dependencyGraph.hasFormula(coordinate)) {
      dependencyGraph.removeFormula(coordinate);
    }
    worksheet.removeCell(coordinate);
    recalculateDependents(worksheet, [coordinate], workbook: workbook);
  }

  /// Recalculates all dependent formulas affected by changes in [changedCells].
  void recalculateDependents(
    Worksheet worksheet,
    Iterable<CellCoordinate> changedCells, {
    Workbook? workbook,
  }) {
    final plan = dependencyGraph.getRecalculationPlan(changedCells);

    final context = WorksheetEvaluationContext(
      activeWorksheet: worksheet,
      workbook: workbook,
    );

    // 1. Mark all circular cells with #CIRCULAR!
    for (final coord in plan.circularCells) {
      final cell = worksheet.getCell(coord);
      if (cell != null) {
        worksheet.setCell(
          cell.copyWith(
            computedValue: const ErrorCellValue(CellError.circular),
          ),
        );
      }
    }

    // 2. Evaluate all non-circular cells in topological order
    for (final coord in plan.orderedCells) {
      final ast = dependencyGraph.getFormula(coord);
      final cell = worksheet.getCell(coord);
      if (ast != null && cell != null) {
        final newVal = evaluator.evaluate(ast, context);
        worksheet.setCell(cell.copyWith(computedValue: newVal));
      }
    }
  }

  /// Clears all registered formulas and dependencies from the engine.
  void clear() {
    dependencyGraph.clear();
  }

  /// Recalculates all formula cells currently populated in [worksheet].
  void recalculateAll(Worksheet worksheet, {Workbook? workbook}) {
    // Collect all formula cells
    for (final cell in worksheet.populatedCells) {
      if (cell.isFormula && !dependencyGraph.hasFormula(cell.coordinate)) {
        final ast = parse(cell.rawInput);
        dependencyGraph.setFormula(cell.coordinate, ast);
      }
    }

    final allCoords = dependencyGraph.formulaCells.toList();
    recalculateDependents(worksheet, allCoords, workbook: workbook);
  }

  /// Clears and recalculates all formula cells across all worksheets in [workbook].
  void recalculateWorkbook(Workbook workbook) {
    clear();
    for (final sheet in workbook.sheets) {
      recalculateAll(sheet, workbook: workbook);
    }
  }
}
