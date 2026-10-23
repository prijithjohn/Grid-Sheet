import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/cell/cell_coordinate.dart';
import 'package:grid_sheet/domain/cell/cell_model.dart';
import 'package:grid_sheet/domain/cell/cell_range.dart';
import 'package:grid_sheet/domain/worksheet/worksheet_model.dart';

void main() {
  group('Worksheet - Construction & Name Validation', () {
    test('constructs worksheet with valid name', () {
      final sheet = Worksheet(id: 'sheet_1', name: 'Expenses 2026');
      expect(sheet.id, 'sheet_1');
      expect(sheet.name, 'Expenses 2026');
      expect(sheet.populatedCellCount, 0);
    });

    test('trims whitespace from sheet names', () {
      final sheet = Worksheet(id: 'sheet_1', name: '  Summary  ');
      expect(sheet.name, 'Summary');
    });

    test('rejects empty or whitespace-only sheet names', () {
      expect(() => Worksheet(id: 's', name: ''), throwsArgumentError);
      expect(() => Worksheet(id: 's', name: '   '), throwsArgumentError);
    });

    test('rejects sheet names exceeding 31 characters', () {
      const longName = 'ThisNameIsWayTooLongForAnExcelSheetTabAndShouldFail';
      expect(() => Worksheet(id: 's', name: longName), throwsArgumentError);
    });

    test('rejects forbidden characters in sheet names', () {
      final forbidden = [
        r'Sheet\1',
        'Sheet/1',
        'Sheet?1',
        'Sheet*1',
        'Sheet[1]',
        'Sheet:1',
      ];
      for (final name in forbidden) {
        expect(
          () => Worksheet(id: 's', name: name),
          throwsArgumentError,
          reason: 'Should reject forbidden name: $name',
        );
      }
    });

    test('updating name enforces the same validation rules', () {
      final sheet = Worksheet(id: 's', name: 'Valid');
      expect(() => sheet.name = 'Invalid/Name', throwsArgumentError);
      expect(sheet.name, 'Valid'); // Preserved
    });
  });

  group('Worksheet - Sparse Matrix Storage & Operations', () {
    late Worksheet sheet;

    setUp(() {
      sheet = Worksheet(id: 'test_sheet', name: 'Data');
    });

    test('unpopulated cells return null from getCell and empty cell from getCellOrEmpty', () {
      const coord = CellCoordinate(5, 5);
      expect(sheet.getCell(coord), isNull);

      final fallback = sheet.getCellOrEmpty(coord);
      expect(fallback.coordinate, coord);
      expect(fallback.isEmpty, isTrue);
    });

    test('stores and retrieves cells accurately in sparse matrix', () {
      final cellA1 = Cell.fromInput(const CellCoordinate(0, 0), 'Header');
      final cellB2 = Cell.fromInput(const CellCoordinate(1, 1), '100');

      sheet.setCell(cellA1);
      sheet.setCell(cellB2);

      expect(sheet.populatedCellCount, 2);
      expect(sheet.getCell(const CellCoordinate(0, 0)), equals(cellA1));
      expect(sheet.getCell(const CellCoordinate(1, 1)), equals(cellB2));
    });

    test('demonstrates sparse efficiency with scattered coordinates across large grid', () {
      // Cell at top-left (0, 0) and cell at extreme bottom-right (999,999, 16,383)
      final c1 = Cell.fromInput(const CellCoordinate(0, 0), 'Start');
      final c2 = Cell.fromInput(const CellCoordinate(999999, 16383), 'Extreme');

      sheet.setCell(c1);
      sheet.setCell(c2);

      // Only 2 cells stored in sparse matrix
      expect(sheet.populatedCellCount, 2);
      expect(sheet.maxPopulatedRow, 999999);
      expect(sheet.maxPopulatedCol, 16383);
    });

    test('removing cell updates sparse matrix and cell count', () {
      final cell = Cell.fromInput(const CellCoordinate(2, 3), 'Temp');
      sheet.setCell(cell);
      expect(sheet.populatedCellCount, 1);

      sheet.removeCell(const CellCoordinate(2, 3));
      expect(sheet.populatedCellCount, 0);
      expect(sheet.getCell(const CellCoordinate(2, 3)), isNull);
    });

    test('clearRange removes only cells within bounding range', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Keep Top'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 2), 'Delete 1'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(3, 3), 'Delete 2'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(5, 5), 'Keep Bottom'));

      expect(sheet.populatedCellCount, 4);

      // Clear range B2:D4 (rows 1..3, cols 1..3)
      final range = CellRange.fromA1('B2:D4');
      sheet.clearRange(range);

      expect(sheet.populatedCellCount, 2);
      expect(sheet.getCell(const CellCoordinate(0, 0)), isNotNull);
      expect(sheet.getCell(const CellCoordinate(5, 5)), isNotNull);
      expect(sheet.getCell(const CellCoordinate(2, 2)), isNull);
      expect(sheet.getCell(const CellCoordinate(3, 3)), isNull);
    });

    test('clear resets the entire worksheet', () {
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), '1'));
      sheet.setColumnWidth(0, 150.0);
      sheet.setRowHeight(0, 40.0);

      sheet.clear();

      expect(sheet.populatedCellCount, 0);
      expect(sheet.maxPopulatedRow, -1);
      expect(sheet.maxPopulatedCol, -1);
      expect(sheet.getColumnWidth(0), Worksheet.defaultColumnWidth);
      expect(sheet.getRowHeight(0), Worksheet.defaultRowHeight);
    });
  });

  group('Worksheet - Dimension Metadata (Column Widths & Row Heights)', () {
    late Worksheet sheet;

    setUp(() {
      sheet = Worksheet(id: 'sheet', name: 'Sheet1');
    });

    test('returns default dimensions when no custom overrides are set', () {
      expect(sheet.getColumnWidth(0), Worksheet.defaultColumnWidth);
      expect(sheet.getRowHeight(0), Worksheet.defaultRowHeight);
    });

    test('sets and preserves custom column width and row height', () {
      sheet.setColumnWidth(2, 120.0);
      sheet.setRowHeight(4, 35.0);

      expect(sheet.getColumnWidth(2), 120.0);
      expect(sheet.getRowHeight(4), 35.0);

      // Other columns/rows retain defaults
      expect(sheet.getColumnWidth(0), Worksheet.defaultColumnWidth);
      expect(sheet.getRowHeight(0), Worksheet.defaultRowHeight);
    });

    test('clamps dimensions to minimum thresholds to prevent UI collapse', () {
      sheet.setColumnWidth(1, 5.0); // Below min 20.0
      expect(sheet.getColumnWidth(1), Worksheet.minColumnWidth);

      sheet.setRowHeight(1, 10.0); // Below min 16.0
      expect(sheet.getRowHeight(1), Worksheet.minRowHeight);
    });
  });
}
