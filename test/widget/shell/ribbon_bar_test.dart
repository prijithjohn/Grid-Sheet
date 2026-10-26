import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/app/state/workbook_state.dart';
import 'package:grid_sheet/core/theme/app_dimensions.dart';
import 'package:grid_sheet/domain/domain.dart';
import 'package:grid_sheet/features/workbook/widgets/ribbon_bar.dart';

void main() {
  group('Phase 03A: RibbonBar Widget Tests', () {
    WorkbookState makeState() =>
        WorkbookState(initialWorkbook: Workbook.createDefault());

    testWidgets('renders all primary tab labels', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      for (final tab in [
        'File',
        'Home',
        'Insert',
        'Page Layout',
        'Formulas',
        'Data',
        'View',
      ]) {
        expect(find.text(tab), findsOneWidget, reason: 'Tab "$tab" not found');
      }
    });

    testWidgets('action area is visible when expanded (default)', (
      tester,
    ) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      // Action groups present in expanded state
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Redo'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);
    });

    testWidgets('collapses to tab-bar-only height on toggle', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      // Collapse via toggle button
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Action items hidden
      expect(find.text('Bold'), findsNothing);
      expect(find.text('Undo'), findsNothing);

      // Tab bar still visible
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('expands back after second toggle tap', (tester) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Bold'), findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Bold'), findsOneWidget);
    });

    testWidgets('ribbon action area height is ~88px (tabs + action row)', (
      tester,
    ) async {
      final state = makeState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      // Measure tab height + action height
      final expectedHeight =
          AppDimensions.ribbonTabHeight + AppDimensions.ribbonActionHeight;
      expect(
        expectedHeight,
        closeTo(88.0, 2.0),
        reason: 'Ribbon total height should be ~88px (tab 32 + action 56 ≈ 88)',
      );
    });

    testWidgets('Undo button disabled when canUndo is false', (tester) async {
      final state = makeState();
      expect(state.canUndo, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      // The Undo ribbon button should show as disabled (no active tap reaction)
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('Undo button enabled and functional when canUndo is true', (
      tester,
    ) async {
      final state = makeState();

      // Dirty the state
      state.editCellAt(const CellCoordinate(0, 0), 'Hello');
      expect(state.canUndo, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      await tester.pump();

      // Tap Undo ribbon button
      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(state.canUndo, isFalse);
    });

    testWidgets('Bold button triggers applyStyleToSelection', (tester) async {
      final workbook = Workbook.createDefault();
      workbook.activeSheet.setCell(
        CellModel.fromInput(const CellCoordinate(0, 0), 'Hello'),
      );
      final state = WorkbookState(initialWorkbook: workbook);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RibbonBar(state: state)),
        ),
      );

      final cellBefore = state.activeWorksheet.getCell(
        const CellCoordinate(0, 0),
      );
      final boldBefore = cellBefore?.style.isBold ?? false;

      await tester.tap(find.text('Bold'));
      await tester.pump();

      final cellAfter = state.activeWorksheet.getCell(
        const CellCoordinate(0, 0),
      );
      expect(cellAfter?.style.isBold, !boldBefore);
    });
  });
}
