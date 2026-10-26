import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/sorting/sorting.dart';

void main() {
  group('SortEngine & SortRangeCommand', () {
    late Workbook workbook;
    late Worksheet sheet;
    late WorkbookState state;

    setUp(() {
      workbook = Workbook(id: 'wb1', title: 'Test Workbook');
      sheet = workbook.sheets[0];
      state = WorkbookState(initialWorkbook: workbook);
    });

    test('sorts numeric rows ascending with complete row movement', () {
      // Row 0: Charlie, 30
      // Row 1: Alice, 10
      // Row 2: Bob, 20
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Charlie'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 1), '30'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Alice'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 1), '10'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), 'Bob'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 1), '20'));

      // Sort A1:B3 by Column B (col index 1) ascending
      final options = SortOptions(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(2, 1),
        ),
        sortColumn: 1,
        ascending: true,
      );

      final cmd = SortRangeCommand(
        worksheet: sheet,
        options: options,
        engine: state.formulaEngine,
        workbook: workbook,
      );

      state.executeCommand(cmd);

      // Row 0 should be Alice (10)
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'Alice');
      expect(sheet.getCell(const CellCoordinate(0, 1))?.rawInput, '10');

      // Row 1 should be Bob (20)
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, 'Bob');
      expect(sheet.getCell(const CellCoordinate(1, 1))?.rawInput, '20');

      // Row 2 should be Charlie (30)
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, 'Charlie');
      expect(sheet.getCell(const CellCoordinate(2, 1))?.rawInput, '30');

      // Undo restores original order
      state.undo();
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'Charlie');
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, 'Alice');
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, 'Bob');
    });

    test('sorts text rows descending', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Apple'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Banana'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), 'Cherry'));

      final options = SortOptions(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(2, 0),
        ),
        sortColumn: 0,
        ascending: false,
      );

      final cmd = SortRangeCommand(
        worksheet: sheet,
        options: options,
        engine: state.formulaEngine,
        workbook: workbook,
      );

      state.executeCommand(cmd);

      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'Cherry');
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, 'Banana');
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, 'Apple');
    });

    test('blanks always sort to the bottom in ascending and descending', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '10'));
      // Row 1 is empty
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), '5'));

      // Ascending
      final cmdAsc = SortRangeCommand(
        worksheet: sheet,
        options: SortOptions(
          range: CellRange(
            const CellCoordinate(0, 0),
            const CellCoordinate(2, 0),
          ),
          sortColumn: 0,
          ascending: true,
        ),
        engine: state.formulaEngine,
        workbook: workbook,
      );
      state.executeCommand(cmdAsc);

      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '5');
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, '10');
      expect(sheet.getCell(const CellCoordinate(2, 0)), isNull);

      // Descending
      final cmdDesc = SortRangeCommand(
        worksheet: sheet,
        options: SortOptions(
          range: CellRange(
            const CellCoordinate(0, 0),
            const CellCoordinate(2, 0),
          ),
          sortColumn: 0,
          ascending: false,
        ),
        engine: state.formulaEngine,
        workbook: workbook,
      );
      state.executeCommand(cmdDesc);

      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, '10');
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, '5');
      expect(sheet.getCell(const CellCoordinate(2, 0)), isNull);
    });

    test('preserves header row when hasHeader is true', () {
      // Row 0 is Header
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Name'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 1), 'Score'));

      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Zack'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 1), '50'));

      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), 'Aaron'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 1), '95'));

      final options = SortOptions(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(2, 1),
        ),
        sortColumn: 0,
        ascending: true,
        hasHeader: true,
      );

      final cmd = SortRangeCommand(
        worksheet: sheet,
        options: options,
        engine: state.formulaEngine,
        workbook: workbook,
      );
      state.executeCommand(cmd);

      // Header remains at Row 0
      expect(sheet.getCell(const CellCoordinate(0, 0))?.rawInput, 'Name');
      expect(sheet.getCell(const CellCoordinate(0, 1))?.rawInput, 'Score');

      // Data sorted below header
      expect(sheet.getCell(const CellCoordinate(1, 0))?.rawInput, 'Aaron');
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, 'Zack');
    });

    test('does not touch cells outside chosen range', () {
      // Cell outside range
      sheet.setCell(
        Cell.fromInput(const CellCoordinate(0, 5), 'Outside Value'),
      );

      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'B'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'A'));

      final options = SortOptions(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(1, 0),
        ),
        sortColumn: 0,
        ascending: true,
      );

      final cmd = SortRangeCommand(
        worksheet: sheet,
        options: options,
        engine: state.formulaEngine,
        workbook: workbook,
      );
      state.executeCommand(cmd);

      expect(
        sheet.getCell(const CellCoordinate(0, 5))?.rawInput,
        'Outside Value',
      );
    });
  });
}
