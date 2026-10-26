import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/find_replace/find_replace.dart';

void main() {
  group('FindReplaceEngine', () {
    const engine = FindReplaceEngine();
    late Workbook workbook;
    late Worksheet sheet1;
    late Worksheet sheet2;

    setUp(() {
      workbook = Workbook(id: 'wb1', title: 'Test Workbook');
      sheet1 = workbook.sheets[0];
      sheet2 = workbook.createSheet(name: 'Sheet2');

      // Populate sheet 1
      sheet1.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Apple'));
      sheet1.setCell(Cell.fromInput(const CellCoordinate(0, 1), 'Pineapple'));
      sheet1.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'banana'));
      sheet1.setCell(Cell.fromInput(const CellCoordinate(1, 1), 'apple pie'));

      // Formula cell: displays "42" from =SUM(20, 22)
      sheet1.setCell(
        Cell(
          coordinate: const CellCoordinate(2, 0),
          rawInput: '=SUM(20, 22)',
          computedValue: const NumberCellValue(42),
          style: CellStyle.defaultStyle,
        ),
      );

      // Populate sheet 2
      sheet2.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Apple Cider'));
    });

    test(
      'case-insensitive search finds all substring occurrences in active sheet',
      () {
        final results = engine.findAll(
          workbook: workbook,
          activeSheetIndex: 0,
          options: const FindReplaceOptions(query: 'apple'),
        );

        expect(results.length, 3);
        expect(results[0].coordinate, const CellCoordinate(0, 0)); // Apple
        expect(results[1].coordinate, const CellCoordinate(0, 1)); // Pineapple
        expect(results[2].coordinate, const CellCoordinate(1, 1)); // apple pie
      },
    );

    test('case-sensitive search respects case', () {
      final results = engine.findAll(
        workbook: workbook,
        activeSheetIndex: 0,
        options: const FindReplaceOptions(query: 'Apple', matchCase: true),
      );

      expect(results.length, 1);
      expect(results[0].coordinate, const CellCoordinate(0, 0));
    });

    test('matchEntireCell matches only full cell text', () {
      final results = engine.findAll(
        workbook: workbook,
        activeSheetIndex: 0,
        options: const FindReplaceOptions(
          query: 'apple',
          matchEntireCell: true,
        ),
      );

      expect(results.length, 1);
      expect(results[0].coordinate, const CellCoordinate(0, 0));
    });

    test('searchWorkbook traverses all sheets in workbook', () {
      final results = engine.findAll(
        workbook: workbook,
        activeSheetIndex: 0,
        options: const FindReplaceOptions(query: 'apple', searchWorkbook: true),
      );

      // 3 in Sheet1 + 1 in Sheet2 = 4
      expect(results.length, 4);
      expect(results[3].worksheetName, 'Sheet2');
      expect(results[3].coordinate, const CellCoordinate(0, 0));
    });

    test('searchFormulas = true searches raw formula input', () {
      final results = engine.findAll(
        workbook: workbook,
        activeSheetIndex: 0,
        options: const FindReplaceOptions(query: 'SUM', searchFormulas: true),
      );

      expect(results.length, 1);
      expect(results[0].coordinate, const CellCoordinate(2, 0));
      expect(results[0].matchedText, '=SUM(20, 22)');
    });

    test(
      'searchFormulas = false searches displayed value instead of formula',
      () {
        final results = engine.findAll(
          workbook: workbook,
          activeSheetIndex: 0,
          options: const FindReplaceOptions(query: '42', searchFormulas: false),
        );

        expect(results.length, 1);
        expect(results[0].coordinate, const CellCoordinate(2, 0));
        expect(results[0].matchedText, '42');
      },
    );

    test('empty query returns no matches', () {
      final results = engine.findAll(
        workbook: workbook,
        activeSheetIndex: 0,
        options: const FindReplaceOptions(query: ''),
      );
      expect(results, isEmpty);
    });
  });

  group('Replace Commands & Undo/Redo', () {
    late WorkbookState state;

    setUp(() {
      final workbook = Workbook(id: 'wb1', title: 'Test Workbook');
      final sheet = workbook.sheets[0];
      sheet.setCell(
        Cell.fromInput(
          const CellCoordinate(0, 0),
          'Item 1',
          style: const CellStyle(isBold: true),
        ),
      );
      sheet.setCell(
        Cell.fromInput(
          const CellCoordinate(0, 1),
          'Item 2',
          style: const CellStyle(isItalic: true),
        ),
      );
      sheet.setCell(
        Cell.fromInput(const CellCoordinate(1, 0), 'Other Product'),
      );

      state = WorkbookState(initialWorkbook: workbook);
    });

    test(
      'ReplaceMatchCommand replaces single match and preserves cell style',
      () {
        const match = FindReplaceMatch(
          worksheetIndex: 0,
          worksheetName: 'Sheet1',
          coordinate: CellCoordinate(0, 0),
          matchedText: 'Item 1',
          isFormula: false,
        );

        final cmd = ReplaceMatchCommand(
          workbook: state.workbook,
          match: match,
          options: const FindReplaceOptions(
            query: 'Item',
            replacement: 'Product',
          ),
          engine: state.formulaEngine,
        );

        state.executeCommand(cmd);

        final cell = state.activeWorksheet.getCell(const CellCoordinate(0, 0));
        expect(cell?.rawInput, 'Product 1');
        expect(cell?.style.isBold, isTrue); // formatting preserved

        // Undo
        state.undo();
        final restored = state.activeWorksheet.getCell(
          const CellCoordinate(0, 0),
        );
        expect(restored?.rawInput, 'Item 1');
        expect(restored?.style.isBold, isTrue);
      },
    );

    test(
      'ReplaceAllCommand replaces all occurrences as a single undoable step',
      () {
        final matches = [
          const FindReplaceMatch(
            worksheetIndex: 0,
            worksheetName: 'Sheet1',
            coordinate: CellCoordinate(0, 0),
            matchedText: 'Item 1',
            isFormula: false,
          ),
          const FindReplaceMatch(
            worksheetIndex: 0,
            worksheetName: 'Sheet1',
            coordinate: CellCoordinate(0, 1),
            matchedText: 'Item 2',
            isFormula: false,
          ),
        ];

        final cmd = ReplaceAllCommand(
          workbook: state.workbook,
          matches: matches,
          options: const FindReplaceOptions(query: 'Item', replacement: 'SKU'),
          engine: state.formulaEngine,
        );

        state.executeCommand(cmd);

        expect(cmd.replacedCount, 2);
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput,
          'SKU 1',
        );
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 1))?.rawInput,
          'SKU 2',
        );
        expect(
          state.activeWorksheet
              .getCell(const CellCoordinate(0, 1))
              ?.style
              .isItalic,
          isTrue,
        );

        // Undo
        state.undo();
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput,
          'Item 1',
        );
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 1))?.rawInput,
          'Item 2',
        );

        // Redo
        state.redo();
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput,
          'SKU 1',
        );
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 1))?.rawInput,
          'SKU 2',
        );
      },
    );
  });
}
