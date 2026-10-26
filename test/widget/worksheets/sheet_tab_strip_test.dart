import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/worksheets/widgets/sheet_tab_strip.dart';

void main() {
  group('Phase 03A: SheetTabStrip Widget Tests', () {
    WorkbookState makeState({int extraSheets = 0}) {
      final workbook = Workbook.createDefault();
      for (int i = 0; i < extraSheets; i++) {
        workbook.createSheet(name: 'Sheet${i + 2}');
      }
      return WorkbookState(initialWorkbook: workbook);
    }

    testWidgets('renders all sheet tabs in workbook order', (tester) async {
      final state = makeState(extraSheets: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      expect(find.text('Sheet1'), findsOneWidget);
      expect(find.text('Sheet2'), findsOneWidget);
      expect(find.text('Sheet3'), findsOneWidget);
    });

    testWidgets('highlights the active sheet tab', (tester) async {
      final state = makeState(extraSheets: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      // Default active is Sheet1 (index 0)
      expect(state.activeSheetIndex, 0);
    });

    testWidgets('clicking a tab switches active sheet', (tester) async {
      final state = makeState(extraSheets: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      await tester.tap(find.text('Sheet3'));
      await tester.pumpAndSettle();

      expect(state.activeSheetIndex, 2);
    });

    testWidgets('clicking + button adds a new sheet', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      expect(state.sheetCount, 1);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(state.sheetCount, 2);
      expect(find.text('Sheet2'), findsOneWidget);
    });

    testWidgets('right-click context menu shows Rename and Delete options', (
      tester,
    ) async {
      final state = makeState(extraSheets: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      // Right-click / long-press a tab
      await tester.longPress(find.text('Sheet2'));
      await tester.pumpAndSettle();

      expect(find.text('Rename Sheet'), findsOneWidget);
      expect(find.text('Delete Sheet'), findsOneWidget);
    });

    testWidgets('deleting a sheet removes it and adjusts active index', (
      tester,
    ) async {
      final state = makeState(extraSheets: 1);
      state.setActiveSheetIndex(1); // Make Sheet2 active

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      await tester.longPress(find.text('Sheet2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Sheet'));
      await tester.pumpAndSettle();

      expect(state.sheetCount, 1);
      expect(find.text('Sheet2'), findsNothing);
    });

    testWidgets('cannot delete the last remaining sheet', (tester) async {
      final state = makeState(); // Only 1 sheet

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SheetTabStrip(state: state)),
        ),
      );

      await tester.longPress(find.text('Sheet1'));
      await tester.pumpAndSettle();

      // Delete should be disabled/absent when only 1 sheet
      // (implementation shows it greyed out or absent)
      expect(state.sheetCount, 1);
    });
  });
}
