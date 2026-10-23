import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/domain/cell/cell_range.dart';
import 'package:grid_sheet/domain/workbook/workbook_model.dart';
import 'package:grid_sheet/domain/worksheet/worksheet_model.dart';

void main() {
  group('Workbook - Initialization & Invariants', () {
    test('initializes with a default Sheet1 if no initial sheets provided', () {
      final workbook = Workbook(id: 'wb_1');
      expect(workbook.sheetCount, 1);
      expect(workbook.activeSheetIndex, 0);
      expect(workbook.activeSheet.name, 'Sheet1');
      expect(workbook.title, 'Untitled.gsheet');
    });

    test('initializes with provided sheets', () {
      final s1 = Worksheet(id: 's1', name: 'Revenue');
      final s2 = Worksheet(id: 's2', name: 'Expenses');

      final workbook = Workbook(
        id: 'wb_custom',
        title: 'Budget 2026.xlsx',
        initialSheets: [s1, s2],
      );

      expect(workbook.sheetCount, 2);
      expect(workbook.activeSheetIndex, 0);
      expect(workbook.activeSheet.name, 'Revenue');
      expect(workbook.sheets[1].name, 'Expenses');
    });
  });

  group('Workbook - Sheet Tab CRUD Operations', () {
    late Workbook workbook;

    setUp(() {
      workbook = Workbook(id: 'wb_test');
    });

    test('createSheet generates unique sequential names', () {
      final s2 = workbook.createSheet();
      expect(s2.name, 'Sheet2');
      expect(workbook.sheetCount, 2);

      final s3 = workbook.createSheet();
      expect(s3.name, 'Sheet3');
      expect(workbook.sheetCount, 3);
    });

    test('createSheet with custom name succeeds when unique', () {
      final custom = workbook.createSheet(name: 'Forecast');
      expect(custom.name, 'Forecast');
      expect(workbook.sheetCount, 2);
    });

    test('createSheet rejects duplicate sheet names (case-insensitive)', () {
      expect(() => workbook.createSheet(name: 'Sheet1'), throwsArgumentError);
      expect(() => workbook.createSheet(name: 'sheet1'), throwsArgumentError);
    });

    test('renameSheet renames sheet successfully', () {
      workbook.renameSheet(0, 'Overview');
      expect(workbook.activeSheet.name, 'Overview');
      expect(workbook.containsSheetName('Overview'), isTrue);
      expect(workbook.containsSheetName('Sheet1'), isFalse);
    });

    test('renameSheet rejects collisions with existing sheets', () {
      workbook.createSheet(name: 'Sheet2');
      expect(() => workbook.renameSheet(0, 'Sheet2'), throwsArgumentError);
      expect(() => workbook.renameSheet(0, 'sheet2'), throwsArgumentError);
    });

    test('removeSheetAt removes sheet and adjusts active index', () {
      workbook.createSheet(name: 'Sheet2');
      final s3 = workbook.createSheet(name: 'Sheet3');

      // 3 sheets: Sheet1 (0), Sheet2 (1), Sheet3 (2)
      workbook.activeSheetIndex = 2; // Active is Sheet3
      expect(workbook.activeSheet, equals(s3));

      // Remove middle sheet (Sheet2)
      workbook.removeSheetAt(1);

      expect(workbook.sheetCount, 2);
      // Active index should shift from 2 to 1 (still pointing to Sheet3)
      expect(workbook.activeSheetIndex, 1);
      expect(workbook.activeSheet.name, 'Sheet3');

      // Remove Sheet3 (now at index 1)
      workbook.removeSheetAt(1);
      expect(workbook.sheetCount, 1);
      expect(workbook.activeSheetIndex, 0);
      expect(workbook.activeSheet.name, 'Sheet1');
    });

    test('cannot remove the last remaining worksheet in a workbook', () {
      expect(workbook.sheetCount, 1);
      expect(() => workbook.removeSheetAt(0), throwsStateError);
      expect(workbook.sheetCount, 1);
    });
  });

  group('Workbook - Tab Reordering', () {
    late Workbook workbook;

    setUp(() {
      workbook = Workbook(
        id: 'wb',
        initialSheets: [
          Worksheet(id: 's1', name: 'Tab A'),
          Worksheet(id: 's2', name: 'Tab B'),
          Worksheet(id: 's3', name: 'Tab C'),
        ],
      );
    });

    test('reorders sheets and updates active index tracking', () {
      workbook.activeSheetIndex = 0; // Tab A is active

      // Move Tab A from index 0 to index 2
      workbook.reorderSheet(0, 2);

      expect(workbook.sheets[0].name, 'Tab B');
      expect(workbook.sheets[1].name, 'Tab C');
      expect(workbook.sheets[2].name, 'Tab A');

      // Active sheet index should follow Tab A to index 2
      expect(workbook.activeSheetIndex, 2);
      expect(workbook.activeSheet.name, 'Tab A');
    });

    test(
      'reorder preserves active sheet when another sheet moves around it',
      () {
        workbook.activeSheetIndex = 1; // Tab B is active (index 1)

        // Move Tab C from index 2 to index 0
        workbook.reorderSheet(2, 0);

        expect(workbook.sheets[0].name, 'Tab C');
        expect(workbook.sheets[1].name, 'Tab A');
        expect(workbook.sheets[2].name, 'Tab B');

        // Active sheet index should shift from 1 to 2 to follow Tab B
        expect(workbook.activeSheetIndex, 2);
        expect(workbook.activeSheet.name, 'Tab B');
      },
    );
  });

  group('Workbook - Named Ranges & Lookups', () {
    late Workbook workbook;

    setUp(() {
      workbook = Workbook(id: 'wb');
    });

    test('manages named ranges', () {
      final range = CellRange.fromA1('A1:B10');
      workbook.setNamedRange('QuarterlySales', range);

      expect(workbook.getNamedRange('QuarterlySales'), equals(range));
      expect(workbook.getNamedRange('NonExistent'), isNull);
    });

    test('lookups by name and id', () {
      final sheet = workbook.createSheet(name: 'Summary');

      expect(workbook.getSheetByName('Summary'), equals(sheet));
      expect(
        workbook.getSheetByName('summary'),
        equals(sheet),
      ); // Case-insensitive
      expect(workbook.getSheetById(sheet.id), equals(sheet));
      expect(workbook.getSheetByName('Unknown'), isNull);
    });
  });
}
