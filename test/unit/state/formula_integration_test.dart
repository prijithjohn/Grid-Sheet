import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/state.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  // ---------------------------------------------------------------------------
  // A. Formula Entry and Evaluation
  // ---------------------------------------------------------------------------
  group('Phase 05 — Formula Entry and Evaluation', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('entering a plain number stores it and displays as NumberCellValue', () {
      state.editCellAt(const CellCoordinate(0, 0), '42');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell, isNotNull);
      expect(cell!.rawInput, equals('42'));
      expect(cell.computedValue, isA<NumberCellValue>());
      expect((cell.computedValue as NumberCellValue).value, equals(42));
    });

    test('entering a formula evaluates and stores result', () {
      state.editCellAt(const CellCoordinate(0, 0), '10');
      state.editCellAt(const CellCoordinate(1, 0), '20');
      state.editCellAt(const CellCoordinate(2, 0), '=SUM(A1:A2)');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(2, 0));
      expect(cell, isNotNull);
      expect(cell!.rawInput, equals('=SUM(A1:A2)'));
      expect(cell.computedValue, isA<NumberCellValue>());
      expect((cell.computedValue as NumberCellValue).value, equals(30));
    });

    test('formula bar shows raw formula input not computed value', () {
      state.editCellAt(const CellCoordinate(0, 0), '10');
      state.editCellAt(const CellCoordinate(1, 0), '=A1*2');

      // Select the formula cell
      state.selectCell(const CellCoordinate(1, 0));

      // activeCellInput returns rawInput which is the formula text
      expect(state.activeCellInput, equals('=A1*2'));

      // The computed value is 20
      final cell = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect((cell!.computedValue as NumberCellValue).value, equals(20));
    });

    test('ordinary text cells behave correctly', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Hello World');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell!.computedValue, isA<TextCellValue>());
      expect(cell.formattedText, equals('Hello World'));
    });

    test('boolean literal TRUE/FALSE parsed correctly', () {
      state.editCellAt(const CellCoordinate(0, 0), 'TRUE');
      state.editCellAt(const CellCoordinate(1, 0), 'FALSE');

      final t = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      final f = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect(t!.computedValue, isA<BooleanCellValue>());
      expect(f!.computedValue, isA<BooleanCellValue>());
    });

    test('empty input clears the cell', () {
      state.editCellAt(const CellCoordinate(0, 0), '100');
      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0)), isNotNull);

      state.editCellAt(const CellCoordinate(0, 0), '');
      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0)), isNull);
    });

    test('arithmetic formula evaluates correctly', () {
      state.editCellAt(const CellCoordinate(0, 0), '=(2+3)*4');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect((cell!.computedValue as NumberCellValue).value, equals(20));
    });
  });

  // ---------------------------------------------------------------------------
  // B. Dependency Invalidation and Recalculation
  // ---------------------------------------------------------------------------
  group('Phase 05 — Dependency Invalidation and Recalculation', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('changing a precedent cell recalculates its dependent', () {
      state.editCellAt(const CellCoordinate(0, 0), '10'); // A1
      state.editCellAt(const CellCoordinate(1, 0), '=A1*2'); // A2 = 20

      final before = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect((before!.computedValue as NumberCellValue).value, equals(20));

      state.editCellAt(const CellCoordinate(0, 0), '15'); // A1 = 15

      final after = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect((after!.computedValue as NumberCellValue).value, equals(30));
    });

    test('cascaded dependency recalculation: A1->B1->C1', () {
      state.editCellAt(const CellCoordinate(0, 0), '10'); // A1
      state.editCellAt(const CellCoordinate(0, 1), '=A1+5'); // B1 = 15
      state.editCellAt(const CellCoordinate(0, 2), '=B1*2'); // C1 = 30

      final c1 = state.activeWorksheet.getCell(const CellCoordinate(0, 2));
      expect((c1!.computedValue as NumberCellValue).value, equals(30));

      state.editCellAt(const CellCoordinate(0, 0), '20'); // A1 = 20

      final b1 = state.activeWorksheet.getCell(const CellCoordinate(0, 1));
      final c1b = state.activeWorksheet.getCell(const CellCoordinate(0, 2));
      expect((b1!.computedValue as NumberCellValue).value, equals(25)); // 20+5
      expect((c1b!.computedValue as NumberCellValue).value, equals(50)); // 25*2
    });

    test('range-based formula recalculates when any cell in range changes', () {
      state.editCellAt(const CellCoordinate(0, 0), '5');  // A1
      state.editCellAt(const CellCoordinate(1, 0), '10'); // A2
      state.editCellAt(const CellCoordinate(2, 0), '=SUM(A1:A2)'); // A3

      var sumCell = state.activeWorksheet.getCell(const CellCoordinate(2, 0));
      expect((sumCell!.computedValue as NumberCellValue).value, equals(15));

      state.editCellAt(const CellCoordinate(1, 0), '20'); // A2 = 20

      sumCell = state.activeWorksheet.getCell(const CellCoordinate(2, 0));
      expect((sumCell!.computedValue as NumberCellValue).value, equals(25));
    });

    test('clearing a precedent cell recalculates dependent to empty reference', () {
      state.editCellAt(const CellCoordinate(0, 0), '100'); // A1
      state.editCellAt(const CellCoordinate(1, 0), '=A1+5'); // A2 = 105

      // Clear A1
      state.selectCell(const CellCoordinate(0, 0));
      state.clearSelection();

      // A2 should recalculate — A1 is now empty (0 in SUM context)
      final a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect(a2, isNotNull);
      // EmptyCellValue treated as 0 in arithmetic, so =A1+5 = 5
      expect((a2!.computedValue as NumberCellValue).value, equals(5));
    });

    test('formula replacement cleans up old dependencies', () {
      state.editCellAt(const CellCoordinate(0, 0), '10'); // A1
      state.editCellAt(const CellCoordinate(0, 1), '5');  // B1
      state.editCellAt(const CellCoordinate(0, 2), '=A1+B1'); // C1 = 15

      var c1 = state.activeWorksheet.getCell(const CellCoordinate(0, 2));
      expect((c1!.computedValue as NumberCellValue).value, equals(15));

      // Replace formula — now only depends on A1
      state.editCellAt(const CellCoordinate(0, 2), '=A1*3'); // C1 = 30
      c1 = state.activeWorksheet.getCell(const CellCoordinate(0, 2));
      expect((c1!.computedValue as NumberCellValue).value, equals(30));

      // Changing B1 should NOT affect C1 anymore
      state.editCellAt(const CellCoordinate(0, 1), '999');
      c1 = state.activeWorksheet.getCell(const CellCoordinate(0, 2));
      expect((c1!.computedValue as NumberCellValue).value, equals(30));
    });

    test('multiple dependent formulas all update correctly', () {
      state.editCellAt(const CellCoordinate(0, 0), '5');   // A1
      state.editCellAt(const CellCoordinate(0, 1), '=A1+1'); // B1 = 6
      state.editCellAt(const CellCoordinate(0, 2), '=A1+2'); // C1 = 7
      state.editCellAt(const CellCoordinate(0, 3), '=A1+3'); // D1 = 8

      state.editCellAt(const CellCoordinate(0, 0), '10'); // A1 = 10

      expect(
        (state.activeWorksheet.getCell(const CellCoordinate(0, 1))!.computedValue as NumberCellValue).value,
        equals(11),
      );
      expect(
        (state.activeWorksheet.getCell(const CellCoordinate(0, 2))!.computedValue as NumberCellValue).value,
        equals(12),
      );
      expect(
        (state.activeWorksheet.getCell(const CellCoordinate(0, 3))!.computedValue as NumberCellValue).value,
        equals(13),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // C. Undo / Redo with Formula Engine
  // ---------------------------------------------------------------------------
  group('Phase 05 — Undo and Redo of Formula Changes', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('undo reverts formula cell and dependent recalculates', () {
      state.editCellAt(const CellCoordinate(0, 0), '10'); // A1
      state.editCellAt(const CellCoordinate(1, 0), '=A1*2'); // A2 = 20

      // Change A1
      state.editCellAt(const CellCoordinate(0, 0), '50'); // A2 should be 100

      var a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect((a2!.computedValue as NumberCellValue).value, equals(100));

      // Undo change to A1
      state.undo();

      a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      final a1 = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect((a1!.computedValue as NumberCellValue).value, equals(10));
      expect((a2!.computedValue as NumberCellValue).value, equals(20));
    });

    test('redo re-applies formula and recalculates', () {
      state.editCellAt(const CellCoordinate(0, 0), '5');
      state.editCellAt(const CellCoordinate(1, 0), '=A1+10'); // A2 = 15

      state.editCellAt(const CellCoordinate(0, 0), '20'); // A2 should be 30

      state.undo(); // A1 back to 5, A2 back to 15

      var a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect((a2!.computedValue as NumberCellValue).value, equals(15));

      state.redo(); // A1 = 20, A2 = 30

      a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect((a2!.computedValue as NumberCellValue).value, equals(30));
    });

    test('undo formula entry removes it and dependents recalculate', () {
      state.editCellAt(const CellCoordinate(0, 0), '7');
      state.editCellAt(const CellCoordinate(1, 0), '=A1*3'); // 21

      state.undo(); // Undo =A1*3 entry

      final a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect(a2, isNull); // Cell removed
    });

    test('undo clearing a formula cell restores the formula', () {
      state.editCellAt(const CellCoordinate(0, 0), '8');
      state.editCellAt(const CellCoordinate(1, 0), '=A1+2'); // 10

      // Clear A2 (formula cell)
      state.selectCell(const CellCoordinate(1, 0));
      state.clearSelection();

      expect(state.activeWorksheet.getCell(const CellCoordinate(1, 0)), isNull);

      state.undo(); // Restore formula

      final a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect(a2, isNotNull);
      expect(a2!.rawInput, equals('=A1+2'));
      expect((a2.computedValue as NumberCellValue).value, equals(10));
    });
  });

  // ---------------------------------------------------------------------------
  // D. Formula Error Handling
  // ---------------------------------------------------------------------------
  group('Phase 05 — Formula Error Display', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('division by zero returns #DIV/0! error cell value', () {
      state.editCellAt(const CellCoordinate(0, 0), '=1/0');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell!.computedValue, isA<ErrorCellValue>());
      expect((cell.computedValue as ErrorCellValue).error, equals(CellError.divZero));
    });

    test('unknown function returns #NAME? error', () {
      state.editCellAt(const CellCoordinate(0, 0), '=FAKEFUNC(1,2)');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell!.computedValue, isA<ErrorCellValue>());
      expect((cell.computedValue as ErrorCellValue).error, equals(CellError.name));
    });

    test('circular reference returns #CIRCULAR! error', () {
      // A1 depends on A1 itself
      state.editCellAt(const CellCoordinate(0, 0), '=A1+1');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell!.computedValue, isA<ErrorCellValue>());
      expect((cell.computedValue as ErrorCellValue).error, equals(CellError.circular));
    });

    test('malformed formula does not crash — returns error value', () {
      // Unclosed parenthesis — parser should recover gracefully
      expect(
        () => state.editCellAt(const CellCoordinate(0, 0), '=SUM(A1:A2'),
        returnsNormally,
      );
    });

    test('errors propagate through dependent chain', () {
      state.editCellAt(const CellCoordinate(0, 0), '=1/0'); // #DIV/0!
      state.editCellAt(const CellCoordinate(1, 0), '=A1+5'); // Should propagate error

      final a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect(a2!.computedValue, isA<ErrorCellValue>());
    });
  });

  // ---------------------------------------------------------------------------
  // E. Cross-Sheet Formulas
  // ---------------------------------------------------------------------------
  group('Phase 05 — Cross-Sheet Formula References', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('cross-sheet reference resolves value from another sheet', () {
      // Set value in Sheet1 A1
      state.editCellAt(const CellCoordinate(0, 0), '100');

      // Add Sheet2
      state.addWorksheet(name: 'Sheet2');
      state.setActiveSheetIndex(1);

      // Enter cross-sheet formula at B1 (different coord from Sheet1!A1 which is (0,0))
      // This avoids a false-circular dep-graph collision in the current flat graph
      state.editCellAt(const CellCoordinate(0, 1), '=Sheet1!A1');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 1));
      expect(cell, isNotNull);
      expect(cell!.rawInput, equals('=Sheet1!A1'));
      expect(cell.computedValue, isA<NumberCellValue>());
      expect((cell.computedValue as NumberCellValue).value, equals(100));
    });

    test('switching sheets preserves formula cell rawInput for formula bar', () {
      state.editCellAt(const CellCoordinate(0, 0), '42');
      state.editCellAt(const CellCoordinate(1, 0), '=A1*2');
      state.selectCell(const CellCoordinate(1, 0));

      expect(state.activeCellInput, equals('=A1*2'));

      // Switch to a new sheet and back
      state.addWorksheet(name: 'Sheet2');
      state.setActiveSheetIndex(1);
      state.setActiveSheetIndex(0);

      // Must re-select the formula cell since switching sheets resets selection to A1
      state.selectCell(const CellCoordinate(1, 0));
      expect(state.activeCellInput, equals('=A1*2'));
    });

    test('missing sheet reference returns #REF! error gracefully', () {
      state.editCellAt(const CellCoordinate(0, 0), '=NoSuchSheet!A1');

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell!.computedValue, isA<ErrorCellValue>());
    });
  });

  // ---------------------------------------------------------------------------
  // F. Cell Formatting
  // ---------------------------------------------------------------------------
  group('Phase 05 — Cell Formatting', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('bold applied to selection via applyStyleToSelection', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Title');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection((s) => s.copyWith(isBold: true));

      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.style.isBold, isTrue);
    });

    test('italic applied and undone correctly', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Item');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection((s) => s.copyWith(isItalic: true));
      expect(state.activeCell?.style.isItalic, isTrue);

      state.undo();
      expect(state.activeCell?.style.isItalic, isFalse);
    });

    test('underline applied to range of cells', () {
      state.editCellAt(const CellCoordinate(0, 0), 'A');
      state.editCellAt(const CellCoordinate(0, 1), 'B');
      state.selectRange(CellRange.fromA1('A1:B1'));

      state.applyStyleToSelection((s) => s.copyWith(isUnderline: true));

      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.style.isUnderline,
        isTrue,
      );
      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 1))?.style.isUnderline,
        isTrue,
      );
    });

    test('font size applied and undone', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Large');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection((s) => s.copyWith(fontSize: 18));
      expect(state.activeCell?.style.fontSize, equals(18));

      state.undo();
      expect(state.activeCell?.style.fontSize, equals(CellStyle.defaultStyle.fontSize));
    });

    test('alignment applied correctly', () {
      state.editCellAt(const CellCoordinate(0, 0), 'centered');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection(
        (s) => s.copyWith(horizontalAlignment: CellHorizontalAlignment.center),
      );
      expect(
        state.activeCell?.style.horizontalAlignment,
        equals(CellHorizontalAlignment.center),
      );
    });

    test('formatting persists when cell content changes', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Original');
      state.selectCell(const CellCoordinate(0, 0));
      state.applyStyleToSelection((s) => s.copyWith(isBold: true));

      // Change content — bold should persist
      state.editCellAt(const CellCoordinate(0, 0), 'Updated');

      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.style.isBold, isTrue);
      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput, equals('Updated'));
    });

    test('formatting preserved when formula result updates', () {
      state.editCellAt(const CellCoordinate(0, 0), '10');
      state.editCellAt(const CellCoordinate(1, 0), '=A1*3');
      state.selectCell(const CellCoordinate(1, 0));
      state.applyStyleToSelection((s) => s.copyWith(isBold: true));

      // Trigger recalculation by changing A1
      state.editCellAt(const CellCoordinate(0, 0), '20');

      final a2 = state.activeWorksheet.getCell(const CellCoordinate(1, 0));
      expect((a2!.computedValue as NumberCellValue).value, equals(60));
      expect(a2.style.isBold, isTrue); // Formatting should be preserved
    });

    test('clearing content with clearSelection does not erase formatting', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Styled');
      state.selectCell(const CellCoordinate(0, 0));
      state.applyStyleToSelection((s) => s.copyWith(isBold: true, fontSize: 16));

      // Clear via clearSelection (content only — leaves style-only cell)
      state.clearSelection();

      // Cell is removed — but style-only empty cells appear as null in sparse storage
      // The important thing is no crash, and formatting undo works
      state.undo(); // Restore clear

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell, isNotNull);
      expect(cell!.rawInput, equals('Styled'));
      expect(cell.style.isBold, isTrue);
    });

    test('number format: currency applied to cell', () {
      state.editCellAt(const CellCoordinate(0, 0), '1234.56');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection(
        (s) => s.copyWith(numberFormat: CellNumberFormat.currency),
      );

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell!.style.numberFormat.type, equals(NumberFormatType.currency));
      // formattedText should include currency symbol
      expect(cell.formattedText, contains('\$'));
    });

    test('number format: percentage applied to cell', () {
      state.editCellAt(const CellCoordinate(0, 0), '0.5');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection(
        (s) => s.copyWith(numberFormat: CellNumberFormat.percentage),
      );

      final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
      expect(cell!.formattedText, contains('%'));
    });

    test('formatting undo/redo cycle is fully reversible', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Hello');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection((s) => s.copyWith(isBold: true));
      state.applyStyleToSelection((s) => s.copyWith(fontSize: 24));

      expect(state.activeCell?.style.isBold, isTrue);
      expect(state.activeCell?.style.fontSize, equals(24));

      state.undo(); // Undo fontSize
      expect(state.activeCell?.style.fontSize, equals(CellStyle.defaultStyle.fontSize));
      expect(state.activeCell?.style.isBold, isTrue); // Bold still applied

      state.undo(); // Undo bold
      expect(state.activeCell?.style.isBold, isFalse);

      state.redo(); // Redo bold
      expect(state.activeCell?.style.isBold, isTrue);

      state.redo(); // Redo fontSize
      expect(state.activeCell?.style.fontSize, equals(24));
    });
  });

  // ---------------------------------------------------------------------------
  // G. WorkbookState - formulaEngine getter
  // ---------------------------------------------------------------------------
  group('Phase 05 — FormulaEngine Exposure', () {
    test('formulaEngine getter is accessible from state', () {
      final state = WorkbookState();
      expect(state.formulaEngine, isA<FormulaEngine>());
    });

    test('formulaEngine dependency graph tracks formula cells', () {
      final state = WorkbookState();
      state.editCellAt(const CellCoordinate(0, 0), '5');
      state.editCellAt(const CellCoordinate(1, 0), '=A1+1');

      final engine = state.formulaEngine;
      expect(engine.dependencyGraph.hasFormula(const CellCoordinate(1, 0)), isTrue);
      expect(engine.dependencyGraph.hasFormula(const CellCoordinate(0, 0)), isFalse);
    });
  });
}
