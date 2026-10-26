import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/grid/painters/grid_painter.dart';
import 'package:grid_sheet/features/grid/painters/selection_painter.dart';
import 'package:grid_sheet/features/grid/widgets/grid_viewport.dart';

void main() {
  group('Phase 03B: Grid Canvas / Painter Tests', () {
    testWidgets('GridPainter instantiates and paints without exception', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      workbook.activeSheet.setCell(
        CellModel.fromInput(const CellCoordinate(0, 0), 'Hello'),
      );

      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: GridViewport(state: state),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('GridPainter shouldRepaint returns true when scrollX changes', () {
      final worksheet = Workbook.createDefault().activeSheet;

      final a = GridPainter(
        worksheet: worksheet,
        scrollX: 0,
        scrollY: 0,
        viewportWidth: 800,
        viewportHeight: 600,
      );

      final b = GridPainter(
        worksheet: worksheet,
        scrollX: 50,
        scrollY: 0,
        viewportWidth: 800,
        viewportHeight: 600,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test('GridPainter shouldRepaint returns false when nothing changes', () {
      final worksheet = Workbook.createDefault().activeSheet;

      final a = GridPainter(
        worksheet: worksheet,
        scrollX: 10,
        scrollY: 20,
        viewportWidth: 800,
        viewportHeight: 600,
      );

      final b = GridPainter(
        worksheet: worksheet,
        scrollX: 10,
        scrollY: 20,
        viewportWidth: 800,
        viewportHeight: 600,
      );

      expect(b.shouldRepaint(a), isFalse);
    });

    test('SelectionPainter shouldRepaint triggers on scroll change', () {
      final workbook = Workbook.createDefault();
      final state = WorkbookState(initialWorkbook: workbook);

      final a = SelectionPainter(
        worksheet: workbook.activeSheet,
        selection: state.selection,
        scrollX: 0,
        scrollY: 0,
      );

      final b = SelectionPainter(
        worksheet: workbook.activeSheet,
        selection: state.selection,
        scrollX: 100,
        scrollY: 50,
      );

      expect(b.shouldRepaint(a), isTrue);
    });

    test(
      'SelectionPainter shouldRepaint returns false when state identical',
      () {
        final workbook = Workbook.createDefault();
        final state = WorkbookState(initialWorkbook: workbook);

        final a = SelectionPainter(
          worksheet: workbook.activeSheet,
          selection: state.selection,
          scrollX: 0,
          scrollY: 0,
        );

        final b = SelectionPainter(
          worksheet: workbook.activeSheet,
          selection: state.selection,
          scrollX: 0,
          scrollY: 0,
        );

        expect(b.shouldRepaint(a), isFalse);
      },
    );

    testWidgets('cells with fill colors are rendered without error', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      workbook.activeSheet.setCell(
        CellModel.fromInput(
          const CellCoordinate(0, 0),
          'Green Header',
          style: const CellStyle(fillColor: 0xFFE2F0D9, isBold: true),
        ),
      );

      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: GridViewport(state: state),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
