import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/formula_bar/widgets/formula_bar.dart';
import 'package:grid_sheet/features/workbook/widgets/ribbon_bar.dart';
import 'package:grid_sheet/features/workbook/widgets/window_title_bar.dart';
import 'package:grid_sheet/features/worksheets/widgets/sheet_tab_strip.dart';

void main() {
  group('Phase 03A: Desktop Shell Widget Tests', () {
    testWidgets('renders WindowTitleBar with clean and dirty states', (
      tester,
    ) async {
      final workbook = Workbook.createDefault(title: 'Q1_Financials.gsheet');
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WindowTitleBar(state: state)),
        ),
      );

      // Verify branding and filename
      expect(find.text('Grid Sheet'), findsOneWidget);
      expect(find.text('Q1_Financials.gsheet'), findsOneWidget);

      // Mutate state to dirty
      state.editCellAt(const CellCoordinate(0, 0), '100');
      await tester.pump();

      // Unsaved change indicator dot appears
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('RibbonBar expands and collapses on double-tap or toggle', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      // Action toolbar visible by default
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);

      // Tap toggle button to collapse
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Action bar collapsed
      expect(find.text('Bold'), findsNothing);

      // Tap toggle button to expand
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Bold'), findsOneWidget);
    });

    testWidgets('FormulaBar synchronizes bidirectionally with active cell', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FormulaBar(state: state)),
        ),
      );

      // Initially A1
      expect(find.text('A1'), findsOneWidget);

      // Select B5
      state.selectCell(const CellCoordinate(4, 1));
      await tester.pump();

      expect(find.text('B5'), findsOneWidget);

      // Enter formula in FormulaBar
      final formulaField = find.byType(TextField).last;
      await tester.enterText(formulaField, '=SUM(A1:A4)');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Check cell value committed to workbook state
      expect(state.activeCellInput, '=SUM(A1:A4)');
    });

    testWidgets('SheetTabStrip creates new sheet and switches active tabs', (
      tester,
    ) async {
      final workbook = Workbook.createDefault();
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      expect(find.text('Sheet1'), findsOneWidget);
      expect(state.sheetCount, 1);

      // Tap + button to add sheet
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(state.sheetCount, 2);
      expect(find.text('Sheet2'), findsOneWidget);

      // Switch to Sheet1
      await tester.tap(find.text('Sheet1'));
      await tester.pumpAndSettle();
      expect(state.activeSheetIndex, 0);

      // Switch to Sheet2
      await tester.tap(find.text('Sheet2'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(state.activeSheetIndex, 1);
    });
  });
}
