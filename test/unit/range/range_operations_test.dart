import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/core/commands/commands.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('Range & Row/Col Operations', () {
    late Workbook workbook;
    late Worksheet sheet;
    late WorkbookState state;

    setUp(() {
      workbook = Workbook(id: 'wb1', title: 'Test Workbook');
      sheet = workbook.sheets[0];
      state = WorkbookState(initialWorkbook: workbook);
    });

    test('FillDownCommand fills down and adjusts relative references', () {
      // Row 0 has formula =A1*2 in B1
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '10'));
      sheet.setCell(
        const Cell(
          coordinate: CellCoordinate(0, 1),
          rawInput: '=A1*2',
          style: CellStyle(isBold: true),
        ),
      );

      final cmd = FillDownCommand(
        worksheet: sheet,
        range: CellRange(
          const CellCoordinate(0, 1),
          const CellCoordinate(2, 1),
        ),
        engine: state.formulaEngine,
        workbook: workbook,
      );

      state.executeCommand(cmd);

      // B2 (Row 1, Col 1) should be =A2*2 with bold style preserved
      final cellB2 = sheet.getCell(const CellCoordinate(1, 1));
      expect(cellB2?.rawInput, '=A2*2');
      expect(cellB2?.style.isBold, isTrue);

      // B3 (Row 2, Col 1) should be =A3*2
      final cellB3 = sheet.getCell(const CellCoordinate(2, 1));
      expect(cellB3?.rawInput, '=A3*2');

      // Undo restores B2 and B3 to null
      state.undo();
      expect(sheet.getCell(const CellCoordinate(1, 1)), isNull);
      expect(sheet.getCell(const CellCoordinate(2, 1)), isNull);
    });

    test('FillRightCommand fills right and adjusts relative references', () {
      // A1 has formula =A2+1
      sheet.setCell(
        const Cell(
          coordinate: CellCoordinate(0, 0),
          rawInput: '=A2+1',
          style: CellStyle(isItalic: true),
        ),
      );

      final cmd = FillRightCommand(
        worksheet: sheet,
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(0, 2),
        ),
        engine: state.formulaEngine,
        workbook: workbook,
      );

      state.executeCommand(cmd);

      // B1 (0, 1) should be =B2+1
      expect(sheet.getCell(const CellCoordinate(0, 1))?.rawInput, '=B2+1');
      expect(sheet.getCell(const CellCoordinate(0, 1))?.style.isItalic, isTrue);

      // C1 (0, 2) should be =C2+1
      expect(sheet.getCell(const CellCoordinate(0, 2))?.rawInput, '=C2+1');

      // Undo
      state.undo();
      expect(sheet.getCell(const CellCoordinate(0, 1)), isNull);
      expect(sheet.getCell(const CellCoordinate(0, 2)), isNull);
    });

    test('DuplicateRangeCommand duplicates range with reference shift', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '100'));
      sheet.setCell(
        const Cell(
          coordinate: CellCoordinate(0, 1),
          rawInput: '=A1*2',
          style: CellStyle(isUnderline: true),
        ),
      );

      final cmd = DuplicateRangeCommand(
        worksheet: sheet,
        sourceRange: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(0, 1),
        ),
        targetTopLeft: const CellCoordinate(5, 2), // C6
        engine: state.formulaEngine,
        workbook: workbook,
      );

      state.executeCommand(cmd);

      // C6 (5, 2) should be '100'
      expect(sheet.getCell(const CellCoordinate(5, 2))?.rawInput, '100');
      // D6 (5, 3) should be =C6*2 (A1 shifted by +5 rows and +2 cols = C6)
      final cellD6 = sheet.getCell(const CellCoordinate(5, 3));
      expect(cellD6?.rawInput, '=C6*2');
      expect(cellD6?.style.isUnderline, isTrue);

      // Undo
      state.undo();
      expect(sheet.getCell(const CellCoordinate(5, 2)), isNull);
      expect(sheet.getCell(const CellCoordinate(5, 3)), isNull);
    });

    test('InsertRowsCommand shifts rows down and updates formulas', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '10'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), '20'));
      sheet.setCell(
        const Cell(coordinate: CellCoordinate(2, 0), rawInput: '=A1+A2'),
      );

      // Insert 1 row at index 1 (between row 0 and row 1)
      final cmd = InsertRowsCommand(
        worksheet: sheet,
        startRow: 1,
        count: 1,
        engine: state.formulaEngine,
        workbook: workbook,
      );

      state.executeCommand(cmd);

      // Row 0 is still '10'
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
      // Row 1 is newly inserted (empty)
      expect(sheet.getCell(const CellCoordinate(1, 0)), isNull);
      // Row 2 is previous row 1 ('20')
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, '20');
      // Row 3 is previous row 2, with updated formula referencing shifted A2 -> A3: '=A1+A3'
      expect(sheet.getCell(const CellCoordinate(3, 0))?.rawInput, '=A1+A3');

      // Undo
      state.undo();
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, '20');
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, '=A1+A2');
    });

    test(
      'DeleteRowsCommand deletes rows and converts deleted references to #REF!',
      () {
        sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '10'));
        sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), '20'));
        sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), '30'));
        sheet.setCell(
          const Cell(coordinate: CellCoordinate(3, 0), rawInput: '=A1+A2+A3'),
        );

        // Delete Row index 1 (A2)
        final cmd = DeleteRowsCommand(
          worksheet: sheet,
          startRow: 1,
          count: 1,
          engine: state.formulaEngine,
          workbook: workbook,
        );

        state.executeCommand(cmd);

        // Row 0 is '10'
        expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
        // Row 1 is previous Row 2 ('30')
        expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, '30');
        // Row 2 is previous Row 3, with formula '=A1+#REF!+A2'
        expect(
          sheet.getCell(const CellCoordinate(2, 0))?.rawInput,
          '=A1+#REF!+A2',
        );

        // Undo
        state.undo();
        expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
        expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, '20');
        expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, '30');
        expect(
          sheet.getCell(const CellCoordinate(3, 0))?.rawInput,
          '=A1+A2+A3',
        );
      },
    );

    test('InsertColumnsCommand shifts columns right and updates formulas', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '10'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 1), '20'));
      sheet.setCell(
        const Cell(coordinate: CellCoordinate(0, 2), rawInput: '=A1+B1'),
      );

      // Insert column at B (index 1)
      final cmd = InsertColumnsCommand(
        worksheet: sheet,
        startCol: 1,
        count: 1,
        engine: state.formulaEngine,
        workbook: workbook,
      );

      state.executeCommand(cmd);

      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
      expect(sheet.getCell(const CellCoordinate(0, 1)), isNull);
      expect(sheet.getCell(const CellCoordinate(0, 2))?.rawInput, '20');
      expect(sheet.getCell(const CellCoordinate(0, 3))?.rawInput, '=A1+C1');

      // Undo
      state.undo();
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
      expect(sheet.getCell(const CellCoordinate(0, 1))?.rawInput, '20');
      expect(sheet.getCell(const CellCoordinate(0, 2))?.rawInput, '=A1+B1');
    });

    test(
      'DeleteColumnsCommand deletes columns and turns references into #REF!',
      () {
        sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '10'));
        sheet.setCell(Cell.fromInput(const CellCoordinate(0, 1), '20'));
        sheet.setCell(
          const Cell(coordinate: CellCoordinate(0, 2), rawInput: '=A1+B1'),
        );

        // Delete Column B (index 1)
        final cmd = DeleteColumnsCommand(
          worksheet: sheet,
          startCol: 1,
          count: 1,
          engine: state.formulaEngine,
          workbook: workbook,
        );

        state.executeCommand(cmd);

        expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
        expect(
          sheet.getCell(const CellCoordinate(0, 1))?.rawInput,
          '=A1+#REF!',
        );

        // Undo
        state.undo();
        expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
        expect(sheet.getCell(const CellCoordinate(0, 1))?.rawInput, '20');
        expect(sheet.getCell(const CellCoordinate(0, 2))?.rawInput, '=A1+B1');
      },
    );
  });
}
