import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/formula/formula_engine.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';
import 'package:grid_sheet/domain/cell/cell_value.dart';
import 'package:grid_sheet/domain/worksheet/worksheet_model.dart';

/// Creates a thin helper that reads computed value of a cell by A1 address.
CellValue? computed(Worksheet ws, String a1) {
  final coord = CellCoordinate.fromA1(a1);
  return ws.getCell(coord)?.computedValue;
}

void main() {
  group('FormulaEngine', () {
    late FormulaEngine engine;
    late Worksheet sheet;

    setUp(() {
      engine = FormulaEngine();
      sheet = Worksheet(id: 'ws1', name: 'Sheet1');
    });

    // -------------------------------------------------------------------------
    // setCellInput — literals
    // -------------------------------------------------------------------------
    group('setCellInput — plain values', () {
      test('sets numeric literal cell', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '42');
        expect(computed(sheet, 'A1'), const NumberCellValue(42));
      });

      test('sets text literal cell', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), 'hello');
        expect(computed(sheet, 'A1'), const TextCellValue('hello'));
      });

      test('empty input removes cell', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '5');
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '');
        expect(sheet.getCell(CellCoordinate.fromA1('A1')), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // setCellInput — formula evaluation
    // -------------------------------------------------------------------------
    group('setCellInput — formula evaluation', () {
      test('evaluates constant formula', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '=1+2');
        expect(computed(sheet, 'A1'), const NumberCellValue(3));
      });

      test('evaluates formula referencing another cell', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '10');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1*2');
        expect(computed(sheet, 'B1'), const NumberCellValue(20));
      });

      test('evaluates SUM formula over range', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '1');
        engine.setCellInput(sheet, CellCoordinate.fromA1('A2'), '2');
        engine.setCellInput(sheet, CellCoordinate.fromA1('A3'), '3');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=SUM(A1:A3)');
        expect(computed(sheet, 'B1'), const NumberCellValue(6));
      });

      test('evaluates IF formula', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '10');
        engine.setCellInput(
            sheet, CellCoordinate.fromA1('B1'), '=IF(A1>5,"big","small")');
        expect(computed(sheet, 'B1'), const TextCellValue('big'));
      });
    });

    // -------------------------------------------------------------------------
    // Automatic recalculation of dependents
    // -------------------------------------------------------------------------
    group('automatic recalculation', () {
      test('dependent formula updates when precedent changes', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '5');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1*2');
        expect(computed(sheet, 'B1'), const NumberCellValue(10));

        // Change A1 -> B1 should automatically recalculate
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '7');
        expect(computed(sheet, 'B1'), const NumberCellValue(14));
      });

      test('chain recalculation: A1 -> B1 -> C1', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '2');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1+3');
        engine.setCellInput(sheet, CellCoordinate.fromA1('C1'), '=B1*2');
        expect(computed(sheet, 'B1'), const NumberCellValue(5));
        expect(computed(sheet, 'C1'), const NumberCellValue(10));

        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '10');
        expect(computed(sheet, 'B1'), const NumberCellValue(13));
        expect(computed(sheet, 'C1'), const NumberCellValue(26));
      });

      test('multi-dependent: both B1 and C1 depend on A1', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '4');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1+1');
        engine.setCellInput(sheet, CellCoordinate.fromA1('C1'), '=A1*10');

        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '6');
        expect(computed(sheet, 'B1'), const NumberCellValue(7));
        expect(computed(sheet, 'C1'), const NumberCellValue(60));
      });

      test('formula updated to literal clears dependency and recalculates', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '5');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1*2');
        expect(computed(sheet, 'B1'), const NumberCellValue(10));

        // Replace B1 formula with a literal
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '99');
        expect(computed(sheet, 'B1'), const NumberCellValue(99));
        // No longer a formula — dependency on A1 should be gone
        expect(engine.dependencyGraph.hasFormula(CellCoordinate.fromA1('B1')),
            isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // removeCell
    // -------------------------------------------------------------------------
    group('removeCell', () {
      test('removes the cell from worksheet', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '42');
        engine.removeCell(sheet, CellCoordinate.fromA1('A1'));
        expect(sheet.getCell(CellCoordinate.fromA1('A1')), isNull);
      });

      test('removing formula cell clears dependency graph entry', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '=B1+1');
        engine.removeCell(sheet, CellCoordinate.fromA1('A1'));
        expect(engine.dependencyGraph.hasFormula(CellCoordinate.fromA1('A1')),
            isFalse);
      });

      test('dependents of removed cell recalculate to empty/0', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '5');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1+1');
        expect(computed(sheet, 'B1'), const NumberCellValue(6));

        engine.removeCell(sheet, CellCoordinate.fromA1('A1'));
        // A1 is now empty (0 in arithmetic context), so B1 = 0+1 = 1
        expect(computed(sheet, 'B1'), const NumberCellValue(1));
      });
    });

    // -------------------------------------------------------------------------
    // Circular reference handling
    // -------------------------------------------------------------------------
    group('circular reference handling', () {
      test('direct self-reference produces #CIRCULAR!', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '=A1');
        expect(computed(sheet, 'A1'),
            const ErrorCellValue(CellError.circular));
      });

      test('indirect circular reference A1->B1->A1', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '=B1');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1');
        // At least one of them should show #CIRCULAR!
        final aVal = computed(sheet, 'A1');
        final bVal = computed(sheet, 'B1');
        expect(
          aVal == const ErrorCellValue(CellError.circular) ||
              bVal == const ErrorCellValue(CellError.circular),
          isTrue,
          reason: 'Expected at least one circular cell to show #CIRCULAR!',
        );
      });
    });

    // -------------------------------------------------------------------------
    // Division by zero
    // -------------------------------------------------------------------------
    group('division by zero', () {
      test('formula dividing by zero cell returns #DIV/0!', () {
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '0');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=10/A1');
        expect(computed(sheet, 'B1'), const ErrorCellValue(CellError.divZero));
      });
    });

    // -------------------------------------------------------------------------
    // recalculateAll
    // -------------------------------------------------------------------------
    group('recalculateAll', () {
      test('recalculateAll evaluates all formula cells', () {
        // Set up cells directly without engine to simulate load from storage
        engine.setCellInput(sheet, CellCoordinate.fromA1('A1'), '10');
        engine.setCellInput(sheet, CellCoordinate.fromA1('B1'), '=A1*5');
        engine.setCellInput(sheet, CellCoordinate.fromA1('C1'), '=SUM(A1:B1)');

        // Create fresh engine (simulates reload)
        final freshEngine = FormulaEngine();
        freshEngine.recalculateAll(sheet);

        expect(computed(sheet, 'B1'), const NumberCellValue(50));
        expect(computed(sheet, 'C1'), const NumberCellValue(60));
      });
    });
  });
}
