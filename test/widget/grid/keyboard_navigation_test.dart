import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/workbook/screens/workbook_screen.dart';

void main() {
  group('Phase 03B: Keyboard Navigation Tests', () {
    WorkbookState makeState() =>
        WorkbookState(initialWorkbook: Workbook.createDefault());

    Widget buildApp(WorkbookState state) =>
        MaterialApp(home: WorkbookScreen(state: state));

    testWidgets('ArrowDown moves active cursor down one row', (tester) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(2, 2)); // C3

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(state.selection.primaryCell.row, 3);
      expect(state.selection.primaryCell.col, 2);
    });

    testWidgets('ArrowUp moves active cursor up one row', (tester) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(2, 2)); // C3

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(state.selection.primaryCell.row, 1);
      expect(state.selection.primaryCell.col, 2);
    });

    testWidgets('ArrowRight moves active cursor right one column', (
      tester,
    ) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(2, 2)); // C3

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(state.selection.primaryCell.row, 2);
      expect(state.selection.primaryCell.col, 3);
    });

    testWidgets('ArrowLeft moves active cursor left one column', (
      tester,
    ) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(2, 2)); // C3

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(state.selection.primaryCell.row, 2);
      expect(state.selection.primaryCell.col, 1);
    });

    testWidgets('Shift+ArrowDown extends selection range downward', (
      tester,
    ) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(0, 0)); // A1

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();

      // Should now span A1:A2 — 2 cells
      expect(state.selection.activeRange.cellCount, greaterThanOrEqualTo(2));
    });

    testWidgets('Shift+ArrowRight extends selection range to the right', (
      tester,
    ) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(0, 0)); // A1

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();

      expect(state.selection.activeRange.cellCount, greaterThanOrEqualTo(2));
    });

    testWidgets('Delete key clears the content of selected cells', (
      tester,
    ) async {
      final state = makeState();
      state.editCellAt(const CellCoordinate(0, 0), 'ToBeClearedValue');

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      state.selectCell(const CellCoordinate(0, 0));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(state.activeWorksheet.getCell(const CellCoordinate(0, 0)), isNull);
    });

    testWidgets('Tab advances cursor to next column', (tester) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(0, 0)); // A1

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(state.selection.primaryCell.col, greaterThanOrEqualTo(1));
    });

    testWidgets('Enter advances cursor to next row', (tester) async {
      final state = makeState();
      state.selectCell(const CellCoordinate(0, 0)); // A1

      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(state.selection.primaryCell.row, greaterThanOrEqualTo(1));
    });
  });
}
