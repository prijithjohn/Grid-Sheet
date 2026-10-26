import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/selection_state.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/workbook/screens/workbook_screen.dart';

void main() {
  group('Phase 03A: Desktop Keyboard Shortcuts Tests', () {
    WorkbookState makeState() {
      final workbook = Workbook.createDefault();
      return WorkbookState(initialWorkbook: workbook);
    }

    testWidgets('Ctrl+Z invokes WorkbookState.undo()', (tester) async {
      final state = makeState();

      await tester.pumpWidget(MaterialApp(home: WorkbookScreen(state: state)));
      await tester.pumpAndSettle();

      // Make an edit to enable undo
      state.editCellAt(const CellCoordinate(0, 0), 'EditedValue');
      await tester.pump();
      expect(state.canUndo, isTrue);

      // Press Ctrl+Z
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(state.canUndo, isFalse);
      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0)), isNull);
    });

    testWidgets('Ctrl+Y invokes WorkbookState.redo()', (tester) async {
      final state = makeState();

      await tester.pumpWidget(MaterialApp(home: WorkbookScreen(state: state)));
      await tester.pumpAndSettle();

      // Edit then undo to enable redo
      state.editCellAt(const CellCoordinate(0, 0), 'EditedValue');
      state.undo();
      await tester.pump();
      expect(state.canRedo, isTrue);

      // Press Ctrl+Y
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(state.canRedo, isFalse);
      expect(state.activeCellInput, 'EditedValue');
    });

    testWidgets('Ctrl+A selects entire worksheet', (tester) async {
      final state = makeState();

      await tester.pumpWidget(MaterialApp(home: WorkbookScreen(state: state)));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(state.selection.mode, SelectionMode.entireSheet);
    });

    testWidgets('Delete key calls clearSelection', (tester) async {
      final state = makeState();

      // Populate a cell first
      state.editCellAt(const CellCoordinate(0, 0), 'ToBeDeleted');
      await tester.pumpWidget(MaterialApp(home: WorkbookScreen(state: state)));
      await tester.pumpAndSettle();

      // Press Delete
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0)), isNull);
    });
  });
}
