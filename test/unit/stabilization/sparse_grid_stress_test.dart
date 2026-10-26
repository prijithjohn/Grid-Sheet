import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/core/commands/range_commands.dart';

void main() {
  group('Phase 09: Sparse Grid & Viewport Offset Performance Tests', () {
    late Worksheet sheet;
    late Workbook workbook;

    setUp(() {
      workbook = Workbook.createDefault();
      sheet = workbook.sheets[0];
    });

    test('Distant cells at row 100,000 and col 15,000 have instant O(1) offset calculations', () {
      sheet.setCell(
        Cell.fromInput(const CellCoordinate(100000, 15000), 'Distant'),
      );

      final sw = Stopwatch()..start();
      final rowOffset = sheet.getRowOffset(100000);
      final colOffset = sheet.getColumnOffset(15000);
      sw.stop();

      // Calculation must be instantaneous (under 5 milliseconds)
      expect(sw.elapsedMilliseconds, lessThan(5));
      expect(rowOffset, equals(100000 * Worksheet.defaultRowHeight));
      expect(colOffset, equals(15000 * Worksheet.defaultColumnWidth));

      // Reverse lookup
      final targetRow = sheet.getRowAtOffset(rowOffset + 5);
      final targetCol = sheet.getColumnAtOffset(colOffset + 10);
      expect(targetRow, equals(100000));
      expect(targetCol, equals(15000));
    });

    test('clearRange on entire 1,000,000 row sheet runs instantaneously without iterating empty cells', () {
      // Populate 3 distant cells
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'A1'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(5000, 10), 'Mid'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(999999, 100), 'End'));

      expect(sheet.populatedCellCount, equals(3));

      // Clear the entire 1,000,000 row range
      final sw = Stopwatch()..start();
      sheet.clearRange(
        CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(
            CellCoordinate.maxRows - 1,
            CellCoordinate.maxCols - 1,
          ),
        ),
      );
      sw.stop();

      // Must complete in under 20 milliseconds (proves no 17-billion iteration loop)
      expect(sw.elapsedMilliseconds, lessThan(20));
      expect(sheet.populatedCellCount, equals(0));
    });

    test('clearCells preserves custom column widths, row heights, and freeze panes', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '100'));
      sheet.setColumnWidth(0, 150.0);
      sheet.setRowHeight(0, 45.0);
      sheet.freezePanes(rows: 1, cols: 1);

      sheet.clearCells();

      // Cells removed
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNull);
      // Dimensions and freeze settings preserved
      expect(sheet.getColumnWidth(0), equals(150.0));
      expect(sheet.getRowHeight(0), equals(45.0));
      expect(sheet.frozenRows, equals(1));
      expect(sheet.frozenCols, equals(1));
    });

    test('Undoing InsertRowsCommand preserves custom column widths', () {
      final engine = FormulaEngine();
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Item'));
      sheet.setColumnWidth(0, 180.0);

      final cmd = InsertRowsCommand(
        worksheet: sheet,
        startRow: 0,
        count: 1,
        engine: engine,
        workbook: workbook,
      );

      cmd.execute();
      expect(sheet.getColumnWidth(0), equals(180.0));

      cmd.undo();
      // Custom column width must still be 180.0 after undoing row insertion
      expect(sheet.getColumnWidth(0), equals(180.0));
      expect(
        sheet.getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Item'),
      );
    });

    test('Undoing InsertColumnsCommand preserves custom row heights', () {
      final engine = FormulaEngine();
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Item'));
      sheet.setRowHeight(0, 50.0);

      final cmd = InsertColumnsCommand(
        worksheet: sheet,
        startCol: 0,
        count: 1,
        engine: engine,
        workbook: workbook,
      );

      cmd.execute();
      expect(sheet.getRowHeight(0), equals(50.0));

      cmd.undo();
      // Custom row height must still be 50.0 after undoing column insertion
      expect(sheet.getRowHeight(0), equals(50.0));
      expect(
        sheet.getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Item'),
      );
    });

    test('Worksheet boundary coordinate limits (XFD1048576) do not overflow or wrap', () {
      const maxCoord = CellCoordinate(
        CellCoordinate.maxRows - 1,
        CellCoordinate.maxCols - 1,
      );
      expect(maxCoord.row, equals(1048575));
      expect(maxCoord.col, equals(16383));
      expect(maxCoord.a1, equals('XFD1048576'));

      sheet.setCell(Cell.fromInput(maxCoord, 'Corner'));
      expect(sheet.getCell(maxCoord)?.rawInput, equals('Corner'));
    });
  });
}
