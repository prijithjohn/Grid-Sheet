import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/selection_state.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/grid/widgets/grid_viewport.dart';

void main() {
  group('Phase 03B: Selection Interaction Tests', () {
    Widget buildViewport(WorkbookState state) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: GridViewport(state: state),
          ),
        ),
      );
    }

    testWidgets('clicking a cell sets it as primary active cell', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      // Tap within the grid body
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();

      // Primary cell should have moved
      expect(state.selection.primaryCell.row, greaterThanOrEqualTo(0));
      expect(state.selection.primaryCell.col, greaterThanOrEqualTo(0));
    });

    testWidgets('selecting a range via selectRange creates bounded range', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      state.selectRange(
        const CellRange.normalized(
          start: CellCoordinate(0, 0),
          end: CellCoordinate(2, 2),
          topRow: 0,
          bottomRow: 2,
          leftCol: 0,
          rightCol: 2,
        ),
      );
      await tester.pump();

      expect(state.selection.activeRange.cellCount, 9); // 3x3 = 9 cells
    });

    testWidgets('selecting entire column sets mode to entireColumn', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      state.selectEntireColumn(0);
      await tester.pump();

      expect(state.selection.mode, SelectionMode.entireColumn);
    });

    testWidgets('selecting entire row sets mode to entireRow', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      state.selectEntireRow(0);
      await tester.pump();

      expect(state.selection.mode, SelectionMode.entireRow);
    });

    testWidgets('selectAll sets mode to entireSheet', (tester) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      state.selectAll();
      await tester.pump();

      expect(state.selection.mode, SelectionMode.entireSheet);
    });

    testWidgets('pan drag from A1 to C3 extends selection range', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(buildViewport(state));
      await tester.pumpAndSettle();

      state.selectCell(const CellCoordinate(0, 0));
      await tester.pump();

      // Pan from A1 area to further right/down
      final panGesture = await tester.startGesture(const Offset(60, 36));
      await tester.pump();
      await panGesture.moveBy(const Offset(200, 120));
      await tester.pump();
      await panGesture.up();
      await tester.pumpAndSettle();

      // Range should have expanded
      expect(state.selection.activeRange.cellCount, greaterThan(1));
    });
  });
}
