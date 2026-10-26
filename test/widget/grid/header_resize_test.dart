import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/grid/widgets/column_header_strip.dart';
import 'package:grid_sheet/features/grid/widgets/row_header_strip.dart';

void main() {
  group('Phase 03B: Header Resize Tests', () {
    testWidgets('ColumnHeaderStrip renders visible column labels', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: ColumnHeaderStrip(
                state: state,
                scrollX: 0,
                viewportWidth: 800,
              ),
            ),
          ),
        ),
      );

      // Columns A through some visible range should be shown
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('RowHeaderStrip renders visible row number labels', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: RowHeaderStrip(
                state: state,
                scrollY: 0,
                viewportHeight: 600,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('dragging column resize handle changes column width', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());
      final initialWidth = state.activeWorksheet.getColumnWidth(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: ColumnHeaderStrip(
                state: state,
                scrollX: 0,
                viewportWidth: 800,
              ),
            ),
          ),
        ),
      );

      // Drag the right edge of column A
      // Column A starts at x=0, default width is ~64px, so edge is ~64px
      final colAEdge = Offset(initialWidth, 12);

      final drag = await tester.startGesture(colAEdge);
      await drag.moveBy(const Offset(50, 0)); // widen by 50px
      await drag.up();
      await tester.pumpAndSettle();

      final newWidth = state.activeWorksheet.getColumnWidth(0);
      expect(newWidth, greaterThan(initialWidth));
    });

    testWidgets('dragging row resize handle changes row height', (
      tester,
    ) async {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());
      final initialHeight = state.activeWorksheet.getRowHeight(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: RowHeaderStrip(
                state: state,
                scrollY: 0,
                viewportHeight: 600,
              ),
            ),
          ),
        ),
      );

      // Drag the bottom edge of row 1
      final rowEdge = Offset(20, initialHeight);
      final drag = await tester.startGesture(rowEdge);
      await drag.moveBy(const Offset(0, 20)); // taller by 20px
      await drag.up();
      await tester.pumpAndSettle();

      final newHeight = state.activeWorksheet.getRowHeight(0);
      expect(newHeight, greaterThan(initialHeight));
    });

    test('resizeColumn clamps to minimum threshold', () {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      // Try setting an impossibly small width
      state.resizeColumn(0, 2.0);

      // Should be clamped to minColumnWidth (typically 20px)
      expect(
        state.activeWorksheet.getColumnWidth(0),
        greaterThanOrEqualTo(10.0),
      );
    });

    test('resizeRow clamps to minimum threshold', () {
      final state = WorkbookState(initialWorkbook: Workbook.createDefault());

      state.resizeRow(0, 2.0);

      expect(state.activeWorksheet.getRowHeight(0), greaterThanOrEqualTo(8.0));
    });
  });
}
