import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('Filtering', () {
    late Workbook workbook;
    late Worksheet sheet;
    late WorkbookState state;

    setUp(() {
      workbook = Workbook(id: 'wb1', title: 'Test Workbook');
      sheet = workbook.sheets[0];

      // Row 0: Headers
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 0), 'Department'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(0, 1), 'Sales'));

      // Row 1: Electronics, 1500
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 0), 'Electronics'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(1, 1), '1500'));

      // Row 2: Clothing, 800
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 0), 'Clothing'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(2, 1), '800'));

      // Row 3: Electronics, 450
      sheet.setCell(Cell.fromInput(const CellCoordinate(3, 0), 'Electronics'));
      sheet.setCell(Cell.fromInput(const CellCoordinate(3, 1), '450'));

      // Row 4: Home & Kitchen, blank sales
      sheet.setCell(
        Cell.fromInput(const CellCoordinate(4, 0), 'Home & Kitchen'),
      );

      state = WorkbookState(initialWorkbook: workbook);
    });

    test('WorksheetFilter filters by text contains and preserves header', () {
      final filter = WorksheetFilter(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(4, 1),
        ),
      );

      // Filter Column 0 for contains 'Electro'
      filter.setColumnFilter(
        0,
        const ColumnFilterCriteria(textContains: 'Electro'),
      );
      filter.apply(sheet);

      // Header row 0 is NEVER hidden
      expect(sheet.isRowHidden(0), isFalse);
      expect(sheet.getRowHeight(0), Worksheet.defaultRowHeight);

      // Row 1 (Electronics) visible
      expect(sheet.isRowHidden(1), isFalse);

      // Row 2 (Clothing) hidden
      expect(sheet.isRowHidden(2), isTrue);
      expect(sheet.getRowHeight(2), 0.0);

      // Row 3 (Electronics) visible
      expect(sheet.isRowHidden(3), isFalse);

      // Row 4 (Home & Kitchen) hidden
      expect(sheet.isRowHidden(4), isTrue);

      // Underlying data is preserved completely
      expect(sheet.getCell(const CellCoordinate(2, 0))?.rawInput, 'Clothing');
      expect(sheet.getCell(const CellCoordinate(2, 1))?.rawInput, '800');
    });

    test('WorksheetFilter filters by numeric comparisons', () {
      final filter = WorksheetFilter(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(4, 1),
        ),
      );

      // Filter Column 1 (Sales) for >= 1000
      filter.setColumnFilter(
        1,
        const ColumnFilterCriteria(
          numericOp: NumericFilterOp.greaterThanOrEqual,
          numericValue: 1000,
        ),
      );
      filter.apply(sheet);

      // Row 1 (1500) visible
      expect(sheet.isRowHidden(1), isFalse);

      // Row 2 (800) hidden
      expect(sheet.isRowHidden(2), isTrue);

      // Row 3 (450) hidden
      expect(sheet.isRowHidden(3), isTrue);

      // Row 4 (blank) hidden by numeric filter
      expect(sheet.isRowHidden(4), isTrue);
    });

    test('WorksheetFilter hideBlanks hides empty cells', () {
      final filter = WorksheetFilter(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(4, 1),
        ),
      );

      filter.setColumnFilter(1, const ColumnFilterCriteria(hideBlanks: true));
      filter.apply(sheet);

      expect(sheet.isRowHidden(1), isFalse);
      expect(sheet.isRowHidden(2), isFalse);
      expect(sheet.isRowHidden(3), isFalse);
      // Row 4 has blank sales, so it is hidden
      expect(sheet.isRowHidden(4), isTrue);
    });

    test('clearColumnFilter and clearAll restore all rows', () {
      final filter = WorksheetFilter(
        range: CellRange(
          const CellCoordinate(0, 0),
          const CellCoordinate(4, 1),
        ),
      );

      filter.setColumnFilter(
        0,
        const ColumnFilterCriteria(textEquals: 'Clothing'),
      );
      filter.apply(sheet);

      expect(sheet.isRowHidden(1), isTrue);
      expect(sheet.isRowHidden(2), isFalse);

      // Clear filter
      filter.clearAll();
      filter.apply(sheet);

      expect(sheet.isRowHidden(1), isFalse);
      expect(sheet.isRowHidden(2), isFalse);
      expect(sheet.isRowHidden(3), isFalse);
      expect(sheet.isRowHidden(4), isFalse);
    });

    test('WorkbookState toggleFilter and applyColumnFilter workflow', () {
      // Initially no filter
      expect(sheet.filter, isNull);

      // Select range and toggle
      state.selectRange(
        CellRange(const CellCoordinate(0, 0), const CellCoordinate(4, 1)),
      );
      state.toggleFilter();

      expect(sheet.filter, isNotNull);

      // Apply filter on Department
      state.applyColumnFilter(
        0,
        const ColumnFilterCriteria(textEquals: 'Clothing'),
      );
      expect(sheet.isRowHidden(1), isTrue);
      expect(sheet.isRowHidden(2), isFalse);

      // Toggle off clears all hidden rows
      state.toggleFilter();
      expect(sheet.filter, isNull);
      expect(sheet.hiddenRows, isEmpty);
    });
  });
}
