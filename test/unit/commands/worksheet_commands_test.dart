import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/core/commands/commands.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('AddWorksheetCommand - Lifecycle & Reversibility', () {
    late Workbook workbook;

    setUp(() {
      workbook = Workbook.createDefault();
    });

    test('adds sheet to workbook and removes on undo', () {
      final cmd = AddWorksheetCommand(workbook: workbook, name: 'Expenses');

      expect(workbook.sheetCount, equals(1));
      cmd.execute();
      expect(workbook.sheetCount, equals(2));
      expect(workbook.sheets[1].name, equals('Expenses'));

      cmd.undo();
      expect(workbook.sheetCount, equals(1));
      expect(workbook.containsSheetName('Expenses'), isFalse);

      cmd.execute();
      expect(workbook.sheetCount, equals(2));
      expect(workbook.sheets[1].name, equals('Expenses'));
    });

    test('inserts sheet at specific index and restores on undo', () {
      workbook.createSheet(name: 'SheetB');
      expect(workbook.sheets.map((s) => s.name), equals(['Sheet1', 'SheetB']));

      final cmd = AddWorksheetCommand(
        workbook: workbook,
        name: 'SheetA',
        index: 1,
      );
      cmd.execute();

      expect(
        workbook.sheets.map((s) => s.name),
        equals(['Sheet1', 'SheetA', 'SheetB']),
      );

      cmd.undo();
      expect(workbook.sheets.map((s) => s.name), equals(['Sheet1', 'SheetB']));
    });
  });

  group('RemoveWorksheetCommand - Safe Removal & Restoration', () {
    late Workbook workbook;

    setUp(() {
      workbook = Workbook(
        id: 'wb1',
        initialSheets: [
          Worksheet(id: 's1', name: 'Sheet1'),
          Worksheet(id: 's2', name: 'Sheet2'),
        ],
      );
    });

    test('removes sheet and restores with all cells intact on undo', () {
      final targetSheet = workbook.sheets[1];
      targetSheet.setCell(
        CellModel.fromInput(const CellCoordinate(0, 0), 'Data In Sheet 2'),
      );

      final cmd = RemoveWorksheetCommand(workbook: workbook, index: 1);
      expect(cmd.canExecute, isTrue);

      cmd.execute();
      expect(workbook.sheetCount, equals(1));
      expect(workbook.containsSheetName('Sheet2'), isFalse);

      cmd.undo();
      expect(workbook.sheetCount, equals(2));
      expect(workbook.sheets[1].name, equals('Sheet2'));
      expect(
        workbook.sheets[1].getCell(const CellCoordinate(0, 0))?.rawInput,
        equals('Data In Sheet 2'),
      );
    });

    test('rejects deletion of the last remaining worksheet in workbook', () {
      final singleSheetWb = Workbook.createDefault();
      final cmd = RemoveWorksheetCommand(workbook: singleSheetWb, index: 0);

      expect(cmd.canExecute, isFalse);
      expect(() => cmd.execute(), throwsStateError);
    });
  });

  group('RenameWorksheetCommand - Reversible Naming', () {
    late Workbook workbook;

    setUp(() {
      workbook = Workbook.createDefault();
    });

    test('renames sheet and restores previous name on undo', () {
      final cmd = RenameWorksheetCommand(
        workbook: workbook,
        index: 0,
        newName: 'Q1_Summary',
      );

      cmd.execute();
      expect(workbook.sheets[0].name, equals('Q1_Summary'));

      cmd.undo();
      expect(workbook.sheets[0].name, equals('Sheet1'));

      cmd.execute();
      expect(workbook.sheets[0].name, equals('Q1_Summary'));
    });
  });

  group('ReorderWorksheetCommand - Tab Ordering', () {
    late Workbook workbook;

    setUp(() {
      workbook = Workbook(
        id: 'wb1',
        initialSheets: [
          Worksheet(id: 's1', name: 'A'),
          Worksheet(id: 's2', name: 'B'),
          Worksheet(id: 's3', name: 'C'),
        ],
      );
    });

    test('reorders sheets and restores original sequence on undo', () {
      final cmd = ReorderWorksheetCommand(
        workbook: workbook,
        oldIndex: 0,
        newIndex: 2,
      );

      cmd.execute();
      expect(workbook.sheets.map((s) => s.name), equals(['B', 'C', 'A']));

      cmd.undo();
      expect(workbook.sheets.map((s) => s.name), equals(['A', 'B', 'C']));
    });
  });

  group('Dimension Resize Commands - Columns & Rows', () {
    late Worksheet sheet;

    setUp(() {
      sheet = Worksheet(id: 's1', name: 'Sheet1');
    });

    test('ResizeColumnCommand updates width and resets to default on undo', () {
      final cmd = ResizeColumnCommand(
        worksheet: sheet,
        colIndex: 2,
        newWidth: 200,
      );

      expect(sheet.getColumnWidth(2), equals(Worksheet.defaultColumnWidth));

      cmd.execute();
      expect(sheet.getColumnWidth(2), equals(200));

      cmd.undo();
      expect(sheet.getColumnWidth(2), equals(Worksheet.defaultColumnWidth));

      cmd.execute();
      expect(sheet.getColumnWidth(2), equals(200));
    });

    test('ResizeColumnCommand restores existing custom width on undo', () {
      sheet.setColumnWidth(1, 120);
      final cmd = ResizeColumnCommand(
        worksheet: sheet,
        colIndex: 1,
        newWidth: 180,
      );

      cmd.execute();
      expect(sheet.getColumnWidth(1), equals(180));

      cmd.undo();
      expect(sheet.getColumnWidth(1), equals(120));
    });

    test('ResizeRowCommand updates height and resets on undo', () {
      final cmd = ResizeRowCommand(
        worksheet: sheet,
        rowIndex: 5,
        newHeight: 50,
      );

      expect(sheet.getRowHeight(5), equals(Worksheet.defaultRowHeight));

      cmd.execute();
      expect(sheet.getRowHeight(5), equals(50));

      cmd.undo();
      expect(sheet.getRowHeight(5), equals(Worksheet.defaultRowHeight));

      cmd.execute();
      expect(sheet.getRowHeight(5), equals(50));
    });
  });
}
