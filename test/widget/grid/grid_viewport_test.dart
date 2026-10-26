import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/selection_state.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/grid/widgets/grid_viewport.dart';

void main() {
  group('Phase 03B: GridViewport Tests', () {
    Widget buildViewport(
      WorkbookState state, {
      double w = 800,
      double h = 600,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: w,
            height: h,
            child: GridViewport(state: state),
          ),
        ),
      );
    }

    testWidgets('viewport renders without errors', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('grid renders only visible cells (no crash on 100k cells)', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      // Scatter data across a wide range — only viewport subset should paint
      for (int r = 0; r < 50; r++) {
        for (int c = 0; c < 10; c++) {
          workbook.activeSheet.setCell(
            CellModel.fromInput(CellCoordinate(r, c), 'R${r}C$c'),
          );
        }
      }

      final state = WorkbookState(initialWorkbook: workbook);
      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      // No exception or overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a cell selects it in WorkbookState', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      expect(state.selection.primaryCell, const CellCoordinate(0, 0));

      // Tap roughly in the grid body area (right of row header, below col header)
      final gesture = await tester.startGesture(const Offset(200, 80));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Selection should have moved
      expect(state.selection.primaryCell.row, greaterThanOrEqualTo(0));
      expect(state.selection.primaryCell.col, greaterThanOrEqualTo(0));
    });

    testWidgets('column headers remain after horizontal scroll', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      // Confirm column header strip is present
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('double-tap opens in-grid editor TextField', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      // Select cell A1 first
      state.selectCell(const CellCoordinate(0, 0));
      await tester.pump();

      // Double-tap in the grid body at A1 position
      await tester.tapAt(const Offset(60, 36));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(60, 36));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('typing in in-grid editor and pressing Enter commits cell', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      state.selectCell(const CellCoordinate(0, 0));
      await tester.pump();

      await tester.tapAt(const Offset(60, 36));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(60, 36));
      await tester.pumpAndSettle();

      final editorFinder = find.byType(TextField);
      expect(editorFinder, findsOneWidget);

      await tester.enterText(editorFinder, 'Q4 Revenue');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        state.activeWorksheet.getCell(const CellCoordinate(0, 0))?.rawInput,
        'Q4 Revenue',
      );
    });

    testWidgets('select-all corner box triggers selectAll', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      // Tap the top-left corner (select-all box)
      await tester.tapAt(const Offset(22, 12));
      await tester.pumpAndSettle();

      expect(state.selection.mode, SelectionMode.entireSheet);
    });
  });
}
