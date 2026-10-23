import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/state.dart';
import 'package:grid_sheet/domain/domain.dart';

void main() {
  group('WorkbookState - Initialization & Reactive Invariants', () {
    test(
      'initializes with default workbook, Sheet1 active, and cursor at A1',
      () {
        final state = WorkbookState();

        expect(state.sheetCount, equals(1));
        expect(state.activeSheetIndex, equals(0));
        expect(state.activeWorksheet.name, equals('Sheet1'));
        expect(state.selection.primaryCell.a1, equals('A1'));
        expect(state.activeCellAddress, equals('A1'));
        expect(state.activeCell, isNull);
        expect(state.activeCellInput, isEmpty);
        expect(state.isDirty, isFalse);
        expect(state.canUndo, isFalse);
        expect(state.canRedo, isFalse);
        expect(state.filePath, isNull);
      },
    );

    test('selection changes update cursor properties and notify listeners', () {
      final state = WorkbookState();
      var notificationCount = 0;
      state.addListener(() => notificationCount++);

      state.selectCell(const CellCoordinate(2, 1)); // B3

      expect(notificationCount, equals(1));
      expect(state.selection.primaryCell.a1, equals('B3'));
      expect(state.activeCellAddress, equals('B3'));
    });
  });

  group('WorkbookState - Cell Mutations & Command Integration', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test('editActiveCell routes to CommandStack, marks dirty, and notifies listeners', () {
      var notifications = 0;
      state.addListener(() => notifications++);

      state.editActiveCell('Quarterly Report');

      expect(notifications, equals(1));
      expect(state.activeCell?.rawInput, equals('Quarterly Report'));
      expect(state.activeCellInput, equals('Quarterly Report'));
      expect(state.isDirty, isTrue);
      expect(state.canUndo, isTrue);
      expect(state.canRedo, isFalse);
    });

    test('editCellAt targets arbitrary coordinate without requiring selection change', () {
      const target = CellCoordinate(5, 5); // F6
      state.editCellAt(target, '999');

      expect(state.activeWorksheet.getCell(target)?.rawInput, equals('999'));
      expect(
        state.activeWorksheet.getCell(target)?.value,
        isA<NumberCellValue>(),
      );
      expect(state.isDirty, isTrue);
      expect(state.canUndo, isTrue);
    });

    test('clearSelection clears cells across active range and marks dirty', () {
      state.editCellAt(const CellCoordinate(0, 0), 'A1');
      state.editCellAt(const CellCoordinate(0, 1), 'B1');
      state.selectRange(CellRange.fromA1('A1:B1'));

      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0)),
        isNotNull,
      );
      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 1)),
        isNotNull,
      );

      state.clearSelection();

      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0)), isNull);
      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 1)), isNull);
      expect(state.canUndo, isTrue);
    });

    test('applyStyleToSelection updates styles and supports undo', () {
      state.editCellAt(const CellCoordinate(0, 0), 'Title');
      state.selectCell(const CellCoordinate(0, 0));

      state.applyStyleToSelection(
        (s) => s.copyWith(isBold: true, fontSize: 18),
      );

      expect(state.activeCell?.style.isBold, isTrue);
      expect(state.activeCell?.style.fontSize, equals(18));

      state.undo();
      expect(state.activeCell?.style.isBold, isFalse);
      expect(state.activeCell?.style.fontSize, equals(11)); // Default font size
    });
  });

  group('WorkbookState - Worksheet Operations', () {
    late WorkbookState state;

    setUp(() {
      state = WorkbookState();
    });

    test(
      'addWorksheet and removeWorksheetAt mutate workbook and notify listeners',
      () {
        var notifications = 0;
        state.addListener(() => notifications++);

        state.addWorksheet(name: 'Budget');
        expect(state.sheetCount, equals(2));
        expect(state.sheets[1].name, equals('Budget'));
        expect(notifications, equals(1));

        state.removeWorksheetAt(1);
        expect(state.sheetCount, equals(1));
        expect(notifications, equals(2));

        state.undo(); // Undo delete -> Budget re-inserted
        expect(state.sheetCount, equals(2));
        expect(state.sheets[1].name, equals('Budget'));
      },
    );

    test(
      'renameWorksheet and reorderWorksheets execute and reverse cleanly',
      () {
        state.addWorksheet(name: 'Tab2');
        state.addWorksheet(name: 'Tab3');

        state.renameWorksheet(0, 'Overview');
        expect(state.sheets[0].name, equals('Overview'));

        state.reorderWorksheets(0, 2);
        expect(
          state.sheets.map((s) => s.name),
          equals(['Tab2', 'Tab3', 'Overview']),
        );

        state.undo(); // Undo reorder
        expect(
          state.sheets.map((s) => s.name),
          equals(['Overview', 'Tab2', 'Tab3']),
        );

        state.undo(); // Undo rename
        expect(
          state.sheets.map((s) => s.name),
          equals(['Sheet1', 'Tab2', 'Tab3']),
        );
      },
    );

    test(
      'setActiveSheetIndex updates active sheet and resets selection to A1',
      () {
        state.addWorksheet(name: 'Sheet2');
        state.selectCell(const CellCoordinate(5, 5)); // F6 on Sheet1

        state.setActiveSheetIndex(1);

        expect(state.activeSheetIndex, equals(1));
        expect(state.activeWorksheet.name, equals('Sheet2'));
        expect(state.selection.primaryCell.a1, equals('A1'));
      },
    );

    test('resizeColumn and resizeRow update active worksheet dimensions', () {
      state.resizeColumn(0, 150);
      expect(state.activeColumnWidth, equals(150));

      state.resizeRow(0, 40);
      expect(state.activeRowHeight, equals(40));

      state.undo();
      expect(state.activeRowHeight, equals(Worksheet.defaultRowHeight));

      state.undo();
      expect(state.activeColumnWidth, equals(Worksheet.defaultColumnWidth));
    });
  });

  group('WorkbookState - Undo/Redo & Save Lifecycle', () {
    test('markClean resets dirty flag and records file path', () {
      final state = WorkbookState();
      state.editActiveCell('Unsaved change');
      expect(state.isDirty, isTrue);

      state.markClean(savedFilePath: 'C:/Documents/model.gsheet');
      expect(state.isDirty, isFalse);
      expect(state.filePath, equals('C:/Documents/model.gsheet'));
    });

    test('loadWorkbook clears history and installs fresh workbook', () {
      final state = WorkbookState();
      state.editActiveCell('Dirty edit');
      expect(state.canUndo, isTrue);

      final freshWb = Workbook(
        id: 'fresh',
        initialSheets: [Worksheet(id: 's', name: 'FreshSheet')],
      );
      state.loadWorkbook(freshWb, filePath: 'C:/test.gsheet');

      expect(state.workbook.id, equals('fresh'));
      expect(state.activeWorksheet.name, equals('FreshSheet'));
      expect(state.isDirty, isFalse);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.filePath, equals('C:/test.gsheet'));
    });

    test(
      'complex multi-step sequence executes with 100% reversible undo and redo',
      () {
        final state = WorkbookState();

        // 1. Edit A1
        state.selectCell(const CellCoordinate(0, 0));
        state.editActiveCell('Revenue');

        // 2. Edit A2
        state.selectCell(const CellCoordinate(1, 0));
        state.editActiveCell('50000');

        // 3. Select A1:A2 and apply Bold
        state.selectRange(CellRange.fromA1('A1:A2'));
        state.applyStyleToSelection((s) => s.copyWith(isBold: true));

        expect(
          state.activeWorksheet
              .getCell(const CellCoordinate(0, 0))
              ?.style
              .isBold,
          isTrue,
        );
        expect(
          state.activeWorksheet
              .getCell(const CellCoordinate(1, 0))
              ?.style
              .isBold,
          isTrue,
        );

        // Undo 3: Undo Bold
        expect(state.undo(), isTrue);
        expect(
          state.activeWorksheet
              .getCell(const CellCoordinate(0, 0))
              ?.style
              .isBold,
          isFalse,
        );
        expect(
          state.activeWorksheet
              .getCell(const CellCoordinate(1, 0))
              ?.style
              .isBold,
          isFalse,
        );
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(1, 0))?.rawInput,
          equals('50000'),
        );

        // Undo 2: Undo A2 edit
        expect(state.undo(), isTrue);
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(1, 0)),
          isNull,
        );
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput,
          equals('Revenue'),
        );

        // Undo 1: Undo A1 edit
        expect(state.undo(), isTrue);
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 0)),
          isNull,
        );
        expect(state.canUndo, isFalse);

        // Redo 1: Redo A1
        expect(state.redo(), isTrue);
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput,
          equals('Revenue'),
        );

        // Redo 2: Redo A2
        expect(state.redo(), isTrue);
        expect(
          state.activeWorksheet.getCell(const CellCoordinate(1, 0))?.rawInput,
          equals('50000'),
        );

        // Redo 3: Redo Bold
        expect(state.redo(), isTrue);
        expect(
          state.activeWorksheet
              .getCell(const CellCoordinate(0, 0))
              ?.style
              .isBold,
          isTrue,
        );
        expect(
          state.activeWorksheet
              .getCell(const CellCoordinate(1, 0))
              ?.style
              .isBold,
          isTrue,
        );
        expect(state.canRedo, isFalse);
      },
    );
  });
}
