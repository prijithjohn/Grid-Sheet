import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('Phase 09: Realistic Dependency Chain & Graph Stabilization Tests', () {
    late FormulaEngine engine;
    late Worksheet sheet;
    late Workbook workbook;

    setUp(() {
      engine = FormulaEngine();
      workbook = Workbook.createDefault();
      sheet = workbook.sheets[0];
    });

    test('Deep linear dependency chain (50 levels) recalculates in topological order', () {
      // Setup chain: A0 = 1, A1 = A0 + 1, A2 = A1 + 1, ..., A50 = A49 + 1
      engine.setCellInput(
        sheet,
        const CellCoordinate(0, 0),
        '1',
        workbook: workbook,
      );

      for (var r = 1; r <= 50; r++) {
        final prevA1 = CellCoordinate(r - 1, 0).a1;
        engine.setCellInput(
          sheet,
          CellCoordinate(r, 0),
          '=$prevA1+1',
          workbook: workbook,
        );
      }

      // Initial check: Row 50 should equal 51
      expect(
        sheet.getCell(const CellCoordinate(50, 0))?.computedValue,
        const NumberCellValue(51),
      );

      // Now update root A0 to 10
      engine.setCellInput(
        sheet,
        const CellCoordinate(0, 0),
        '10',
        workbook: workbook,
      );

      // Verify all 50 cells recalculated; Row 50 should now equal 60
      expect(
        sheet.getCell(const CellCoordinate(50, 0))?.computedValue,
        const NumberCellValue(60),
      );
      expect(
        sheet.getCell(const CellCoordinate(25, 0))?.computedValue,
        const NumberCellValue(35),
      );
    });

    test('Diamond dependency graph evaluates merge node exactly once after branches', () {
      //       A1 (10)
      //      /  \
      //  B1 (=A1*2)  C1 (=A1*3)
      //      \  /
      //    D1 (=B1+C1)
      const coordA1 = CellCoordinate(0, 0);
      const coordB1 = CellCoordinate(0, 1);
      const coordC1 = CellCoordinate(0, 2);
      const coordD1 = CellCoordinate(0, 3);

      engine.setCellInput(sheet, coordA1, '10', workbook: workbook);
      engine.setCellInput(sheet, coordB1, '=A1*2', workbook: workbook);
      engine.setCellInput(sheet, coordC1, '=A1*3', workbook: workbook);
      engine.setCellInput(sheet, coordD1, '=B1+C1', workbook: workbook);

      // D1 = 20 + 30 = 50
      expect(sheet.getCell(coordD1)?.computedValue, const NumberCellValue(50));

      // Check plan order for changed A1
      final plan = engine.dependencyGraph.getRecalculationPlan([coordA1]);
      expect(plan.circularCells, isEmpty);
      expect(plan.orderedCells.contains(coordB1), isTrue);
      expect(plan.orderedCells.contains(coordC1), isTrue);
      expect(plan.orderedCells.contains(coordD1), isTrue);

      // D1 must appear strictly AFTER both B1 and C1 in topological ordering
      final idxB1 = plan.orderedCells.indexOf(coordB1);
      final idxC1 = plan.orderedCells.indexOf(coordC1);
      final idxD1 = plan.orderedCells.indexOf(coordD1);
      expect(idxD1, greaterThan(idxB1));
      expect(idxD1, greaterThan(idxC1));

      // Mutate root A1 to 5
      engine.setCellInput(sheet, coordA1, '5', workbook: workbook);
      expect(sheet.getCell(coordB1)?.computedValue, const NumberCellValue(10));
      expect(sheet.getCell(coordC1)?.computedValue, const NumberCellValue(15));
      expect(sheet.getCell(coordD1)?.computedValue, const NumberCellValue(25));
    });

    test('Circular reference with downstream dependent assigns #CIRCULAR!', () {
      // A1 = B1 + 1
      // B1 = A1 * 2 (cycle)
      // C1 = A1 + 10 (downstream of circular cell)
      const coordA1 = CellCoordinate(0, 0);
      const coordB1 = CellCoordinate(0, 1);
      const coordC1 = CellCoordinate(0, 2);

      engine.setCellInput(sheet, coordA1, '=B1+1', workbook: workbook);
      engine.setCellInput(sheet, coordB1, '=A1*2', workbook: workbook);
      engine.setCellInput(sheet, coordC1, '=A1+10', workbook: workbook);

      expect(
        sheet.getCell(coordA1)?.computedValue,
        const ErrorCellValue(CellError.circular),
      );
      expect(
        sheet.getCell(coordB1)?.computedValue,
        const ErrorCellValue(CellError.circular),
      );
      expect(
        sheet.getCell(coordC1)?.computedValue,
        const ErrorCellValue(CellError.circular),
      );

      // Break the cycle by making B1 a constant 5
      engine.setCellInput(sheet, coordB1, '5', workbook: workbook);

      expect(sheet.getCell(coordA1)?.computedValue, const NumberCellValue(6));
      expect(sheet.getCell(coordC1)?.computedValue, const NumberCellValue(16));
    });

    test('Replacing formula removes obsolete precedent edges and prevents recalculation', () {
      const coordA1 = CellCoordinate(0, 0);
      const coordB1 = CellCoordinate(0, 1);
      const coordC1 = CellCoordinate(0, 2);

      engine.setCellInput(sheet, coordA1, '10', workbook: workbook);
      engine.setCellInput(sheet, coordB1, '20', workbook: workbook);
      // C1 initially depends on A1 and B1
      engine.setCellInput(sheet, coordC1, '=A1+B1', workbook: workbook);

      expect(engine.dependencyGraph.getDependents(coordA1), contains(coordC1));
      expect(engine.dependencyGraph.getDependents(coordB1), contains(coordC1));

      // Change C1 to only depend on A1
      engine.setCellInput(sheet, coordC1, '=A1*5', workbook: workbook);

      // B1 should no longer list C1 as a dependent
      expect(
        engine.dependencyGraph.getDependents(coordB1),
        isNot(contains(coordC1)),
      );
      expect(engine.dependencyGraph.getDependents(coordA1), contains(coordC1));

      // Modifying B1 should NOT include C1 in the recalculation plan
      final plan = engine.dependencyGraph.getRecalculationPlan([coordB1]);
      expect(plan.orderedCells, isNot(contains(coordC1)));
    });

    test(
      'Disconnected subgraphs do not cross-contaminate recalculation plans',
      () {
        // Subgraph 1: A1 -> A2
        // Subgraph 2: B1 -> B2
        const a1 = CellCoordinate(0, 0);
        const a2 = CellCoordinate(1, 0);
        const b1 = CellCoordinate(0, 1);
        const b2 = CellCoordinate(1, 1);

        engine.setCellInput(sheet, a1, '10', workbook: workbook);
        engine.setCellInput(sheet, a2, '=A1*2', workbook: workbook);

        engine.setCellInput(sheet, b1, '100', workbook: workbook);
        engine.setCellInput(sheet, b2, '=B1*2', workbook: workbook);

        // Changing A1 only recalculates A2
        final planA = engine.dependencyGraph.getRecalculationPlan([a1]);
        expect(planA.orderedCells, equals([a2]));

        // Changing B1 only recalculates B2
        final planB = engine.dependencyGraph.getRecalculationPlan([b1]);
        expect(planB.orderedCells, equals([b2]));
      },
    );
  });
}
